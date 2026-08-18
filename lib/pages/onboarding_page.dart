import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_providers.dart';
import '../theme/app_colors.dart';

/// First-launch, non-dismissible privacy disclosure (Phase 1).
///
/// Gates every other screen until the user explicitly acknowledges the
/// hardware / context constraints and the on-device privacy statement.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  bool _acknowledged = false;

  Future<void> _continue() async {
    if (!_acknowledged) return;
    await ref
        .read(acknowledgeOnboardingProvider.future)
        .catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(Theme.of(context).brightness);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gaima',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your private, on-device AI. No servers, no accounts, no analytics.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    _SectionCard(
                      title: 'Privacy first',
                      icon: Icons.lock_outline_rounded,
                      child: const Text(
                        'Everything runs directly on your phone. After the one-time model '
                        'download, the app works completely offline — your conversations '
                        'never leave the device.',
                      ),
                    ),
                    const SizedBox(height: 16),

                    _SectionCard(
                      title: 'Hardware expectations',
                      icon: Icons.memory_rounded,
                      children: const [
                        _FactRow('6\u20138 GB of free RAM recommended'),
                        _FactRow('Generation speed: 5\u201315 tokens / second'),
                        _FactRow(
                          'Prolonged use may cause warming and throttling',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _SectionCard(
                      title: 'Capabilities',
                      icon: Icons.chat_bubble_outline_rounded,
                      children: const [
                        _FactRow('Text input and output only — no images'),
                        _FactRow('2048-token rolling context window'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      value: _acknowledged,
                      onChanged: (v) =>
                          setState(() => _acknowledged = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('I understand these limits'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _acknowledged ? _continue : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    this.child,
    this.children,
  });

  final String title;
  final IconData icon;
  final Widget? child;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.accentBrown),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ?child,
          ...?children,
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 6, color: colors.accentBrown),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: colors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
