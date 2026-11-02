class TicketMessage {
  const TicketMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.attachments,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) => TicketMessage(
        id: json['id'] as String,
        senderId: json['sender_id'] as String,
        body: json['body'] as String,
        attachments: (json['attachments'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  final String id;
  final String senderId;
  final String body;
  final List<String> attachments;
  final DateTime createdAt;
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: json['id'] as String,
        ticketNumber: json['ticket_number'] as String,
        subject: json['subject'] as String,
        category: json['category'] as String? ?? 'general',
        priority: json['priority'] as String? ?? 'medium',
        status: json['status'] as String,
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      );

  final String id;
  final String ticketNumber;
  final String subject;
  final String category;
  final String priority;
  final String status;
  final DateTime updatedAt;

  bool get isClosed => status == 'resolved' || status == 'closed';
}

class TicketDetail extends SupportTicket {
  const TicketDetail({
    required super.id,
    required super.ticketNumber,
    required super.subject,
    required super.category,
    required super.priority,
    required super.status,
    required super.updatedAt,
    required this.userId,
    required this.messages,
  });

  factory TicketDetail.fromJson(Map<String, dynamic> json) => TicketDetail(
        id: json['id'] as String,
        ticketNumber: json['ticket_number'] as String,
        subject: json['subject'] as String,
        category: json['category'] as String? ?? 'general',
        priority: json['priority'] as String? ?? 'medium',
        status: json['status'] as String,
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
        userId: json['user_id'] as String,
        messages: (json['messages'] as List<dynamic>? ?? [])
            .map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String userId;
  final List<TicketMessage> messages;

  TicketDetail copyWithMessages(List<TicketMessage> messages) => TicketDetail(
        id: id,
        ticketNumber: ticketNumber,
        subject: subject,
        category: category,
        priority: priority,
        status: status,
        updatedAt: updatedAt,
        userId: userId,
        messages: messages,
      );
}
