import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../models/incoming_request_model.dart';

// Card used on the "All Incoming Requests" screen.
//
// Layout mirrors the customer summary container at the top of the Request
// Details design: avatar, customer name, requested service, a short preview
// of the problem description, then location and distance from the worker.
//
// WHY this is separate from RequestCard:
//   RequestCard is the compact tile on the technician home screen, keyed on
//   the service name. This card leads with the customer and adds distance.
//   Keeping them apart leaves the working home screen untouched.
class IncomingRequestCard extends StatelessWidget {
  const IncomingRequestCard({
    super.key,
    required this.request,
    this.onTap,
  });

  final IncomingRequest request;
  final VoidCallback? onTap;

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
                _CategoryAvatar(iconUrl: request.iconUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1A1830),
                        ),
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
                        child: Text(
                          request.distanceLabel,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
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

// The category icon comes from Skill.icon, which is nullable on the backend
// and can also fail to load (bad path, server down). Both cases fall back to
// a neutral tool glyph rather than showing a broken image.
class _CategoryAvatar extends StatelessWidget {
  const _CategoryAvatar({required this.iconUrl});

  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(9),
      decoration: const BoxDecoration(
        color: Color(0xffF3EBFF),
        shape: BoxShape.circle,
      ),
      child: iconUrl == null
          ? const _FallbackIcon()
          : Image.network(
              iconUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const _FallbackIcon(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const _FallbackIcon(),
            ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.handyman_outlined,
      size: 24,
      color: AppColors.primary,
    );
  }
}
