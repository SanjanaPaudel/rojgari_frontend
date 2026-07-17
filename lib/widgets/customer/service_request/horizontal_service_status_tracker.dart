import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../models/service_request/request_search_status.dart';

class HorizontalServiceStatusTracker extends StatefulWidget {
  const HorizontalServiceStatusTracker({required this.status, super.key});

  final RequestSearchStatus status;

  @override
  State<HorizontalServiceStatusTracker> createState() =>
      _HorizontalServiceStatusTrackerState();
}

class _HorizontalServiceStatusTrackerState
    extends State<HorizontalServiceStatusTracker>
    with SingleTickerProviderStateMixin {
  static const _labels = <String>[
    'Accepted',
    'On the\nWay',
    'Arrived',
    'Working',
    'Completed',
  ];

  late final AnimationController _pulseController;

  int get _activeIndex => switch (widget.status) {
    RequestSearchStatus.accepted => 0,
    RequestSearchStatus.workerOnTheWay => 1,
    RequestSearchStatus.arrived => 2,
    RequestSearchStatus.working => 3,
    RequestSearchStatus.completed => 4,
    _ => 0,
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _activeIndex;
    final allCompleted = widget.status.isCompleted;
    return Container(
      key: const ValueKey('horizontal-service-status-tracker'),
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8E3F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C1A1233),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final circleSize = constraints.maxWidth < 330 ? 25.0 : 28.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 3, bottom: 12),
                child: Text(
                  'Service Status',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Row(
                children: [
                  for (var index = 0; index < _labels.length; index++) ...[
                    if (index > 0)
                      Expanded(
                        child: Container(
                          key: ValueKey('status-line-$index'),
                          height: 3,
                          color: index <= activeIndex
                              ? AppColors.primary
                              : AppColors.lightPurple,
                        ),
                      ),
                    _StatusPoint(
                      key: ValueKey('status-point-$index'),
                      size: circleSize,
                      completed: allCompleted || index < activeIndex,
                      active: !allCompleted && index == activeIndex,
                      pulse: _pulseController,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < _labels.length; index++)
                    Expanded(
                      child: Text(
                        _labels[index],
                        key: ValueKey('status-label-$index'),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          color: index <= activeIndex
                              ? AppColors.primary
                              : AppColors.grey,
                          fontSize: constraints.maxWidth < 330 ? 8 : 9,
                          height: 1.15,
                          fontWeight: index == activeIndex
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusPoint extends StatelessWidget {
  const _StatusPoint({
    required this.size,
    required this.completed,
    required this.active,
    required this.pulse,
    super.key,
  });

  final double size;
  final bool completed;
  final bool active;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final scale = active ? 1 + pulse.value * .08 : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: completed || active
                  ? AppColors.primary
                  : AppColors.lightPurple,
              shape: BoxShape.circle,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(
                          alpha: .18 + pulse.value * .12,
                        ),
                        blurRadius: 9,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              completed ? Icons.check_rounded : Icons.circle,
              size: completed ? size * .62 : size * .28,
              color: completed || active ? Colors.white : AppColors.grey,
            ),
          ),
        );
      },
    );
  }
}
