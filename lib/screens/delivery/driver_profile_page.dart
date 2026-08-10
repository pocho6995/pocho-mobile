import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../di/injection_container.dart' as di;
import '../../repositories/delivery_repository.dart';
import '../../models/delivery/driver.dart';
import '../../widgets/modern_dialog.dart';
import '../../widgets/modern_snackbar.dart';
import 'driver_documents_page.dart';
import 'driver_vehicle_page.dart';
import 'driver_orders_page.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  static const String routeName = '/delivery/driver-profile';

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final DeliveryRepository _deliveryRepository = di.getIt<DeliveryRepository>();
  
  Driver? _driver;
  DriverStatistics? _statistics;
  bool _isLoading = true;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    try {
      final driver = await _deliveryRepository.getMyDriverProfile();
      DriverStatistics? statistics;
      try {
        statistics = await _deliveryRepository.getDriverStatistics();
      } catch (e) {
        // Игнорируем ошибки статистики
      }
      setState(() {
        _driver = driver;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ModernDialog.show(
          context: context,
          title: 'Ошибка',
          content: 'Не удалось загрузить профиль: ${e.toString()}',
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red,
          primaryAction: DialogAction(
            label: 'OK',
            onPressed: () {},
          ),
        );
      }
    }
  }

  Future<void> _toggleOnlineStatus() async {
    if (_driver == null) return;

    // Проверка статуса перед переходом в онлайн
    // Можно перейти в онлайн только если статус approved или уже online/offline
    final canGoOnline = _driver!.status == 'approved' || 
                        _driver!.status == 'online' || 
                        _driver!.status == 'offline';
    
    if (!_driver!.isOnline && !canGoOnline) {
      String message;
      switch (_driver!.status) {
        case 'pending':
          message = 'Ваша заявка еще не одобрена администратором. Ожидайте проверки документов.';
          break;
        case 'rejected':
          message = 'Ваша заявка была отклонена администратором. Обратитесь в поддержку.';
          break;
        case 'suspended':
          message = 'Ваш аккаунт временно заблокирован. Обратитесь в поддержку.';
          break;
        default:
          message = 'Вы не можете перейти в онлайн. Обратитесь в поддержку.';
      }
      
      if (mounted) {
        ModernDialog.show(
          context: context,
          title: 'Невозможно перейти в онлайн',
          content: message,
          icon: Icons.error_outline_rounded,
          iconColor: Colors.orange,
          primaryAction: DialogAction(
            label: 'OK',
            onPressed: () {},
          ),
        );
      }
      return;
    }

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await _deliveryRepository.updateOnlineStatus(
        isOnline: !_driver!.isOnline,
      );
      await _loadDriverProfile();
      if (mounted) {
        ModernSnackBar.showSuccess(
          context,
          message: _driver!.isOnline 
              ? 'Вы перешли в оффлайн' 
              : 'Вы перешли в онлайн',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Не удалось обновить статус';
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('не одобрен') || errorStr.contains('not approved')) {
          errorMessage = 'Вы не можете перейти в онлайн, пока администратор не одобрит вашу заявку.';
        } else if (errorStr.contains('400')) {
          errorMessage = 'Вы не можете перейти в онлайн. Проверьте статус вашей заявки.';
        }
        ModernDialog.show(
          context: context,
          title: 'Ошибка',
          content: errorMessage,
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red,
          primaryAction: DialogAction(
            label: 'OK',
            onPressed: () {},
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
      case 'online':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return Colors.red;
      case 'suspended':
        return Colors.red.shade700;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    // Если водитель онлайн, показываем "Онлайн", даже если статус approved
    if (_driver != null && _driver!.isOnline && status == 'approved') {
      return 'Онлайн';
    }
    
    switch (status) {
      case 'approved':
        return 'Одобрен';
      case 'pending':
        return 'На проверке';
      case 'rejected':
        return 'Отклонен';
      case 'suspended':
        return 'Заблокирован';
      case 'offline':
        return 'Оффлайн';
      case 'online':
        return 'Онлайн';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
      case 'online':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'suspended':
        return Icons.block_rounded;
      case 'offline':
        return Icons.offline_bolt_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _formatBalance(double balance) {
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(1)}M';
    } else if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(0)}k';
    } else {
      return balance.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_driver == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text('Профиль водителя'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Профиль не найден'),
        ),
      );
    }

    // Можно перейти в онлайн только если статус approved или уже online/offline
    final canGoOnline = _driver!.status == 'approved' || 
                        _driver!.status == 'online' || 
                        _driver!.status == 'offline';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Профиль водителя',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDriverProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Статус модерации
              Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(_driver!.isOnline ? 'online' : _driver!.status),
                      _getStatusColor(_driver!.isOnline ? 'online' : _driver!.status).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(_driver!.isOnline ? 'online' : _driver!.status).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      _getStatusIcon(_driver!.isOnline ? 'online' : _driver!.status),
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width < 360 ? 40 : 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getStatusText(_driver!.isOnline ? 'online' : _driver!.status),
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 360 ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_driver!.status == 'pending') ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Ожидайте проверки документов администратором',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                    if (_driver!.status == 'rejected' && _driver!.adminComment != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _driver!.adminComment!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    if (_driver!.status == 'suspended' && _driver!.adminComment != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _driver!.adminComment!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 400))
                  .slideY(begin: -0.2, end: 0),
              const SizedBox(height: 20),
              // Информация о водителе
              Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Фото водителя
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width < 360 ? 60 : 80,
                          height: MediaQuery.of(context).size.width < 360 ? 60 : 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            border: Border.all(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: _driver!.photoUrl != null && _driver!.photoUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    _driver!.photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person_rounded,
                                        size: 40,
                                        color: Colors.grey,
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _driver!.fullName,
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width < 360 ? 18 : 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _driver!.phoneNumber,
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width < 360 ? 14 : 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (_driver!.email.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _driver!.email,
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Статистика - адаптивная сетка
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 360;
                        return Wrap(
                          spacing: isSmallScreen ? 8 : 12,
                          runSpacing: isSmallScreen ? 8 : 12,
                          children: [
                            SizedBox(
                              width: isSmallScreen 
                                  ? (constraints.maxWidth - 16) / 3 
                                  : null,
                              child: _InfoCard(
                                icon: Icons.star_rounded,
                                label: 'Рейтинг',
                                value: (_statistics?.rating ?? _driver!.rating).toStringAsFixed(1),
                                color: const Color(0xFFF59E0B),
                                isSmall: isSmallScreen,
                              ),
                            ),
                            SizedBox(
                              width: isSmallScreen 
                                  ? (constraints.maxWidth - 16) / 3 
                                  : null,
                              child: _InfoCard(
                                icon: Icons.check_circle_rounded,
                                label: 'Заказов',
                                value: '${_statistics?.completedOrders ?? _driver!.completedOrders}',
                                color: const Color(0xFF10B981),
                                isSmall: isSmallScreen,
                              ),
                            ),
                            SizedBox(
                              width: isSmallScreen 
                                  ? (constraints.maxWidth - 16) / 3 
                                  : null,
                              child: _InfoCard(
                                icon: Icons.account_balance_wallet_rounded,
                                label: 'Баланс',
                                value: _formatBalance(_statistics?.balance ?? _driver!.balance),
                                color: const Color(0xFF6366F1),
                                isSmall: isSmallScreen,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (_statistics != null && _statistics!.ordersToday > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.today_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Сегодня: ${_statistics!.ordersToday} заказов',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  Text(
                                    'Заработано: ${_formatBalance(_statistics!.earningsToday)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 200),
                  )
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 20),
              // Кнопка переключения статуса онлайн
              if (canGoOnline)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_driver!.isOnline 
                            ? Colors.orange 
                            : const Color(0xFF10B981)).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isUpdatingStatus ? null : _toggleOnlineStatus,
                    icon: _isUpdatingStatus
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            _driver!.isOnline 
                                ? Icons.offline_bolt_rounded 
                                : Icons.online_prediction_rounded,
                          ),
                    label: Text(
                      _driver!.isOnline 
                          ? 'Перейти в оффлайн' 
                          : 'Перейти в онлайн',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 360 ? 16 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _driver!.isOnline 
                          ? Colors.orange 
                          : const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.width < 360 ? 16 : 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(
                      duration: const Duration(milliseconds: 400),
                      delay: const Duration(milliseconds: 400),
                    )
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1),
                      delay: const Duration(milliseconds: 400),
                    ),
              if (!canGoOnline)
                Container(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.orange.shade700,
                        size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Вы не можете перейти в онлайн до одобрения администратором',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(
                      duration: const Duration(milliseconds: 400),
                      delay: const Duration(milliseconds: 400),
                    ),
              const SizedBox(height: 20),
              // Меню действий
              _MenuTile(
                icon: Icons.description_rounded,
                title: 'Документы',
                subtitle: 'Управление документами',
                color: const Color(0xFF6366F1),
                onTap: () {
                  Navigator.of(context).pushNamed(DriverDocumentsPage.routeName);
                },
              )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 600),
                  )
                  .slideX(begin: -0.1, end: 0),
              _MenuTile(
                icon: Icons.directions_car_rounded,
                title: 'Транспортное средство',
                subtitle: 'Регистрация и управление ТС',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.of(context).pushNamed(DriverVehiclePage.routeName);
                },
              )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 700),
                  )
                  .slideX(begin: -0.1, end: 0),
              _MenuTile(
                icon: Icons.local_shipping_rounded,
                title: 'Мои заказы',
                subtitle: 'История и активные заказы',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.of(context).pushNamed(DriverOrdersPage.routeName);
                },
              )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 800),
                  )
                  .slideX(begin: -0.1, end: 0),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isSmall = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 8 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isSmall ? 20 : 24),
          SizedBox(height: isSmall ? 6 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 14 : 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 9 : 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
