import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/chat_message.dart';
import '../core/chat_session.dart';
import '../services/inference/inference_engine.dart';
import '../services/storage/chat_dao.dart';
import '../utils/context_truncator.dart';
import 'inference_providers.dart';
import 'storage_providers.dart';

/// Live view of the active generation (the "Thinking" pill).
class GenerationView {
  final bool isStreaming;
  final String partial;
  final String? error;

  const GenerationView._({
    this.isStreaming = false,
    this.partial = '',
    this.error,
  });

  factory GenerationView.idle() => const GenerationView._();
  factory GenerationView.streaming(String partial) =>
      GenerationView._(isStreaming: true, partial: partial);
  factory GenerationView.error(String message) =>
      GenerationView._(error: message);
}

class ChatState {
  final List<ChatSession> sessions;
  final int? activeSessionId;
  final List<ChatMessage> messages;
  final bool rawVisible;
  final GenerationView generation;

  const ChatState({
    this.sessions = const [],
    this.activeSessionId,
    this.messages = const [],
    this.rawVisible = false,
    this.generation = const GenerationView._(),
  });

  ChatState copyWith({
    List<ChatSession>? sessions,
    int? Function()? activeSessionId,
    List<ChatMessage>? messages,
    bool? rawVisible,
    GenerationView? generation,
  }) =>
      ChatState(
        sessions: sessions ?? this.sessions,
        activeSessionId:
            activeSessionId != null ? activeSessionId() : this.activeSessionId,
        messages: messages ?? this.messages,
        rawVisible: rawVisible ?? this.rawVisible,
        generation: generation ?? this.generation,
      );
}

/// Coordinates session CRUD, message persistence, and streaming generation.
class ChatNotifier extends Notifier<ChatState> {
  ChatDao? _dao;
  ContextTruncator get _truncator => const ContextTruncator();
  StreamSubscription<String>? _tokenSub;
  String _running = '';

  @override
  ChatState build() {
    ref.onDispose(() => _tokenSub?.cancel());
    _bootstrap();
    return const ChatState();
  }

  Future<void> _bootstrap() async {
    final dao = await ref.read(chatDaoProvider.future);
    _dao = dao;
    final sessions = await dao.listSessions();
    state = state.copyWith(sessions: sessions);
  }

  // ---- Session management ------------------------------------------------

  Future<void> selectSession(int id) async {
    final dao = _dao!;
    _tokenSub?.cancel();
    final messages = await dao.messagesFor(id);
    state = state.copyWith(
      activeSessionId: () => id,
      messages: messages,
      generation: const GenerationView._(),
      rawVisible: false,
    );
  }

  Future<void> newSession() async {
    final dao = _dao!;
    final id = await dao.createSession('New chat');
    final sessions = await dao.listSessions();
    state = state.copyWith(
      sessions: sessions,
      activeSessionId: () => id,
      messages: const [],
      generation: const GenerationView._(),
      rawVisible: false,
    );
  }

  Future<void> deleteSession(int id) async {
    final dao = _dao!;
    _tokenSub?.cancel();
    await dao.deleteSession(id);
    final sessions = await dao.listSessions();
    final next = sessions.isNotEmpty ? sessions.first.id : null;
    final messages = next != null ? await dao.messagesFor(next) : const <ChatMessage>[];
    state = state.copyWith(
      sessions: sessions,
      activeSessionId: () => next,
      messages: messages,
      generation: const GenerationView._(),
    );
  }

  Future<void> renameSession(int id, String title) async {
    final dao = _dao!;
    await dao.renameSession(id, title);
    state = state.copyWith(sessions: await dao.listSessions());
  }

  // ---- Generation ---------------------------------------------------------

  /// Accepts, persists, and streams a reply to [text] in the active session.
  Future<void> sendMessage(String text) async {
    final dao = _dao!;
    final activeId = state.activeSessionId;
    final trimmedInput = text.trim();
    if (activeId == null || trimmedInput.isEmpty) return;
    if (state.generation.isStreaming) return;

    // Persist the user turn.
    await dao.insertMessage(ChatMessage(
      sessionId: activeId,
      role: Role.user,
      body: trimmedInput,
      timestamp: DateTime.now(),
    ));
    await dao.touchSession(activeId);
    final messages = await dao.messagesFor(activeId);
    state = state.copyWith(
      messages: messages,
      generation: const GenerationView._(isStreaming: true),
    );

    final engine = ref.read(inferenceEngineProvider);
    if (engine == null) {
      state = state.copyWith(
          generation: GenerationView.error('Model not loaded.'));
      return;
    }

    _running = '';
    final trimmed = _truncator.trim(messages);

    final GenerationHandle handle;
    try {
      handle = await engine.generate(sessionId: activeId, messages: trimmed);
    } catch (e) {
      state = state.copyWith(generation: GenerationView.error('$e'));
      return;
    }

    _tokenSub = handle.tokens.listen(
      (token) {
        _running += token;
        state = state.copyWith(
            generation: GenerationView.streaming(_running));
      },
      onError: (Object e) {
        state =
            state.copyWith(generation: GenerationView.error('Generation failed'));
      },
    );

    // Finalize on completion (includes user Stop), or surface error.
    await handle.done.then(
      (_) => _finalize(dao, activeId),
      onError: (Object e) => _finalizeError(activeId, '$e'),
    );
  }

  /// Cancels the in-flight generation (clean isolate stop via the scope).
  Future<void> stopGeneration() async {
    final activeId = state.activeSessionId;
    if (activeId == null || !state.generation.isStreaming) return;
    await ref.read(inferenceEngineProvider)?.stop(activeId);
  }

  /// Toggles the collapsible raw-stream ("Thinking") view.
  void toggleRawView() =>
      state = state.copyWith(rawVisible: !state.rawVisible);

  Future<void> _finalize(ChatDao dao, int sessionId) async {
    await _tokenSub?.cancel();
    final finalText = _running.trim().isEmpty ? '(no response)' : _running;
    await dao.insertMessage(ChatMessage(
      sessionId: sessionId,
      role: Role.assistant,
      body: finalText,
      timestamp: DateTime.now(),
    ));
    await dao.touchSession(sessionId);
    final messages = await dao.messagesFor(sessionId);
    state = state.copyWith(
      messages: messages,
      sessions: await dao.listSessions(),
      generation: const GenerationView._(),
      rawVisible: false,
    );
  }

  Future<void> _finalizeError(int sessionId, String error) async {
    await _tokenSub?.cancel();
    _running = '';
    state = state.copyWith(generation: GenerationView.error(error));
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);