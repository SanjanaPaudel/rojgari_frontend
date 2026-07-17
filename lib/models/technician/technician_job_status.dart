enum TechnicianJobStatus {
  accepted,
  enRoute,
  arrived,
  working,
  completed;

  String get displayLabel => switch (this) {
    TechnicianJobStatus.accepted => 'Accepted',
    TechnicianJobStatus.enRoute => 'In Progress',
    TechnicianJobStatus.arrived => 'Arrived',
    TechnicianJobStatus.working => 'Working',
    TechnicianJobStatus.completed => 'Completed',
  };

  String get backendValue => switch (this) {
    TechnicianJobStatus.accepted => 'accepted',
    TechnicianJobStatus.enRoute => 'en_route',
    TechnicianJobStatus.arrived => 'arrived',
    TechnicianJobStatus.working => 'working',
    TechnicianJobStatus.completed => 'completed',
  };

  static TechnicianJobStatus fromBackendValue(String? value) {
    switch (value?.trim().toLowerCase().replaceAll('-', '_')) {
      case 'on_the_way':
      case 'en_route':
      case 'in_progress':
        return TechnicianJobStatus.enRoute;
      case 'arrived':
        return TechnicianJobStatus.arrived;
      case 'working':
      case 'in_service':
        return TechnicianJobStatus.working;
      case 'completed':
      case 'complete':
        return TechnicianJobStatus.completed;
      case 'accepted':
      default:
        return TechnicianJobStatus.accepted;
    }
  }
}
