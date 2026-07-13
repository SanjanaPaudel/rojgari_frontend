import 'dart:typed_data';

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
}

// BACKEND TODO: Fetch/update the technician profile and selected skills, upload
// the required profile photo and citizenship images plus optional experience
// certificate, and fetch document verification status using confirmed API
// endpoints. Frontend canAcceptJobs checks improve UX only; backend enforcement
// is the security boundary.
