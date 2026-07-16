import 'dart:typed_data';

import '../core/constants/api_urls.dart';

enum TechnicianVerificationStatus { verified, pending, rejected, incomplete }

class TechnicianModel {
  const TechnicianModel({
    this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.about,
    this.profileImageUrl,
    this.localProfileImagePath,
    this.localProfileImageBytes,
    this.selectedSkills = const [],
    this.verificationStatus = TechnicianVerificationStatus.incomplete,
    this.citizenshipFrontUrl,
    this.citizenshipBackUrl,
    this.experienceCertificateUrl,
    this.hasLocalCitizenshipFront = false,
    this.hasLocalCitizenshipBack = false,
    this.localCitizenshipFrontBytes,
    this.localCitizenshipFrontName,
    this.localCitizenshipBackBytes,
    this.localCitizenshipBackName,
    this.localExperienceCertificateBytes,
    this.localExperienceCertificateName,
    this.serviceAreas = const [],
  });

  final String? id;
  final String fullName;
  final String phone;
  final String email;
  final String about;
  final String? profileImageUrl;
  final String? localProfileImagePath;
  final Uint8List? localProfileImageBytes;
  final List<String> selectedSkills;
  final TechnicianVerificationStatus verificationStatus;
  final String? citizenshipFrontUrl;
  final String? citizenshipBackUrl;
  final String? experienceCertificateUrl;
  final bool hasLocalCitizenshipFront;
  final bool hasLocalCitizenshipBack;
  final Uint8List? localCitizenshipFrontBytes;
  final String? localCitizenshipFrontName;
  final Uint8List? localCitizenshipBackBytes;
  final String? localCitizenshipBackName;
  final Uint8List? localExperienceCertificateBytes;
  final String? localExperienceCertificateName;
  final List<String> serviceAreas;

  bool get hasProfileImage =>
      (profileImageUrl?.trim().isNotEmpty ?? false) ||
      (localProfileImagePath?.trim().isNotEmpty ?? false) ||
      (localProfileImageBytes?.isNotEmpty ?? false);

  bool get hasCitizenshipFront =>
      (citizenshipFrontUrl?.trim().isNotEmpty ?? false) ||
      hasLocalCitizenshipFront ||
      (localCitizenshipFrontBytes?.isNotEmpty ?? false);

  bool get hasCitizenshipBack =>
      (citizenshipBackUrl?.trim().isNotEmpty ?? false) ||
      hasLocalCitizenshipBack ||
      (localCitizenshipBackBytes?.isNotEmpty ?? false);

  bool get canAcceptJobs =>
      hasProfileImage && hasCitizenshipFront && hasCitizenshipBack;

  String get verificationLabel =>
      canAcceptJobs &&
          verificationStatus == TechnicianVerificationStatus.incomplete
      ? 'Verification Completed'
      : switch (verificationStatus) {
          TechnicianVerificationStatus.verified => 'Verified Worker',
          TechnicianVerificationStatus.pending => 'Verification Pending',
          TechnicianVerificationStatus.rejected => 'Verification Required',
          TechnicianVerificationStatus.incomplete => 'Complete Verification',
        };

  String get identityDocumentSubtitle => switch (verificationStatus) {
    TechnicianVerificationStatus.verified => 'Identity verified',
    TechnicianVerificationStatus.pending =>
      'Documents submitted for verification',
    TechnicianVerificationStatus.rejected ||
    TechnicianVerificationStatus.incomplete => 'Citizenship documents required',
  };

