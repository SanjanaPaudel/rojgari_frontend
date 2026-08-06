import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../models/customer/booking_history_item.dart';
import '../../services/booking_history_store.dart';
import '../../services/navigation_service.dart';
import '../../widgets/customer/booking_history_card.dart';

/// Full booking history, opened from the customer home screen's "View All"
/// button on the Bookings section.
///
/// Reads from the shared [BookingHistoryStore] — the same source the home
/// screen preview reads from — and renders each entry with the shared
/// [BookingHistoryCard] widget, so the two screens can never visually or
/// data-wise drift apart.
class CustomerBookingsHistoryScreen extends StatefulWidget {
  const CustomerBookingsHistoryScreen({super.key});

  @override
  State<CustomerBookingsHistoryScreen> createState() =>
      _CustomerBookingsHistoryScreenState();
}

enum _BookingFilter { all, inProgress, completed, cancelled }

class _CustomerBookingsHistoryScreenState
    extends State<CustomerBookingsHistoryScreen>
    with RouteAware {
  _BookingFilter _filter = _BookingFilter.all;
  late Future<void> _initialLoad;

  @override
  void initState() {
    super.initState();
    _initialLoad = _loadInitial();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    NavigationService.routeObserver.subscribe(
      this,
      ModalRoute.of(context) as PageRoute,
    );
  }

  @override
  void dispose() {
    NavigationService.routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Fires when returning here after a pushed detail/tracking screen (e.g.
  // CustomerBookingTrackingLoader) is popped — refreshes quietly in the
  // background so a booking that changed status while the customer was
  // looking at its detail screen shows up-to-date without a manual
  // pull-to-refresh.
  @override
  void didPopNext() {
    BookingHistoryStore.instance.refreshNow();
  }

  /// If the store already has a cached list (e.g. the home screen preview
  /// already fetched it), show it immediately instead of blocking this
  /// screen behind another full round trip — refresh quietly in the
  /// background instead. Only a genuinely empty store (nothing fetched yet
  /// this session) waits on the real network call and surfaces its errors.
  Future<void> _loadInitial() {
    if (BookingHistoryStore.instance.history.value.isNotEmpty) {
      BookingHistoryStore.instance.refreshNow();
      return Future.value();
    }
    return BookingHistoryStore.instance.refreshOrThrow();
  }

  Future<void> _retry() {
    final future = BookingHistoryStore.instance.refreshOrThrow();
    setState(() => _initialLoad = future);
    return future;
  }

  bool _matchesFilter(BookingHistoryItem item) {
    final status = item.status.trim().toLowerCase().replaceAll(' ', '_');
    return switch (_filter) {
      _BookingFilter.all => true,
      _BookingFilter.inProgress => status == 'in_progress',
      _BookingFilter.completed => status == 'completed',
      _BookingFilter.cancelled => status == 'cancelled',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _BookingsHeader(),
            const SizedBox(height: 14),
            _FilterChipsRow(
              filter: _filter,
              onChanged: (filter) => setState(() => _filter = filter),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<void>(
                future: _initialLoad,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _BookingsErrorState(onRetry: _retry);
                  }
                  return ValueListenableBuilder<List<BookingHistoryItem>>(
                    valueListenable: BookingHistoryStore.instance.history,
                    builder: (context, allBookings, _) {
                      final visible = allBookings
                          .where(_matchesFilter)
                          .toList();
                      return RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: BookingHistoryStore.instance.refreshOrThrow,
                        child: visible.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 80),
                                  _EmptyBookingsState(),
                                ],
                              )
                            : ListView.separated(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  4,
                                  20,
                                  24,
                                ),
                                itemCount: visible.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) =>
                                    BookingHistoryCard(
                                      booking: visible[index],
                                      onTap: () => openBookingHistoryDetail(
                                        context,
                                        visible[index],
                                      ),
                                    ),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsErrorState extends StatelessWidget {
  const _BookingsErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.red,
            size: 36,
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Unable to load your bookings. Please check your connection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingsHeader extends StatelessWidget {
  const _BookingsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back,
                color: AppColors.black,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'My Bookings',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({required this.filter, required this.onChanged});

  final _BookingFilter filter;
  final ValueChanged<_BookingFilter> onChanged;

  static const _labels = {
    _BookingFilter.all: 'All',
    _BookingFilter.inProgress: 'In Progress',
    _BookingFilter.completed: 'Completed',
    _BookingFilter.cancelled: 'Cancelled',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _BookingFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = _BookingFilter.values[index];
          final isActive = value == filter;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onChanged(value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary
                      : const Color(0xFFEFE9FF),
                ),
              ),
              child: Text(
                _labels[value]!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : AppColors.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyBookingsState extends StatelessWidget {
  const _EmptyBookingsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.lightPurple.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No bookings here',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bookings matching this filter will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
