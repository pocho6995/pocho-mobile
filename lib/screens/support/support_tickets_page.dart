import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

import '../../di/injection_container.dart' as di;
import '../../repositories/support_repository.dart';
import '../../models/support/support_ticket.dart';
import '../../models/support/support_message.dart';
import '../../widgets/modern_snackbar.dart';
import '../../widgets/modern_bottom_sheet.dart';
import '../../exceptions/auth_exceptions.dart';
import 'support_chat_page.dart';

class SupportTicketsPage extends StatefulWidget {
  const SupportTicketsPage({super.key});

  static const String routeName = '/support';

  @override
  State<SupportTicketsPage> createState() => _SupportTicketsPageState();
}

class _SupportTicketsPageState extends State<SupportTicketsPage> {
  late SupportRepository _supportRepository;
  List<SupportTicket> _tickets = [];
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;
  String _selectedStatus = 'Все';
  final List<String> _statusFilters = ['Все', 'open', 'in_progress', 'resolved', 'closed'];
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _supportRepository = di.getIt<SupportRepository>();
    _loadTickets();
    // Подписываемся на новые сообщения через WebSocket
    _messageSubscription = _supportRepository.messageStream.listen((message) {
      // Обновляем тикет, если он открыт
      setState(() {
        final ticketIndex = _tickets.indexWhere((t) => t.id == message.ticketId);
        if (ticketIndex != -1) {
          final ticket = _tickets[ticketIndex];
          final updatedMessages = List<SupportMessage>.from(ticket.messages ?? [])..add(message);
          _tickets[ticketIndex] = SupportTicket(
            id: ticket.id,
            userId: ticket.userId,
            subject: ticket.subject,
            status: ticket.status,
            priority: ticket.priority,
            assignedTo: ticket.assignedTo,
            isReadByUser: ticket.isReadByUser,
            isReadByAdmin: ticket.isReadByAdmin,
            createdAt: ticket.createdAt,
            updatedAt: ticket.updatedAt,
            resolvedAt: ticket.resolvedAt,
            closedAt: ticket.closedAt,
            messages: updatedMessages,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTickets({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final status = _selectedStatus == 'Все' ? null : _selectedStatus;
      final tickets = await _supportRepository.loadTickets(
        skip: 0,
        limit: 100,
        status: status,
        forceRefresh: forceRefresh,
      );

      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } on UnauthorizedException {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = 'Сессия истекла. Пожалуйста, войдите снова.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = 'Не удалось загрузить тикеты: ${e.toString()}';
      });
    }
  }

  Future<void> _createNewTicket() async {
    final result = await ModernBottomSheet.show<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      child: _CreateTicketDialog(),
    );

    if (result != null && result['subject'] != null && result['message'] != null) {
      try {
        final ticket = await _supportRepository.createTicket(
          subject: result['subject']!,
          message: result['message']!,
        );

        if (mounted) {
          ModernSnackBar.showSuccess(
            context,
            message: 'Тикет создан успешно',
          );
          // Переходим в чат нового тикета
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SupportChatPage(ticketId: ticket.id),
            ),
          );
          // Обновляем список
          _loadTickets(forceRefresh: true);
        }
      } catch (e) {
        if (mounted) {
          ModernSnackBar.showError(
            context,
            message: 'Не удалось создать тикет: ${e.toString()}',
          );
        }
      }
    }
  }

  List<SupportTicket> get _filteredTickets {
    if (_selectedStatus == 'Все') {
      return _tickets;
    }
    return _tickets.where((t) => t.status.value == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Техническая поддержка',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Фильтры по статусу
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((status) {
                  final isSelected = _selectedStatus == status;
                  final displayName = status == 'Все'
                      ? 'Все'
                      : TicketStatus.fromString(status).displayName;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedStatus = status;
                          });
                          _loadTickets(forceRefresh: true);
                        }
                      },
                      selectedColor: const Color(0xFF1565C0),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Список тикетов
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isError
                    ? _buildErrorState()
                    : _filteredTickets.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () => _loadTickets(forceRefresh: true),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredTickets.length,
                              itemBuilder: (context, index) {
                                final ticket = _filteredTickets[index];
                                return _buildTicketCard(ticket, index);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTicket,
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Создать тикет',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket, int index) {
    final unreadCount = ticket.messages
            ?.where((m) => !m.isFromUser && ticket.isReadByUser == false)
            .length ??
        0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ticket.isReadByUser ? Colors.grey.shade200 : const Color(0xFF1565C0),
          width: ticket.isReadByUser ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SupportChatPage(ticketId: ticket.id),
              ),
            ).then((_) {
              // Обновляем список после возврата
              _loadTickets(forceRefresh: true);
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.subject,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusChip(ticket.status),
                    const SizedBox(width: 8),
                    _buildPriorityChip(ticket.priority),
                    const Spacer(),
                    Text(
                      _formatDate(ticket.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (ticket.messages != null && ticket.messages!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    ticket.messages!.last.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 50).ms)
        .slideY(begin: 0.2, end: 0, delay: (index * 50).ms);
  }

  Widget _buildStatusChip(TicketStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Color(status.colorValue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(status.colorValue),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(TicketPriority priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Color(priority.colorValue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(priority.colorValue),
        ),
      ),
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
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 40,
            ),
          )
              .animate()
              .scale(duration: 500.ms, delay: 200.ms),
          const SizedBox(height: 24),
          const Text(
            'Нет тикетов',
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
            'Создайте новый тикет для обращения в поддержку',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Произошла ошибка',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadTickets(forceRefresh: true),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

class _CreateTicketDialog extends StatefulWidget {
  @override
  State<_CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<_CreateTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModernBottomSheet(
      title: 'Создать тикет',
      showCloseButton: true,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Тема',
                  hintText: 'Краткое описание проблемы',
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите тему';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Сообщение',
                  hintText: 'Подробное описание проблемы',
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
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите сообщение';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
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
                      child: const Text(
                        'Отмена',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.of(context).pop({
                            'subject': _subjectController.text.trim(),
                            'message': _messageController.text.trim(),
                          });
                        }
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
                      child: const Text(
                        'Создать',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

