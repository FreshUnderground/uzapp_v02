import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/auth_service.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/message_repository.dart';
import '../components/empty_state.dart';
import '../components/async_content.dart';
import '../components/custom_refresh_indicator.dart';
import '../../data/services/sync_service.dart';
import '../utils/page_transitions.dart';
import 'auth/login_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userPhone = context.watch<AuthService>().user?.phoneNumber ?? '';

    if (userPhone.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(context, 'messages'))),
        body: EmptyState(
          icon: Icons.chat_bubble_outline,
          title: tr(context, 'messages_empty'),
          subtitle: tr(context, 'messages_empty_hint'),
          actionLabel: tr(context, 'login'),
          onAction: () => Navigator.push(
            context,
            SlideUpRoute(page: const LoginScreen()),
          ),
        ),
      );
    }

    final msgRepo = context.watch<MessageRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'messages'))),
      body: UzaRefreshIndicator(
        onRefresh: () async {
          await context.read<SyncService>().syncNow();
        },
        child: StreamBuilder<List<ChatMessage>>(
          stream: msgRepo.watchInbox(userPhone),
          builder: (context, snapshot) {
            return AsyncContent<List<ChatMessage>>(
              snapshot: snapshot,
              builder: (all) {
          if (all.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: tr(context, 'messages_empty'),
                    subtitle: tr(context, 'messages_empty_hint'),
                  ),
                ),
              ],
            );
          }
          final threads = <String, ChatMessage>{};
          for (final m in all) {
            final other = m.senderPhone == userPhone
                ? m.receiverPhone
                : m.senderPhone;
            final key = msgRepo.threadKey(userPhone, other, shopId: m.shopId);
            threads.putIfAbsent(key, () => m);
          }
          final entries = threads.entries.toList()
            ..sort(
              (a, b) => b.value.createdAt.compareTo(a.value.createdAt),
            );

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final last = entries[index].value;
              final other = last.senderPhone == userPhone
                  ? last.receiverPhone
                  : last.senderPhone;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: UzaColors.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.person, color: UzaColors.primary),
                ),
                title: Text(other),
                subtitle: Text(
                  last.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: last.receiverPhone == userPhone && !last.isRead
                    ? const Icon(Icons.circle, size: 10, color: UzaColors.primary)
                    : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatThreadScreen(
                      userPhone: userPhone,
                      otherPhone: other,
                      shopId: last.shopId,
                    ),
                  ),
                ),
              );
            },
          );
              },
            );
          },
        ),
      ),
    );
  }
}

class ChatThreadScreen extends StatefulWidget {
  final String userPhone;
  final String otherPhone;
  final int? shopId;

  const ChatThreadScreen({
    super.key,
    required this.userPhone,
    required this.otherPhone,
    this.shopId,
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageRepository>().markThreadRead(
            userPhone: widget.userPhone,
            otherPhone: widget.otherPhone,
            shopId: widget.shopId,
          );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await context.read<MessageRepository>().sendMessage(
          senderPhone: widget.userPhone,
          receiverPhone: widget.otherPhone,
          body: text,
          shopId: widget.shopId,
        );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final msgRepo = context.watch<MessageRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.otherPhone)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: msgRepo.watchThread(
                userPhone: widget.userPhone,
                otherPhone: widget.otherPhone,
                shopId: widget.shopId,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final isMe = m.senderPhone == widget.userPhone;
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? UzaColors.primary.withValues(alpha: 0.15)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(m.body),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: tr(context, 'message_hint'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: UzaColors.primary),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
