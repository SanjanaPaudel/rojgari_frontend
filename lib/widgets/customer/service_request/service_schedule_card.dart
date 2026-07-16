import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

class ServiceScheduleCard extends StatelessWidget {
  const ServiceScheduleCard({
    required this.isEnabled,
    required this.scheduledFor,
    required this.onToggle,
    required this.onSelectTime,
    super.key,
  });

  final bool isEnabled;
  final DateTime? scheduledFor;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSelectTime;

  String _formattedTime(BuildContext context) {
    final value = scheduledFor;
    if (value == null) return 'Select time';
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2DEEB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule for Later',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Set a specific time today',
                      style: TextStyle(color: AppColors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: onToggle,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isEnabled
                ? Padding(
                    key: const ValueKey('schedule-time'),
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: onSelectTime,
                            child: Container(
                              height: 54,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F6FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2DEEB),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formattedTime(context),
                                      style: const TextStyle(
                                        color: AppColors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: AppColors.black,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Today',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('schedule-empty')),
          ),
        ],
      ),
    );
  }
}
