class ServiceBookingDemoConfig {
  const ServiceBookingDemoConfig._();

  // FRONTEND DEMO ONLY:
  // These delays simulate backend request-status updates so the complete UI
  // can be reviewed without a connected backend. Remove/disable these timers
  // after the real request-status API, polling, WebSocket or server event
  // integration is connected.
  //
  // DISABLED (2026-07-17): backend status integration is being wired up step
  // by step, starting from FindingServicePersonScreen staying on "searching".
  // Flip back to true only for a one-off visual preview of the full flow.
  static const bool enableDemoBookingFlow = false;

  // TEMP TEST-ONLY: single switch for both fake-walk stubs (customer-side
  // FakeWorkerTrackingController in finding_service_person_screen.dart, and
  // worker-side FakeWorkerLocationService in
  // incoming_request_details_loader.dart) — see dev_testing/fake_worker_movement.dart.
  //
  // true  -> both sides simulate the worker walking to the customer, so a
  //          full test run doesn't require physically moving a device.
  // false -> both sides use real device GPS instead: the worker's screen
  //          reads its own live location and PATCHes it to the backend, the
  //          customer's screen connects its socket for real and receives
  //          genuine location/status pushes. Physically walking the worker's
  //          device toward the customer's location will then move things
  //          for real, on both screens.
  static const bool useFakeWorkerMovement = true;
  static const Duration searchingDuration = Duration(seconds: 20);
  static const Duration acceptedDisplayDuration = Duration(seconds: 2);
  static const Duration workerArrivalDuration = Duration(seconds: 15);
  static const Duration trackingUpdateInterval = Duration(milliseconds: 50);
  static const Duration trackingSnapshotInterpolationDuration = Duration(
    seconds: 5,
  );
  static const Duration arrivedAcknowledgementDuration = Duration(
    milliseconds: 1200,
  );
  static const Duration workingPreviewDuration = Duration(seconds: 15);
  static const Duration completedDisplayDuration = Duration(milliseconds: 1500);
}
