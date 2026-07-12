import 'dart:io';

import 'package:flutter/material.dart';

class ProfilePhotoViewer extends StatelessWidget {
  const ProfilePhotoViewer({
    super.key,
    required this.heroTag,
    required this.assetPath,
    this.networkUrl,
    this.localImagePath,
  });

  final String heroTag;
  final String assetPath;
  final String? networkUrl;
  final String? localImagePath;

  static Future<void> show(
    BuildContext context, {
    required String heroTag,
    required String assetPath,
    String? networkUrl,
    String? localImagePath,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, animation, secondaryAnimation) => ProfilePhotoViewer(
        heroTag: heroTag,
        assetPath: assetPath,
        networkUrl: networkUrl,
        localImagePath: localImagePath,
      ),
      transitionBuilder: (_, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  Widget _image() {
    final localPath = localImagePath?.trim();
    if (localPath != null && localPath.isNotEmpty) {
      return Image.file(
        File(localPath),
        fit: BoxFit.contain,
        errorBuilder: (_, error, stackTrace) =>
            Image.asset(assetPath, fit: BoxFit.contain),
      );
    }
    final url = networkUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stackTrace) =>
            Image.asset(assetPath, fit: BoxFit.contain),
      );
    }
    return Image.asset(assetPath, fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Hero(
                  tag: heroTag,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 620,
                      maxHeight: size.height * .82,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 28),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: _image(),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 16,
              child: IconButton.filled(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(backgroundColor: Colors.white24),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
