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
  static const Duration searchingDuration = Duration(seconds: 20);
  static const Duration acceptedDisplayDuration = Duration(milliseconds: 1500);
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
