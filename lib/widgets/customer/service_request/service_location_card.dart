import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../models/service_request/selected_service_location.dart';

class ServiceLocationCard extends StatelessWidget {
  const ServiceLocationCard({
    required this.location,
    required this.onChange,
    super.key,
  });

  final SelectedServiceLocation? location;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final selected = location;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2DEEB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onChange,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 118),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1EBFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected == null
                          ? 'No service location selected'
                          : 'Service location selected',
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (selected != null) ...[
                      const SizedBox(height: 6),
                      if (selected.landmark?.trim().isNotEmpty ?? false)
                        Text(
                          selected.landmark!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF555266),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      if (selected.landmark?.trim().isEmpty ?? true)
                        const Text(
                          'Readable address unavailable. Tap Change to search.',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 11.5,
                          ),
                        ),
                      const SizedBox(height: 5),
                      Text(
                        '${selected.latitude.toStringAsFixed(6)}, '
                        '${selected.longitude.toStringAsFixed(6)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                constraints: const BoxConstraints(minWidth: 76),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C3EF4), Color(0xFF5124D4)],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x305B2DE1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      selected == null ? 'Select' : 'Change',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
