/// A single booking entry in a customer's booking history — shown on the
/// customer home screen's Bookings preview and the full
/// CustomerBookingsHistoryScreen ("View All") list.
class BookingHistoryItem {
  final String bookingId;
  final String title;
  final String issue;
  final String status;
  final String timeLabel;
  final String icon;
  final String? visitCharge;

  const BookingHistoryItem({
    required this.bookingId,
    required this.title,
    required this.issue,
    required this.status,
    required this.timeLabel,
    required this.icon,
    this.visitCharge,
  });

  /// Same normalization BookingHistoryStatusStyle.fromBackend uses — single
  /// source of truth for "is this the one status that should navigate to
  /// live tracking when tapped."
  bool get isInProgress =>
      status.trim().toLowerCase().replaceAll(' ', '_') == 'in_progress';

  /// Same normalization, for "should this navigate to the completed booking
  /// details screen when tapped."
  bool get isCompleted =>
      status.trim().toLowerCase().replaceAll(' ', '_') == 'completed';

  /// Maps one entry of `GET /api/services/bookings/list/`'s response
  /// (BookingListSerializer) to this card's shape. See BookingHistoryStore
  /// for the shared fetch this feeds both the home screen preview and
  /// CustomerBookingsHistoryScreen from.
  ///
  /// Backend `status` is one of active/scheduled/assigned/working/completed/
  /// cancelled — collapsed here to the three buckets
  /// BookingHistoryStatusStyle.fromBackend actually styles differently
  /// (everything before "completed"/"cancelled" reads as "in progress" to
  /// the customer).
  factory BookingHistoryItem.fromApi(Map<String, dynamic> json) {
    final rawStatus = (json['status'] as String? ?? '').trim().toLowerCase();
    final status = switch (rawStatus) {
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      _ => 'In Progress',
    };

    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');
    final visitCharge = json['visit_charge'];

    return BookingHistoryItem(
      bookingId: json['id'].toString(),
      title: json['category']?.toString() ?? '',
      issue: json['description']?.toString() ?? '',
      status: status,
      timeLabel: createdAt == null ? '' : _formatTimeLabel(createdAt),
      icon: json['category_icon']?.toString() ?? '',
      visitCharge: visitCharge is num
          ? 'Rs ${visitCharge.toStringAsFixed(0)}'
          : null,
    );
  }
}

String _formatTimeLabel(DateTime createdAt) {
  final local = createdAt.toLocal();
  final now = DateTime.now();
  final diffDays = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(local.year, local.month, local.day)).inDays;

  if (diffDays == 0) return 'Today, ${_formatHour(local)}';
  if (diffDays == 1) return 'Yesterday';
  if (diffDays < 7) return '$diffDays days ago';
  final weeks = diffDays ~/ 7;
  if (weeks < 5) return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
  return '${local.day}/${local.month}/${local.year}';
}

String _formatHour(DateTime dt) {
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final period = dt.hour < 12 ? 'AM' : 'PM';
  return '$hour12 $period';
}

// Kept for now as fixture/reference data only — no longer read by either
// screen (see BookingHistoryStore). Not deleted without an explicit call —
// ask before removing.
const List<BookingHistoryItem> sampleBookingHistory = [
  BookingHistoryItem(
    bookingId: 'booking_003',
    title: 'AC Repair',
    issue: 'Cooling service check. The service was very nice and helpful',
    status: 'In Progress',
    timeLabel: 'Today, 4 PM',
    icon: 'ac_repair',
    visitCharge: 'Rs 150',
  ),
  BookingHistoryItem(
    bookingId: 'booking_002',
    title: 'Electrician Service',
    issue: 'Switch board not working',
    status: 'In Progress',
    timeLabel: 'Yesterday',
    icon: 'electrical',
    visitCharge: 'Rs 120',
  ),
  BookingHistoryItem(
    bookingId: 'booking_001',
    title: 'Plumbing Service',
    issue: 'Leakage in bathroom pipe',
    status: 'Completed',
    timeLabel: '2 days ago',
    icon: 'plumbing',
    visitCharge: 'Rs 100',
  ),
  BookingHistoryItem(
    bookingId: 'booking_004',
    title: 'Gardener Service',
    issue: 'Lawn mowing and trimming',
    status: 'Completed',
    timeLabel: '4 days ago',
    icon: 'gardening',
    visitCharge: 'Rs 90',
  ),
  BookingHistoryItem(
    bookingId: 'booking_005',
    title: 'House Cleaning',
    issue: 'Deep cleaning, 2BHK',
    status: 'Cancelled',
    timeLabel: '5 days ago',
    icon: 'cleaning',
    visitCharge: 'Rs 130',
  ),
  BookingHistoryItem(
    bookingId: 'booking_006',
    title: 'Painter Service',
    issue: 'Living room wall touch-up',
    status: 'Completed',
    timeLabel: '1 week ago',
    icon: 'painting',
    visitCharge: 'Rs 110',
  ),
  BookingHistoryItem(
    bookingId: 'booking_007',
    title: 'Car Mechanic',
    issue: 'Engine noise inspection',
    status: 'Completed',
    timeLabel: '2 weeks ago',
    icon: 'mechanic',
    visitCharge: 'Rs 200',
  ),
  BookingHistoryItem(
    bookingId: 'booking_008',
    title: 'TV Repair',
    issue: 'No display, power light on',
    status: 'Cancelled',
    timeLabel: '3 weeks ago',
    icon: 'tv_repair',
    visitCharge: 'Rs 140',
  ),
  BookingHistoryItem(
    bookingId: 'booking_009',
    title: 'Computer Repair',
    issue: 'Laptop not booting',
    status: 'Completed',
    timeLabel: '3 weeks ago',
    icon: 'computer_repair',
    visitCharge: 'Rs 160',
  ),
];
