import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Tin nhắn',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF9622E)),
            );
          }

          if (chatProvider.conversations.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa có tin nhắn nào.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.separated(
            itemCount: chatProvider.conversations.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) {
              final conversation = chatProvider.conversations[index];
              return ListTile(
                tileColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundImage: conversation.shopAvatarUrl != null
                      ? NetworkImage(conversation.shopAvatarUrl!)
                      : null,
                  backgroundColor: Colors.grey[200],
                  child: conversation.shopAvatarUrl == null
                      ? const Icon(Icons.store, color: Colors.grey)
                      : null,
                ),
                title: Text(
                  conversation.shopName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    conversation.lastMessage?.body ?? 'Chưa có tin nhắn',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: conversation.lastMessage?.senderType == 'SHOP_USER'
                          ? Colors.black87
                          : Colors.black54,
                      fontWeight:
                          conversation.lastMessage?.senderType == 'SHOP_USER'
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
                trailing: conversation.lastMessage != null
                    ? Text(
                        _formatTime(conversation.lastMessage!.createdAt),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        conversationId: conversation.id,
                        shopId: conversation.shopId,
                        shopName: conversation.shopName,
                        shopAvatarUrl: conversation.shopAvatarUrl,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else {
      return '\${time.day}/\${time.month}';
    }
  }
}
