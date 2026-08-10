import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../di/injection_container.dart' as di;
import '../../repositories/delivery_repository.dart';
import '../../models/delivery/delivery_order.dart';
import '../../widgets/modern_dialog.dart';
import '../../widgets/modern_snackbar.dart';
import '../../state/app_state.dart';
import 'package:intl/intl.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
    this.isDriverContext = false,
  });

  final int orderId;

  /// true — заказ открыт из раздела водителя (загрузка через driver/orders/{id})
  final bool isDriverContext;
  static const String routeName = '/delivery/order-detail';

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final DeliveryRepository _deliveryRepository = di.getIt<DeliveryRepository>();

  DeliveryOrder? _order;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadOrder(widget.orderId);
  }

  Future<void> _loadOrder(int orderId) async {
    try {
      final order = widget.isDriverContext
          ? await _deliveryRepository.getDriverOrderById(orderId)
          : await _deliveryRepository.getOrderById(orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernDialog.show(
          context: context,
          title: appState.t('error'),
          content:
              '${appState.t('delivery_failed_to_load_order')}: ${e.toString()}',
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red,
          primaryAction: DialogAction(label: 'OK', onPressed: () {}),
        );
      }
    }
  }

  Future<void> _acceptOrder() async {
    if (_order == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _deliveryRepository.acceptDriverOrder(_order!.id);
      await _loadOrder(_order!.id);
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showSuccess(
          context,
          message: appState.t('delivery_order_accepted'),
        );
      }
    } catch (e) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        String errorMessage = appState.t('delivery_failed_to_accept');
        IconData errorIcon = Icons.error_outline_rounded;
        Color errorColor = Colors.red;

        final errorString = e.toString().toLowerCase();

        if (errorString.contains('не одобрен') ||
            errorString.contains('не одобрена') ||
            errorString.contains('403')) {
          errorMessage = appState.t('delivery_not_approved');
          errorIcon = Icons.info_outline_rounded;
          errorColor = Colors.orange;
        } else if (errorString.contains('отклонен') ||
            errorString.contains('rejected')) {
          errorMessage = appState.t('delivery_rejected');
          errorIcon = Icons.cancel_outlined;
          errorColor = Colors.red;
        } else if (errorString.contains('заблокирован') ||
            errorString.contains('suspended')) {
          errorMessage = appState.t('delivery_blocked');
          errorIcon = Icons.block_rounded;
          errorColor = Colors.red.shade700;
        } else if (errorString.contains('не онлайн') ||
            errorString.contains('offline')) {
          errorMessage = appState.t('delivery_not_online');
          errorIcon = Icons.offline_bolt_rounded;
          errorColor = Colors.orange;
        } else if (errorString.contains('уже принят') ||
            errorString.contains('already accepted')) {
          errorMessage = appState.t('delivery_already_accepted');
          errorIcon = Icons.info_outline_rounded;
          errorColor = Colors.blue;
        } else {
          errorMessage =
              '${appState.t('delivery_failed_to_accept')}: ${e.toString()}';
        }

        final dialogAppState = Provider.of<AppState>(context, listen: false);
        ModernDialog.show(
          context: context,
          title: dialogAppState.t('error'),
          content: errorMessage,
          icon: errorIcon,
          iconColor: errorColor,
          primaryAction: DialogAction(label: 'OK', onPressed: () {}),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String newStatus, {String? comment}) async {
    if (_order == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final statusLower = newStatus.toLowerCase();
      if (statusLower == 'cancelled' || statusLower == 'canceled') {
        // Для отмены передаем комментарий как reason
        await _deliveryRepository.cancelOrder(_order!.id, reason: comment);
      } else {
        await _deliveryRepository.updateDriverOrderStatus(
          _order!.id,
          newStatus,
        );
      }
      await _loadOrder(_order!.id);
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showSuccess(
          context,
          message: appState.t('delivery_status_updated'),
        );
      }
    } catch (e) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        String errorMessage = appState.t('delivery_failed_to_update_status');
        final errorStr = e.toString().toLowerCase();

        if (errorStr.contains('403') || errorStr.contains('forbidden')) {
          errorMessage = appState.t('delivery_no_permission_update');
        } else if (errorStr.contains('422') ||
            errorStr.contains('unprocessable')) {
          errorMessage = appState.t('delivery_invalid_status_transition');
        } else if (errorStr.contains('нельзя отменить') ||
            errorStr.contains('cannot cancel') ||
            errorStr.contains('400')) {
          errorMessage = appState.t('delivery_cannot_cancel_after_pickup');
        } else {
          errorMessage =
              '${appState.t('delivery_failed_to_update_status')}: ${e.toString()}';
        }

        final dialogAppState = Provider.of<AppState>(context, listen: false);
        ModernDialog.show(
          context: context,
          title: dialogAppState.t('error'),
          content: errorMessage,
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red,
          primaryAction: DialogAction(label: 'OK', onPressed: () {}),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _showCommentDialog(String status, String statusName) async {
    if (!mounted) return;

    final commentController = TextEditingController();
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final currentAppState = Provider.of<AppState>(context, listen: false);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final dialogAppState = Provider.of<AppState>(
          dialogContext,
          listen: false,
        );
        return ModernDialog(
          title: dialogAppState.t('delivery_update_status'),
          contentWidget: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.1),
                      const Color(0xFF8B5CF6).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statusName,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              TextField(
                controller: commentController,
                autofocus: false,
                decoration: InputDecoration(
                  labelText:
                      statusName == dialogAppState.t('delivery_cancel_order')
                      ? dialogAppState.t('delivery_cancel_reason_optional')
                      : dialogAppState.t('delivery_comment_optional'),
                  hintText:
                      statusName == dialogAppState.t('delivery_cancel_order')
                      ? dialogAppState.t('delivery_specify_cancel_reason')
                      : dialogAppState.t('delivery_add_comment'),
                  prefixIcon: Icon(
                    statusName == dialogAppState.t('delivery_cancel_order')
                        ? Icons.cancel_outlined
                        : Icons.comment_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF6366F1),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                ),
                maxLines: 3,
                style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
              ),
            ],
          ),
          icon: Icons.update_rounded,
          iconColor: const Color(0xFF6366F1),
          primaryAction: DialogAction(
            label: dialogAppState.t('delivery_confirm'),
            onPressed: () {},
            color: const Color(0xFF6366F1),
            returnValue: () =>
                commentController.text.trim(), // Функция для получения значения
          ),
          secondaryAction: DialogAction(
            label: dialogAppState.t('delivery_cancel'),
            onPressed: () {},
            returnValue: null,
          ),
        );
      },
    );

    // Обрабатываем результат
    if (!mounted) return;

    String? commentResult;
    if (result != null) {
      // Если результат - функция, вызываем её
      try {
        final dynamic resultValue = result;
        if (resultValue is Function) {
          commentResult = (resultValue as dynamic)();
        } else {
          commentResult = resultValue.toString();
        }
      } catch (e) {
        // Если не удалось обработать, игнорируем
        commentResult = null;
      }
    }

    if (mounted && commentResult != null) {
      await _updateStatus(
        status,
        comment: commentResult.isEmpty ? null : commentResult,
      );
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '—';
    return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Builder(
            builder: (context) {
              final appState = Provider.of<AppState>(context, listen: false);
              return Text(appState.t('delivery_order_details'));
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Builder(
          builder: (context) {
            final appState = Provider.of<AppState>(context, listen: false);
            return Center(child: Text(appState.t('delivery_order_not_found')));
          },
        ),
      );
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final canUpdateStatus =
        _order!.driverId != null &&
        !_order!.isDelivered &&
        !_order!.isCancelled &&
        !_order!.isFailed;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final appState = Provider.of<AppState>(context, listen: false);
            return Text(
              '${appState.t('delivery_order')} #${_order!.id}',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.w700,
              ),
            );
          },
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
        onRefresh: () => _loadOrder(_order!.id),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Статус заказа с прогресс-баром
              _OrderStatusCard(order: _order!, isSmallScreen: isSmallScreen),
              const SizedBox(height: 16),
              // Временные метки
              if (_order!.acceptedAt != null ||
                  _order!.pickedUpAt != null ||
                  _order!.deliveredAt != null ||
                  _order!.cancelledAt != null)
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
                      Builder(
                        builder: (context) {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.t('delivery_timeline'),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _TimelineItem(
                                icon: Icons.add_circle_outline_rounded,
                                label: appState.t(
                                  'delivery_order_created_status',
                                ),
                                time: _formatDateTime(_order!.createdAt),
                                color: Colors.blue,
                                isSmallScreen: isSmallScreen,
                              ),
                              if (_order!.acceptedAt != null)
                                _TimelineItem(
                                  icon: Icons.check_circle_outline_rounded,
                                  label: appState.t(
                                    'delivery_accepted_by_driver',
                                  ),
                                  time: _formatDateTime(_order!.acceptedAt),
                                  color: Colors.green,
                                  isSmallScreen: isSmallScreen,
                                ),
                              if (_order!.pickedUpAt != null)
                                _TimelineItem(
                                  icon: Icons.inventory_2_outlined,
                                  label: appState.t('delivery_cargo_received'),
                                  time: _formatDateTime(_order!.pickedUpAt),
                                  color: Colors.orange,
                                  isSmallScreen: isSmallScreen,
                                ),
                              if (_order!.deliveredAt != null)
                                _TimelineItem(
                                  icon: Icons.done_all_rounded,
                                  label: appState.t('delivery_delivered'),
                                  time: _formatDateTime(_order!.deliveredAt),
                                  color: Colors.green.shade700,
                                  isSmallScreen: isSmallScreen,
                                ),
                              if (_order!.cancelledAt != null)
                                _TimelineItem(
                                  icon: Icons.cancel_outlined,
                                  label: appState.t('delivery_cancelled'),
                                  time: _formatDateTime(_order!.cancelledAt),
                                  color: Colors.red,
                                  isSmallScreen: isSmallScreen,
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              if (_order!.acceptedAt != null ||
                  _order!.pickedUpAt != null ||
                  _order!.deliveredAt != null ||
                  _order!.cancelledAt != null)
                const SizedBox(height: 16),
              // Основная информация о заказе
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
                    // Адрес отправления
                    Builder(
                      builder: (context) {
                        final appState = Provider.of<AppState>(
                          context,
                          listen: false,
                        );
                        return _AddressSection(
                          icon: Icons.location_on_rounded,
                          title: appState.t('delivery_from'),
                          address:
                              _order!.pickupAddress ??
                              (_order!.pickupLatitude != null &&
                                      _order!.pickupLongitude != null
                                  ? '${_order!.pickupLatitude!.toStringAsFixed(6)}, ${_order!.pickupLongitude!.toStringAsFixed(6)}'
                                  : appState.t(
                                      'delivery_address_not_specified',
                                    )),
                          contactName: _order!.pickupContactName,
                          contactPhone: _order!.pickupContactPhone ?? '',
                          isSmallScreen: isSmallScreen,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Адрес доставки
                    Builder(
                      builder: (context) {
                        final appState = Provider.of<AppState>(
                          context,
                          listen: false,
                        );
                        return _AddressSection(
                          icon: Icons.location_on_rounded,
                          title: appState.t('delivery_to'),
                          address:
                              _order!.deliveryAddress ??
                              (_order!.deliveryLatitude != null &&
                                      _order!.deliveryLongitude != null
                                  ? '${_order!.deliveryLatitude!.toStringAsFixed(6)}, ${_order!.deliveryLongitude!.toStringAsFixed(6)}'
                                  : appState.t(
                                      'delivery_address_not_specified',
                                    )),
                          contactName: _order!.deliveryContactName,
                          contactPhone: _order!.deliveryContactPhone ?? '',
                          isSmallScreen: isSmallScreen,
                        );
                      },
                    ),
                    if (_order!.cargoDescription != null &&
                        _order!.cargoDescription!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Builder(
                        builder: (context) {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          return _InfoRow(
                            icon: Icons.description_rounded,
                            label: appState.t(
                              'delivery_cargo_description_label',
                            ),
                            value: _order!.cargoDescription!,
                            isSmallScreen: isSmallScreen,
                          );
                        },
                      ),
                    ],
                    if (_order!.cargoWeightKg != null) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          return _InfoRow(
                            icon: Icons.scale_rounded,
                            label: appState.t('delivery_weight'),
                            value:
                                '${_order!.cargoWeightKg!.toStringAsFixed(1)} кг',
                            isSmallScreen: isSmallScreen,
                          );
                        },
                      ),
                    ],
                    if (_order!.cargoVolumeM3 != null) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          return _InfoRow(
                            icon: Icons.inventory_2_rounded,
                            label: appState.t('delivery_volume'),
                            value:
                                '${_order!.cargoVolumeM3!.toStringAsFixed(2)} м³',
                            isSmallScreen: isSmallScreen,
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final appState = Provider.of<AppState>(
                          context,
                          listen: false,
                        );
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appState.t('delivery_distance'),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _order!.displayDistance > 0
                                      ? '${_order!.displayDistance.toStringAsFixed(1)} км'
                                      : '—',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.w700,
                                    color: _order!.displayDistance > 0
                                        ? const Color(0xFF111827)
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  appState.t('delivery_cost'),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _order!.displayPrice > 0
                                      ? '${_order!.displayPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} сум'
                                      : '—',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 22,
                                    fontWeight: FontWeight.w800,
                                    color: _order!.displayPrice > 0
                                        ? const Color(0xFF6366F1)
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final appState = Provider.of<AppState>(
                          context,
                          listen: false,
                        );
                        return _InfoRow(
                          icon: Icons.payment_rounded,
                          label: appState.t('delivery_payment_method'),
                          value: _order!.paymentMethodName,
                          isSmallScreen: isSmallScreen,
                        );
                      },
                    ),
                    if (_order!.customerComment != null &&
                        _order!.customerComment!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          return _InfoRow(
                            icon: Icons.comment_rounded,
                            label: appState.t('delivery_client_comment'),
                            value: _order!.customerComment!,
                            isSmallScreen: isSmallScreen,
                          );
                        },
                      ),
                    ],
                    if (_order!.driverComment != null &&
                        _order!.driverComment!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          return _InfoRow(
                            icon: Icons.note_rounded,
                            label: appState.t('delivery_driver_comment'),
                            value: _order!.driverComment!,
                            isSmallScreen: isSmallScreen,
                          );
                        },
                      ),
                    ],
                    if (_order!.driverName != null ||
                        _order!.driverPhone != null) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: isSmallScreen ? 40 : 48,
                            height: isSmallScreen ? 40 : 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Builder(
                                  builder: (context) {
                                    final appState = Provider.of<AppState>(
                                      context,
                                      listen: false,
                                    );
                                    return Text(
                                      appState.t('delivery_driver'),
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 11 : 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 2),
                                if (_order!.driverName != null)
                                  Text(
                                    _order!.driverName!,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                if (_order!.driverPhone != null) ...[
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () {
                                      // Можно добавить вызов телефона
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.phone_rounded,
                                          size: isSmallScreen ? 14 : 16,
                                          color: const Color(0xFF1565C0),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _order!.driverPhone!,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 12 : 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1565C0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_order!.cancelReason != null &&
                        _order!.cancelReason!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          return _InfoRow(
                            icon: Icons.cancel_outlined,
                            label: appState.t('delivery_cancel_reason'),
                            value: _order!.cancelReason!,
                            isSmallScreen: isSmallScreen,
                            valueColor: Colors.red,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Кнопки действий для водителя
              if (_order!.isPending) ...[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isUpdating ? null : _acceptOrder,
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: Builder(
                      builder: (context) {
                        final appState = Provider.of<AppState>(
                          context,
                          listen: false,
                        );
                        return Text(
                          appState.t('delivery_accept_order'),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 16 : 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
              if (_order!.isAccepted && canUpdateStatus) ...[
                ElevatedButton.icon(
                  onPressed: _isUpdating
                      ? null
                      : () {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          _showCommentDialog(
                            'picking_up',
                            appState.t('delivery_driver_on_way'),
                          );
                        },
                  icon: const Icon(Icons.directions_car_rounded),
                  label: Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      return Text(appState.t('delivery_going_for_order'));
                    },
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _CancelButton(
                  onPressed: _isUpdating
                      ? null
                      : () {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          _showCommentDialog(
                            'cancelled',
                            appState.t('delivery_cancel_order'),
                          );
                        },
                  isSmallScreen: isSmallScreen,
                ),
              ],
              if (_order!.isPickingUp && canUpdateStatus) ...[
                ElevatedButton.icon(
                  onPressed: _isUpdating
                      ? null
                      : () {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          _showCommentDialog(
                            'in_transit',
                            appState.t('delivery_on_way_to_recipient'),
                          );
                        },
                  icon: const Icon(Icons.local_shipping_rounded),
                  label: Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      return Text(appState.t('delivery_on_way_to_recipient'));
                    },
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _CancelButton(
                  onPressed: _isUpdating
                      ? null
                      : () {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          _showCommentDialog(
                            'cancelled',
                            appState.t('delivery_cancel_order'),
                          );
                        },
                  isSmallScreen: isSmallScreen,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isUpdating
                      ? null
                      : () {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          _showCommentDialog(
                            'failed',
                            appState.t('delivery_failed_to_deliver'),
                          );
                        },
                  icon: const Icon(Icons.error_outline_rounded),
                  label: Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      return Text(appState.t('delivery_failed_to_deliver'));
                    },
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
              if (_order!.isInTransit && canUpdateStatus) ...[
                ElevatedButton.icon(
                  onPressed: _isUpdating
                      ? null
                      : () {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          _showCommentDialog(
                            'delivered',
                            appState.t('delivery_delivered'),
                          );
                        },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      return Text(appState.t('delivery_delivered_status'));
                    },
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isUpdating
                      ? null
                      : () {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          _showCommentDialog(
                            'failed',
                            appState.t('delivery_failed_to_deliver'),
                          );
                        },
                  icon: const Icon(Icons.error_outline_rounded),
                  label: Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      return Text(appState.t('delivery_failed_to_deliver'));
                    },
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
              if (_order!.isDelivered ||
                  _order!.isCancelled ||
                  _order!.isFailed) ...[
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: (_order!.isDelivered ? Colors.green : Colors.red)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (_order!.isDelivered ? Colors.green : Colors.red)
                          .withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _order!.isDelivered
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: _order!.isDelivered ? Colors.green : Colors.red,
                        size: isSmallScreen ? 24 : 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _order!.isDelivered
                              ? Provider.of<AppState>(
                                  context,
                                  listen: false,
                                ).t('delivery_order_successfully_delivered')
                              : _order!.isCancelled
                              ? Provider.of<AppState>(
                                  context,
                                  listen: false,
                                ).t('delivery_order_cancelled')
                              : Provider.of<AppState>(
                                  context,
                                  listen: false,
                                ).t('delivery_failed_to_deliver_order'),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: _order!.isDelivered
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({required this.order, required this.isSmallScreen});

  final DeliveryOrder order;
  final bool isSmallScreen;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'picking_up':
        return Colors.orange.shade700;
      case 'in_transit':
        return Colors.blue.shade700;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'failed':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'picking_up':
        return Icons.directions_car_rounded;
      case 'in_transit':
        return Icons.local_shipping_rounded;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'failed':
        return Icons.error_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  double _getProgress(String status) {
    switch (status) {
      case 'pending':
        return 0.0;
      case 'accepted':
        return 0.25;
      case 'picking_up':
        return 0.5;
      case 'in_transit':
        return 0.75;
      case 'delivered':
        return 1.0;
      case 'cancelled':
      case 'failed':
        return 0.0;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final progress = _getProgress(order.status);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(order.status),
            color: Colors.white,
            size: isSmallScreen ? 40 : 48,
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            order.statusName,
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (!order.isCancelled && !order.isFailed && !order.isDelivered) ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              '${(progress * 100).toInt()}% выполнено',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
    required this.isSmallScreen,
  });

  final IconData icon;
  final String label;
  final String time;
  final Color color;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isSmallScreen ? 18 : 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey.shade600,
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

class _AddressSection extends StatelessWidget {
  const _AddressSection({
    required this.icon,
    required this.title,
    required this.address,
    required this.contactName,
    required this.contactPhone,
    required this.isSmallScreen,
  });

  final IconData icon;
  final String title;
  final String address;
  final String? contactName;
  final String contactPhone;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6366F1),
                size: isSmallScreen ? 18 : 20,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Text(
          address,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF111827),
          ),
        ),
        if (contactName != null) ...[
          SizedBox(height: isSmallScreen ? 4 : 6),
          Text(
            contactName!,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
        SizedBox(height: isSmallScreen ? 4 : 6),
        Text(
          contactPhone,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isSmallScreen,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isSmallScreen;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: isSmallScreen ? 18 : 20, color: Colors.grey.shade600),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed, required this.isSmallScreen});

  final VoidCallback? onPressed;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.cancel_outlined),
      label: Builder(
        builder: (context) {
          final appState = Provider.of<AppState>(context, listen: false);
          return Text(appState.t('delivery_cancel_order'));
        },
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
