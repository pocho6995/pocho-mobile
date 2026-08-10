import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/modern_snackbar.dart';
import '../di/injection_container.dart' as di;
import '../repositories/notification_repository.dart';
import '../models/notification/notification.dart' as notification_models;
import '../exceptions/auth_exceptions.dart';
import '../widgets/modern_dialog.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  static const String routeName = '/notifications';

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NotificationRepository _notificationRepository;
  String _selectedFilter = 'all';
  bool _isLoading = false;
  bool _isError = false;

  List<String> _getFilters(AppState appState) {
    return [
      appState.t('notifications_all'),
      appState.t('notifications_unread'),
      appState.t('notifications_promotions'),
      appState.t('notifications_prices'),
    ];
  }

  List<String> _getFilterKeys() {
    return ['all', 'unread', 'promotions', 'prices'];
  }

  // Общие уведомления (для всех пользователей) - user_id == null
  List<notification_models.Notification> _publicNotifications = [];
  // Личные уведомления (для конкретного пользователя) - user_id != null
  List<notification_models.Notification> _personalNotifications = [];

  // Рекламные блоки
  List<Map<String, dynamic>> _getAds(AppState appState) {
    return [
      {
        'title': appState.t('notifications_premium_title'),
        'subtitle': appState.t('notifications_premium_subtitle'),
        'icon': Icons.star_rounded,
        'color': [0xFFFF9800, 0xFFFFB74D],
      },
      {
        'title': appState.t('notifications_invite_title'),
        'subtitle': appState.t('notifications_invite_subtitle'),
        'icon': Icons.people_rounded,
        'color': [0xFF4CAF50, 0xFF81C784],
      },
    ];
  }

  List<notification_models.Notification> get _currentNotifications {
    return _tabController.index == 0
        ? _publicNotifications
        : _personalNotifications;
  }

  List<notification_models.Notification> get _filteredNotifications {
    final notifications = _currentNotifications;
    switch (_selectedFilter) {
      case 'unread':
        return notifications.where((n) => !n.isRead).toList();
      case 'promotions':
        return notifications
            .where(
              (n) =>
                  n.notificationType ==
                  notification_models.NotificationType.promotion,
            )
            .toList();
      case 'prices':
        return notifications
            .where(
              (n) =>
                  n.notificationType ==
                  notification_models.NotificationType.info,
            ) // Можно добавить отдельный тип для цен
            .toList();
      case 'info':
        return notifications
            .where(
              (n) =>
                  n.notificationType ==
                  notification_models.NotificationType.info,
            )
            .toList();
      case 'messages':
        return notifications
            .where(
              (n) =>
                  n.notificationType ==
                  notification_models.NotificationType.info,
            ) // Можно добавить отдельный тип для сообщений
            .toList();
      default:
        return notifications;
    }
  }

  int get _publicUnreadCount =>
      _publicNotifications.where((n) => !n.isRead).length;
  int get _personalUnreadCount =>
      _personalNotifications.where((n) => !n.isRead).length;

  String _formatTime(DateTime time, AppState appState) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return appState.t('notifications_just_now');
    } else if (difference.inMinutes < 60) {
      final form = _pluralize(difference.inMinutes, appState.t('notifications_minute_one'), appState.t('notifications_minute_few'), appState.t('notifications_minute_many'));
      return appState.t('notifications_minutes_ago').replaceAll('{minutes}', difference.inMinutes.toString()).replaceAll('{form}', form);
    } else if (difference.inHours < 24) {
      final form = _pluralize(difference.inHours, appState.t('notifications_hour_one'), appState.t('notifications_hour_few'), appState.t('notifications_hour_many'));
      return appState.t('notifications_hours_ago').replaceAll('{hours}', difference.inHours.toString()).replaceAll('{form}', form);
    } else if (difference.inDays == 1) {
      return appState.t('notifications_yesterday');
    } else if (difference.inDays < 7) {
      final form = _pluralize(difference.inDays, appState.t('notifications_day_one'), appState.t('notifications_day_few'), appState.t('notifications_day_many'));
      return appState.t('notifications_days_ago').replaceAll('{days}', difference.inDays.toString()).replaceAll('{form}', form);
    } else {
      return '${time.day}.${time.month}.${time.year}';
    }
  }

  String _pluralize(int count, String one, String few, String many) {
    if (count % 10 == 1 && count % 100 != 11) return one;
    if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return few;
    }
    return many;
  }

  @override
  void initState() {
    super.initState();
    _notificationRepository = di.getIt<NotificationRepository>();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedFilter = 'all'; // Сбрасываем фильтр при переключении вкладок
      });
    });
    _loadNotifications();
    _setupWebSocketListeners();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final response = await _notificationRepository.getNotifications(
        skip: 0,
        limit: 1000,
      );

      setState(() {
        // Разделяем на глобальные (user_id == null) и персональные (user_id != null)
        _publicNotifications = response.notifications
            .where((n) => n.userId == null)
            .toList();
        _personalNotifications = response.notifications
            .where((n) => n.userId != null)
            .toList();
        _isLoading = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
      });
      if (mounted) {
        ModernDialog.show(
          context: context,
          title: 'Ошибка',
          content: e.message,
          icon: Icons.error_outline_rounded,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
      });
      if (mounted) {
        ModernDialog.show(
          context: context,
          title: 'Ошибка',
          content: 'Не удалось загрузить уведомления. Попробуйте позже.',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  void _setupWebSocketListeners() {
    _notificationRepository.setOnNotificationReceived((notification) {
      if (mounted) {
        setState(() {
          if (notification.userId == null) {
            // Глобальное уведомление
            _publicNotifications.insert(0, notification);
          } else {
            // Персональное уведомление
            _personalNotifications.insert(0, notification);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await _notificationRepository.markAsRead(notificationId);
      setState(() {
        // Обновляем статус в общих уведомлениях
        final publicIndex = _publicNotifications.indexWhere(
          (n) => n.id == notificationId,
        );
        if (publicIndex != -1) {
          _publicNotifications[publicIndex] = _publicNotifications[publicIndex]
              .copyWith(isRead: true, readAt: DateTime.now());
          return;
        }

        // Обновляем статус в личных уведомлениях
        final personalIndex = _personalNotifications.indexWhere(
          (n) => n.id == notificationId,
        );
        if (personalIndex != -1) {
          _personalNotifications[personalIndex] =
              _personalNotifications[personalIndex].copyWith(
                isRead: true,
                readAt: DateTime.now(),
              );
        }
      });
    } catch (e) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: appState.t('notifications_mark_read_error'),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationRepository.markAllAsRead();
      setState(() {
        final now = DateTime.now();
        if (_tabController.index == 0) {
          _publicNotifications = _publicNotifications.map((notification) {
            return notification.copyWith(isRead: true, readAt: now);
          }).toList();
        } else {
          _personalNotifications = _personalNotifications.map((notification) {
            return notification.copyWith(isRead: true, readAt: now);
          }).toList();
        }
      });
      final appState = Provider.of<AppState>(context, listen: false);
      ModernSnackBar.showSuccess(
        context,
        message: _tabController.index == 0
            ? appState.t('notifications_mark_all_read_success_public')
            : appState.t('notifications_mark_all_read_success_personal'),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: appState.t('notifications_mark_all_read_error'),
        );
      }
    }
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Builder(
        builder: (context) {
          return Container(
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Builder(
                      builder: (context) {
                        final appState = Provider.of<AppState>(context);
                        return Row(
                          children: [
                            Text(
                              appState.t('notifications_additional_filters'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFilter = 'all';
                                });
                                Navigator.pop(context);
                              },
                              child: Text(appState.t('notifications_reset')),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(context);
                      final infoCount = _currentNotifications.where((n) => n.notificationType == notification_models.NotificationType.info).length;
                      final promotionCount = _currentNotifications.where((n) => n.notificationType == notification_models.NotificationType.promotion).length;
                      return Column(
                        children: [
                          _FilterMenuTile(
                            icon: Icons.info_outline_rounded,
                            title: appState.t('notifications_info'),
                            subtitle: appState.t('notifications_count').replaceAll('{count}', infoCount.toString()),
                            color: const Color(0xFF42A5F5),
                            onTap: () {
                              setState(() {
                                _selectedFilter = 'info';
                              });
                              Navigator.pop(context);
                            },
                          ),
                          _FilterMenuTile(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: appState.t('notifications_messages'),
                            subtitle: appState.t('notifications_count').replaceAll('{count}', infoCount.toString()),
                            color: const Color(0xFF4CAF50),
                            onTap: () {
                              setState(() {
                                _selectedFilter = 'messages';
                              });
                              Navigator.pop(context);
                            },
                          ),
                          _FilterMenuTile(
                            icon: Icons.local_offer_outlined,
                            title: appState.t('notifications_promotions_promo'),
                            subtitle: appState.t('notifications_count').replaceAll('{count}', promotionCount.toString()),
                            color: const Color(0xFFFF9800),
                            onTap: () {
                              setState(() {
                                _selectedFilter = 'promotions';
                              });
                              Navigator.pop(context);
                            },
                          ),
                          _FilterMenuTile(
                            icon: Icons.local_gas_station_outlined,
                            title: appState.t('notifications_price_changes'),
                            subtitle: appState.t('notifications_count').replaceAll('{count}', infoCount.toString()),
                            color: const Color(0xFF1565C0),
                            onTap: () {
                              setState(() {
                                _selectedFilter = 'prices';
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          appState.t('notifications'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF111827),
        actions: [
          if (_currentNotifications.any((n) => !n.isRead))
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.done_all_rounded),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              tooltip: appState.t('notifications_mark_all_read'),
              onPressed: _markAllAsRead,
            ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: appState.t('notifications_filters'),
            onPressed: _showFilterMenu,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(color: Colors.white),
            child: Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(context);
                      return _CustomTabButton(
                        label: appState.t('notifications_public'),
                        isSelected: _tabController.index == 0,
                        unreadCount: _publicUnreadCount,
                        onTap: () {
                          _tabController.animateTo(0);
                        },
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(context);
                      return _CustomTabButton(
                        label: appState.t('notifications_personal'),
                        isSelected: _tabController.index == 1,
                        unreadCount: _personalUnreadCount,
                        onTap: () {
                          _tabController.animateTo(1);
                        },
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7B1FA2), Color(0xFFBA68C8)],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Отступ между таббаром и фильтрами
          const SizedBox(height: 20),
          // Фильтры
          Builder(
            builder: (context) {
              final appState = Provider.of<AppState>(context);
              final filters = _getFilters(appState);
              final filterKeys = _getFilterKeys();
              return SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filters.length,
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    final filterKey = filterKeys[index];
                    final isSelected = filterKey == _selectedFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _FilterChip(
                        label: filter,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedFilter = filterKey;
                          });
                        },
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                          .slideX(
                            begin: -0.2,
                            end: 0,
                            delay: (index * 50).ms,
                          ),
                    );
                  },
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(begin: -0.1, end: 0);
            },
          ),
          const SizedBox(height: 16),
          // Список уведомлений с вкладками
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildNotificationsList(), _buildNotificationsList()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: Color(0xFF1565C0)),
        ),
      );
    }

    if (_isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final appState = Provider.of<AppState>(context);
                return Text(
                  appState.t('notifications_load_failed'),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final appState = Provider.of<AppState>(context);
                return ElevatedButton(
                  onPressed: _loadNotifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                  ),
                  child: Text(appState.t('notifications_try_again')),
                );
              },
            ),
          ],
        ),
      );
    }

    final filtered = _filteredNotifications;
    return filtered.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                      Icons.notifications_none_rounded,
                      size: 80,
                      color: Colors.grey.shade300,
                    )
                    .animate()
                    .scale(duration: 600.ms)
                    .then()
                    .shimmer(duration: 2000.ms),
                const SizedBox(height: 20),
                Builder(
                  builder: (context) {
                    final appState = Provider.of<AppState>(context);
                    return Text(
                      appState.t('notifications_empty'),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final appState = Provider.of<AppState>(context);
                    return Text(
                      _tabController.index == 0
                          ? appState.t('notifications_public_empty')
                          : appState.t('notifications_personal_empty'),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    );
                  },
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadNotifications,
            color: const Color(0xFF1565C0),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final notification = filtered[index];
                return Dismissible(
                  key: Key('notification_${notification.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onDismissed: (direction) {
                    // Сразу удаляем элемент из списка (синхронно)
                    final notificationToDelete = notification;
                    final wasPublic = notification.userId == null;

                    setState(() {
                      if (wasPublic) {
                        _publicNotifications.removeWhere(
                          (n) => n.id == notification.id,
                        );
                      } else {
                        _personalNotifications.removeWhere(
                          (n) => n.id == notification.id,
                        );
                      }
                    });

                    // Затем вызываем API асинхронно
                    _notificationRepository
                        .deleteNotification(notification.id)
                        .then((_) {
                          if (mounted) {
                            final appState = Provider.of<AppState>(context, listen: false);
                            ModernSnackBar.showSuccess(
                              context,
                              message: appState.t('notifications_deleted'),
                            );
                          }
                        })
                        .catchError((e) {
                          // Восстанавливаем уведомление при ошибке
                          if (mounted) {
                            setState(() {
                              if (wasPublic) {
                                _publicNotifications.insert(
                                  index,
                                  notificationToDelete,
                                );
                              } else {
                                _personalNotifications.insert(
                                  index,
                                  notificationToDelete,
                                );
                              }
                            });
                            final appState = Provider.of<AppState>(context, listen: false);
                            ModernSnackBar.showError(
                              context,
                              message: appState.t('notifications_delete_error'),
                            );
                          }
                        });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationCard(
                      notification: notification,
                      formatTime: (time) {
                        final appState = Provider.of<AppState>(context, listen: false);
                        return _formatTime(time, appState);
                      },
                      index: index,
                      onTap: () => _markAsRead(notification.id),
                    )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                            .slideY(begin: 0.2, end: 0, delay: (index * 50).ms),
                  ),
                );
              },
            ),
          );
  }
}

// Старые классы удалены, используем реальную модель Notification

class _CustomTabButton extends StatelessWidget {
  const _CustomTabButton({
    required this.label,
    required this.isSelected,
    required this.unreadCount,
    required this.onTap,
    required this.gradient,
  });

  final String label;
  final bool isSelected;
  final int unreadCount;
  final VoidCallback onTap;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: isSelected ? gradient : null,
                color: isSelected ? null : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.grey.shade300.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: gradient.colors.first.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.3)
                            : gradient.colors.first.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : gradient.colors.first,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        )
        .animate(target: isSelected ? 1 : 0)
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(0.98, 0.98),
          duration: 150.ms,
        );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.formatTime,
    required this.index,
    this.onTap,
  });

  final notification_models.Notification notification;
  final String Function(DateTime) formatTime;
  final int index;
  final VoidCallback? onTap;

  IconData _getIcon() {
    switch (notification.notificationType) {
      case notification_models.NotificationType.info:
        return Icons.info_rounded;
      case notification_models.NotificationType.warning:
        return Icons.warning_rounded;
      case notification_models.NotificationType.success:
        return Icons.check_circle_rounded;
      case notification_models.NotificationType.error:
        return Icons.error_rounded;
      case notification_models.NotificationType.promotion:
        return Icons.local_offer_rounded;
    }
  }

  Color _getIconColor() {
    return Color(notification.notificationType.colorValue);
  }

  Color _getBackgroundColor() {
    if (!notification.isRead) {
      switch (notification.notificationType) {
        case notification_models.NotificationType.info:
          return const Color(0xFFE1F5FE);
        case notification_models.NotificationType.warning:
          return const Color(0xFFFFF3E0);
        case notification_models.NotificationType.success:
          return const Color(0xFFE8F5E9);
        case notification_models.NotificationType.error:
          return const Color(0xFFFFEBEE);
        case notification_models.NotificationType.promotion:
          return const Color(0xFFFFF3E0);
      }
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (!notification.isRead && onTap != null) {
          onTap!();
        }
        // TODO: открыть детали уведомления
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade200
                : _getIconColor().withOpacity(0.3),
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: notification.isRead
                  ? Colors.black.withOpacity(0.04)
                  : _getIconColor().withOpacity(0.15),
              blurRadius: notification.isRead ? 8 : 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Иконка
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_getIconColor(), _getIconColor().withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getIconColor().withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(_getIcon(), color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            // Контент
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: const Color(0xFF111827),
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getIconColor(),
                                _getIconColor().withOpacity(0.8),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _getIconColor().withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 1.5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.5,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdBanner extends StatelessWidget {
  const _AdBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        // TODO: Открыть детали рекламы
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Builder(
                      builder: (context) {
                        final appState = Provider.of<AppState>(context);
                        return Text(
                          appState.t('notifications_ad'),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterMenuTile extends StatelessWidget {
  const _FilterMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
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
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}
