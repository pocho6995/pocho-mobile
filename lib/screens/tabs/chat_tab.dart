import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../widgets/modern_snackbar.dart';
import '../../widgets/modern_dialog.dart';

enum MessageType { text, voice, video }

class ChatMessage {
  final String id;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final bool isMe;
  final String? userName;
  final String? userAvatar;
  final int? voiceDuration; // в секундах для голосовых
  final String? videoThumbnail; // для видео

  ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
    required this.isMe,
    this.userName,
    this.userAvatar,
    this.voiceDuration,
    this.videoThumbnail,
  });
}

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasText = false;
  final _messages = <ChatMessage>[
    ChatMessage(
      id: '1',
      text: 'Добро пожаловать в глобальный чат водителей PoCho!',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isMe: false,
      userName: 'PoCho',
      userAvatar: null,
    ),
    ChatMessage(
      id: '2',
      text: 'Поделитесь, где сейчас самые выгодные цены на топливо.',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      isMe: false,
      userName: 'PoCho',
      userAvatar: null,
    ),
  ];
  bool _isRecording = false;
  bool _isSearchMode = false;
  final _searchController = TextEditingController();
  final List<ChatMessage> _filteredMessages = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMessages.clear();
      } else {
        _filteredMessages.clear();
        _filteredMessages.addAll(
          _messages.where((msg) => msg.text.toLowerCase().contains(query)),
        );
      }
    });
  }

  void _showSearch() {
    setState(() {
      _isSearchMode = true;
    });
  }

  void _hideSearch() {
    setState(() {
      _isSearchMode = false;
      _searchController.clear();
    });
  }

  void _showChatMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _MenuTile(
                icon: Icons.notifications_outlined,
                title: 'Уведомления',
                subtitle: 'Включены',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Настройки уведомлений
                },
              ),
              _MenuTile(
                icon: Icons.volume_up_outlined,
                title: 'Звуки',
                subtitle: 'Включены',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Настройки звуков
                },
              ),
              _MenuTile(
                icon: Icons.block_outlined,
                title: 'Заблокированные',
                subtitle: '0 пользователей',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Список заблокированных
                },
              ),
              _MenuTile(
                icon: Icons.delete_outline,
                title: 'Очистить историю',
                subtitle: 'Удалить все сообщения',
                onTap: () {
                  Navigator.pop(context);
                  _showClearHistoryDialog();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearHistoryDialog() {
    ModernDialog.show(
      context: context,
      title: 'Очистить историю?',
      content: 'Все сообщения будут удалены. Это действие нельзя отменить.',
      icon: Icons.delete_outline_rounded,
      iconColor: Colors.red,
      primaryAction: DialogAction(
        label: 'Очистить',
        onPressed: () {
          setState(() {
            _messages.clear();
          });
        },
        isDestructive: true,
      ),
      secondaryAction: DialogAction(
        label: 'Отмена',
        onPressed: () {},
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    _AttachmentOption(
                      icon: Icons.photo_outlined,
                      label: 'Фото',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Выбрать фото
                        ModernSnackBar.showInfo(
                          context,
                          message: 'Выбор фото',
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    _AttachmentOption(
                      icon: Icons.videocam_outlined,
                      label: 'Видео',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _recordVideo();
                      },
                    ),
                    const SizedBox(width: 20),
                    _AttachmentOption(
                      icon: Icons.insert_drive_file_outlined,
                      label: 'Файл',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Выбрать файл
                        ModernSnackBar.showInfo(
                          context,
                          message: 'Выбор файла',
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    _AttachmentOption(
                      icon: Icons.location_on_outlined,
                      label: 'Местоположение',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Отправить местоположение
                        ModernSnackBar.showInfo(
                          context,
                          message: 'Отправка местоположения',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        type: MessageType.text,
        timestamp: DateTime.now(),
        isMe: true,
      ));
      _controller.clear();
    });
    _scrollToBottom();
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

  void _startVoiceRecording() {
    setState(() {
      _isRecording = true;
    });
    // TODO: Начать запись голоса
  }

  void _stopVoiceRecording() {
    setState(() {
      _isRecording = false;
    });
    // TODO: Остановить запись и отправить голосовое сообщение
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Голосовое сообщение',
        type: MessageType.voice,
        timestamp: DateTime.now(),
        isMe: true,
        voiceDuration: 15,
      ));
    });
    _scrollToBottom();
  }

  void _cancelVoiceRecording() {
    setState(() {
      _isRecording = false;
    });
    // TODO: Отменить запись
  }

  void _recordVideo() {
    // TODO: Открыть камеру для записи видео
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Видео сообщение',
        type: MessageType.video,
        timestamp: DateTime.now(),
        isMe: true,
        videoThumbnail: null,
      ));
    });
    _scrollToBottom();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else {
      return '${time.day}.${time.month}.${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.group_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Глобальный чат',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Онлайн: 127',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_isSearchMode)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: _hideSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: _showSearch,
            ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: _showChatMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          // Поисковая панель
          if (_isSearchMode)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Поиск в чате...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
            ),
          // Результаты поиска или список сообщений
          Expanded(
            child: _isSearchMode && _filteredMessages.isNotEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredMessages.length,
                    itemBuilder: (context, index) {
                      final message = _filteredMessages[index];
                      return ListTile(
                        leading: Icon(
                          message.type == MessageType.voice
                              ? Icons.mic_rounded
                              : message.type == MessageType.video
                                  ? Icons.videocam_rounded
                                  : Icons.message_rounded,
                          color: const Color(0xFF1565C0),
                        ),
                        title: Text(
                          message.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        onTap: () {
                          // TODO: Прокрутить к сообщению
                          _hideSearch();
                        },
                      );
                    },
                  )
                : _isSearchMode && _searchController.text.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Сообщения не найдены',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isFirst = index == 0 ||
                              _messages[index - 1]
                                      .timestamp
                                      .difference(message.timestamp)
                                      .inHours >
                                  0;
                          final isLast = index == _messages.length - 1 ||
                              _messages[index + 1]
                                      .timestamp
                                      .difference(message.timestamp)
                                      .inHours >
                                  0 ||
                              _messages[index + 1].isMe != message.isMe;

                          return _MessageBubble(
                            message: message,
                            isFirst: isFirst,
                            isLast: isLast,
                            formatTime: _formatTime,
                          )
                              .animate()
                              .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                              .slideX(
                                begin: message.isMe ? 0.2 : -0.2,
                                end: 0,
                                delay: (index * 50).ms,
                              );
                        },
                      ),
          ),
          // Индикатор записи голоса
          if (_isRecording)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                      .animate(onPlay: (controller) {
                    controller.repeat();
                  })
                      .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    duration: 500.ms,
                    curve: Curves.easeInOut,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Запись...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _cancelVoiceRecording,
                    child: const Text('Отменить'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _stopVoiceRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Отправить'),
                  ),
                ],
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
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    // Кнопка прикрепления
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showAttachmentMenu,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.attach_file_rounded,
                            color: Colors.grey.shade700,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Поле ввода
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 100),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Сообщение...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Кнопка записи голоса или отправки
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _hasText
                          ? Material(
                              key: const ValueKey('send'),
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _sendMessage,
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            )
                          : Material(
                              key: const ValueKey('mic'),
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _recordVideo,
                                onLongPress: _startVoiceRecording,
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.mic_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isFirst,
    required this.isLast,
    required this.formatTime,
  });

  final ChatMessage message;
  final bool isFirst;
  final bool isLast;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    if (message.isMe) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isFirst ? 20 : 4),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(isLast ? 20 : 4),
                      ),
                    ),
                    child: _buildMessageContent(),
                  ),
                  if (isLast)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4),
                      child: Text(
                        formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLast)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: message.userAvatar != null
                    ? ClipOval(
                        child: Image.network(
                          message.userAvatar!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLast && message.userName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(
                        message.userName!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isFirst ? 20 : 4),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(isLast ? 20 : 4),
                      ),
                    ),
                    child: _buildMessageContent(),
                  ),
                  if (isLast)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.text,
          style: TextStyle(
            fontSize: 15,
            color: message.isMe ? Colors.white : const Color(0xFF111827),
            height: 1.4,
          ),
        );
      case MessageType.voice:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_filled,
              color: message.isMe ? Colors.white : const Color(0xFF1565C0),
              size: 24,
            ),
            const SizedBox(width: 8),
            Container(
              width: 100,
              height: 4,
              decoration: BoxDecoration(
                color: message.isMe
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${message.voiceDuration ?? 0}с',
              style: TextStyle(
                fontSize: 13,
                color: message.isMe
                    ? Colors.white.withOpacity(0.9)
                    : Colors.grey.shade700,
              ),
            ),
          ],
        );
      case MessageType.video:
        return Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              if (message.videoThumbnail != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    message.videoThumbnail!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF1565C0),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
