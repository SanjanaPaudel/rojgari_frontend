// ─── DEBUG-ONLY FIXTURE FILE — DELETE BEFORE MERGING ───────────────────────
// Single source of truth for previewing the Completed Booking Details UI
// without a real backend booking to tap into (the booking history list is
// still sample data with fake IDs like 'booking_001', so the real
// GET .../bookings/<id>/status/ call would just 404). Flip
// [debugUseFakeCompletedBooking] to true and hot-restart to preview this
// screen from any "Completed" card in the booking history.
//
// The fixture JSON is parsed through the real BookingStatusResponse.fromJson,
// so a passing preview here proves the JSON-parsing contract too, not just
// the widgets — once the real endpoint returns a real completed booking,
// nothing about CompletedBookingDetailsScreen itself needs to change.
//
// Callers must also gate on kDebugMode before using this so it never runs in
// release builds. See CompletedBookingDetailsLoader for the gate.

import '../../models/service_request/booking_status_response.dart';

/// Set true to preview CompletedBookingDetailsScreen with fixture data
/// instead of calling the real API. Must be false before merging.
const bool debugUseFakeCompletedBooking = true;

const _sampleCompletedBookingJson = {
  'id': 9001,
  'status': 'completed',
  'job_progress': 'completed',
  'category': 'Plumbing Service',
  'description':
      'Leakage in bathroom pipe near the sink, water has been dripping '
      'continuously for the last two days and the floor tiles are damp.',
  'address_text': 'Lazimpat, Kathmandu',
  'latitude': 27.7172,
  'longitude': 85.3240,
  'created_at': '2026-07-30T10:15:00Z',
  'visit_charge': 150,
  'rating': 4.5,
  'review_text':
      'Very professional and fixed the leak quickly. Would book again.',
  'worker': {
    'id': 42,
    'full_name': 'Ramesh Shrestha',
    'phone_number': '+977 9812345678',
    'average_rating': 4.7,
    'completed_jobs': 128,
    'profile_photo': null,
    'current_latitude': 27.7180,
    'current_longitude': 85.3235,
  },
};

BookingStatusResponse debugFakeCompletedBooking() =>
    BookingStatusResponse.fromJson(_sampleCompletedBookingJson);
