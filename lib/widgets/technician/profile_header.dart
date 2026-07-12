import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final double rating;
  final String profession;
  final String experienceText;
  final bool isVerified;
  final String avatarImage;
  final Uint8List? avatarBytes;
  final bool isOnline;
  final ValueChanged<bool>? onStatusChanged;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.rating,
    required this.profession,
    required this.experienceText,
    required this.isVerified,
    required this.avatarImage,
    this.avatarBytes,
    required this.isOnline,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 145,

      child: Stack(
        children: [
          Positioned(
            right: -65,
            top: -10,

            child: Opacity(
              opacity: 0.40,

              child: Image.asset(
                "assets/images/background_temple.png",

                width: 290,
                height: 165,

                fit: BoxFit.cover,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 28),

                  child: Container(
                    width: 104,
                    height: 104,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF0EFF4),
                      border: Border.all(
                        color: const Color(0xFFE8E3F3),
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _ProfileImage(
                      imagePath: avatarImage,
                      imageBytes: avatarBytes,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 28),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          "Hello, $name 👋",

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),

                              decoration: BoxDecoration(
                                color: AppColors.primary,

                                borderRadius: BorderRadius.circular(8),
                              ),

                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.yellow,
                                  ),

                                  const SizedBox(width: 3),

                                  Text(
                                    rating.toStringAsFixed(1),

                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,

                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 7),

                            const Flexible(
                              child: Text(
                                "Top Rated Worker",

                                overflow: TextOverflow.ellipsis,

                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,

                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "$profession • $experienceText",

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 12,

                            color: Color(0xff555555),

                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Row(
                          children: [
                            Icon(
                              isVerified
                                  ? Icons.verified_user
                                  : Icons.info_outline,

                              size: 16,

                              color: isVerified
                                  ? AppColors.primary
                                  : Colors.grey,
                            ),

                            const SizedBox(width: 4),

                            Text(
                              isVerified ? "Verified" : "Verify Now",

                              style: TextStyle(
                                fontSize: 12,

                                color: isVerified
                                    ? AppColors.primary
                                    : Colors.grey,

                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const Spacer(),

                            PopupMenuButton<bool>(
                              tooltip: "Change availability",
                              onSelected: onStatusChanged,
                              position: PopupMenuPosition.under,
                              color: Colors.white,
                              surfaceTintColor: Colors.white,
                              elevation: 6,
                              constraints: const BoxConstraints(
                                minWidth: 116,
                                maxWidth: 116,
                              ),
                              menuPadding: const EdgeInsets.symmetric(
                                vertical: 5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(
                                  color: Color(0xffE9E5EF),
                                ),
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem<bool>(
                                  value: true,
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: _StatusOption(
                                    label: "Online",
                                    color: const Color(0xff22A447),
                                    isSelected: isOnline,
                                  ),
                                ),
                                PopupMenuItem<bool>(
                                  value: false,
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: _StatusOption(
                                    label: "Offline",
                                    color: const Color(0xff8A8F98),
                                    isSelected: !isOnline,
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isOnline
                                      ? const Color(0xffEAF8EF)
                                      : const Color(0xffF1F2F4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isOnline
                                        ? const Color(0xffBDE8CA)
                                        : const Color(0xffD8DADE),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isOnline
                                            ? const Color(0xff22A447)
                                            : const Color(0xff8A8F98),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isOnline ? "Online" : "Offline",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isOnline
                                            ? const Color(0xff18833A)
                                            : const Color(0xff6F747C),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 15,
                                      color: isOnline
                                          ? const Color(0xff18833A)
                                          : const Color(0xff6F747C),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;

  const _StatusOption({
    required this.label,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        if (isSelected) Icon(Icons.check_rounded, size: 15, color: color),
      ],
    );
  }
}

class _ProfileImage extends StatelessWidget {
  final String imagePath;
  final Uint8List? imageBytes;

  const _ProfileImage({required this.imagePath, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    if (imageBytes?.isNotEmpty ?? false) {
      return Image.memory(
        imageBytes!,
        fit: BoxFit.contain,
        alignment: Alignment.topCenter,
      );
    }
    if (imagePath.startsWith("http")) {
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        alignment: Alignment.topCenter,

        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            "assets/images/technician_avatar.png",

            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
          );
        },
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.contain,
      alignment: Alignment.topCenter,
    );
  }
}
