import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/chat/composer.dart';
import '../widgets/chat/message_bubble.dart';
import '../widgets/chat/session_drawer.dart';
import '../widgets/chat/thinking_pill.dart';
import '../widgets/common/empty_state.dart';

/// The main chat screen. Hosts the session drawer, message history, streaming
/// "Thinking" pill, and the composer.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final colors = AppColors.of(Theme.of(context).brightness);
    final hasSession = chat.activeSessionId != null;

    // Scroll to bottom when messages or the streaming partial changes.
    ref.listen(chatProvider, (prev, next) {
      if (next.messages.length > (prev?.messages.length ?? 0) ||
          next.generation.partial.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Sessions',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Gaima'),
      ),
      drawer: const SessionDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: hasSession
                  ? _buildMessages(chat)
                  : EmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Start a conversation',
                      message:
                          'Open the menu to create a new chat and start '
                          'talking to Gaima, your private on-device assistant.',
                      action: FilledButton.icon(
                        onPressed: () =>
                            ref.read(chatProvider.notifier).newSession(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('New chat'),
                      ),
                    ),
            ),
            if (chat.generation.isStreaming) const ThinkingPill(),
            const Composer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(ChatState chat) {
    final hasMessages = chat.messages.isNotEmpty;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: hasMessages ? chat.messages.length : 1,
      itemBuilder: (context, index) {
        if (!hasMessages) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Say hello to start the conversation.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return MessageBubble(message: chat.messages[index]);
      },
    );
  }
}
