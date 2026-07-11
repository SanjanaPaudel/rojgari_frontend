import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

class CustomerProfileHeader extends StatelessWidget {
  const CustomerProfileHeader({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    required this.isVerified,
    required this.assetImagePath,
    required this.onPhotoTap,
    required this.onEdit,
    this.networkImageUrl,
    this.localImagePath,
    this.heroTag = 'customer-profile-photo',
  });

  final String name;
  final String phone;
  final String email;
  final bool isVerified;
  final String assetImagePath;
  final String? networkImageUrl;
  final String? localImagePath;
  final String heroTag;
  final VoidCallback onPhotoTap;
  final VoidCallback onEdit;

  Widget _profileImage() {
    final localPath = localImagePath?.trim();
    if (localPath != null && localPath.isNotEmpty) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, error, stackTrace) => Image.asset(
          assetImagePath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      );
    }
    final url = networkImageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, error, stackTrace) => Image.asset(
          assetImagePath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      );
    }
    return Image.asset(
      assetImagePath,
      fit: BoxFit.cover,
      alignment: Alignment.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 520;
        return Container(
          width: double.infinity,
          height: narrow ? 205 : 195,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF0ECF8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x162B1B54),
                blurRadius: 24,
                offset: Offset(0, 9),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: .38,
                    child: Image.asset(
                      'assets/images/profile_nepal_bg.png',
                      fit: BoxFit.fill,
                      alignment: Alignment.center,
                      color: Colors.white.withValues(alpha: .22),
                      colorBlendMode: BlendMode.screen,
                    ),
                  ),
                ),
              ),
              narrow ? _narrowContent() : _wideContent(),
            ],
          ),
        );
      },
    );
  }

  Widget _photo(double size) {
    return Semantics(
      button: true,
      label: 'View profile photo',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPhotoTap,
        child: Hero(
          tag: heroTag,
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE7E0F7)),
              boxShadow: const [
                BoxShadow(color: Color(0x1F241A44), blurRadius: 12),
              ],
            ),
            child: ClipOval(child: _profileImage()),
          ),
        ),
      ),
    );
  }

  Widget _details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (isVerified) ...[
          const SizedBox(height: 5),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Verified Customer',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 11),
        _ContactLine(icon: Icons.phone_outlined, value: phone),
        const SizedBox(height: 7),
        _ContactLine(icon: Icons.email_outlined, value: email),
      ],
    );
  }

  Widget _editButton() {
    return OutlinedButton.icon(
      onPressed: onEdit,
      icon: const Icon(Icons.edit_outlined, size: 17),
      label: const Text('Edit Profile'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: Colors.white.withValues(alpha: .92),
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _wideContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _photo(140),
          const SizedBox(width: 25),
          Expanded(child: _details()),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(top: 102),
            child: _editButton(),
          ),
        ],
      ),
    );
  }

  Widget _narrowContent() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(top: 10, left: 14, child: _photo(104)),
        Positioned(top: 12, left: 128, right: 12, child: _details()),
        Positioned(right: 12, bottom: 11, child: _editButton()),
      ],
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.grey, size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
