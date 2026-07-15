import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../models/service_request/service_category.dart';
import '../../../models/service_request/service_category_presentation.dart';

class ServiceRequestHeader extends StatelessWidget {
  const ServiceRequestHeader({required this.category, super.key});

  final ServiceCategory category;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.black),
        ),
        const SizedBox(width: 6),
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.lightPurple,
            shape: BoxShape.circle,
          ),
          child: Icon(
            ServiceCategoryPresentation.iconFor(category.slug),
            color: AppColors.primary,
            size: 27,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book ${category.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Tell us about your issue',
                style: TextStyle(color: AppColors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
