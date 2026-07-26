import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/utils/service_category_icon_resolver.dart';
import '../../models/technician/incoming_service_request_details.dart';
import '../../repositories/technician_job/technician_job_repository.dart';
import '../../repositories/technician_job/technician_job_repository_provider.dart';
import '../../widgets/media_gallery_viewer.dart';
import 'technician_active_job_screen.dart';

/// Builds the combined, swipeable media sequence for this request — every
/// photo first, then the video (if any) last — matching the order they're
/// already displayed in on screen.
List<GalleryMediaItem> _galleryItemsFor(IncomingServiceRequestDetails request) {
  return [
    for (final url in request.photoUrls) GalleryMediaItem.photo(url),
    if ((request.videoUrl ?? '').trim().isNotEmpty)
      GalleryMediaItem.video(request.videoUrl!),
  ];
}

typedef RequestActionCallback = Future<void> Function(String requestId);
typedef RequestNavigationCallback = Future<void> Function();
typedef VideoTapCallback = void Function(String videoUrl);

class IncomingRequestDetailsScreen extends StatefulWidget {
  const IncomingRequestDetailsScreen({
    super.key,
    required this.request,
    this.onAcceptRequest,
    this.onDeclineRequest,
    this.onAcceptedNavigation,
    this.onDeclinedNavigation,
    this.onVideoTap,
    this.jobRepository,
  });

  final IncomingServiceRequestDetails request;
  final RequestActionCallback? onAcceptRequest;
  final RequestActionCallback? onDeclineRequest;
  final RequestNavigationCallback? onAcceptedNavigation;
  final RequestNavigationCallback? onDeclinedNavigation;
  final VideoTapCallback? onVideoTap;
  final TechnicianJobRepository? jobRepository;

  @override
  State<IncomingRequestDetailsScreen> createState() =>
      _IncomingRequestDetailsScreenState();
}

enum _RequestAction { accept, decline }

class _IncomingRequestDetailsScreenState
    extends State<IncomingRequestDetailsScreen> {
  _RequestAction? _processingAction;

  bool get _isProcessing => _processingAction != null;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _accept() async {
    if (_isProcessing) return;
    final callback = widget.onAcceptRequest;
    if (callback != null) {
      await _runAction(
        action: _RequestAction.accept,
        callback: callback,
        navigation: widget.onAcceptedNavigation,
        successMessage: 'Request accepted.',
      );
      return;
    }

    // BACKEND INTEGRATION - ACCEPT:
    // Call the technician request-action API here through a repository/service.
    // Send the request ID and change the request status to "accepted".
    //
    // CUSTOMER-SIDE UPDATE:
    // The backend must persist the accepted status and expose it to the customer
    // through polling, request-status API, WebSocket, push notification, or the
    // project’s selected real-time mechanism. This technician UI cannot directly
    // update the customer’s phone.
    //
    // NAVIGATION INTEGRATION:
    // After successful acceptance, navigate to the actual accepted-job,
    // active-job, matching, or job-details screen.
    setState(() => _processingAction = _RequestAction.accept);
    try {
      // BACKEND INTEGRATION:
      // Replace the default mock repository with the real technician accept
      // operation (suggested, not confirmed: POST
      // /technician/requests/{requestId}/accept). Include the bearer token via
      // the existing ApiService, parse the returned active-job object, and
      // navigate only after a successful 2xx response. If another technician
      // already accepted it, keep this page open and show a friendly error.
      // Persist "accepted" and notify the customer through the final realtime
      // approach; this technician UI must not update the customer UI directly.
      final repository = widget.jobRepository ?? technicianJobRepository;
      final activeJob = await repository.acceptRequest(widget.request);
      if (!mounted) return;
      await Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TechnicianActiveJobScreen(job: activeJob, repository: repository),
        ),
      );
    } catch (_) {
      _showMessage('Unable to accept this request. Please try again.');
    } finally {
      if (mounted) setState(() => _processingAction = null);
    }
  }

  Future<void> _decline() async {
    if (_isProcessing) return;
    final callback = widget.onDeclineRequest;
    if (callback == null) {
      _showMessage('Decline API will be connected during backend integration.');
      return;
    }

    // The actual POST .../request/<offer_id>/reject/ call and post-decline
    // navigation are injected by the caller (IncomingRequestDetailsLoader),
    // keeping this screen presentational — see its class doc.
    await _runAction(
      action: _RequestAction.decline,
      callback: callback,
      navigation: widget.onDeclinedNavigation,
      successMessage: 'Request declined.',
    );
  }

  Future<void> _runAction({
    required _RequestAction action,
    required RequestActionCallback callback,
    required RequestNavigationCallback? navigation,
    required String successMessage,
  }) async {
    setState(() => _processingAction = action);
    try {
      await callback(widget.request.id);
      if (!mounted) return;
      _showMessage(successMessage);
      await navigation?.call();
    } catch (error) {
      _showMessage('Unable to update the request. Please try again.');
    } finally {
      if (mounted) setState(() => _processingAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () {
            // NAVIGATION INTEGRATION:
            // Replace Navigator.maybePop with navigation to the actual
            // technician dashboard when this page is connected to the final app flow.
            Navigator.maybePop(context);
          },
        ),
        title: const Text(
          'Request Details',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RequestSummaryCard(request: request),
              const SizedBox(height: 14),
              _DetailsCard(request: request, onVideoTap: widget.onVideoTap),
              const SizedBox(height: 18),
              _ActionButtons(
                processingAction: _processingAction,
                onAccept: _accept,
                onDecline: _decline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestSummaryCard extends StatelessWidget {
  const _RequestSummaryCard({required this.request});
  final IncomingServiceRequestDetails request;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: AppColors.lightPurple,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ServiceCategoryIconResolver.resolve(
                slug: request.categorySlug,
                name: request.categoryName,
              ),
              size: 34,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.customerName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  request.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff246BFD),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (request.shortDescription.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    request.shortDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 12.5,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _IconText(
                  icon: Icons.location_on_outlined,
                  text: request.locationText,
                ),
                if (request.distanceKm != null) ...[
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.only(left: 21),
                    child: Text(
                      '${request.distanceKm!.toStringAsFixed(1)} km away',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.request, required this.onVideoTap});
  final IncomingServiceRequestDetails request;
  final VideoTapCallback? onVideoTap;

  @override
  Widget build(BuildContext context) {
    final hasVideo = request.videoUrl?.trim().isNotEmpty ?? false;
    final galleryItems = _galleryItemsFor(request);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Problem Description'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xffF6F3FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              request.description.trim().isEmpty
                  ? 'No description provided.'
                  : request.description,
              style: const TextStyle(
                color: AppColors.grey,
                height: 1.55,
                fontSize: 13,
              ),
            ),
          ),
          if (request.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 22),
            _SectionTitle('Photos (${request.photoUrls.length})'),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 290 ? 2 : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: request.photoUrls.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.88,
                  ),
                  itemBuilder: (_, index) => InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => MediaGalleryViewer.show(
                      context,
                      items: galleryItems,
                      initialIndex: index,
                    ),
                    child: _MediaImage(
                      source: request.photoUrls[index],
                      semanticLabel: 'Customer photo ${index + 1}',
                    ),
                  ),
                );
              },
            ),
          ],
          if (hasVideo) ...[
            const SizedBox(height: 22),
            const _SectionTitle('Video (1)'),
            const SizedBox(height: 10),
            _VideoPreview(
              request: request,
              onVideoTap: onVideoTap,
              galleryItems: galleryItems,
              videoIndex: request.photoUrls.length,
            ),
          ],
        ],
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({
    required this.request,
    required this.onVideoTap,
    required this.galleryItems,
    required this.videoIndex,
  });
  final IncomingServiceRequestDetails request;
  final VideoTapCallback? onVideoTap;
  final List<GalleryMediaItem> galleryItems;
  final int videoIndex;

  @override
  Widget build(BuildContext context) {
    final videoUrl = request.videoUrl!;
    return Semantics(
      button: true,
      label: 'Play customer video',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // A caller can still inject its own handling via onVideoTap; the
          // default (nothing injected, which is every real caller today)
          // opens the same full-screen swipeable viewer the photos use.
          if (onVideoTap != null) {
            onVideoTap!(videoUrl);
            return;
          }
          MediaGalleryViewer.show(
            context,
            items: galleryItems,
            initialIndex: videoIndex,
          );
        },
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (request.videoThumbnailUrl?.trim().isNotEmpty ?? false)
                _MediaImage(
                  source: request.videoThumbnailUrl!,
                  semanticLabel: 'Customer video thumbnail',
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffE8E3F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.videocam_outlined,
                    size: 44,
                    color: AppColors.grey,
                  ),
                ),
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .94),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 34,
                    color: AppColors.black,
                  ),
                ),
              ),
              if (request.videoDurationSeconds != null)
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatDuration(request.videoDurationSeconds!),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;
    final minutes = safeSeconds ~/ 60;
    final remainder = safeSeconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }
}

