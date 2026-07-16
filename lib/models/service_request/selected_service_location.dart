class SelectedServiceLocation {
  const SelectedServiceLocation({
    required this.latitude,
    required this.longitude,
    this.landmark,
    this.accuracyMeters,
    this.source = 'map',
  });

  final double latitude;
  final double longitude;
  final String? landmark;
  final double? accuracyMeters;
  final String source;

  bool get hasValidCoordinates =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'landmark': landmark,
    'accuracyMeters': accuracyMeters,
    'source': source,
  };

  SelectedServiceLocation copyWith({
    double? latitude,
    double? longitude,
    String? landmark,
    double? accuracyMeters,
    String? source,
  }) => SelectedServiceLocation(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    landmark: landmark ?? this.landmark,
    accuracyMeters: accuracyMeters ?? this.accuracyMeters,
    source: source ?? this.source,
  );
}
