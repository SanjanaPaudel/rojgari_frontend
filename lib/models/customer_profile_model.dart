/// Maps `GET /api/auth/customer/profile/`'s response.
class CustomerProfileModel {
  const CustomerProfileModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.isVerified,
    this.profilePhoto,
  });

  final int id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final bool isVerified;
  final String? profilePhoto;

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    return CustomerProfileModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      fullName: json['full_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      isVerified: json['is_verified'] == true,
      profilePhoto: json['profile_photo']?.toString(),
    );
  }
}
