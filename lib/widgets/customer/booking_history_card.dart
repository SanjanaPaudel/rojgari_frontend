import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../models/customer/booking_history_item.dart';

/// The single reusable card for rendering a [BookingHistoryItem] — used by
/// both the customer home screen's Bookings preview and the full
/// CustomerBookingsHistoryScreen ("View All") list, so the two can never
/// visually drift apart.
class BookingHistoryCard extends StatelessWidget {
  const BookingHistoryCard({super.key, required this.booking, this.onTap});

  final BookingHistoryItem booking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusStyle = BookingHistoryStatusStyle.fromBackend(booking.status);

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEFE9FF)),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F7FF),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(booking.iconPath, fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          booking.timeLabel,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      booking.issue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusStyle.backgroundColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusStyle.label,
                            style: TextStyle(
                              color: statusStyle.textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (booking.visitCharge != null) ...[
                          const Spacer(),
                          Text(
                            booking.visitCharge!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.lightPurple,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onTap,
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.primary,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookingHistoryStatusStyle {
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const BookingHistoryStatusStyle({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  // BACKEND TODO:
  // Keep backend bookingStatus values simple and consistent:
  // completed, in_progress, booked, pending, cancelled.
  // If backend sends a new status, add one case here only; the card UI will
  // update automatically without changing the widget layout.
  factory BookingHistoryStatusStyle.fromBackend(String status) {
    switch (status.trim().toLowerCase().replaceAll(' ', '_')) {
      case 'completed':
        return BookingHistoryStatusStyle(
          label: 'Completed',
          textColor: AppColors.green,
          backgroundColor: AppColors.green.withValues(alpha: .12),
        );
      case 'in_progress':
        return const BookingHistoryStatusStyle(
          label: 'In Progress',
          textColor: Color(0xFF1877F2),
          backgroundColor: Color(0xFFEAF2FF),
        );
      case 'booked':
        return const BookingHistoryStatusStyle(
          label: 'Booked',
          textColor: AppColors.primary,
          backgroundColor: AppColors.lightPurple,
        );
      case 'cancelled':
        return const BookingHistoryStatusStyle(
          label: 'Cancelled',
          textColor: AppColors.red,
          backgroundColor: Color(0xFFFFECEC),
        );
      default:
        return const BookingHistoryStatusStyle(
          label: 'Pending',
          textColor: Color(0xFF8A5A00),
          backgroundColor: Color(0xFFFFF3D6),
        );
    }
  }
}
