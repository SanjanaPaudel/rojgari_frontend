import 'package:flutter/foundation.dart';

import '../models/customer/booking_history_item.dart';
import 'booking_history_service.dart';

/// Single shared source of truth for the customer's booking history.
///
/// WHY this exists:
///   The home screen's "Bookings" preview and the full
///   CustomerBookingsHistoryScreen ("View All") both need the same list —
///   the preview just shows the first 3. Fetching independently in each
///   screen risked them disagreeing (e.g. one screen showing a booking the
///   other hasn't refreshed to yet). Both screens now read this one shared
///   list instead, so they always agree.
///
/// Unlike IncomingRequestsStore, there is no live push channel behind this
/// data — `bookings/list/` is a plain REST endpoint, not WebSocket-driven —
/// so this store only ever needs an explicit fetch-on-demand. No socket,
/// no reconnect logic, no attach()/detach() lifecycle to manage.
class BookingHistoryStore {
  BookingHistoryStore._();

  static final BookingHistoryStore instance = BookingHistoryStore._();

  final BookingHistoryService _service = BookingHistoryService();

  /// The current list, newest-first. Screens listen to this via
  /// ValueListenableBuilder; nobody should assign to it directly except
  /// this class.
  final ValueNotifier<List<BookingHistoryItem>> history =
      ValueNotifier<List<BookingHistoryItem>>(const []);

  bool _loaded = false;

  /// Forces an immediate refresh. Silently keeps the last known-good list
  /// on failure — for callers (e.g. the home screen preview) with no error
  /// UI of their own to show.
  Future<void> refreshNow() async {
    try {
      await refreshOrThrow();
    } catch (_) {
      // A failed fetch is likely transient — keep showing the last
      // known-good list rather than clearing it.
    }
  }

  /// Like [refreshNow], but rethrows on failure instead of silently keeping
  /// the last known-good list — for callers (e.g.
  /// CustomerBookingsHistoryScreen's initial load / pull-to-refresh) that
  /// show their own loading/error UI around a single fetch attempt.
  Future<void> refreshOrThrow() async {
    final fresh = await _service.fetchHistory();
    history.value = fresh;
    _loaded = true;
  }

  /// Fetches only if nothing has been loaded yet this session — for the
  /// home screen preview, so returning to it after
  /// CustomerBookingsHistoryScreen already refreshed doesn't re-fetch
  /// pointlessly. Callers that need guaranteed-fresh data (e.g. right after
  /// creating or cancelling a booking) should call [refreshNow] instead.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await refreshNow();
  }
}
