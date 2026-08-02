// ─── DEBUG-ONLY FIXTURE FILE — DELETE BEFORE MERGING ───────────────────────
// Single source of truth for previewing the "incoming requests" list UI
// (home screen preview + IncomingRequestsScreen's "View All" list) without a
// working backend. Both screens import this so they preview the SAME fake
// dataset — flip [debugFakeIncomingRequestCount] and hot-restart.
//
// WHY only the list is faked here:
//   GET /api/auth/worker/incoming-requests/ is currently broken (always
//   returns null), but GET /api/auth/worker/request/<offer_id>/ and the
//   accept endpoint already work for real. So this file only fakes the list
//   response — tapping a fixture card still calls the real detail/accept
//   API with a real offer_id (15 or 16), giving a true end-to-end check of
//   the working endpoints rather than faking them too.
//
// The first two fixtures below are verbatim the real payload the backend is
// supposed to return for offers 15 and 16, so what you see here is exactly
// what the list screen will look like once the backend bug is fixed.
//
// Fixtures are parsed through the real IncomingRequest.fromJson, so a
// passing preview here proves the JSON-parsing contract too, not just the
// widgets.
//
// Callers must also gate on kDebugMode before using this so it never runs in
// release builds.

import '../../models/incoming_request_model.dart';

/// 0 = use the real API. Any other value (1, 2, 5, 10, ...) previews that
/// many fake pending offers instead. 2 matches the real backend's current
/// {"count": 2, ...} payload for offers 15 and 16.
const int debugFakeIncomingRequestCount = 0;

/// The two real records GET /api/auth/worker/incoming-requests/ is supposed
/// to return right now (verbatim, including the real offer_id), plus two
/// synthetic ones so counts above 2 can still be used to test the "top 2"
/// preview cap / sort behavior on the home screen.
const _sampleOffers = [
  {
    'offer_id': 15,
    'customer_name': 'Ram Bahadur',
    'service': 'Plumber',
    'service_icon': '/media/skills/plumber.png',
    'description': 'Kitchen pipe leaking...',
    'address': 'Lazimpat, Kathmandu',
    'distance_km': 0,
    'visit_charge': 250,
    'expires_in_seconds': 95,
    'created_at': '2026-07-17T09:15:00Z',
  },
  {
    'offer_id': 16,
    'customer_name': 'Sita Sharma',
    'service': 'Electrician',
    'service_icon': '/media/skills/electrician.png',
    'description': 'Power socket not working...',
    'address': 'Baneshwor, Kathmandu',
    'distance_km': 0,
    'visit_charge': 180,
    'expires_in_seconds': 42,
    'created_at': '2026-07-17T09:20:00Z',
  },
  {
    'offer_id': 9002,
    'customer_name': 'Gopal K.C.',
    'service': 'Painting Service',
    'service_icon': null,
    'description': 'Two bedroom walls need a fresh coat before move-in.',
    'address': 'Baneshwor, Kathmandu',
    'distance_km': 2.0,
    'visit_charge': 320,
    'expires_in_seconds': 15,
    'created_at': null, // filled in at generation time, see below
  },
  {
    'offer_id': 9003,
    'customer_name': 'Anita Gurung',
    'service': 'Carpentry Service',
    'service_icon': null,
    'description': 'Wardrobe door hinge is broken.',
    'address': 'Thamel, Kathmandu',
    'distance_km': 2.5,
    'visit_charge': 200,
    'expires_in_seconds': 110,
    'created_at': null,
  },
];

List<IncomingRequest> debugFakeIncomingRequests(int count) {
  return List.generate(count, (i) {
    final s = _sampleOffers[i % _sampleOffers.length];
    return IncomingRequest.fromJson({
      ...s,
      // The two real fixtures already carry a fixed created_at; the
      // synthetic ones get a decreasing recency so "latest 2" sorting has
      // something to prove beyond just 2 real items.
      'created_at':
          s['created_at'] ??
          DateTime.now()
              .subtract(Duration(minutes: 5 * (i + 1)))
              .toUtc()
              .toIso8601String(),
    });
  });
}
// ─── END DEBUG-ONLY FIXTURE FILE ────────────────────────────────────────────
