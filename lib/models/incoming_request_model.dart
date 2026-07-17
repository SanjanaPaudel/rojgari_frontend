import '../core/constants/api_urls.dart';

// Worker-facing model for a pending booking offer, shown on the
// "All Incoming Requests" screen.
//
// Backed by GET /api/auth/worker/incoming-requests/, which returns:
//   offer_id, customer_name, service, service_icon, description, address,
//   distance_km, created_at
//
// BACKEND GAPS (see fromJson for how each is handled):
//   • distance_km is hardcoded to 0 in WorkerService.get_incoming_requests,
//     so every card currently reads "0.0 km away".
//   • The endpoint returns only offers with status="pending" and sends no
//     status field, so every request is mapped to `isNew`.

enum IncomingRequestStatus {
  isNew('New'),
  viewed('Viewed'),
  offered('Offered');

  const IncomingRequestStatus(this.label);
  final String label;
}

class IncomingRequest {
  IncomingRequest({
    required this.id,
    required this.customerName,
    required this.title,
    required this.description,
    required this.location,
    required this.distanceKm,
    required this.createdAt,
    required this.status,
    this.iconUrl,
  });

  // The BookingOffer id — the value the detail and accept routes expect.
  final String id;

  // The customer who raised the request — shown as the card's headline.
  final String customerName;

  // The requested service, e.g. "Plumbing Service".
  final String title;

  // The customer's full problem text. Use [descriptionPreview] on the card.
  final String description;

  final String location;
  final double distanceKm;
  final DateTime createdAt;

  // Absolute URL of the category icon, or null when the Skill has no icon.
  final String? iconUrl;

  IncomingRequestStatus status;

  factory IncomingRequest.fromJson(Map<String, dynamic> json) {
    final icon = json['service_icon']?.toString();

    return IncomingRequest(
      id: json['offer_id'].toString(),
      customerName: json['customer_name']?.toString() ?? '',
      title: json['service']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['address']?.toString() ?? '',
      // Sent as 0 by the backend today; parsed properly so the card works
      // as soon as Django starts computing it.
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      iconUrl: (icon == null || icon.isEmpty)
          ? null
          : ApiUrls.resolveMediaUrl(icon),
      // The endpoint only ever returns pending offers and sends no status.
      status: IncomingRequestStatus.isNew,
    );
  }

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km away';

  // First four words of the description, ellipsised when there is more.
  // "Kitchen pipe is leaking under the sink..." -> "Kitchen pipe is leaking..."
  String get descriptionPreview {
    final words = description.trim().split(RegExp(r'\s+'));
    if (words.length <= _previewWordCount) return description.trim();
    return '${words.take(_previewWordCount).join(' ')}...';
  }

  static const int _previewWordCount = 4;

  // "Posted 5 mins ago" — derived from created_at, which the backend sends as
  // an ISO-8601 timestamp rather than pre-formatted text.
  String get postedLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Posted just now';
    if (diff.inMinutes < 60) {
      return 'Posted ${diff.inMinutes} ${diff.inMinutes == 1 ? 'min' : 'mins'} ago';
    }
    if (diff.inHours < 24) {
      return 'Posted ${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    }
    return 'Posted ${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
  }
}
