import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import '../models/notification_model.dart';

/// Single reusable row for rendering a [NotificationItem] on the
/// notifications screen. Visuals (icon, tint) key off [NotificationItem.type];
/// unread items get a leading dot and a trailing chevron, read items render
/// with a muted icon and neither.
class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key, required this.notification, this.onTap});

  final NotificationItem notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(notification.type);
    final isUnread = !notification.isRead;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A231447), blurRadius: 14)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 14,
                  child: isUnread
                      ? const Center(
                          child: _Dot(color: AppColors.primary, size: 7),
                        )
                      : null,
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isUnread
                        ? visual.tint
                        : visual.tint.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    visual.icon,
                    size: 21,
                    color: isUnread
                        ? visual.color
                        : visual.color.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff1A1830),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _relativeTime(notification.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff9A97AC),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff6E7191),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(width: 4),
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Color(0xffBFB8D6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _NotificationVisual {
  const _NotificationVisual(this.icon, this.color, this.tint);

  final IconData icon;
  final Color color;
  final Color tint;
}

_NotificationVisual _visualFor(NotificationType type) {
  switch (type) {
    case NotificationType.bookingAccepted:
      return const _NotificationVisual(
        Icons.check_circle_outline,
        AppColors.green,
        Color(0xffE4F9EC),
      );
    case NotificationType.bookingRejected:
      return const _NotificationVisual(
        Icons.cancel_outlined,
        AppColors.red,
        Color(0xffFFE9E7),
      );
    case NotificationType.general:
      return const _NotificationVisual(
        Icons.notifications_none_rounded,
        AppColors.primary,
        Color(0xffEDE7FF),
      );
  }
}

String _relativeTime(DateTime timestamp) {
  final diff = DateTime.now().difference(timestamp);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) {
    final hours = diff.inHours;
    return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
  }
  if (diff.inDays < 7) {
    return diff.inDays == 1 ? 'Yesterday' : '${diff.inDays} days ago';
  }
  return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
}
