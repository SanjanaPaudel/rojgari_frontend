/// A single chat message in a booking's customer <-> worker conversation.
///
/// The backend exposes chat messages in two slightly different shapes:
///   * REST history (`GET .../messages/`): sender is a plain user id under
///     `sender`, and there's an `is_read` flag.
///   * WebSocket push (rides the booking socket): sender id is under
///     `sender_id`, and the frame carries an `"event": "chat_message"` marker
///     to tell it apart from booking-status updates on the same socket.
///
/// Both are normalized into this one type via [ChatMessage.fromRest] /
/// [ChatMessage.fromWebSocket] so the UI only ever deals with a single model.
class ChatMessage {
  const ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.id,
    this.localId,
    this.pending = false,
  });

  /// Server-assigned message id. Null while a message this device just sent
  /// is still waiting for its echo back from the server.
  final int? id;

  /// Client-only temporary id for an optimistically-shown (pending) message,
  /// used to reconcile it with the server echo once that arrives.
  final String? localId;

  final int senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;

  /// True for a message this device sent that the server hasn't echoed back
  /// yet — rendered with a "sending" indicator until confirmed.
  final bool pending;

  factory ChatMessage.fromRest(Map<String, dynamic> json) {
    return ChatMessage(
      id: _int(json['id']),
      senderId: _int(json['sender']) ?? 0,
      senderName: (json['sender_name'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: _date(json['created_at']),
    );
  }

  factory ChatMessage.fromWebSocket(Map<String, dynamic> json) {
    return ChatMessage(
      id: _int(json['id']),
      senderId: _int(json['sender_id']) ?? 0,
      senderName: (json['sender_name'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: _date(json['created_at']),
    );
  }

  /// A locally-created, not-yet-sent message shown immediately in the thread.
  factory ChatMessage.pendingOutgoing({
    required String localId,
    required int senderId,
    required String content,
  }) {
    return ChatMessage(
      localId: localId,
      senderId: senderId,
      senderName: '',
      content: content,
      createdAt: DateTime.now(),
      pending: true,
    );
  }

  /// Whether a decoded WebSocket frame is a chat message (vs a booking-status
  /// update) — both ride the same booking socket and are told apart by the
  /// presence of this `event` key.
  static bool isChatEvent(Map<String, dynamic> json) =>
      json['event'] == 'chat_message';

  static int? _int(dynamic value) =>
      value is int ? value : int.tryParse('$value');

  static DateTime _date(dynamic value) =>
      DateTime.tryParse('$value')?.toLocal() ?? DateTime.now();
}
