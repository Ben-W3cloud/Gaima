import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../providers/chat_providers.dart';
import '../../theme/app_colors.dart';

/// Collapsed "Thinking\u2026" view that streams the raw response.
///
/// Auto-collapsed always — the user taps to expand and inspect the raw token
/// stream. The final text is NOT rendered here; that happens as a normal bubble
/// after streaming ends.
class ThinkingPill extends ConsumerWidget {
  const ThinkingPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatProvider);
    final gen = state.generation;
    final colors = AppColors.of(Theme.of(context).brightness);
    final expanded = state.rawVisible;

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bubbleAssistant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.divider),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => ref.read(chatProvider.notifier).toggleRawView(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.accentBrown,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Thinking\u2026',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: MarkdownBody(
                      data: gen.partial.isEmpty ? '…' : gen.partial,
                      selectable: true,
                      styleSheet:
                          MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}