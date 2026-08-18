import 'dart:async';

import 'package:llama_cpp_dart/llama_cpp_dart.dart';

import '../../core/chat_message.dart';
import '../../core/model_metadata.dart';

/// Result handle for one in-flight generation.
class GenerationHandle {
  final String sessionKey;
  final Stream<String> tokens;
  final Future<void> done;
  final Future<void> Function() stop;

  GenerationHandle({
    required this.sessionKey,
    required this.tokens,
    required this.done,
    required this.stop,
  });
}

/// Owns the llama_cpp_dart model handle and keeps it off the UI thread.
///
/// `LlamaParent` already runs inference inside its own managed isolate — the UI
/// frame never blocks on compute. Every chat session is given an independent KV
/// slot via [LlamaScope], so switching sessions rebuilds a clean, fully
/// independent inference context.
class InferenceEngine {
  InferenceEngine({required this.modelPath});

  final String modelPath;

  LlamaParent? _parent;
  final Map<int, LlamaScope> _scopes = {};
  bool _disposed = false;

  Future<void> initialize() async {
    if (_parent != null) return;

    final parent = LlamaParent(
      LlamaLoad(
        path: modelPath,
        modelParams: ModelParams()
          ..nGpuLayers =
              0 // CPU-only offload for the 2B model
          ..useMemorymap = true,
        contextParams: ContextParams()
          ..nCtx = ModelMetadata.contextTokens
          ..nBatch = 512
          ..nUbatch = 512
          ..nPredict = ModelMetadata.maxNewTokens,
        samplingParams: SamplerParams()
          ..temp = 0.7
          ..topK = 40
          ..topP = 0.95,
      ),
      GemmaFormat(),
    );

    await parent.init();
    _parent = parent;
  }

  LlamaScope _scopeFor(int sessionId) =>
      _scopes.putIfAbsent(sessionId, () => _parent!.getScope() as LlamaScope);

  bool get isGenerating => _parent?.isGenerating ?? false;
  bool get isInitialized => _parent != null;

  /// Starts a generation for [sessionId] from the already-trimmed [messages].
  ///
  /// Bridges the push-based engine stream into [GenerationHandle.tokens] and
  /// completes [GenerationHandle.done] exactly once — on success, error, or
  /// user Stop (the child fires a terminal event for all three).
  Future<GenerationHandle> generate({
    required int sessionId,
    required List<ChatMessage> messages,
  }) async {
    final parent = _parent;
    if (parent == null) throw StateError('Engine not initialized');
    if (_disposed) throw StateError('Engine disposed');

    final scope = _scopeFor(sessionId);

    // The Gemma formatter renders `parent.messages` when non-empty. Re-pushing
    // the full trimmed context each turn keeps sessions fully isolated.
    parent.messages = messages
        .map((m) => {'role': m.role.wireName, 'content': m.body})
        .toList();

    // Replays already-produced tokens to late subscribers, then continues live.
    final buffered = <String>[];
    final live = StreamController<String>();

    void emitToken(String token) {
      buffered.add(token);
      if (!live.isClosed) live.add(token);
    }

    final done = Completer<void>();

    void fail(Object e) {
      if (!done.isCompleted) done.completeError(e);
    }

    Stream<String> replay() async* {
      while (buffered.isNotEmpty) {
        yield buffered.removeAt(0);
      }
      yield* live.stream;
    }

    final tokenSub = scope.stream.listen(emitToken, onError: fail);
    final completionSub = scope.completions.listen((event) {
      if (done.isCompleted) return;
      if (event.success) {
        done.complete();
      } else {
        done.completeError(
          Exception(event.errorDetails ?? 'Generation failed'),
        );
      }
    }, onError: fail);

    Future<void> cleanup() async {
      if (!live.isClosed) await live.close();
      await tokenSub.cancel();
      await completionSub.cancel();
    }

    done.future.then((_) => cleanup(), onError: (_) => cleanup());

    await scope.sendPrompt(messages.isNotEmpty ? messages.last.body : '');

    return GenerationHandle(
      sessionKey: sessionId.toString(),
      tokens: replay(),
      done: done.future,
      stop: () => scope.stop(),
    );
  }

  /// Stops any in-flight generation for [sessionId] (clean isolate teardown).
  Future<void> stop(int sessionId) async {
    final scope = _scopes[sessionId];
    if (scope != null) await scope.stop();
  }

  /// Releases the managed isolate and every session slot.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _scopes.clear();
    await _parent?.dispose();
    _parent = null;
  }
}
