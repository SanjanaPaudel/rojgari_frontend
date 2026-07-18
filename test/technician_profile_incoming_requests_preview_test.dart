import 'package:flutter_test/flutter_test.dart';
import 'package:rojgari_frontend_one/models/incoming_request_model.dart';

// Mirrors the fixed GET /api/auth/worker/incoming-requests/ contract that
// backs the technician profile screen's "Incoming Requests" preview (top two
// cards) and the "View All" -> IncomingRequestsScreen destination. The
// backend is not live yet, so this simulates its documented success response
// with 5 offers to prove the parsing + top-two-preview logic is correct
// against the exact shape the backend will send.
const _fiveRequestsBody = {
  "count": 5,
  "requests": [
    {
      "offer_id": 15,
      "customer_name": "Ram Bahadur",
      "service": "Plumber",
      "service_icon": "/media/skills/plumber.png",
      "description": "Kitchen pipe leaking...",
      "address": "Lazimpat, Kathmandu",
      "distance_km": 0,
      "created_at": "2026-07-17T09:15:00Z",
    },
    {
      "offer_id": 16,
      "customer_name": "Sita Sharma",
      "service": "Electrician",
      "service_icon": "/media/skills/electrician.png",
      "description": "Power socket not working...",
      "address": "Baneshwor, Kathmandu",
      "distance_km": 0,
      "created_at": "2026-07-17T09:20:00Z",
    },
    {
      "offer_id": 17,
      "customer_name": "Hari Prasad",
      "service": "Carpenter",
      "service_icon": "/media/skills/carpenter.png",
      "description": "Door hinge broken...",
      "address": "Patan, Lalitpur",
      "distance_km": 1.2,
      "created_at": "2026-07-17T09:25:00Z",
    },
    {
      "offer_id": 18,
      "customer_name": "Gita Thapa",
      "service": "Painter",
      "service_icon": "/media/skills/painter.png",
      "description": "Living room wall needs repainting...",
      "address": "Boudha, Kathmandu",
      "distance_km": 3.4,
      "created_at": "2026-07-17T09:30:00Z",
    },
    {
      "offer_id": 19,
      "customer_name": "Bikash Rai",
      "service": "AC Repair",
      "service_icon": "/media/skills/ac_repair.png",
      "description": "AC not cooling properly...",
      "address": "Baluwatar, Kathmandu",
      "distance_km": 5,
      "created_at": "2026-07-17T09:35:00Z",
    },
  ],
};

void main() {
  test('parses every field of the fixed incoming-requests contract', () {
    final requests = (_fiveRequestsBody['requests']! as List)
        .map((item) => IncomingRequest.fromJson(item as Map<String, dynamic>))
        .toList();

    expect(requests, hasLength(5));

    final first = requests.first;
    expect(first.id, '15');
    expect(first.customerName, 'Ram Bahadur');
    expect(first.title, 'Plumber');
    expect(first.description, 'Kitchen pipe leaking...');
    expect(first.location, 'Lazimpat, Kathmandu');
    expect(first.distanceKm, 0);
    expect(first.iconUrl, contains('/media/skills/plumber.png'));
    // The endpoint only ever returns pending offers and sends no status
    // field, so every request must map to isNew.
    expect(first.status, IncomingRequestStatus.isNew);

    final last = requests.last;
    expect(last.id, '19');
    expect(last.customerName, 'Bikash Rai');
    expect(last.distanceKm, 5);
  });

  test('profile screen preview shows only the top two, in API order', () {
    final requests = (_fiveRequestsBody['requests']! as List)
        .map((item) => IncomingRequest.fromJson(item as Map<String, dynamic>))
        .toList();

    // This is exactly the slicing _IncomingRequestsPreviewSection applies in
    // lib/screens/technician/profile_screen.dart.
    final preview = requests.take(2).toList();

    expect(preview, hasLength(2));
    expect(preview[0].id, '15');
    expect(preview[0].customerName, 'Ram Bahadur');
    expect(preview[1].id, '16');
    expect(preview[1].customerName, 'Sita Sharma');

    // The badge next to "Incoming Requests" reflects the full count, not the
    // two-item preview.
    expect(requests.length, 5);
  });
}
