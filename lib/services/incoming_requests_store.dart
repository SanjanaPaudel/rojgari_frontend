import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants/api_urls.dart';
import '../models/incoming_request_model.dart';
import '../screens/technician/debug_incoming_request_fixtures.dart';
import 'api_service.dart';
import 'app_web_socket.dart';
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
class IncomingRequestsStore with WidgetsBindingObserver {
  IncomingRequestsStore._();

  static final IncomingRequestsStore instance = IncomingRequestsStore._();

  final IncomingRequestService _service = IncomingRequestService();

  /// The current list. Screens listen to this via ValueListenableBuilder;
  /// nobody should ever assign to it directly except this class.
  final ValueNotifier<List<IncomingRequest>> requests =
      ValueNotifier<List<IncomingRequest>>(const []);

  AppWebSocket? _socket;
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
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
    if (_listenerCount == 1) WidgetsBinding.instance.addObserver(this);
    if (_socket == null) _connectSocket();
  }

  /// Call when a screen no longer needs live updates (e.g. in dispose).
  /// Closes the shared socket only once nothing is listening anymore.
  void detach() {
    if (_listenerCount > 0) _listenerCount--;
    if (_listenerCount == 0) {
      WidgetsBinding.instance.removeObserver(this);
      _socketSubscription?.cancel();
      _socket?.disconnect();
      _socket = null;
      _socketSubscription = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Safety net alongside _handleSocketClosed — covers cases where the
    // socket was never cleanly closed (e.g. the OS just suspended the app)
    // so no onDone ever fired.
    if (state == AppLifecycleState.resumed &&
        _listenerCount > 0 &&
        _socket == null) {
      _connectSocket();
      refreshNow();
    }
  }

  Future<void> _connectSocket() async {
    final token = await StorageService.getAccessToken();
    if (token == null) return; // not logged in — nothing to connect for
    // Everyone may have detached again while we were awaiting the token.
    if (_listenerCount == 0) return;

    final socket = AppWebSocket(ApiUrls.workerOffersSocket(token));
    _socket = socket;
    _socketSubscription = socket.connect().listen((_) {
      // Payload is a single new/backfilled offer, but it's missing fields
      // the list needs (offer id, distance, icon, created_at) — treat it
      // as a "something changed" signal and re-fetch the real list, same
      // as the old poll tick did.
      refreshNow();
    }, onDone: () => _handleSocketClosed(socket));
  }

  Future<void> _handleSocketClosed(AppWebSocket closedSocket) async {
    if (_socket != closedSocket) return; // already superseded — ignore
    _socket = null;
    _socketSubscription = null;
    if (_listenerCount == 0) return;

    // 4003: authenticated but not authorized — retrying won't help.
    if (closedSocket.closeCode == 4003) return;

    // 4001: missing/expired token — refresh the session before retrying,
    // otherwise we'd just get rejected the same way immediately again.
    if (closedSocket.closeCode == 4001) {
      final refreshed = await ApiService().checkAndRefreshSession();
      if (!refreshed || _listenerCount == 0) return;
    }

    await _connectSocket();
    // Catch up on anything that happened while disconnected — the socket
    // only tells us about changes from here on, not what we missed.
    refreshNow();
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

  /// Drops [offerId] from the shared list the moment its own client-side
  /// countdown reaches zero — the backend expires offers lazily (only when
  /// next fetched, see WorkerService._expire_if_stale) and never pushes an
  /// "expired" event over the socket, so nothing else would otherwise
  /// remove it from the home preview / full list right when its timer runs
  /// out. A no-op if it's already gone (e.g. accepted/declined first).
  void expireLocally(String offerId) {
    if (!requests.value.any((request) => request.id == offerId)) return;
    requests.value = requests.value
        .where((request) => request.id != offerId)
        .toList(growable: false);
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
}
