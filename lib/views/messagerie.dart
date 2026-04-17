// messagerie_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/message_controller.dart';
import '../models/message_model.dart';

class MessageriePage extends StatefulWidget {
  const MessageriePage({Key? key}) : super(key: key);

  @override
  State<MessageriePage> createState() => _MessageriePageState();
}

class _MessageriePageState extends State<MessageriePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<MessageController>(context, listen: false);
      controller.chargerMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _envoyerMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() => _isSending = true);
    
    final controller = Provider.of<MessageController>(context, listen: false);
    final success = await controller.envoyerMessage(_messageController.text);
    
    setState(() => _isSending = false);
    
    if (success && mounted) {
      _messageController.clear();
      _scrollToBottom();
    } else if (controller.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final controller = Provider.of<MessageController>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messagerie',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Zone des messages
          Expanded(
            child: controller.isLoading && controller.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : controller.messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Aucun message',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Soyez le premier à envoyer un message !',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: controller.messages.length,
                        itemBuilder: (context, index) {
                          final message = controller.messages[index];
                          final isMyMessage = message.expediteurId == user?.uid;
                          return _buildMessageBubble(message, isMyMessage);
                        },
                      ),
          ),
          
          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Écrivez un message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _envoyerMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF003366),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isSending ? null : _envoyerMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMyMessage) {
    final isAdmin = message.expediteurRole == 'admin';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMyMessage
                    ? const Color(0xFF003366)
                    : (isAdmin ? Colors.orange[100] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom de l'expéditeur
                  Row(
                    children: [
                      Text(
                        message.expediteurNom,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isMyMessage
                              ? Colors.white70
                              : (isAdmin ? Colors.orange[800] : Colors.grey[700]),
                        ),
                      ),
                      if (isAdmin && !isMyMessage) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified, size: 12, color: Colors.orange[700]),
                      ],
                      const Spacer(),
                      Text(
                        _formatTime(message.dateEnvoi),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMyMessage ? Colors.white54 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Contenu du message
                  Text(
                    message.contenu,
                    style: TextStyle(
                      color: isMyMessage ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}