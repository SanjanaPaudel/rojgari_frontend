import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../models/customer/booking_history_item.dart';
import '../../widgets/customer/booking_history_card.dart';

/// Full booking history, opened from the customer home screen's "View All"
/// button on the Bookings section.
///
/// UI ONLY — reads the same [sampleBookingHistory] source the home screen
/// preview uses, and renders each entry with the shared [BookingHistoryCard]
/// widget, so the two screens can never visually drift apart.
class CustomerBookingsHistoryScreen extends StatefulWidget {
  const CustomerBookingsHistoryScreen({super.key});

  @override
  State<CustomerBookingsHistoryScreen> createState() =>
      _CustomerBookingsHistoryScreenState();
}

enum _BookingFilter { all, booked, inProgress, completed, cancelled }

class _CustomerBookingsHistoryScreenState
    extends State<CustomerBookingsHistoryScreen> {
  _BookingFilter _filter = _BookingFilter.all;

  bool _matchesFilter(BookingHistoryItem item) {
    final status = item.status.trim().toLowerCase().replaceAll(' ', '_');
    return switch (_filter) {
      _BookingFilter.all => true,
      _BookingFilter.booked => status == 'booked',
      _BookingFilter.inProgress => status == 'in_progress',
      _BookingFilter.completed => status == 'completed',
      _BookingFilter.cancelled => status == 'cancelled',
    };
  }

  @override
  Widget build(BuildContext context) {
    final visible = sampleBookingHistory.where(_matchesFilter).toList();

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
              child: visible.isEmpty
                  ? const _EmptyBookingsState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => BookingHistoryCard(
                        booking: visible[index],
                        onTap: () =>
                            openBookingHistoryDetail(context, visible[index]),
                      ),
                    ),
            ),
          ],
        ),
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
    _BookingFilter.booked: 'Booked',
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
