import 'support_ticket.dart';

/// Модель ответа API со списком тикетов
class SupportTicketListResponse {
  final List<SupportTicket> tickets;
  final int total;
  final int skip;
  final int limit;

  SupportTicketListResponse({
    required this.tickets,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory SupportTicketListResponse.fromJson(Map<String, dynamic> json) {
    return SupportTicketListResponse(
      tickets: (json['tickets'] as List)
          .map((item) => SupportTicket.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      skip: (json['skip'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
    );
  }
}











