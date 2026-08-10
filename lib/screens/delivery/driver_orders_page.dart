import 'package:flutter/material.dart';
import '../../di/injection_container.dart' as di;
import '../../repositories/delivery_repository.dart';
import '../../models/delivery/delivery_order.dart';
import '../../widgets/modern_dialog.dart';
import 'order_detail_page.dart' as order_detail;

class DriverOrdersPage extends StatefulWidget {
  const DriverOrdersPage({super.key});

  static const String routeName = '/delivery/driver-orders';

  @override
  State<DriverOrdersPage> createState() => _DriverOrdersPageState();
}

class _DriverOrdersPageState extends State<DriverOrdersPage>
    with SingleTickerProviderStateMixin {
  final DeliveryRepository _deliveryRepository = di.getIt<DeliveryRepository>();

  List<DeliveryOrder> _orders = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      // Заказы водителя GET /api/v1/delivery/driver/orders (ТЗ)
      final orders = await _deliveryRepository.getDriverOrdersTZ();
      setState(() {
        _orders = orders;
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
          content: 'Не удалось загрузить заказы: ${e.toString()}',
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red,
          primaryAction: DialogAction(label: 'OK', onPressed: () {}),
        );
      }
    }
  }

  List<DeliveryOrder> get _pendingOrders => _orders.where((o) {
    final s = o.status.toLowerCase();
    return s == 'created' ||
        s == 'searching_driver' ||
        s == 'driver_assigned' ||
        s == 'pending';
  }).toList();

  List<DeliveryOrder> get _activeOrders => _orders.where((o) {
    final s = o.status.toLowerCase();
    return s == 'driver_on_way' ||
        s == 'picked_up' ||
        s == 'in_delivery' ||
        s == 'accepted' ||
        s == 'in_transit';
  }).toList();

  List<DeliveryOrder> get _completedOrders => _orders.where((o) {
    final s = o.status.toLowerCase();
    return s == 'delivered' || s == 'completed';
  }).toList();

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          'Мои заказы',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.w700,
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
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Доступные'),
            Tab(text: 'Активные'),
            Tab(text: 'Завершенные'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersList(_pendingOrders, isSmallScreen),
                  _buildOrdersList(_activeOrders, isSmallScreen),
                  _buildOrdersList(_completedOrders, isSmallScreen),
                ],
              ),
            ),
    );
  }

  Widget _buildOrdersList(List<DeliveryOrder> orders, bool isSmallScreen) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Заказы не найдены',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
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
              onTap: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute<void>(
                        builder: (context) => order_detail.OrderDetailPage(
                          orderId: order.id,
                          isDriverContext: true,
                        ),
                      ),
                    )
                    .then((_) => _loadOrders());
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_shipping_rounded,
                        color: _getStatusColor(order.status),
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Заказ #${order.id}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                order.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.statusName,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(order.status),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 6),
                          Text(
                            '${order.pickupAddress} → ${order.deliveryAddress}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 6),
                          Text(
                            '${order.displayPrice.toStringAsFixed(0)} сум',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

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
}
