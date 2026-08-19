import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';

import '../../di/injection_container.dart' as di;
import '../../state/app_state.dart';
import '../../repositories/global_chat_repository.dart';
import '../../models/global_chat/global_chat_message.dart';
import '../../models/global_chat/attachment.dart';
import '../../models/global_chat/user_block.dart';
import '../../widgets/modern_snackbar.dart';
import '../../utils/media_picker_helper.dart';
import '../../widgets/modern_dialog.dart';
import '../../widgets/modern_bottom_sheet.dart';
import '../../widgets/safe_network_image.dart';
import '../../services/profile_service.dart';

class GlobalChatPage extends StatefulWidget {
  const GlobalChatPage({super.key});

  static const String routeName = '/global-chat';

  @override
  State<GlobalChatPage> createState() => _GlobalChatPageState();
}

class _GlobalChatPageState extends State<GlobalChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  GlobalChatRepository? _chatRepository;
  ProfileService? _profileService;
  List<GlobalChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  int _onlineCount = 0;
  bool _isSearching = false;
  String _searchQuery = '';
  int? _currentUserId;
  List<UserBlock> _blockedUsers = [];
  StreamSubscription? _messageSubscription;
  StreamSubscription? _onlineCountSubscription;
  StreamSubscription? _messageDeletedSubscription;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🎬 GlobalChatPage: initState вызван');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        print(
          '⏰ GlobalChatPage: addPostFrameCallback выполнен, запуск инициализации',
        );
      }
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('⚠️ GlobalChatPage: Уже инициализирован, пропускаем');
      }
      return;
    }

    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🚀 GlobalChatPage: Начало инициализации');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    // Устанавливаем состояние загрузки
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (kDebugMode) {
        print('📦 Получение зависимостей...');
      }
      _chatRepository = di.getIt<GlobalChatRepository>();
      _profileService = di.getIt<ProfileService>();

      if (kDebugMode) {
        print('✅ Зависимости получены');
        print('👤 Загрузка профиля...');
      }

      // Загружаем профиль для получения текущего user_id
      await _loadCurrentUserId();

      if (kDebugMode) {
        print('🚫 Загрузка заблокированных пользователей...');
      }

      // Загружаем список заблокированных пользователей
      await _loadBlockedUsers();

      if (kDebugMode) {
        print('📨 Загрузка сообщений...');
      }

      await _loadMessages();

      if (kDebugMode) {
        print('🔌 Подключение к WebSocket...');
      }

      await _connectWebSocket();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }

      if (kDebugMode) {
        print('✅ GlobalChatPage: Инициализация завершена');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ GlobalChatPage: Ошибка инициализации');
        print('   Error: $e');
        print('   StackTrace: $stackTrace');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: '${appState.t('global_chat_init_error')}: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _loadCurrentUserId() async {
    try {
      if (kDebugMode) {
        print('👤 Загрузка профиля для получения user_id...');
      }
      final profile = await _profileService!.getProfile();
      setState(() {
        _currentUserId = profile.user.id;
      });
      if (kDebugMode) {
        print('✅ User ID загружен: ${profile.user.id}');
      }
    } catch (e) {
      // Игнорируем ошибки загрузки профиля
      if (kDebugMode) {
        print('⚠️ Не удалось загрузить user_id: $e');
      }
    }
  }

  Future<void> _loadBlockedUsers() async {
    try {
      if (kDebugMode) {
        print('🚫 Загрузка заблокированных пользователей...');
      }
      final blockedUsers = await _chatRepository!.getBlockedUsers();
      setState(() {
        _blockedUsers = blockedUsers;
      });
      if (kDebugMode) {
        print('✅ Заблокированных пользователей: ${blockedUsers.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Не удалось загрузить заблокированных: $e');
      }
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('🔌 GlobalChatPage: dispose вызван');
    }
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    _onlineCountSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _chatRepository?.disconnectWebSocket();
    super.dispose();
  }

  Future<void> _loadMessages({bool forceRefresh = false}) async {
    if (_chatRepository == null) {
      if (kDebugMode) {
        print('⚠️ _loadMessages: _chatRepository == null');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    if (kDebugMode) {
      print('📨 Загрузка сообщений (forceRefresh: $forceRefresh)...');
    }

    if (mounted && !forceRefresh) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final messages = await _chatRepository!.loadMessages(
        skip: 0,
        limit: 100,
        forceRefresh: forceRefresh,
      );

      if (kDebugMode) {
        print('✅ Загружено сообщений: ${messages.length}');
      }

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }

      _scrollToBottom();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Ошибка загрузки сообщений: $e');
        print('   StackTrace: $stackTrace');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: '${appState.t('global_chat_load_error')}: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _connectWebSocket() async {
    if (_chatRepository == null) return;

    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔌 GlobalChatPage: Начало подключения WebSocket');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    try {
      if (kDebugMode) {
        print('📞 Вызов _chatRepository.connectWebSocket()...');
      }

      await _chatRepository!.connectWebSocket();

      if (kDebugMode) {
        print('✅ WebSocket подключен, настройка подписок...');
      }

      // Подписываемся на новые сообщения
      if (kDebugMode) {
        print('📨 Подписка на messageStream...');
      }
      _messageSubscription = _chatRepository!.messageStream.listen(
        (message) {
          if (kDebugMode) {
            print('💬 Получено новое сообщение через stream: ${message.id}');
          }
          if (mounted) {
            setState(() {
              if (!_messages.any((m) => m.id == message.id)) {
                _messages.insert(0, message);
              }
            });
            _scrollToBottom();
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('❌ Ошибка в messageStream: $error');
          }
        },
      );

      // Подписываемся на обновление онлайн
      if (kDebugMode) {
        print('👥 Подписка на onlineCountStream...');
      }
      _onlineCountSubscription = _chatRepository!.onlineCountStream.listen(
        (count) {
          if (kDebugMode) {
            print('👥 Обновление онлайн: $count');
          }
          if (mounted) {
            setState(() {
              _onlineCount = count;
            });
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('❌ Ошибка в onlineCountStream: $error');
          }
        },
      );

      // Подписываемся на удаленные сообщения
      if (kDebugMode) {
        print('🗑️ Подписка на messageDeletedStream...');
      }
      _messageDeletedSubscription = _chatRepository!.messageDeletedStream
          .listen(
            (messageId) {
              if (kDebugMode) {
                print('🗑️ Сообщение удалено: $messageId');
              }
              if (mounted) {
                setState(() {
                  _messages.removeWhere((m) => m.id == messageId);
                });
              }
            },
            onError: (error) {
              if (kDebugMode) {
                print('❌ Ошибка в messageDeletedStream: $error');
              }
            },
          );

      // Получаем начальное количество онлайн
      if (kDebugMode) {
        print('📊 Получение начального количества онлайн...');
      }
      final onlineCount = await _chatRepository!.getOnlineCount();
      if (kDebugMode) {
        print('📊 Начальное количество онлайн: $onlineCount');
      }
      if (mounted) {
        setState(() {
          _onlineCount = onlineCount;
        });
      }

      if (kDebugMode) {
        print('✅ GlobalChatPage: WebSocket подключение завершено');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ GlobalChatPage: Ошибка подключения WebSocket');
        print('   Error: $e');
        print('   StackTrace: $stackTrace');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: '${appState.t('global_chat_connect_error')}: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_chatRepository == null || !_isInitialized) {
      if (mounted) {
        ModernSnackBar.showError(
          context,
          message: 'Чат еще не готов. Подождите...',
        );
      }
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (mounted) {
      setState(() {
        _isSending = true;
      });
    }

    try {
      await _chatRepository!.sendTextMessage(text);
      if (mounted) {
        setState(() {
          _messageController.clear();
          _isSending = false;
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: '${appState.t('global_chat_send_error')}: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _pickAndSendFile(String fileType) async {
    if (_chatRepository == null || !_isInitialized) {
      if (mounted) {
        ModernSnackBar.showError(
          context,
          message: 'Чат еще не готов. Подождите...',
        );
      }
      return;
    }

    try {
      File? selectedFile;

      if (fileType == 'image') {
        final pickedFile = await MediaPickerHelper.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        if (pickedFile == null) return;
        selectedFile = File(pickedFile.path);
      } else if (fileType == 'video') {
        final pickedFile = await MediaPickerHelper.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 10),
        );
        if (pickedFile == null) return;
        selectedFile = File(pickedFile.path);
      } else if (fileType == 'audio' || fileType == 'file') {
        // Для аудио и файлов используем file_picker
        // Если пакет не установлен, показываем сообщение
        if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          ModernSnackBar.showError(
            context,
            message: appState.t('global_chat_file_picker_unavailable'),
          );
        }
        return;
      }

      if (selectedFile == null) return;

      // Проверяем размер файла (максимум 50 MB)
      final fileSize = await selectedFile.length();
      if (fileSize > 50 * 1024 * 1024) {
        if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          ModernSnackBar.showError(
            context,
            message: appState.t('global_chat_file_too_large'),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isSending = true;
        });
      }

      try {
        await _chatRepository!.sendFileMessage(
          file: selectedFile,
          fileType: fileType,
        );
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
        _scrollToBottom();
        if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          ModernSnackBar.showSuccess(
            context,
            message: appState.t('global_chat_file_sent'),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
          final appState = Provider.of<AppState>(context, listen: false);
          ModernSnackBar.showError(
            context,
            message: '${appState.t('global_chat_file_error')}: ${e.toString()}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: '${appState.t('global_chat_file_picker_error')}: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _searchMessages(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchQuery = '';
      });
      await _loadMessages(forceRefresh: true);
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final messages = await _chatRepository!.searchMessages(query: query);
      setState(() {
        _messages = messages;
      });
    } catch (e) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: '${appState.t('global_chat_search_error')}: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _blockUser(int userId, String userName) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final confirmed = await ModernDialog.show<bool>(
      context: context,
      title: appState.t('global_chat_block_user'),
      content: appState.t('global_chat_block_confirm').replaceAll('{userName}', userName),
      icon: Icons.block_rounded,
      iconColor: Colors.red,
      primaryAction: DialogAction(
        label: appState.t('global_chat_block'),
        onPressed: () {},
        isDestructive: true,
      ),
      secondaryAction: DialogAction(
        label: appState.t('cancel'),
        onPressed: () {},
      ),
    );

    if (confirmed != true) return;

    try {
      if (_chatRepository == null) return;
      await _chatRepository!.blockUser(userId);
      await _loadBlockedUsers();
      await _loadMessages(forceRefresh: true);
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showSuccess(
          context,
          message: appState.t('global_chat_user_blocked'),
        );
      }
    } catch (e) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: '${appState.t('global_chat_block_error')}: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _unblockUser(int userId) async {
    try {
      if (_chatRepository == null) return;
      await _chatRepository!.unblockUser(userId);
      await _loadBlockedUsers();
      await _loadMessages(forceRefresh: true);
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showSuccess(
          context,
          message: appState.t('global_chat_user_unblocked'),
        );
      }
    } catch (e) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: '${appState.t('global_chat_unblock_error')}: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _deleteMessage(GlobalChatMessage message) async {
    // Проверяем, что это сообщение текущего пользователя
    if (_currentUserId == null || message.userId != _currentUserId) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: appState.t('global_chat_only_own_messages'),
        );
      }
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final confirmed = await ModernDialog.show<bool>(
      context: context,
      title: appState.t('global_chat_delete_message'),
      content: appState.t('global_chat_delete_confirm'),
      icon: Icons.delete_outline_rounded,
      iconColor: Colors.red,
      primaryAction: DialogAction(
        label: appState.t('global_chat_delete'),
        onPressed: () {},
        isDestructive: true,
      ),
      secondaryAction: DialogAction(
        label: appState.t('cancel'),
        onPressed: () {},
      ),
    );

    if (confirmed != true) return;

    try {
      if (_chatRepository == null) return;
      await _chatRepository!.deleteMessage(message.id);
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == message.id);
        });
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showSuccess(context, message: appState.t('global_chat_message_deleted'));
      }
    } catch (e) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: '${appState.t('global_chat_delete_error')}: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _clearHistory() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final confirmed = await ModernDialog.show<bool>(
      context: context,
      title: appState.t('global_chat_clear_history_title'),
      content: appState.t('global_chat_clear_confirm'),
      icon: Icons.delete_sweep_rounded,
      iconColor: Colors.orange,
      primaryAction: DialogAction(
        label: appState.t('global_chat_clear'),
        onPressed: () {},
        isDestructive: true,
      ),
      secondaryAction: DialogAction(
        label: appState.t('cancel'),
        onPressed: () {},
      ),
    );

    if (confirmed != true) return;

    try {
      if (_chatRepository == null) return;
      final count = await _chatRepository!.clearHistory();
      if (mounted) {
        setState(() {
          _messages.clear();
        });
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showSuccess(
          context,
          message: '${appState.t('global_chat_history_cleared')} ($count ${appState.t('global_chat_message')} скрыто)',
        );
      }
    } catch (e) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: '${appState.t('global_chat_clear_error')}: ${e.toString()}',
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients && _messages.isNotEmpty) {
        try {
          // Для reverse: true прокручиваем к началу (к новым сообщениям)
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (e) {
          // Игнорируем ошибки прокрутки
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final appState = Provider.of<AppState>(context);
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appState.t('global_chat'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (_onlineCount > 0)
                  Text(
                    '${appState.t('global_chat_online')}: $_onlineCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => _SearchDialog(
                  onSearch: _searchMessages,
                  onCancel: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                    });
                    _loadMessages(forceRefresh: true);
                  },
                ),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'blocked',
                child: Builder(
                  builder: (context) {
                    final appState = Provider.of<AppState>(context);
                    return Row(
                      children: [
                        const Icon(Icons.block_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(appState.t('global_chat_blocked_users')),
                      ],
                    );
                  },
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Builder(
                  builder: (context) {
                    final appState = Provider.of<AppState>(context);
                    return Row(
                      children: [
                        const Icon(Icons.delete_sweep_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(appState.t('global_chat_clear_history')),
                      ],
                    );
                  },
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'clear') {
                _clearHistory();
              } else if (value == 'blocked') {
                _showBlockedUsersDialog();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final appState = Provider.of<AppState>(context);
                        return Text(
                          appState.t('global_chat_search_query').replaceAll('{query}', _searchQuery),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                      });
                      _loadMessages(forceRefresh: true);
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading && !_isInitialized
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final appState = Provider.of<AppState>(context);
                            return Text(
                              appState.t('global_chat_loading'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : _messages.isEmpty && !_isLoading
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () => _loadMessages(forceRefresh: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        try {
                          if (index >= _messages.length) {
                            return const SizedBox.shrink();
                          }
                          final message = _messages[index];
                          return _buildMessageBubble(message, index);
                        } catch (e) {
                          if (kDebugMode) {
                            print('❌ Ошибка построения сообщения: $e');
                          }
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
          ),
          _buildInputArea(),
        ],
      ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 40,
            ),
          ).animate().scale(duration: 500.ms, delay: 200.ms),
          const SizedBox(height: 24),
          Builder(
            builder: (context) {
              final appState = Provider.of<AppState>(context);
              return Text(
                appState.t('global_chat_no_messages_title'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
            },
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final appState = Provider.of<AppState>(context);
              return Text(
                appState.t('global_chat_start_conversation'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ).animate().fadeIn(duration: 400.ms, delay: 600.ms);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(GlobalChatMessage message, int index) {
    final isMyMessage =
        _currentUserId != null && message.userId == _currentUserId;
    final isBlocked = _blockedUsers.any((b) => b.blockedId == message.userId);

    // Не показываем заблокированные сообщения
    if (isBlocked) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
          onLongPress: () {
            if (isMyMessage) {
              // Показываем меню для удаления своего сообщения
              _showMessageMenu(message, isMyMessage: true);
            } else {
              // Показываем меню для блокировки пользователя
              _showMessageMenu(message, isMyMessage: false);
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: isMyMessage
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMyMessage) ...[
                  GestureDetector(
                    onTap: () {
                      // Можно добавить переход на профиль пользователя
                    },
                    child: SafeAvatar(
                      imageUrl: message.userAvatar,
                      radius: 16,
                      placeholderText: message.userName.isNotEmpty
                          ? message.userName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Column(
                    crossAxisAlignment: isMyMessage
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (!isMyMessage)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            message.userName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isMyMessage
                              ? const Color(0xFF1565C0)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMyMessage ? 4 : 20),
                            bottomRight: Radius.circular(isMyMessage ? 20 : 4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.message != null &&
                                message.message!.isNotEmpty)
                              Text(
                                message.message!,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isMyMessage
                                      ? Colors.white
                                      : Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            if (message.attachments != null &&
                                message.attachments!.isNotEmpty)
                              ...message.attachments!.map((attachment) {
                                return _buildAttachment(
                                  attachment,
                                  isMyMessage,
                                );
                              }),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(message.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isMyMessage
                                        ? Colors.white70
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                if (isMyMessage) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.done_all,
                                    size: 12,
                                    color: Colors.white70,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMyMessage) ...[
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                    child: const Icon(
                      Icons.person,
                      size: 16,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 30).ms)
        .slideY(begin: 0.2, end: 0, delay: (index * 30).ms);
  }

  void _showMessageMenu(
    GlobalChatMessage message, {
    required bool isMyMessage,
  }) {
    ModernBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMyMessage) ...[
            Builder(
              builder: (context) {
                final appState = Provider.of<AppState>(context);
                return ModernBottomSheetOption(
                  icon: Icons.delete_outline_rounded,
                  title: appState.t('global_chat_delete_message'),
                  iconColor: Colors.red,
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message);
                  },
                );
              },
            ),
          ] else ...[
            Builder(
              builder: (context) {
                final appState = Provider.of<AppState>(context);
                return ModernBottomSheetOption(
                  icon: Icons.block_rounded,
                  title: appState.t('global_chat_block_user'),
                  iconColor: Colors.red,
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _blockUser(message.userId, message.userName);
                  },
                );
              },
            ),
            Builder(
              builder: (context) {
                final appState = Provider.of<AppState>(context);
                return ModernBottomSheetOption(
                  icon: Icons.person_outline_rounded,
                  title: appState.t('global_chat_user_profile'),
                  subtitle: message.userName,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Переход на профиль пользователя
                  },
                );
              },
            ),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _showBlockedUsersDialog() {
    final appState = Provider.of<AppState>(context, listen: false);
    ModernBottomSheet.show(
      context: context,
      title: appState.t('global_chat_blocked_users'),
      showCloseButton: true,
      child: _blockedUsers.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.block_rounded,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(context);
                      return Text(
                        appState.t('global_chat_no_blocked_users'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: _blockedUsers.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final block = _blockedUsers[index];
                return Builder(
                  builder: (context) {
                    final appState = Provider.of<AppState>(context);
                    return ModernBottomSheetOption(
                      icon: Icons.person_off_rounded,
                      title: block.blockedUserName,
                      subtitle: '${appState.t('global_chat_blocked')} ${_formatDate(block.createdAt)}',
                      iconColor: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _unblockUser(block.blockedId);
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final appState = Provider.of<AppState>(context, listen: false);

    if (difference.inDays == 0) {
      return appState.t('global_chat_today');
    } else if (difference.inDays == 1) {
      return appState.t('global_chat_yesterday_lower');
    } else if (difference.inDays < 7) {
      return appState.t('global_chat_days_ago').replaceAll('{days}', difference.inDays.toString());
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  Widget _buildAttachment(Attachment attachment, bool isMyMessage) {
    if (attachment.type == 'image') {
      return GestureDetector(
        onTap: () {
          // Можно добавить полноэкранный просмотр изображения
        },
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isMyMessage ? Colors.white24 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SafeNetworkImage(
              imageUrl: attachment.url,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              placeholder: Container(
                width: 200,
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image_rounded),
              ),
            ),
          ),
        ),
      );
    } else if (attachment.type == 'video') {
      return GestureDetector(
        onTap: () {
          // Можно добавить воспроизведение видео
        },
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 150),
          decoration: BoxDecoration(
            color: isMyMessage
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isMyMessage ? Colors.white24 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.play_circle_filled_rounded,
                size: 48,
                color: isMyMessage ? Colors.white70 : Colors.grey.shade600,
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  attachment.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMyMessage ? Colors.white70 : Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (attachment.type == 'audio') {
      return GestureDetector(
        onTap: () {
          // Можно добавить воспроизведение аудио
          if (mounted) {
            final appState = Provider.of<AppState>(context, listen: false);
            ModernSnackBar.showInfo(
              context,
              message: appState.t('global_chat_audio_playback'),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMyMessage
                ? Colors.white.withOpacity(0.2)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isMyMessage ? Colors.white24 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMyMessage
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.audiotrack_rounded,
                  size: 24,
                  color: isMyMessage ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isMyMessage ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      attachment.sizeFormatted,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMyMessage
                            ? Colors.white70
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.play_circle_filled_rounded,
                size: 32,
                color: isMyMessage ? Colors.white70 : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      );
    } else {
      // Файл (file)
      return GestureDetector(
        onTap: () {
          // Можно добавить открытие файла
          if (mounted) {
            final appState = Provider.of<AppState>(context, listen: false);
            ModernSnackBar.showInfo(
              context,
              message: appState.t('global_chat_file_open'),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMyMessage
                ? Colors.white.withOpacity(0.2)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isMyMessage ? Colors.white24 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMyMessage
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileIcon(attachment.type),
                  size: 24,
                  color: isMyMessage ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isMyMessage ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      attachment.sizeFormatted,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMyMessage
                            ? Colors.white70
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.download_rounded,
                size: 20,
                color: isMyMessage ? Colors.white70 : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      );
    }
  }

  IconData _getFileIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.video_file_rounded;
      case 'audio':
        return Icons.audio_file_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Widget _buildInputArea() {
    return Container(
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.attach_file_rounded),
              onSelected: (value) {
                if (value == 'image') {
                  _pickAndSendFile('image');
                } else if (value == 'video') {
                  _pickAndSendFile('video');
                } else if (value == 'audio') {
                  _pickAndSendFile('audio');
                } else if (value == 'file') {
                  _pickAndSendFile('file');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'image',
                  child: Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(context);
                      return Row(
                        children: [
                          const Icon(Icons.image_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(appState.t('global_chat_attachment_image')),
                        ],
                      );
                    },
                  ),
                ),
                PopupMenuItem(
                  value: 'video',
                  child: Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(context);
                      return Row(
                        children: [
                          const Icon(Icons.video_library_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(appState.t('global_chat_attachment_video')),
                        ],
                      );
                    },
                  ),
                ),
                PopupMenuItem(
                  value: 'audio',
                  child: Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(context);
                      return Row(
                        children: [
                          const Icon(Icons.audio_file_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(appState.t('global_chat_attachment_audio')),
                        ],
                      );
                    },
                  ),
                ),
                PopupMenuItem(
                  value: 'file',
                  child: Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(context);
                      return Row(
                        children: [
                          const Icon(Icons.insert_drive_file_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(appState.t('global_chat_attachment_file')),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Builder(
                builder: (context) {
                  final appState = Provider.of<AppState>(context);
                  return TextField(
                    controller: _messageController,
                    enabled: !_isSending && _isInitialized,
                    decoration: InputDecoration(
                      hintText: _isInitialized
                          ? appState.t('global_chat_enter_message')
                          : appState.t('global_chat_loading'),
                      hintStyle: TextStyle(color: Colors.grey.shade500),
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
                      onSubmitted: (_) {
                        if (_isInitialized) {
                          _sendMessage();
                        }
                      },
                    );
                  },
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
                  onTap: (_isSending || !_isInitialized) ? null : _sendMessage,
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
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    final appState = Provider.of<AppState>(context, listen: false);

    if (difference.inMinutes < 1) {
      return appState.t('global_chat_just_now');
    } else if (difference.inHours < 1) {
      return appState.t('global_chat_minutes_ago').replaceAll('{minutes}', difference.inMinutes.toString());
    } else if (difference.inDays < 1) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _SearchDialog extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onCancel;

  const _SearchDialog({required this.onSearch, required this.onCancel});

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF1565C0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final appState = Provider.of<AppState>(context);
                        return Text(
                          appState.t('global_chat_search_messages'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                            letterSpacing: -0.3,
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.grey.shade400,
                    onPressed: () {
                      widget.onCancel();
                      Navigator.of(context).pop();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Builder(
                builder: (context) {
                  final appState = Provider.of<AppState>(context);
                  return TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: appState.t('global_chat_search_hint'),
                      prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    autofocus: true,
                    onSubmitted: (value) {
                      widget.onSearch(value);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onCancel();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(
                          color: Color(0xFF1565C0),
                          width: 1.5,
                        ),
                      ),
                      child: Builder(
                        builder: (context) {
                          final appState = Provider.of<AppState>(context);
                          return Text(
                            appState.t('cancel'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1565C0),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSearch(_searchController.text);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Builder(
                        builder: (context) {
                          final appState = Provider.of<AppState>(context);
                          return Text(
                            appState.t('global_chat_search'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 200.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 200.ms);
  }
}