class _MediaImage extends StatelessWidget {
  const _MediaImage({required this.source, required this.semanticLabel});
  final String source;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isNetwork =
        source.startsWith('http://') || source.startsWith('https://');
    final image = isNetwork
        ? Image.network(
            source,
            fit: BoxFit.cover,
            semanticLabel: semanticLabel,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
            errorBuilder: (context, error, stackTrace) => const _MediaError(),
          )
        : Image.asset(
            source,
            fit: BoxFit.cover,
            semanticLabel: semanticLabel,
            errorBuilder: (context, error, stackTrace) => const _MediaError(),
          );
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF0EDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError();
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xffF0EDF5),
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image_outlined, color: AppColors.grey),
  );
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.processingAction,
    required this.onAccept,
    required this.onDecline,
  });
  final _RequestAction? processingAction;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final disabled = processingAction != null;
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Accept',
            icon: Icons.check_rounded,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            loading: processingAction == _RequestAction.accept,
            onPressed: disabled ? null : onAccept,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Decline',
            icon: Icons.close_rounded,
            backgroundColor: AppColors.lightPurple,
            foregroundColor: AppColors.primary,
            borderColor: AppColors.primary,
            loading: processingAction == _RequestAction.decline,
            onPressed: disabled ? null : onDecline,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.loading,
    required this.onPressed,
    this.borderColor,
  });
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: loading
          ? const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: backgroundColor.withValues(alpha: .55),
        disabledForegroundColor: foregroundColor.withValues(alpha: .7),
        elevation: 0,
        side: borderColor == null ? null : BorderSide(color: borderColor!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .025),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.black,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: AppColors.grey),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.grey, fontSize: 12),
        ),
      ),
    ],
  );
}

// DASHBOARD NAVIGATION EXAMPLE:
//
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (_) => IncomingRequestDetailsScreen(
//       request: requestDetails,
//     ),
//   ),
// );
//
// The dashboard/backend integrator should replace requestDetails
// with data returned for the selected incoming request.
