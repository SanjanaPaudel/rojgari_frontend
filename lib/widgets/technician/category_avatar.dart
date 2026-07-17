import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

/// Circular avatar for a service category icon.
///
/// The icon comes from `Skill.icon` on the backend, which is nullable and can
/// also fail to load (missing file, server unreachable). Both cases fall back
/// to a neutral tool glyph rather than showing a broken image.
///
/// [iconUrl] must already be absolute — resolve relative Django media paths
/// with `ApiUrls.resolveMediaUrl` before passing them here.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.iconUrl,
    this.size = 56,
    this.padding = 9,
  });

  final String? iconUrl;
  final double size;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: const BoxDecoration(
        color: Color(0xffF3EBFF),
        shape: BoxShape.circle,
      ),
      child: iconUrl == null
          ? _FallbackIcon(size: size)
          : Image.network(
              iconUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _FallbackIcon(size: size),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _FallbackIcon(size: size),
            ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.handyman_outlined,
      size: size * 0.43,
      color: AppColors.primary,
    );
  }
}
