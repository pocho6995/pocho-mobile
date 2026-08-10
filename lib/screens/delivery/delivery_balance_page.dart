import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../di/injection_container.dart' as di;
import '../../repositories/delivery_repository.dart';
import '../../models/delivery/delivery_api_tz.dart';
import '../../widgets/modern_snackbar.dart';
import '../../state/app_state.dart';

/// Страница баланса доставки: текущий баланс и история операций (ТЗ).
class DeliveryBalancePage extends StatefulWidget {
  const DeliveryBalancePage({super.key});

  static const String routeName = '/delivery/balance';

  @override
  State<DeliveryBalancePage> createState() => _DeliveryBalancePageState();
}

class _DeliveryBalancePageState extends State<DeliveryBalancePage> {
  final DeliveryRepository _repo = di.getIt<DeliveryRepository>();

  DeliveryBalanceResponse? _balance;
  List<DeliveryBalanceLogEntry> _log = [];
  bool _balanceLoading = true;
  bool _logLoading = true;
  static const int _logPageSize = 20;
  int _logSkip = 0;
  bool _logHasMore = true;
  bool _logLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _loadLog();
  }

  Future<void> _loadBalance() async {
    setState(() => _balanceLoading = true);
    try {
      final res = await _repo.getDeliveryBalance();
      if (mounted) {
        setState(() {
          _balance = res;
          _balanceLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _balanceLoading = false);
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: '${appState.t('delivery_failed_to_load_balance')}: $e',
        );
      }
    }
  }

  Future<void> _loadLog() async {
    setState(() => _logLoading = true);
    _logSkip = 0;
    _logHasMore = true;
    try {
      final list = await _repo.getDeliveryBalanceLog(
        skip: 0,
        limit: _logPageSize,
      );
      if (mounted) {
        setState(() {
          _log = list;
          _logLoading = false;
          _logHasMore = list.length >= _logPageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _logLoading = false);
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: '${appState.t('delivery_failed_to_load_history')}: $e',
        );
      }
    }
  }

  Future<void> _loadMoreLog() async {
    if (_logLoadingMore || !_logHasMore) return;
    setState(() => _logLoadingMore = true);
    _logSkip += _logPageSize;
    try {
      final list = await _repo.getDeliveryBalanceLog(
        skip: _logSkip,
        limit: _logPageSize,
      );
      if (mounted) {
        setState(() {
          _log.addAll(list);
          _logLoadingMore = false;
          _logHasMore = list.length >= _logPageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _logLoadingMore = false);
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: '${appState.t('delivery_failed_to_load_more')}: $e',
        );
      }
    }
  }

  String _formatPrice(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  }

  String _formatDate(DateTime d, AppState appState) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) {
      return '${appState.t('delivery_today')}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == yesterday) {
      return '${appState.t('delivery_yesterday')}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
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
              appState.t('delivery_balance'),
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
            onPressed: (_balanceLoading || _logLoading)
                ? null
                : () async {
                    await _loadBalance();
                    await _loadLog();
                  },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadBalance();
          await _loadLog();
        },
        color: const Color(0xFF1565C0),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            padding,
            16,
            padding,
            media.padding.bottom + 24,
          ),
          children: [
            // Карточка текущего баланса
            _balanceLoading
                ? Container(
                    padding: EdgeInsets.all(isSmall ? 20 : 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  )
                : Container(
                    padding: EdgeInsets.all(isSmall ? 20 : 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
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
                                    appState.t('delivery_current_balance'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatPrice(_balance?.balance ?? 0)} ${_balance?.currency ?? 'UZS'}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 24),
            Builder(
              builder: (context) {
                final appState = Provider.of<AppState>(context, listen: false);
                return Text(
                  appState.t('delivery_transaction_history'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _logLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  )
                : _log.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final appState = Provider.of<AppState>(
                              context,
                              listen: false,
                            );
                            return Text(
                              appState.t('delivery_no_transactions'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      ..._log.map((e) => _buildLogEntry(e, isSmall)),
                      if (_logHasMore)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: _logLoadingMore ? null : _loadMoreLog,
                            child: _logLoadingMore
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF1565C0),
                                    ),
                                  )
                                : Builder(
                                    builder: (context) {
                                      final appState = Provider.of<AppState>(
                                        context,
                                        listen: false,
                                      );
                                      return Text(
                                        appState.t('delivery_load_more'),
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
    );
  }

  Widget _buildLogEntry(DeliveryBalanceLogEntry e, bool isSmall) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isCredit = e.amount >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.06),
        child: Container(
          padding: EdgeInsets.all(isSmall ? 14 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isCredit ? const Color(0xFF10B981) : Colors.red)
                  .withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isCredit ? const Color(0xFF10B981) : Colors.red)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCredit
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: isCredit ? const Color(0xFF10B981) : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.description ?? e.type,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(e.createdAt, appState),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (e.orderId != null) ...[
                      const SizedBox(height: 2),
                      Builder(
                        builder: (context) {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          return Text(
                            '${appState.t('delivery_order')} #${e.orderId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isCredit ? '+' : ''}${_formatPrice(e.amount)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isCredit ? const Color(0xFF10B981) : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
