import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_providers.dart';
import '../../theme/app_colors.dart';

/// Composer at the bottom. Switches to a Stop control while generating.
class Composer extends ConsumerStatefulWidget {
  const Composer({super.key});

  @override
  ConsumerState<Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<Composer> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    Future<void> send() async {
      await ref.read(chatProvider.notifier).sendMessage(text);
    }

    _controller.clear();
    setState(() => _hasText = false);
    send();
  }

  @override
  Widget build(BuildContext context) {
    final streaming = ref.watch(
        chatProvider.select((s) => s.generation.isStreaming));
    final colors = AppColors.of(Theme.of(context).brightness);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) =>
                    setState(() => _hasText = _controller.text.isNotEmpty),
                decoration: const InputDecoration(
                  hintText: 'Message',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Icon(Icons.chat_bubble_outline_rounded),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (streaming)
              _RoundButton(
                icon: Icons.stop_rounded,
                color: colors.accentBrown,
                onPressed: () => ref.read(chatProvider.notifier).stopGeneration(),
              )
            else
              _RoundButton(
                icon: Icons.arrow_upward_rounded,
                color: colors.primaryBrown,
                enabled: _hasText,
                onPressed: _send,
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.color,
    this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effective = onPressed != null && enabled ? onPressed : null;
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton.filled(
        onPressed: effective,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: effective == null ? Colors.grey : color,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}