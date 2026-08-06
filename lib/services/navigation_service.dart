import 'package:flutter/material.dart';

class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Registered as a navigatorObserver in main.dart. Lets any screen mix in
  /// RouteAware and get notified (didPopNext) when it becomes visible again
  /// after a route pushed on top of it is popped — e.g. so the booking
  /// history preview/list can refresh itself on return, without needing a
  /// live push channel for "the list changed" (see BookingHistoryStore).
  static final RouteObserver<PageRoute<dynamic>> routeObserver =
      RouteObserver<PageRoute<dynamic>>();
}
