import 'dart:async';

import 'package:flutter/material.dart';

enum ServiceRequestNotificationType { error, success, info }

class ServiceRequestNotifier {
  ServiceRequestNotifier._();

  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String message,
    ServiceRequestNotificationType type = ServiceRequestNotificationType.error,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _removeActive();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ServiceRequestTopNotification(
        message: message,
        type: type,
        onDismiss: () => _remove(entry),
      ),
    );
    _activeEntry = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(duration, () => _remove(entry));
  }

  static void _remove(OverlayEntry entry) {
    if (entry.mounted) entry.remove();
    if (identical(_activeEntry, entry)) {
      _activeEntry = null;
      _dismissTimer?.cancel();
      _dismissTimer = null;
    }
  }

  static void _removeActive() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    final entry = _activeEntry;
    _activeEntry = null;
    if (entry != null && entry.mounted) entry.remove();
  }
}

class _ServiceRequestTopNotification extends StatefulWidget {
  const _ServiceRequestTopNotification({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  final String message;
  final ServiceRequestNotificationType type;
  final VoidCallback onDismiss;

  @override
  State<_ServiceRequestTopNotification> createState() =>
      _ServiceRequestTopNotificationState();
}

class _ServiceRequestTopNotificationState
    extends State<_ServiceRequestTopNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _NotificationColors.forType(widget.type);
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(minHeight: 82),
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors.background),
                  border: Border.all(color: colors.border, width: 1.2),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.iconBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(colors.icon, color: colors.foreground),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            colors.title,
                            style: TextStyle(
                              color: colors.foreground,
                              fontFamily: 'Poppins',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.message,
                            style: TextStyle(
                              color: colors.foreground,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Dismiss',
                      onPressed: widget.onDismiss,
                      color: colors.foreground,
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationColors {
  const _NotificationColors({
    required this.title,
    required this.icon,
    required this.foreground,
    required this.iconBackground,
    required this.border,
    required this.background,
    required this.shadow,
  });

  final String title;
  final IconData icon;
  final Color foreground;
  final Color iconBackground;
  final Color border;
  final List<Color> background;
  final Color shadow;

  factory _NotificationColors.forType(ServiceRequestNotificationType type) {
    switch (type) {
      case ServiceRequestNotificationType.error:
        return const _NotificationColors(
          title: 'Action needed',
          icon: Icons.error_outline_rounded,
          foreground: Color(0xFFB4232D),
          iconBackground: Color(0xFFFFDDE0),
          border: Color(0xFFF3A8AE),
          background: [Color(0xFFFFF8F8), Color(0xFFFFEBED)],
          shadow: Color(0x3DB4232D),
        );
      case ServiceRequestNotificationType.success:
        return const _NotificationColors(
          title: 'Request ready',
          icon: Icons.check_circle_outline_rounded,
          foreground: Color(0xFF167249),
          iconBackground: Color(0xFFDDF7EA),
          border: Color(0xFF9AD8BB),
          background: [Color(0xFFF7FFFB), Color(0xFFE8FAF1)],
          shadow: Color(0x30167249),
        );
      case ServiceRequestNotificationType.info:
        return const _NotificationColors(
          title: 'Please note',
          icon: Icons.info_outline_rounded,
          foreground: Color(0xFF5124D4),
          iconBackground: Color(0xFFE9E0FF),
          border: Color(0xFFC7B7F5),
          background: [Color(0xFFFCFAFF), Color(0xFFF0EBFF)],
          shadow: Color(0x305B2DE1),
        );
    }
  }
}
