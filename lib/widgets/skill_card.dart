import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../models/skill_model.dart';

/// Controls which visual theme the card renders in.
/// - [signup]     → the white-card style used on SkillSelectionScreen (auth flow).
/// - [technician] → the animated card style used on TechnicianSkillSelectionScreen.
enum SkillCardStyle { signup, technician }

class SkillCard extends StatelessWidget {
  final Skill skill;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  /// Visual style variant. Defaults to [SkillCardStyle.signup] so all existing
  /// call-sites that omit this parameter are completely unaffected.
  final SkillCardStyle style;

  /// Optional icon shown inside the technician-style card.
  /// When null the fallback [Icons.handyman] is used.
  final IconData? icon;

  const SkillCard({
    super.key,
    required this.skill,
    required this.isSelected,
    this.isDisabled = false,
    required this.onTap,
    this.style = SkillCardStyle.signup,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return style == SkillCardStyle.technician
        ? _TechnicianCard(
            skill: skill,
            isSelected: isSelected,
            isDisabled: isDisabled,
            onTap: onTap,
            icon: icon ?? Icons.handyman,
          )
        : _SignupCard(
            skill: skill,
            isSelected: isSelected,
            isDisabled: isDisabled,
            onTap: onTap,
          );
  }
}

// ---------------------------------------------------------------------------
// Signup-flow card (original look — untouched)
// ---------------------------------------------------------------------------

class _SignupCard extends StatelessWidget {
  const _SignupCard({
    required this.skill,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final Skill skill;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : (isDisabled ? const Color(0xFFEBEBF0) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6A5AE0)
                : (isDisabled ? Colors.grey.shade400 : Colors.grey.shade300),
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
        child: Opacity(
          opacity: isDisabled ? 0.55 : 1.0,
          child: LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = constraints.maxWidth;

            // Responsive scale calculations
            final double containerSize = (cardWidth * 0.35).clamp(40.0, 64.0);
            final double iconSize = containerSize * 0.8;
            final double selectIconSize = (cardWidth * 0.12).clamp(16.0, 22.0);
            final double spacingSize = (cardWidth * 0.08).clamp(8.0, 14.0);
            final double titleFontSize = (cardWidth * 0.1).clamp(11.0, 15.0);
            final double descFontSize = (cardWidth * 0.05).clamp(9.0, 11.5);
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
                              fontSize: descFontSize,
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Technician-profile card (exact visual match to TechnicianSkillSelectionScreen)
// ---------------------------------------------------------------------------

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({
    required this.skill,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
    required this.icon,
  });

  final Skill skill;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.lightPurple
                : (isDisabled ? const Color(0xFFF3F2F6) : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDisabled ? Colors.grey.shade400 : const Color(0xFFEEEAF9)),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A231447),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Opacity(
            opacity: isDisabled ? 0.55 : 1.0,
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.lightPurple,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        skill.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 21,
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