  TechnicianModel copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? about,
    String? profileImageUrl,
    String? localProfileImagePath,
    Uint8List? localProfileImageBytes,
    List<String>? selectedSkills,
    TechnicianVerificationStatus? verificationStatus,
    String? citizenshipFrontUrl,
    String? citizenshipBackUrl,
    String? experienceCertificateUrl,
    bool? hasLocalCitizenshipFront,
    bool? hasLocalCitizenshipBack,
    Uint8List? localCitizenshipFrontBytes,
    String? localCitizenshipFrontName,
    Uint8List? localCitizenshipBackBytes,
    String? localCitizenshipBackName,
    Uint8List? localExperienceCertificateBytes,
    String? localExperienceCertificateName,
    List<String>? serviceAreas,
  }) {
    return TechnicianModel(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      about: about ?? this.about,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      localProfileImagePath:
          localProfileImagePath ?? this.localProfileImagePath,
      localProfileImageBytes:
          localProfileImageBytes ?? this.localProfileImageBytes,
      selectedSkills: selectedSkills ?? this.selectedSkills,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      citizenshipFrontUrl: citizenshipFrontUrl ?? this.citizenshipFrontUrl,
      citizenshipBackUrl: citizenshipBackUrl ?? this.citizenshipBackUrl,
      experienceCertificateUrl:
          experienceCertificateUrl ?? this.experienceCertificateUrl,
      hasLocalCitizenshipFront:
          hasLocalCitizenshipFront ?? this.hasLocalCitizenshipFront,
      hasLocalCitizenshipBack:
          hasLocalCitizenshipBack ?? this.hasLocalCitizenshipBack,
      localCitizenshipFrontBytes:
          localCitizenshipFrontBytes ?? this.localCitizenshipFrontBytes,
      localCitizenshipFrontName:
          localCitizenshipFrontName ?? this.localCitizenshipFrontName,
      localCitizenshipBackBytes:
          localCitizenshipBackBytes ?? this.localCitizenshipBackBytes,
      localCitizenshipBackName:
          localCitizenshipBackName ?? this.localCitizenshipBackName,
      localExperienceCertificateBytes:
          localExperienceCertificateBytes ??
          this.localExperienceCertificateBytes,
      localExperienceCertificateName:
          localExperienceCertificateName ?? this.localExperienceCertificateName,
      serviceAreas: serviceAreas ?? this.serviceAreas,
    );
  }

  // ---------------------------------------------------------------------------
  // fromJson — parses a flat GET /api/auth/worker/profile/ response.
  //
  // Backend shape (flat object, NOT nested under "worker"):
  // {
  //   "full_name":    "Sanjana Paudel",
  //   "phone_number": "9807078737",
  //   "email":        "sanjana@gmail.com",
  //   "about_me":     "I am ready to serve you",
  //   "service_areas":"kathmandu",
  //   "profile_photo":"/media/profile_photos/..."   ← relative path or null
  // }
  //
  // ⚠ Skills and verification status are NOT included in this response.
  //   Callers must preserve them from the existing model via copyWith().
  // ---------------------------------------------------------------------------
  factory TechnicianModel.fromProfileJson(Map<String, dynamic> json) {
    final rawPhoto = json['profile_photo'] as String?;

    String? resolvedPhotoUrl;
    if (rawPhoto != null && rawPhoto.trim().isNotEmpty) {
      if (rawPhoto.startsWith('http')) {
        resolvedPhotoUrl = rawPhoto;
      } else {
        // Relative Django media path — prefix with server root (strip "/api").
        final serverRoot = ApiUrls.baseUrl.replaceFirst('/api', '');
        resolvedPhotoUrl = '$serverRoot$rawPhoto';
      }
    }

    final rawServiceAreas = json['service_areas'] as String? ?? '';
    final serviceAreaList = rawServiceAreas
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return TechnicianModel(
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone_number'] as String? ?? '',
      email: json['email'] as String? ?? '',
      about: json['about_me'] as String? ?? '',
      profileImageUrl: resolvedPhotoUrl,
      serviceAreas: serviceAreaList,
      // Skills and verification come from other sources — leave at defaults.
      // The caller (profile_screen._loadProfile) merges these via copyWith.
    );
  }
}

// BACKEND TODO: Fetch/update the technician profile and selected skills, upload
// the required profile photo and citizenship images plus optional experience
// certificate, and fetch document verification status using confirmed API
// endpoints. Frontend canAcceptJobs checks improve UX only; backend enforcement
// is the security boundary.
