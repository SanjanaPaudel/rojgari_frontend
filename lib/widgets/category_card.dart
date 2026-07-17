import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/utils/category_icon_registry.dart';
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

    // 2. Resolve icon from the backend-provided icon key (falls back to
    // matching the category name, then to a generic icon). See
    // CategoryIconRegistry for the full list of known keys and how to add a
    // new one.
    final IconData iconData = CategoryIconRegistry.resolve(
      icon: category.icon,
      name: category.name,
    );

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
          child: LayoutBuilder(
            builder: (context, innerConstraints) {
              // Shrink the icon box (never grow it) by exactly as much as
              // the wrapped title needs, so the card fits the grid cell's
              // fixed height regardless of name length, font metrics, or the
              // device's text-scale setting. When there's enough room (as
              // there is for every current category) this returns `boxSize`
              // unchanged, so today's layout is pixel-identical.
              const double gap = 10;
              const textStyle = TextStyle(
                color: AppColors.black,
                fontSize: 14,
                height: 1.15,
                fontWeight: FontWeight.w700,
              );
              final textPainter = TextPainter(
                text: TextSpan(text: category.name, style: textStyle),
                maxLines: 2,
                textDirection: TextDirection.ltr,
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: innerConstraints.maxWidth);

              final double availableForIcon =
                  innerConstraints.maxHeight - gap - textPainter.height;
              final double effectiveBoxSize = availableForIcon.clamp(
                40.0,
                boxSize,
              );

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: effectiveBoxSize,
                    height: effectiveBoxSize,
                    padding: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .48),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Icon(
                        iconData,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: gap),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
