import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../widgets/notification_card.dart';

/// Shared notifications screen for both the customer and technician home
/// screens' bell icon. Backed by GET /api/notifications/ for the list and
/// PATCH /api/notifications/{id}/read/ for marking items read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

enum _NotificationFilter { all, updates }

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();

  List<NotificationItem> _notifications = [];
  _NotificationFilter _filter = _NotificationFilter.all;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications = await _service.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<NotificationItem> get _visible => switch (_filter) {
    _NotificationFilter.all => _notifications,
    // No "system/announcement" notification type exists on the backend yet
    // (see NotificationType) — Updates has nothing to show until it does.
    _NotificationFilter.updates => const [],
  };

  // Acts on whichever tab is active — "Mark all as read" on the Updates tab
  // only marks Updates items read, leaving All's other items untouched.
  //
  // No bulk "mark all" endpoint exists on the backend — only a
  // single-notification one — so this loops and calls it once per unread
  // item.
  Future<void> _markAllRead() async {
    final unread = _visible.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    for (final n in unread) {
      try {
        await _service.markAsRead(n.id);
      } catch (_) {
        // Skip this one, keep going with the rest.
      }
    }

    if (!mounted) return;
    final markedIds = unread.map((n) => n.id).toSet();
    setState(() {
      _notifications = [
        for (final n in _notifications)
          if (markedIds.contains(n.id)) n.copyWith(isRead: true) else n,
      ];
    });
  }

  Future<void> _markRead(NotificationItem tapped) async {
    if (tapped.isRead) return;
    try {
      await _service.markAsRead(tapped.id);
    } catch (_) {
      return; // Leave it unread locally if the backend call failed.
    }
    if (!mounted) return;
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
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadNotifications);
    }

    final visible = _visible;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 46,
              color: Color(0xffBFC4D2),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xff6E7191),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: Color(0xffD8CCFB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try again'),
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
