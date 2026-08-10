import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

import '../../di/injection_container.dart' as di;
import '../../repositories/support_repository.dart';
import '../../models/support/support_ticket.dart';
import '../../models/support/support_message.dart';
import '../../widgets/modern_snackbar.dart';

class SupportChatPage extends StatefulWidget {
  final int ticketId;

  const SupportChatPage({
    super.key,
    required this.ticketId,
  });

  static const String routeName = '/support-chat';

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late SupportRepository _supportRepository;
  SupportTicket? _ticket;
  List<SupportMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _supportRepository = di.getIt<SupportRepository>();
    _loadTicket();
    _connectToChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    _supportRepository.disconnectFromChat();
    super.dispose();
  }

  Future<void> _loadTicket() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ticket = await _supportRepository.loadTicket(widget.ticketId);
      setState(() {
        _ticket = ticket;
        _messages = ticket.messages ?? [];
        _isLoading = false;
      });

      // Отмечаем тикет как прочитанный
      if (!ticket.isReadByUser) {
        await _supportRepository.markAsRead(widget.ticketId);
      }

      // Прокрутка вниз
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ModernSnackBar.showError(
          context,
          message: 'Не удалось загрузить тикет: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _connectToChat() async {
    await _supportRepository.connectToTicketChat(widget.ticketId);

    // Подписываемся на новые сообщения через WebSocket
    _messageSubscription = _supportRepository.messageStream.listen((message) {
      if (message.ticketId == widget.ticketId) {
        setState(() {
          // Проверяем, нет ли уже такого сообщения
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.add(message);
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          }
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final message = await _supportRepository.sendMessage(
        ticketId: widget.ticketId,
        message: text,
      );

      setState(() {
        _messages.add(message);
        _messageController.clear();
        _isSending = false;
      });

      _scrollToBottom();

      // Обновляем тикет
      await _loadTicket();
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      if (mounted) {
        ModernSnackBar.showError(
          context,
          message: 'Не удалось отправить сообщение: ${e.toString()}',
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _ticket?.subject ?? 'Техническая поддержка',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_ticket != null)
              Text(
                _ticket!.status.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(_ticket!.status.colorValue),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Список сообщений
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState(context, isDark)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageBubble(
                              _messages[index],
                              context,
                              isDark,
                            )
                                .animate()
                                .fadeIn(
                                  duration: 300.ms,
                                  delay: 50.ms * index,
                                )
                                .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  delay: 50.ms * index,
                                );
                          },
                        ),
                ),
                // Поле ввода
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                    top: 12,
                    left: 16,
                    right: 16,
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            enabled: !_isSending,
                            decoration: InputDecoration(
                              hintText: 'Введите сообщение...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1565C0).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isSending ? null : _sendMessage,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: _isSending
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                              ),
                            ),
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

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 40,
            ),
          )
              .animate()
              .scale(duration: 500.ms, delay: 200.ms),
          const SizedBox(height: 24),
          const Text(
            'Начните диалог',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Напишите сообщение, и мы ответим вам в ближайшее время',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    SupportMessage message,
    BuildContext context,
    bool isDark,
  ) {
    final isFromUser = message.isFromUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromUser
                    ? const Color(0xFF1565C0)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isFromUser ? 4 : 20),
                  bottomRight: Radius.circular(isFromUser ? 20 : 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: isFromUser ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isFromUser ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inDays < 1) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
