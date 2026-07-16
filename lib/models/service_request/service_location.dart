class ServiceLocation {
  const ServiceLocation({
    required this.addressLine1,
    this.addressLine2,
    this.latitude,
    this.longitude,
  });

  final String addressLine1;
  final String? addressLine2;
  final double? latitude;
  final double? longitude;

  ServiceLocation copyWith({
    String? addressLine1,
    String? addressLine2,
    double? latitude,
    double? longitude,
  }) {
    return ServiceLocation(
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() => {
    'address_line_1': addressLine1,
    'address_line_2': addressLine2,
    'latitude': latitude,
    'longitude': longitude,
  };
}
