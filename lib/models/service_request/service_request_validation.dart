import 'selected_service_location.dart';

class ServiceRequestValidation {
  const ServiceRequestValidation._();

  static String? description(String? value) {
    final description = value?.trim() ?? '';
    if (description.isEmpty) return 'Please describe the problem.';
    if (description.length > 300) {
      return 'Description cannot exceed 300 characters.';
    }
    return null;
  }

  static String? location(SelectedServiceLocation? value) {
    if (value == null || !value.hasValidCoordinates) {
      return 'Please select a service location.';
    }
    return null;
  }
}
