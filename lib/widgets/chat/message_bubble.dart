import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/chat_message.dart';
import '../../theme/app_colors.dart';

/// Renders a single persisted turn. Assistant replies are processed into
/// Markdown exactly once (the text is final from the DB) — never per token.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(Theme.of(context).brightness);
    final isUser = !message.isAssistant;

    final background =
        isUser ? colors.bubbleUser : colors.bubbleAssistant;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final maxWidth = MediaQuery.of(context).size.width * 0.82;

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: isUser ? _userBody(context) : _assistantBody(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userBody(BuildContext context) {
    final colors = AppColors.of(Theme.of(context).brightness);
    return Text(
      message.body,
      style: TextStyle(
        fontSize: 15.5,
        height: 1.5,
        color: colors.textPrimary,
      ),
    );
  }

  Widget _assistantBody(BuildContext context) {
    final colors = AppColors.of(Theme.of(context).brightness);
    return MarkdownBody(
      data: message.body,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: TextStyle(fontSize: 15.5, height: 1.5, color: colors.textPrimary),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13.5,
          backgroundColor: colors.bubbleUser,
          color: colors.accentBrown,
        ),
        codeblockDecoration: BoxDecoration(
          color: colors.bubbleUser,
          borderRadius: BorderRadius.circular(8),
        ),
        blockquoteDecoration: BoxDecoration(
          color: colors.bubbleUser,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: colors.accentBrown, width: 3)),
        ),
      ),
    );
  }
}