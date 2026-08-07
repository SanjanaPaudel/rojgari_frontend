/// Notification categories the backend currently sends, per its FCM
/// integration note. Chat/bidding/system types are documented as coming
/// later — add them here once the backend actually emits them.
enum NotificationType {
  bookingAccepted,
  bookingRejected,
  workerVerificationApproved,
  workerVerificationRejected,
  general,
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.bookingId,
    this.workerId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return NotificationItem(
      id: json['id'].toString(),
      type: _typeFromString(json['notification_type'] as String),
      title: json['title'] as String,
      message: json['body'] as String,
      timestamp: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool,
      bookingId: data?['booking_id'] as String?,
      workerId: data?['worker_id'] as String?,
    );
  }

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  /// Present for booking-related types; carried in the FCM `data` payload as
  /// `booking_id` and used to open the right booking once this is wired up.
  final String? bookingId;

  /// Present for worker-verification types (approved/rejected); carried in the
  /// FCM `data` payload as `worker_id`. Lets a notification tap route to the
  /// worker's own profile/verification screen.
  final String? workerId;

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      bookingId: bookingId,
      workerId: workerId,
    );
  }
}

NotificationType _typeFromString(String value) {
  return switch (value) {
    'booking_accepted' => NotificationType.bookingAccepted,
    'booking_rejected' => NotificationType.bookingRejected,
    'worker_verification_approved' =>
      NotificationType.workerVerificationApproved,
    'worker_verification_rejected' =>
      NotificationType.workerVerificationRejected,
    'general' => NotificationType.general,
    // Safe fallback to prevent crashes if the backend adds new types in the future
    _ => NotificationType.general,
  };
}
