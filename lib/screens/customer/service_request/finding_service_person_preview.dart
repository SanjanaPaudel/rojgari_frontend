import 'package:flutter/material.dart';

import '../../../models/service_request/request_search_status.dart';
import '../../../models/service_request/selected_service_location.dart';
import '../../../models/service_request/service_category.dart';
import '../customer_home_screen.dart';
import 'finding_service_person_screen.dart';

/// Debug-only direct preview of the real searching screen.
///
/// These values exist only so the UI can be reviewed without authentication,
/// a submitted backend request, or worker-side acceptance. The feature's
/// clearly marked demo timers advance this preview through the visual flow.
class FindingServicePersonPreview extends StatelessWidget {
  const FindingServicePersonPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return FindingServicePersonScreen(
      requestId: 'PREVIEW-001',
      category: const ServiceCategory(
        id: 'preview-1',
        name: 'Plumber',
        slug: 'plumber',
      ),
      serviceLocation: const SelectedServiceLocation(
        latitude: 27.671234,
        longitude: 85.339876,
        landmark: 'Balkumari Road, Lalitpur, Nepal',
        source: 'preview',
      ),
      requestDescription: 'Kitchen sink is leaking and needs urgent repair.',
      requestedAt: DateTime.now(),
      initialStatus: RequestSearchStatus.searching,
      // FRONTEND PREVIEW ONLY:
      // The normal app already has CustomerHomeScreen underneath this flow.
      // The direct preview does not, so provide the same dashboard destination
      // explicitly for the Thank You page's Back to Home action.
      onBackToHome: () => Navigator.pushAndRemoveUntil<void>(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        (_) => false,
      ),
    );
  }
}
