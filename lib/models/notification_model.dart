/// Notification categories the backend currently sends, per its FCM
/// integration note. Chat/bidding/system types are documented as coming
/// later — add them here once the backend actually emits them.
enum NotificationType { bookingAccepted, bookingRejected }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.bookingId,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  /// Present for booking-related types; carried in the FCM `data` payload as
  /// `booking_id` and used to open the right booking once this is wired up.
  final String? bookingId;

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      bookingId: bookingId,
    );
  }
}
