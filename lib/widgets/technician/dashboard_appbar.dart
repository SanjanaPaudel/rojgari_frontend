import 'package:flutter/material.dart';

class DashboardAppbar extends StatelessWidget {
  final int notificationCount;
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationTap;

  const DashboardAppbar({
    super.key,
    required this.notificationCount,
    this.onMenuTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Menu',
                onPressed: onMenuTap,
                icon: const Icon(Icons.menu, size: 28),
              ),
            ),
            Center(
              child: Image.asset(
                'assets/images/logo_text.png',
                width: 142,
                height: 68,
                fit: BoxFit.contain,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _TopIconWithBadge(
                icon: Icons.notifications_none,
                count: notificationCount,
                onTap: onNotificationTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconWithBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback? onTap;

  const _TopIconWithBadge({
    required this.icon,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(onPressed: onTap, icon: Icon(icon, size: 27)),
        if (count > 0)
          Positioned(
            right: 3,
            top: 3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
