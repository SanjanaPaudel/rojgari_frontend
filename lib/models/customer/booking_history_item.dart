/// A single booking entry in a customer's booking history — shown on the
/// customer home screen's Bookings preview and the full
/// CustomerBookingsHistoryScreen ("View All") list.
class BookingHistoryItem {
  final String bookingId;
  final String title;
  final String issue;
  final String status;
  final String timeLabel;
  final String iconPath;
  final String? visitCharge;

  const BookingHistoryItem({
    required this.bookingId,
    required this.title,
    required this.issue,
    required this.status,
    required this.timeLabel,
    required this.iconPath,
    this.visitCharge,
  });
}

// BACKEND TODO:
// Replace with response.bookings from GET /customer/bookings. Field mapping:
// bookingId -> bookingId, serviceName -> title, issueDescription -> issue,
// bookingStatus -> status, updatedAt/createdAt label -> timeLabel,
// categoryIcon/imageUrl -> iconPath, visitCharge -> visitCharge (null until
// the worker has been assigned a charge for this booking).
//
// Ordered newest-first. The home screen preview takes the first few entries;
// CustomerBookingsHistoryScreen shows the full list — both read from this
// single source so they can never drift out of sync.
const List<BookingHistoryItem> sampleBookingHistory = [
  BookingHistoryItem(
    bookingId: 'booking_003',
    title: 'AC Repair',
    issue: 'Cooling service check',
    status: 'Booked',
    timeLabel: 'Today, 4 PM',
    iconPath: 'assets/images/ac_repair_icon.png',
    visitCharge: 'Rs 150',
  ),
  BookingHistoryItem(
    bookingId: 'booking_002',
    title: 'Electrician Service',
    issue: 'Switch board not working',
    status: 'In Progress',
    timeLabel: 'Yesterday',
    iconPath: 'assets/images/electrician_icon.png',
    visitCharge: 'Rs 120',
  ),
  BookingHistoryItem(
    bookingId: 'booking_001',
    title: 'Plumbing Service',
    issue: 'Leakage in bathroom pipe',
    status: 'Completed',
    timeLabel: '2 days ago',
    iconPath: 'assets/images/plumbing_icon.png',
    visitCharge: 'Rs 100',
  ),
  BookingHistoryItem(
    bookingId: 'booking_004',
    title: 'Gardener Service',
    issue: 'Lawn mowing and trimming',
    status: 'Completed',
    timeLabel: '4 days ago',
    iconPath: 'assets/images/gardner_icon.png',
    visitCharge: 'Rs 90',
  ),
  BookingHistoryItem(
    bookingId: 'booking_005',
    title: 'House Cleaning',
    issue: 'Deep cleaning, 2BHK',
    status: 'Cancelled',
    timeLabel: '5 days ago',
    iconPath: 'assets/images/maid_icon.png',
    visitCharge: 'Rs 130',
  ),
  BookingHistoryItem(
    bookingId: 'booking_006',
    title: 'Painter Service',
    issue: 'Living room wall touch-up',
    status: 'Completed',
    timeLabel: '1 week ago',
    iconPath: 'assets/images/painter_icon.png',
    visitCharge: 'Rs 110',
  ),
  BookingHistoryItem(
    bookingId: 'booking_007',
    title: 'Car Mechanic',
    issue: 'Engine noise inspection',
    status: 'Completed',
    timeLabel: '2 weeks ago',
    iconPath: 'assets/images/mechanic_icon.png',
    visitCharge: 'Rs 200',
  ),
  BookingHistoryItem(
    bookingId: 'booking_008',
    title: 'TV Repair',
    issue: 'No display, power light on',
    status: 'Cancelled',
    timeLabel: '3 weeks ago',
    iconPath: 'assets/images/tv_repair_icon.png',
    visitCharge: 'Rs 140',
  ),
  BookingHistoryItem(
    bookingId: 'booking_009',
    title: 'Computer Repair',
    issue: 'Laptop not booting',
    status: 'Completed',
    timeLabel: '3 weeks ago',
    iconPath: 'assets/images/computer_repair_icon.png',
    visitCharge: 'Rs 160',
  ),
];
