import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/utils/category_icon_registry.dart';
import '../../models/service_request/booking_status_response.dart';

/// Presentational — shows every detail of one completed booking. Fed real
/// data by CompletedBookingDetailsLoader, which does the actual API fetch;
/// this screen never makes network calls itself (same separation as
/// IncomingRequestDetailsScreen on the technician side).
class CompletedBookingDetailsScreen extends StatelessWidget {
  const CompletedBookingDetailsScreen({super.key, required this.booking});

  final BookingStatusResponse booking;

  @override
  Widget build(BuildContext context) {
    final worker = booking.worker;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SummaryCard(booking: booking),
              const SizedBox(height: 14),
              _DescriptionCard(description: booking.description),
              const SizedBox(height: 14),
              _LocationCard(addressText: booking.addressText),
              const SizedBox(height: 14),
              if (worker != null) ...[
                _TechnicianCard(worker: worker),
                const SizedBox(height: 14),
              ],
              _VisitChargeCard(visitCharge: booking.visitCharge),
              const SizedBox(height: 14),
              _RatingCard(rating: booking.rating, reviewText: booking.reviewText),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.booking});

  final BookingStatusResponse booking;

  @override
  Widget build(BuildContext context) {
    final iconData = CategoryIconRegistry.resolve(
      icon: '',
      name: booking.categoryName ?? '',
    );

    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.lightPurple,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, size: 30, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.categoryName?.trim().isNotEmpty == true
                      ? booking.categoryName!
                      : 'Service',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _StatusPill(text: _formatDate(booking.createdAt)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Completed',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} · $hour12:$minute $period';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(Icons.event_outlined, size: 14, color: AppColors.grey),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.grey, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.description});

  final String? description;

  @override
  Widget build(BuildContext context) {
    final text = description?.trim() ?? '';
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Problem Description'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xffF6F3FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text.isEmpty ? 'No description provided.' : text,
              style: const TextStyle(
                color: AppColors.grey,
                height: 1.55,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.addressText});

  final String? addressText;

  @override
  Widget build(BuildContext context) {
    final text = addressText?.trim();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Service Location'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (text == null || text.isEmpty)
                      ? 'Location not available.'
                      : text,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 13.5,
                    height: 1.4,
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

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({required this.worker});

  final AssignedWorkerInfo worker;

  @override
  Widget build(BuildContext context) {
    final photo = worker.profilePhoto;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Technician'),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipOval(
                child: Container(
                  width: 54,
                  height: 54,
                  color: AppColors.lightPurple,
                  child: (photo != null && photo.trim().isNotEmpty)
                      ? Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.person, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.fullName.trim().isEmpty
                          ? 'Technician'
                          : worker.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFFFB020),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          worker.averageRating != null
                              ? worker.averageRating!.toStringAsFixed(1)
                              : 'No rating',
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (worker.completedJobs != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· ${worker.completedJobs} jobs',
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisitChargeCard extends StatelessWidget {
  const _VisitChargeCard({required this.visitCharge});

  final double? visitCharge;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Visit Charge',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            visitCharge != null
                ? 'Rs ${visitCharge!.toStringAsFixed(0)}'
                : 'Not available',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating, this.reviewText});

  final double? rating;
  final String? reviewText;

  @override
  Widget build(BuildContext context) {
    final review = reviewText?.trim() ?? '';
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Your Rating'),
          const SizedBox(height: 10),
          if (rating == null)
            const Text(
              'You haven\'t rated this service yet.',
              style: TextStyle(color: AppColors.grey, fontSize: 13),
            )
          else ...[
            Row(
              children: [
                _RatingStars(rating: rating!),
                const SizedBox(width: 8),
                Text(
                  rating!.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (review.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xffF6F3FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  review,
                  style: const TextStyle(
                    color: AppColors.grey,
                    height: 1.55,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final rounded = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rounded ? Icons.star_rounded : Icons.star_border_rounded,
          size: 18,
          color: const Color(0xFFFFB020),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .025),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.black,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );
}
