import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import '../models/notification_model.dart';
import '../widgets/notification_card.dart';

/// Shared notifications screen for both the customer and technician home
/// screens' bell icon.
///
/// UI-only for now — the list below is placeholder content standing in for
/// the FCM-backed feed (register device token -> backend push on
/// booking_accepted/booking_rejected -> stored/fetched list). Wiring that up
/// is a separate pass. "Mark all as read" and per-card read state are local
/// UI state only, not persisted anywhere yet.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

enum _NotificationFilter { all, updates }

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = _placeholderNotifications;
  _NotificationFilter _filter = _NotificationFilter.all;

  List<NotificationItem> get _visible => switch (_filter) {
    _NotificationFilter.all => _notifications,
    // No "system/announcement" notification type exists on the backend yet
    // (see NotificationType) — Updates has nothing to show until it does.
    _NotificationFilter.updates => const [],
  };

  // Acts on whichever tab is active — "Mark all as read" on the Updates tab
  // only marks Updates items read, leaving All's other items untouched.
  void _markAllRead() {
    final visibleIds = _visible.map((n) => n.id).toSet();
    setState(() {
      _notifications = [
        for (final n in _notifications)
          if (visibleIds.contains(n.id)) n.copyWith(isRead: true) else n,
      ];
    });
  }

  void _markRead(NotificationItem tapped) {
    if (tapped.isRead) return;
    setState(() {
      _notifications = [
        for (final n in _notifications)
          if (n.id == tapped.id) n.copyWith(isRead: true) else n,
      ];
    });
  }

  int get _unreadCount => _visible.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(unreadCount: _unreadCount, onMarkAllRead: _markAllRead),
            const SizedBox(height: 12),
            _FilterTabs(
              filter: _filter,
              onChanged: (filter) => setState(() => _filter = filter),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  for (final notification in visible) ...[
                    NotificationCard(
                      notification: notification,
                      onTap: () => _markRead(notification),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 24),
                  const _AllCaughtUpFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.unreadCount, required this.onMarkAllRead});

  final int unreadCount;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xff171725),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff171725),
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (unreadCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              TextButton(
                onPressed: onMarkAllRead,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Mark all as read',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.filter, required this.onChanged});

  final _NotificationFilter filter;
  final ValueChanged<_NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                icon: Icons.notifications_none_rounded,
                label: 'All',
                isActive: filter == _NotificationFilter.all,
                onTap: () => onChanged(_NotificationFilter.all),
              ),
            ),
            Expanded(
              child: _TabButton(
                icon: Icons.campaign_outlined,
                label: 'Updates',
                isActive: filter == _NotificationFilter.updates,
                onTap: () => onChanged(_NotificationFilter.updates),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : const Color(0xff8B8B9E);

    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.lightPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllCaughtUpFooter extends StatelessWidget {
  const _AllCaughtUpFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.lightPurple.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_rounded,
            size: 32,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          "You're all caught up!",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xff1A1830),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'No more notifications at the moment.',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Color(0xff9A97AC),
          ),
        ),
      ],
    );
  }
}

// Titles/bodies match the exact wording from the backend's FCM integration
// note for the two notification types it actually sends today.
final _placeholderNotifications = <NotificationItem>[
  NotificationItem(
    id: '1',
    type: NotificationType.bookingAccepted,
    title: 'Booking Accepted',
    message: 'Dinesh Adhikari accepted your booking request.',
    timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
    bookingId: '3',
  ),
  NotificationItem(
    id: '2',
    type: NotificationType.bookingRejected,
    title: 'Booking Declined',
    message: 'Sabin Karki declined your booking request.',
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    isRead: true,
    bookingId: '7',
  ),
];
