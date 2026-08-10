import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/support/support_ticket.dart';
import '../models/support/support_message.dart';
import '../services/support_service.dart';
import '../services/support_websocket_service.dart';

/// Репозиторий для управления тикетами поддержки
class SupportRepository {
  final SupportService _supportService;
  final SupportWebSocketService _webSocketService;

  // Кэш тикетов
  List<SupportTicket> _tickets = [];
  Map<int, SupportTicket> _ticketCache = {};
  Map<int, List<SupportMessage>> _messagesCache = {};

  // Stream для новых сообщений
  final _messageStreamController = StreamController<SupportMessage>.broadcast();
  Stream<SupportMessage> get messageStream => _messageStreamController.stream;

  SupportRepository({
    required SupportService supportService,
    required SupportWebSocketService webSocketService,
  })  : _supportService = supportService,
        _webSocketService = webSocketService {
    // Подписываемся на WebSocket сообщения
    _webSocketService.onMessageReceived = (message) {
      _messageStreamController.add(message);
      // Обновляем кэш сообщений
      if (_messagesCache.containsKey(message.ticketId)) {
        _messagesCache[message.ticketId]!.add(message);
      }
    };
  }

  /// Создать новый тикет
  Future<SupportTicket> createTicket({
    required String subject,
    required String message,
  }) async {
    try {
      final ticket = await _supportService.createTicket(
        subject: subject,
        message: message,
      );

      // Добавляем в кэш
      _tickets.insert(0, ticket);
      _ticketCache[ticket.id] = ticket;

      return ticket;
    } catch (e) {
      if (kDebugMode) {
        print('❌ SupportRepository: Ошибка при создании тикета');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Загрузить список тикетов
  Future<List<SupportTicket>> loadTickets({
    int skip = 0,
    int limit = 100,
    String? status,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh && _tickets.isNotEmpty && skip == 0) {
        return _tickets;
      }

      final response = await _supportService.getTickets(
        skip: skip,
        limit: limit,
        status: status,
      );

      if (skip == 0) {
        _tickets = response.tickets;
      } else {
        _tickets.addAll(response.tickets);
      }

      // Обновляем кэш
      for (final ticket in response.tickets) {
        _ticketCache[ticket.id] = ticket;
      }

      return _tickets;
    } catch (e) {
      if (kDebugMode) {
        print('❌ SupportRepository: Ошибка при загрузке тикетов');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Загрузить тикет с сообщениями
  Future<SupportTicket> loadTicket(int ticketId) async {
    try {
      // Проверяем кэш
      if (_ticketCache.containsKey(ticketId) &&
          _messagesCache.containsKey(ticketId)) {
        final cachedTicket = _ticketCache[ticketId]!;
        if (cachedTicket.messages != null && cachedTicket.messages!.isNotEmpty) {
          return cachedTicket;
        }
      }

      final ticket = await _supportService.getTicket(ticketId);

      // Обновляем кэш
      _ticketCache[ticketId] = ticket;
      if (ticket.messages != null) {
        _messagesCache[ticketId] = List.from(ticket.messages!);
      }

      // Обновляем в списке тикетов
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index] = ticket;
      }

      return ticket;
    } catch (e) {
      if (kDebugMode) {
        print('❌ SupportRepository: Ошибка при загрузке тикета');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Отправить сообщение
  Future<SupportMessage> sendMessage({
    required int ticketId,
    required String message,
    List<String>? attachments,
  }) async {
    try {
      final supportMessage = await _supportService.sendMessage(
        ticketId: ticketId,
        message: message,
        attachments: attachments,
      );

      // Добавляем в кэш
      if (!_messagesCache.containsKey(ticketId)) {
        _messagesCache[ticketId] = [];
      }
      _messagesCache[ticketId]!.add(supportMessage);

      // Обновляем тикет в кэше
      if (_ticketCache.containsKey(ticketId)) {
        final ticket = _ticketCache[ticketId]!;
        final updatedMessages = List<SupportMessage>.from(
          ticket.messages ?? [],
        )..add(supportMessage);
        _ticketCache[ticketId] = SupportTicket(
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

      return supportMessage;
    } catch (e) {
      if (kDebugMode) {
        print('❌ SupportRepository: Ошибка при отправке сообщения');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Отметить тикет как прочитанный
  Future<void> markAsRead(int ticketId) async {
    try {
      await _supportService.markAsRead(ticketId);

      // Обновляем в кэше
      if (_ticketCache.containsKey(ticketId)) {
        final ticket = _ticketCache[ticketId]!;
        _ticketCache[ticketId] = SupportTicket(
          id: ticket.id,
          userId: ticket.userId,
          subject: ticket.subject,
          status: ticket.status,
          priority: ticket.priority,
          assignedTo: ticket.assignedTo,
          isReadByUser: true,
          isReadByAdmin: ticket.isReadByAdmin,
          createdAt: ticket.createdAt,
          updatedAt: ticket.updatedAt,
          resolvedAt: ticket.resolvedAt,
          closedAt: ticket.closedAt,
          messages: ticket.messages,
        );
      }

      // Обновляем в списке
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        final ticket = _tickets[index];
        _tickets[index] = SupportTicket(
          id: ticket.id,
          userId: ticket.userId,
          subject: ticket.subject,
          status: ticket.status,
          priority: ticket.priority,
          assignedTo: ticket.assignedTo,
          isReadByUser: true,
          isReadByAdmin: ticket.isReadByAdmin,
          createdAt: ticket.createdAt,
          updatedAt: ticket.updatedAt,
          resolvedAt: ticket.resolvedAt,
          closedAt: ticket.closedAt,
          messages: ticket.messages,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SupportRepository: Ошибка при отметке тикета');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Подключиться к WebSocket чату тикета
  Future<void> connectToTicketChat(int ticketId) async {
    await _webSocketService.connect(ticketId);
  }

  /// Отключиться от WebSocket
  Future<void> disconnectFromChat() async {
    await _webSocketService.disconnect();
  }

  /// Получить сообщения из кэша
  List<SupportMessage>? getCachedMessages(int ticketId) {
    return _messagesCache[ticketId];
  }

  /// Добавить сообщение в кэш (из WebSocket)
  void addMessageToCache(SupportMessage message) {
    if (!_messagesCache.containsKey(message.ticketId)) {
      _messagesCache[message.ticketId] = [];
    }
    _messagesCache[message.ticketId]!.add(message);
  }

  /// Очистить кэш
  void clearCache() {
    _tickets.clear();
    _ticketCache.clear();
    _messagesCache.clear();
  }

  /// Получить список тикетов из кэша
  List<SupportTicket> getCachedTickets() {
    return List.from(_tickets);
  }

  void dispose() {
    _messageStreamController.close();
  }
}

