import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Resolve backgrounds and border colors dynamically
    final String lowerName = category.name.toLowerCase().trim();
    Color bgColor = const Color(0xFFF4EEFF);
    Color borderCol = const Color(0xFFD8C8FF);
    double padding = 6.0;
    double boxSize = 72.0;

    if (lowerName.contains('plumber')) {
      bgColor = const Color(0xFFF4EEFF);
      borderCol = const Color(0xFFD8C8FF);
      padding = 0.0;
      boxSize = 76.0;
    } else if (lowerName.contains('electrician')) {
      bgColor = const Color(0xFFFFF5E7);
      borderCol = const Color(0xFFFFD7A6);
      padding = 0.0;
      boxSize = 76.0;
    } else if (lowerName.contains('mechanic')) {
      bgColor = const Color(0xFFEEF7FF);
      borderCol = const Color(0xFFCFE8FF);
      padding = 0.0;
      boxSize = 76.0;
    } else if (lowerName.contains('gardener')) {
      bgColor = const Color(0xFFF0FFF6);
      borderCol = const Color(0xFFCFEFDC);
      padding = 0.0;
      boxSize = 76.0;
    } else if (lowerName.contains('maid')) {
      bgColor = const Color(0xFFFFF0F6);
      borderCol = const Color(0xFFFFD2E2);
      padding = 0.0;
      boxSize = 76.0;
    } else if (lowerName.contains('carpenter')) {
      bgColor = const Color(0xFFFFF7F1);
      borderCol = const Color(0xFFEBD8CA);
      padding = 0.0;
      boxSize = 76.0;
    } else if (lowerName.contains('painter')) {
      bgColor = const Color(0xFFF8F1FF);
      borderCol = const Color(0xFFDEC9FF);
      padding = 0.0;
      boxSize = 76.0;
    } else if (lowerName.contains('ac repair') || lowerName.contains('ac_repair')) {
      bgColor = const Color(0xFFEEF7FF);
      borderCol = const Color(0xFFCDE7FF);
      padding = 6.0;
      boxSize = 72.0;
    } else if (lowerName.contains('computer') || lowerName.contains('pc repair')) {
      bgColor = const Color(0xFFF0FFF7);
      borderCol = const Color(0xFFCDEDDC);
      padding = 0.0;
      boxSize = 76.0;
    } else if (lowerName.contains('tv repair')) {
      bgColor = const Color(0xFFFFF5E9);
      borderCol = const Color(0xFFFFD9B1);
      padding = 6.0;
      boxSize = 72.0;
    } else {
      // Dynamic fallback palettes for brand new categories
      final List<Color> bgPalettes = [
        const Color(0xFFF4EEFF),
        const Color(0xFFFFF5E7),
        const Color(0xFFEEF7FF),
        const Color(0xFFF0FFF6),
        const Color(0xFFFFF0F6),
        const Color(0xFFFFF7F1),
      ];
      final List<Color> borderPalettes = [
        const Color(0xFFD8C8FF),
        const Color(0xFFFFD7A6),
        const Color(0xFFCFE8FF),
        const Color(0xFFCFEFDC),
        const Color(0xFFFFD2E2),
        const Color(0xFFEBD8CA),
      ];
      final index = category.id % bgPalettes.length;
      bgColor = bgPalettes[index];
      borderCol = borderPalettes[index];
    }

    // 2. Resolve dynamic icon parsing
    IconData iconData = Icons.handyman_outlined;
    final cleanIconStr = category.icon.replaceAll('Icons.', '').toLowerCase().trim();
    if (cleanIconStr.isNotEmpty) {
      switch (cleanIconStr) {
        case 'plumbing':
          iconData = Icons.plumbing;
          break;
        case 'electric_bolt':
          iconData = Icons.electric_bolt;
          break;
        case 'build':
        case 'build_outlined':
          iconData = Icons.build_outlined;
          break;
        case 'local_florist':
        case 'local_florist_outlined':
        case 'eco':
          iconData = Icons.local_florist_outlined;
          break;
        case 'cleaning_services':
        case 'cleaning_services_outlined':
          iconData = Icons.cleaning_services_outlined;
          break;
        case 'handyman':
        case 'handyman_outlined':
          iconData = Icons.handyman_outlined;
          break;
        case 'format_paint':
          iconData = Icons.format_paint_outlined;
          break;
        case 'format_paint_outlined':
          iconData = Icons.format_paint_outlined;
          break;
        case 'ac_unit':
        case 'ac_unit_outlined':
          iconData = Icons.ac_unit_outlined;
          break;
        case 'computer':
        case 'computer_outlined':
          iconData = Icons.computer_outlined;
          break;
        case 'tv':
        case 'tv_outlined':
          iconData = Icons.tv_outlined;
          break;
      }
    } else {
      // Name fallback resolution
      if (lowerName.contains('plumber')) iconData = Icons.plumbing;
      else if (lowerName.contains('electrician')) iconData = Icons.electric_bolt;
      else if (lowerName.contains('mechanic')) iconData = Icons.build_outlined;
      else if (lowerName.contains('gardener')) iconData = Icons.local_florist_outlined;
      else if (lowerName.contains('maid')) iconData = Icons.cleaning_services_outlined;
      else if (lowerName.contains('carpenter')) iconData = Icons.handyman_outlined;
      else if (lowerName.contains('painter')) iconData = Icons.format_paint_outlined;
      else if (lowerName.contains('ac repair') || lowerName.contains('ac_repair')) iconData = Icons.ac_unit_outlined;
      else if (lowerName.contains('computer') || lowerName.contains('pc repair')) iconData = Icons.computer_outlined;
      else if (lowerName.contains('tv repair')) iconData = Icons.tv_outlined;
    }

    return Material(
      color: Color.alphaBlend(
        bgColor.withValues(alpha: .62),
        Colors.white,
      ),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 136,
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderCol.withValues(alpha: .62),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: boxSize,
                height: boxSize,
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .48),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  iconData,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 14,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
