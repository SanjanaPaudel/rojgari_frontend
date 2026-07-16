class MapConfig {
  const MapConfig._();

  static const String openStreetMapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // This matches android/app/build.gradle.kts applicationId.
  static const String userAgentPackageName = 'com.example.rojgari_frontend_one';

  static const String photonBaseUrl = String.fromEnvironment(
    'PHOTON_BASE_URL',
    defaultValue: 'https://photon.komoot.io',
  );

  static const double nepalSearchLatitude = 28.3949;
  static const double nepalSearchLongitude = 84.1240;

  static const Map<String, String> photonHeaders = {
    'User-Agent': 'Rojgari/1.0 (com.example.rojgari_frontend_one)',
    'Accept': 'application/json',
  };
}
