import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../di/injection_container.dart' as di;
import '../../repositories/delivery_repository.dart';
import '../../models/delivery/delivery_order.dart';
import '../../widgets/modern_snackbar.dart';
import '../../state/app_state.dart';
import 'order_detail_page.dart' as order_detail;

/// Страница «Мои заказы» — список заказов пользователя (ТЗ).
class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  static const String routeName = '/delivery/my-orders';

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final DeliveryRepository _repo = di.getIt<DeliveryRepository>();

  List<DeliveryOrder> _orders = [];
  bool _isLoading = true;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _repo.getMyOrders(limit: 50, status: _filterStatus);
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
        // Логируем для отладки
        if (orders.isEmpty) {
          debugPrint('⚠️ MyOrdersPage: No orders found');
        } else {
          debugPrint('✅ MyOrdersPage: Loaded ${orders.length} orders');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ MyOrdersPage error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message:
              '${appState.t('delivery_failed_to_load_orders')}: ${e.toString()}',
        );
      }
    }
  }

  String _formatPrice(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'delivered' || s == 'completed') return const Color(0xFF10B981);
    if (s == 'cancelled' || s == 'canceled') return Colors.red;
    if (s == 'driver_assigned' ||
        s == 'driver_on_way' ||
        s == 'picked_up' ||
        s == 'in_delivery')
      return const Color(0xFF1565C0);
    return Colors.grey.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isSmall = media.size.width < 360;
    final padding = isSmall ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF111827),
        title: Builder(
          builder: (context) {
            final appState = Provider.of<AppState>(context, listen: false);
            return Text(
              appState.t('delivery_my_orders'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            )
          : _orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      return Column(
                        children: [
                          Text(
                            appState.t('delivery_no_orders'),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            appState.t('delivery_create_on_map'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadOrders,
              color: const Color(0xFF1565C0),
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  16,
                  padding,
                  media.padding.bottom + 24,
                ),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final statusColor = _statusColor(order.status);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      elevation: 0,
                      shadowColor: statusColor.withOpacity(0.15),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  order_detail.OrderDetailPage(
                                    orderId: order.id,
                                  ),
                            ),
                          );
                          _loadOrders();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.all(isSmall ? 16 : 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long_rounded,
                                      color: statusColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Builder(
                                          builder: (context) {
                                            final appState =
                                                Provider.of<AppState>(
                                                  context,
                                                  listen: false,
                                                );
                                            return Text(
                                              '${appState.t('delivery_order')} #${order.id}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF111827),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          order.statusName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${_formatPrice(order.finalPrice)} сум',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                ],
                              ),
                              if (order.pickupAddress != null ||
                                  order.deliveryAddress != null) ...[
                                const SizedBox(height: 12),
                                if (order.pickupAddress != null)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.upload_rounded,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          order.pickupAddress!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (order.deliveryAddress != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.download_rounded,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          order.deliveryAddress!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    Provider.of<AppState>(
                                      context,
                                      listen: false,
                                    ).t('delivery_order_details'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1565C0),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: const Color(0xFF1565C0),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
