import '../../../core/network/api_client.dart';
import '../../../core/network/paginated_result.dart';
import '../domain/support_ticket.dart';

class SupportRepository {
  SupportRepository(this._client);

  final ApiClient _client;

  Future<PaginatedResult<SupportTicket>> listTickets({int page = 1, String? status}) async {
    final envelope = await _client.getEnvelope('/support/tickets', queryParameters: {
      'page': page,
      'limit': 20,
      if (status != null) 'status': status,
    },);
    return PaginatedResult.fromEnvelope(envelope, SupportTicket.fromJson);
  }

  Future<TicketDetail> getTicket(String id) async {
    final data = await _client.get('/support/tickets/$id');
    return TicketDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<TicketDetail> createTicket({
    required String subject,
    required String message,
    String? category,
    String? priority,
    String? orderId,
  }) async {
    final data = await _client.post('/support/tickets', data: {
      'subject': subject,
      'message': message,
      if (category != null && category.isNotEmpty) 'category': category,
      if (priority != null) 'priority': priority,
      if (orderId != null) 'orderId': orderId,
    },);
    return TicketDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<TicketMessage> sendMessage(String ticketId, String body) async {
    final data = await _client.post('/support/tickets/$ticketId/messages', data: {'body': body});
    return TicketMessage.fromJson(data as Map<String, dynamic>);
  }
}
