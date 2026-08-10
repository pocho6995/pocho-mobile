import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../di/injection_container.dart' as di;
import '../../repositories/delivery_repository.dart';
import '../../models/delivery/driver.dart';
import '../../models/delivery/delivery_order.dart';
import '../../widgets/modern_dialog.dart';
import '../../widgets/modern_snackbar.dart';
import '../delivery/driver_profile_page.dart';
import '../delivery/order_detail_page.dart';

class DriverTab extends StatefulWidget {
  const DriverTab({super.key});

  @override
  State<DriverTab> createState() => _DriverTabState();
}

class _DriverTabState extends State<DriverTab>
    with SingleTickerProviderStateMixin {
  final DeliveryRepository _deliveryRepository = di.getIt<DeliveryRepository>();

  Driver? _driver;
  List<DeliveryOrder> _orders = [];
  bool _isLoading = true;
  bool _isLoadingOrders = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDriverProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverProfile() async {
    try {
      final driver = await _deliveryRepository.getMyDriverProfile();
      setState(() {
        _driver = driver;
        _isLoading = false;
      });
      // Загружаем заказы после загрузки профиля
      _loadOrders();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ModernDialog.show(
          context: context,
          title: 'Ошибка',
          content: 'Не удалось загрузить профиль водителя: ${e.toString()}',
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red,
          primaryAction: DialogAction(label: 'OK', onPressed: () {}),
        );
      }
    }
  }

  Future<void> _loadOrders() async {
    if (_driver == null) return;

    setState(() {
      _isLoadingOrders = true;
    });

    try {
      // Загружаем только заказы из региона водителя
      final orders = await _deliveryRepository.getOrders(
        limit: 100,
        regionId: _driver!.regionId, // Фильтруем по региону водителя
      );
      setState(() {
        _orders = orders;
        _isLoadingOrders = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingOrders = false;
      });
      if (mounted) {
        ModernSnackBar.showError(
          context,
          message: 'Не удалось загрузить заказы: ${e.toString()}',
        );
      }
    }
  }

  List<DeliveryOrder> get _pendingOrders =>
      _orders.where((o) => o.isPending).toList();

  List<DeliveryOrder> get _activeOrders => _orders
      .where((o) => o.isAccepted || o.isPickingUp || o.isInTransit)
      .toList();

  List<DeliveryOrder> get _completedOrders =>
      _orders.where((o) => o.isDelivered).toList();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

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
          title: const Text('Водитель'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: Text('Профиль водителя не найден')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          'Заказы водителя',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
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
              child: const Icon(Icons.person_rounded, size: 20),
            ),
            onPressed: () {
              Navigator.of(context).pushNamed(DriverProfilePage.routeName);
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w500,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.grey.shade600,
          tabs: const [
            Tab(text: 'Доступные'),
            Tab(text: 'Активные'),
            Tab(text: 'Завершенные'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: Column(
          children: [
            // Информация о статусе водителя
            if (!_driver!.isApproved)
              Container(
                margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.1),
                      Colors.orange.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.orange.shade700,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Text(
                        _driver!.status == 'pending'
                            ? 'Ваша заявка на проверке. После одобрения вы сможете принимать заказы.'
                            : _driver!.status == 'rejected'
                            ? 'Ваша заявка отклонена. Обратитесь в поддержку.'
                            : 'Ваш аккаунт заблокирован. Обратитесь в поддержку.',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Список заказов
            Expanded(
              child: _isLoadingOrders
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrdersList(_pendingOrders, isSmallScreen),
                        _buildOrdersList(_activeOrders, isSmallScreen),
                        _buildOrdersList(_completedOrders, isSmallScreen),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<DeliveryOrder> orders, bool isSmallScreen) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: isSmallScreen ? 48 : 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Заказы не найдены',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : 8),
            Text(
              'Новые заказы появятся здесь',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(
              order: order,
              isSmallScreen: isSmallScreen,
              onTap: () {
                Navigator.of(context)
                    .pushNamed(OrderDetailPage.routeName, arguments: order.id)
                    .then((_) {
                      // Обновляем список после возврата
                      _loadOrders();
                    });
              },
            )
            .animate()
            .fadeIn(
              duration: const Duration(milliseconds: 300),
              delay: Duration(milliseconds: index * 50),
            )
            .slideY(
              begin: 0.1,
              end: 0,
              delay: Duration(milliseconds: index * 50),
            );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isSmallScreen,
    required this.onTap,
  });

  final DeliveryOrder order;
  final bool isSmallScreen;
  final VoidCallback onTap;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'picking_up':
      case 'in_transit':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
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
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.local_shipping_rounded,
                        color: statusColor,
                        size: isSmallScreen ? 18 : 20,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Заказ #${order.id}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 2 : 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  order.statusName,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 11,
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${order.displayPrice.toStringAsFixed(0)} сум',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Text(
                          '${order.displayDistance.toStringAsFixed(1)} км',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                const Divider(height: 1),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: isSmallScreen ? 14 : 16,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 6),
                    Expanded(
                      child: Text(
                        '${order.pickupAddress} → ${order.deliveryAddress}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
