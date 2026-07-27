import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/incoming_request_model.dart';
import '../screens/technician/debug_incoming_request_fixtures.dart';
import 'incoming_request_service.dart';
import 'storage_service.dart';

/// Single shared source of truth for the worker's pending incoming-request
/// offers.
///
/// WHY this exists:
///   Before this, the home screen's preview and the "All Incoming Requests"
///   list each fetched and held their own private copy, so they could show
///   different things depending on which one last happened to refresh. Both
///   screens now read this one shared list instead, so they always agree —
///   there's nothing left for two independent copies to disagree about.
///
/// WHY this is the only place that will need to change for a future
/// socket/push upgrade:
///   Screens only ever read [requests] (a ValueNotifier) — they have no idea
///   how it gets kept fresh. Today that's [_fetch] on a timer; later, a
///   socket listener can update the same [requests] value on a push event
///   instead, with zero changes required in any screen.
class IncomingRequestsStore {
  IncomingRequestsStore._();

  static final IncomingRequestsStore instance = IncomingRequestsStore._();

  static const Duration pollInterval = Duration(seconds: 15);

  final IncomingRequestService _service = IncomingRequestService();

  /// The current list. Screens listen to this via ValueListenableBuilder;
  /// nobody should ever assign to it directly except this class.
  final ValueNotifier<List<IncomingRequest>> requests =
      ValueNotifier<List<IncomingRequest>>(const []);

  Timer? _timer;
  int _listenerCount = 0;

  /// Offer IDs the worker has opened, cached in memory after the first
  /// read from StorageService so we don't hit device storage on every
  /// fetch. Null means "not loaded yet."
  Set<String>? _viewedIds;

  /// Call when a screen showing this list becomes active (e.g. in
  /// initState). Multiple screens can be attached at once — the underlying
  /// poll timer is shared, not duplicated per screen. Purely manages the
  /// timer's lifecycle; callers still fetch explicitly (via [refreshNow] or
  /// [refreshOrThrow]) for their own initial load, so a screen with its own
  /// loading UI isn't fighting an implicit fetch happening at the same time.
  void attach() {
    _listenerCount++;
    _timer ??= Timer.periodic(pollInterval, (_) => _fetch());
  }

  /// Call when a screen no longer needs live updates (e.g. in dispose).
  /// Stops the shared timer only once nothing is listening anymore.
  void detach() {
    if (_listenerCount > 0) _listenerCount--;
    if (_listenerCount == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Forces an immediate refresh outside the normal poll cadence — e.g.
  /// right after an accept/decline, or a manual "check now" action. Silently
  /// keeps the last known-good list on failure — for callers with no error
  /// UI of their own to show.
  Future<void> refreshNow() async {
    try {
      await refreshOrThrow();
    } catch (_) {
      // A failed check is likely transient — keep showing the last
      // known-good list rather than clearing it.
    }
  }

  /// Like [refreshNow], but rethrows on failure instead of silently keeping
  /// the last known-good list — for callers (e.g. IncomingRequestsScreen's
  /// initial load / pull-to-refresh) that show their own loading/error UI
  /// around a single fetch attempt.
  Future<void> refreshOrThrow() async {
    final fresh = (kDebugMode && debugFakeIncomingRequestCount > 0)
        ? debugFakeIncomingRequests(debugFakeIncomingRequestCount)
        : await _service.fetchIncomingRequests();
    requests.value = await _applyViewedStatus(fresh);
  }

  /// Call when the worker opens a specific offer's details — remembers it
  /// as "viewed" on this device (surviving app restarts) and updates the
  /// currently-shown list immediately, without waiting for the next fetch.
  Future<void> markViewed(String offerId) async {
    final ids = await _loadViewedIds();
    if (!ids.add(offerId)) return; // already known as viewed
    await StorageService.saveViewedOfferIds(ids);

    for (final request in requests.value) {
      if (request.id == offerId) {
        request.status = IncomingRequestStatus.viewed;
      }
    }
    // Reassigning — not just mutating the existing list's contents — is
    // what actually makes ValueListenableBuilder notice and rebuild.
    requests.value = [...requests.value];
  }

  Future<Set<String>> _loadViewedIds() async {
    return _viewedIds ??= await StorageService.getViewedOfferIds();
  }

  /// Marks any freshly-fetched request already known as "viewed" and, as
  /// housekeeping, drops saved IDs for offers that aren't in this fetch
  /// anymore (expired / taken / accepted / rejected) so the saved list
  /// doesn't grow forever with IDs for offers that no longer exist.
  Future<List<IncomingRequest>> _applyViewedStatus(
    List<IncomingRequest> fresh,
  ) async {
    final viewedIds = await _loadViewedIds();
    final freshIds = fresh.map((r) => r.id).toSet();
    final trimmed = viewedIds.intersection(freshIds);
    if (trimmed.length != viewedIds.length) {
      _viewedIds = trimmed;
      await StorageService.saveViewedOfferIds(trimmed);
    }

    for (final request in fresh) {
      if (trimmed.contains(request.id)) {
        request.status = IncomingRequestStatus.viewed;
      }
    }
    return fresh;
  }

  Future<void> _fetch() => refreshNow();
}
