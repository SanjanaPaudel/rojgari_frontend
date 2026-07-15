import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../models/service_request/selected_service_location.dart';

class SelectedAddressCard extends StatelessWidget {
  const SelectedAddressCard({
    required this.location,
    required this.displayAddress,
    required this.isResolving,
    super.key,
  });

  final SelectedServiceLocation location;
  final String? displayAddress;
  final bool isResolving;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2DEEB)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected service address',
          style: TextStyle(color: AppColors.grey, fontSize: 11),
        ),
        const SizedBox(height: 6),
        if (isResolving)
          const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text(
                'Finding address...',
                style: TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          )
        else
          Text(
            displayAddress ?? 'Address unavailable for this point',
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        const SizedBox(height: 10),
        Text(
          '${location.latitude.toStringAsFixed(6)}, '
          '${location.longitude.toStringAsFixed(6)}',
          style: const TextStyle(color: AppColors.grey, fontSize: 11),
        ),
        // BACKEND LOCATION NOTE:
        // The readable label is for customer guidance only. The backend must
        // verify the raw coordinates, reverse-geocode the trusted final
        // address, and confirm that the point is inside the service area.
      ],
    ),
  );
}
