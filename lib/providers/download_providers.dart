import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/download/model_downloader.dart';
import 'storage_providers.dart';

enum DownloadPhase { idle, downloading, finalizing, done, failed }

/// Live provisioning state surfaced to the block-screen UI.
class DownloadState {
  final DownloadPhase phase;
  final double progress;
  final int received;
  final int? total;
  final String? error;

  const DownloadState({
    this.phase = DownloadPhase.idle,
    this.progress = 0.0,
    this.received = 0,
    this.total,
    this.error,
  });

  DownloadState copyWith({
    DownloadPhase? phase,
    double? progress,
    int? received,
    int? total,
    String? error,
  }) => DownloadState(
    phase: phase ?? this.phase,
    progress: progress ?? this.progress,
    received: received ?? this.received,
    total: total ?? this.total,
    error: error ?? this.error,
  );
}

/// Drives the block-screen model download with resume support.
class DownloadNotifier extends Notifier<DownloadState> {
  StreamSubscription<DownloadProgress>? _subscription;
  bool _cancelled = false;
  bool _busy = false;

  @override
  DownloadState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const DownloadState();
  }

  Future<DownloadResult?> start() async {
    if (_busy) return null;
    _busy = true;
    _cancelled = false;

    // Pre-check: is a verified model already present?
    try {
      final dir = await ref.read(documentsDirProvider.future);
      if (await ModelDownloader.instance.isModelPresent(dir)) {
        final result = await ModelDownloader.instance.finalize(
          dir,
        ); // no-op for an already-verified file
        state = state.copyWith(phase: DownloadPhase.done, progress: 1.0);
        _busy = false;
        return result;
      }
    } catch (e) {
      state = state.copyWith(
        phase: DownloadPhase.failed,
        error: 'Storage error: $e',
      );
      _busy = false;
      return null;
    }

    state = state.copyWith(
      phase: DownloadPhase.downloading,
      error: null,
      progress: 0.0,
    );

    final completer = Completer<DownloadResult?>();

    try {
      final dir = await ref.read(documentsDirProvider.future);
      final stream = ModelDownloader.instance.start(dir);
      _subscription = stream.listen(
        (p) {
          state = state.copyWith(
            phase: DownloadPhase.downloading,
            progress: p.smoothFraction,
            received: p.received,
            total: p.total,
          );
        },
        onError: (Object e) {
          if (_cancelled) return;
          state = state.copyWith(
            phase: DownloadPhase.failed,
            error: 'Download error: $e',
          );
          if (!completer.isCompleted) completer.complete(null);
        },
        onDone: () async {
          if (_cancelled) {
            if (!completer.isCompleted) completer.complete(null);
            return;
          }
          state = state.copyWith(
            phase: DownloadPhase.finalizing,
            progress: .95,
          );
          final result = await ModelDownloader.instance.finalize(dir);
          state = state.copyWith(
            phase: result is DownloadSuccess
                ? DownloadPhase.done
                : DownloadPhase.failed,
            progress: result is DownloadSuccess ? 1.0 : state.progress,
            error: result is DownloadFailure ? result.message : null,
          );
          if (!completer.isCompleted) completer.complete(result);
        },
      );
      return completer.future;
    } catch (e) {
      state = state.copyWith(
        phase: DownloadPhase.failed,
        error: 'Provisioning error: $e',
      );
      _busy = false;
      return null;
    } finally {
      _busy = false;
    }
  }

  /// Aborts the in-flight download (leaves the `.part` for a future resume).
  Future<void> cancel() async {
    _cancelled = true;
    await _subscription?.cancel();
    state = state.copyWith(phase: DownloadPhase.failed, error: 'Cancelled');
  }
}

final downloadProvider = NotifierProvider<DownloadNotifier, DownloadState>(
  DownloadNotifier.new,
);
