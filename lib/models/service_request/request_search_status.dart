enum RequestSearchStatus {
  searching,
  accepted,
  workerOnTheWay,
  arrived,
  working,
  completed,
  cancelling,
  cancelled,
  error;

  bool get isSearching => this == RequestSearchStatus.searching;
  bool get isFound =>
      this == RequestSearchStatus.accepted ||
      this == RequestSearchStatus.workerOnTheWay ||
      hasReachedService;
  bool get isArrived => this == RequestSearchStatus.arrived;
  bool get hasReachedService =>
      this == RequestSearchStatus.arrived ||
      this == RequestSearchStatus.working ||
      this == RequestSearchStatus.completed;
  bool get isWorking => this == RequestSearchStatus.working;
  bool get isCompleted => this == RequestSearchStatus.completed;
  bool get canCancel => isSearching || this == RequestSearchStatus.error;

  static RequestSearchStatus fromBackendValue(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'found':
      case 'matched':
      case 'assigned':
      case 'accepted':
        return RequestSearchStatus.accepted;
      case 'worker_on_the_way':
      case 'on_the_way':
      case 'approaching':
        return RequestSearchStatus.workerOnTheWay;
      case 'arrived':
        return RequestSearchStatus.arrived;
      case 'working':
      case 'in_service':
      case 'service_started':
        return RequestSearchStatus.working;
      case 'completed':
      case 'complete':
      case 'finished':
        return RequestSearchStatus.completed;
      case 'cancelling':
        return RequestSearchStatus.cancelling;
      case 'cancelled':
      case 'canceled':
        return RequestSearchStatus.cancelled;
      case 'failed':
      case 'error':
        return RequestSearchStatus.error;
      case 'pending':
      case 'active':
      case 'searching':
      default:
        return RequestSearchStatus.searching;
    }
  }
}
