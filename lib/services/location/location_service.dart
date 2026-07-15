import 'package:geolocator/geolocator.dart';

enum AppLocationPermission { notRequested, denied, blocked, granted }

class CurrentDeviceLocation {
  const CurrentDeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LocationService {
  const LocationService();

  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  Future<AppLocationPermission> checkPermission() async =>
      _mapPermission(await Geolocator.checkPermission());

  Future<AppLocationPermission> requestPermission() async =>
      _mapPermission(await Geolocator.requestPermission(), requested: true);

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<CurrentDeviceLocation> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return CurrentDeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
    } catch (_) {
      throw const LocationServiceException(
        'Current location is unavailable. Check your connection and try again.',
      );
    }
  }

  AppLocationPermission _mapPermission(
    LocationPermission permission, {
    bool requested = false,
  }) {
    switch (permission) {
      case LocationPermission.deniedForever:
        return AppLocationPermission.blocked;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return AppLocationPermission.granted;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return requested
            ? AppLocationPermission.denied
            : AppLocationPermission.notRequested;
    }
  }
}
