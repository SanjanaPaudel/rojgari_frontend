import 'package:flutter/material.dart';
import '../models/skill_model.dart';

class SkillCard extends StatelessWidget {
  final Skill skill;
  final bool isSelected;
  final VoidCallback onTap;

  const SkillCard({
    super.key,
    required this.skill,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6A5AE0)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = constraints.maxWidth;

            // Responsive scale calculations
            final double containerSize = (cardWidth * 0.35).clamp(40.0, 64.0);
            final double iconSize = containerSize * 0.8;
            final double selectIconSize = (cardWidth * 0.12).clamp(16.0, 22.0);
            final double spacingSize = (cardWidth * 0.08).clamp(8.0, 14.0);
            final double titleFontSize = (cardWidth * 0.1).clamp(11.0, 15.0);
            final double descFontSize = (cardWidth * 0.5).clamp(9.0, 11.5);
            final double paddingSize = (cardWidth * 0.1).clamp(10.0, 18.0);

            return Stack(
              children: [
                // Selection check icon
                Positioned(
                  top: paddingSize * 0.7,
                  right: paddingSize * 0.5,
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? const Color(0xFF6A5AE0)
                        : Colors.grey,
                    size: selectIconSize,
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(paddingSize),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Skill handyman icon container
                        Container(
                          width: containerSize,
                          height: containerSize,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F4F8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.handyman,
                            size: iconSize,
                            color: const Color(0xFF6A5AE0),
                          ),
                        ),

                        SizedBox(height: spacingSize),

                        Text(
                          skill.name,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        if (skill.description != null &&
                            skill.description!.isNotEmpty) ...[
                          SizedBox(height: spacingSize * 0.5),
                          Text(
                            skill.description!,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}