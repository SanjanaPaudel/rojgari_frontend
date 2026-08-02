import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../models/incoming_request_model.dart';
import 'category_avatar.dart';
import 'request_offer_badges.dart';

/// Which layout [IncomingRequestCard] renders.
enum IncomingRequestCardStyle {
  /// The compact tile used on the technician home screen's "New requests
  /// near you" preview: title + countdown badge, location, distance + visit
  /// charge, chevron button.
  compact,

  /// The denser tile used on "All Incoming Requests": leads with the
  /// customer name, then service, a description preview, location, and
  /// distance.
  detailed,
}

/// The single reusable card for rendering an [IncomingRequest], used by both
/// the technician home screen preview and the "All Incoming Requests" list.
/// [style] picks which of the two layouts to render — the two screens show
/// different information density, not different widgets.
class IncomingRequestCard extends StatelessWidget {
  const IncomingRequestCard({
    super.key,
    required this.request,
    required this.style,
    this.onTap,
    this.onExpired,
  });

  final IncomingRequest request;
  final IncomingRequestCardStyle style;
  final VoidCallback? onTap;

  // Called once, the moment this offer's countdown reaches zero — the
  // caller is expected to drop it from IncomingRequestsStore so it
  // disappears from both the home preview and the full list.
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      IncomingRequestCardStyle.compact => _CompactCard(
        request: request,
        onTap: onTap,
        onExpired: onExpired,
      ),
      IncomingRequestCardStyle.detailed => _DetailedCard(
        request: request,
        onTap: onTap,
        onExpired: onExpired,
      ),
    };
  }
}

class _CompactCard extends StatelessWidget {
  const _CompactCard({required this.request, this.onTap, this.onExpired});

  final IncomingRequest request;
  final VoidCallback? onTap;
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xffE9E5EF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CategoryAvatar(iconUrl: request.iconUrl, size: 58, padding: 5),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            request.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff171725),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ExpiryCountdownBadge(
                          initialSeconds: request.expiresInSeconds,
                          onExpired: onExpired,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _InfoLine(
                      icon: Icons.location_on_outlined,
                      text: request.location,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.distanceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        VisitChargeBadge(amount: request.visitCharge),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xffF3ECFF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xff5F6A8A)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xff5F6A8A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailedCard extends StatelessWidget {
  const _DetailedCard({required this.request, this.onTap, this.onExpired});

  final IncomingRequest request;
  final VoidCallback? onTap;
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context) {
    // Card chrome (radius, border, shadow) is kept identical to _SectionCard
    // in technician profile_screen.dart so every card in the app reads the
    // same. The Container carries the shadow; the transparent Material above
    // it keeps the InkWell ripple.
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEAF9)),
        boxShadow: const [BoxShadow(color: Color(0x0A231447), blurRadius: 14)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryAvatar(iconUrl: request.iconUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              request.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff1A1830),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ExpiryCountdownBadge(
                            initialSeconds: request.expiresInSeconds,
                            onExpired: onExpired,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        request.descriptionPreview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff9A97AC),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Color(0xff8B8B9E),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              request.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff6E7191),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Padding(
                        // Aligns the distance under the location text,
                        // clearing the 14px icon + 5px gap.
                        padding: const EdgeInsets.only(left: 19),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                request.distanceLabel,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            VisitChargeBadge(amount: request.visitCharge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

