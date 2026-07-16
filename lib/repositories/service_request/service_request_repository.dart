import '../../models/service_request/service_request_payload.dart';

class ServiceRequestException implements Exception {
  const ServiceRequestException({
    required this.message,
    this.statusCode,
    this.responseBody,
  });

  final String message;
  final int? statusCode;
  final String? responseBody;

  @override
  String toString() => 'ServiceRequestException: $message';
}

abstract class ServiceRequestRepository {
  Future<ServiceRequestResult> createServiceRequest(
    ServiceRequestPayload payload,
  );
}
