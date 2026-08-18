import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/inference/inference_engine.dart';

/// Lifecycle owner for the model handle. The gate screen loads it once the
/// verified GGUF is on disk; it is torn down cleanly on app close or restart.
class EngineNotifier extends Notifier<InferenceEngine?> {
  InferenceEngine? _engine;

  @override
  InferenceEngine? build() {
    ref.onDispose(() => _engine?.dispose());
    return null;
  }

  /// Spawns the managed inference isolate and loads [modelPath].
  Future<void> load(String modelPath) async {
    if (_engine != null) return;
    final engine = InferenceEngine(modelPath: modelPath);
    await engine.initialize();
    _engine = engine;
    state = engine;
  }

  /// Tears down the isolate and all session slots.
  Future<void> shutdown() async {
    final engine = _engine;
    _engine = null;
    state = null;
    await engine?.dispose();
  }
}

final inferenceEngineProvider =
    NotifierProvider<EngineNotifier, InferenceEngine?>(EngineNotifier.new);