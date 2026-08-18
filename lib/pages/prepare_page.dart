import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/model_metadata.dart';
import '../providers/download_providers.dart';
import '../providers/inference_providers.dart';
import '../providers/storage_providers.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';

/// Non-dismissible model provisioning screen (Phase 2).
///
/// Shows progress %, MB transferred vs total, and a Wi-Fi warning. The engine
/// isolate is loaded the moment the verified GGUF is on disk, then the chat UI
/// unlocks automatically.
class PreparePage extends ConsumerStatefulWidget {
  const PreparePage({super.key});

  @override
  ConsumerState<PreparePage> createState() => _PreparePageState();
}

class _PreparePageState extends ConsumerState<PreparePage> {
  bool _started = false;

  Future<void> _begin() async {
    await ref.read(downloadProvider.notifier).start();
  }

  // Polls storage and ensures the engine is loaded whenever the model lands.
  Future<void> _ensureEngine() async {
    final done = ref.watch(downloadProvider).phase == DownloadPhase.done;
    if (!done) return;
    if (ref.read(inferenceEngineProvider) != null) return;

    final dir = await ref.read(documentsDirProvider.future);
    final modelPath = p.join(dir.path, ModelMetadata.modelFileName);
    await ref.read(inferenceEngineProvider.notifier).load(modelPath);
  }

  @override
  Widget build(BuildContext context) {
    final download = ref.watch(downloadProvider);
    final colors = AppColors.of(Theme.of(context).brightness);
    final theme = Theme.of(context);

    Future<void> init() async {
      if (_started) return;
      _started = true;
      await _begin();
    }

    // Kick off download on first build if not already complete/failed.
    if (download.phase == DownloadPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => init());
    }

    if (download.phase == DownloadPhase.done) {
      _ensureEngine();
    }

    final ready = download.phase == DownloadPhase.done &&
        ref.watch(inferenceEngineProvider) != null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colors.bubbleUser,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.download_rounded,
                        size: 30, color: colors.primaryBrown),
                  ),
                  const SizedBox(height: 20),
                  Text('Setting up your model',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    ready
                        ? 'Model loaded. Everything is ready to chat.'
                        : 'One-time download of the Gemma-2B model (about 1.5 GB) so you '
                            'can chat fully offline afterwards.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 28),

                  if (ready) ...[
                    const SizedBox(height: 8),
                    _ReadyButton(colors: colors),
                  ] else if (download.phase == DownloadPhase.failed) ...[
                    _ErrorState(download: download, colors: colors, onRetry: () {
                      ref.read(downloadProvider.notifier).start();
                    }),
                  ] else ...[
                    _ProgressArea(download: download, colors: colors),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.wifi_rounded,
                            size: 18, color: colors.accentBrown),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Wi-Fi is strongly recommended for this download.'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadyButton extends StatelessWidget {
  const _ReadyButton({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: () => Navigator.of(context).pushReplacementNamed('/chat'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        ),
        icon: const Icon(Icons.forward_rounded),
        label: const Text('Start chatting'),
      ),
    );
  }
}

class _ProgressArea extends StatelessWidget {
  const _ProgressArea({required this.download, required this.colors});
  final DownloadState download;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final received = download.received;
    final total = download.total ?? ModelMetadata.expectedSizeBytes;
    final percent = (download.progress * 100).clamp(0, 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (download.phase == DownloadPhase.finalizing)
          Text('Verifying model checksum\u2026',
              style: TextStyle(color: colors.accentBrown))
        else
          Text(
            '${formatBytes(received)} of ${formatBytes(total)}',
            style: TextStyle(color: colors.textSecondary),
          ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: download.progress,
            minHeight: 10,
            backgroundColor: colors.divider,
            color: colors.primaryBrown,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('$percent%',
                style: TextStyle(color: colors.textSecondary,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            if (download.phase == DownloadPhase.downloading)
              Text('downloading\u2026',
                  style: TextStyle(color: colors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.download,
    required this.colors,
    required this.onRetry,
  });

  final DownloadState download;
  final AppColors colors;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Something went wrong',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(download.error ?? 'Unknown error.',
            style: const TextStyle(color: Color(0xFFB3261E))),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry download'),
        ),
      ],
    );
  }
}