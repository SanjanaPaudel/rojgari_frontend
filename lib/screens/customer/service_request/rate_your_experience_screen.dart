import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/service_request/accepted_worker_ui_model.dart';
import '../../../models/service_request/service_category.dart';
import '../../../models/service_request/service_review_payload.dart';
import 'review_thank_you_screen.dart';

typedef SubmitServiceReviewCallback =
    Future<bool> Function(ServiceReviewPayload payload);

class RateYourExperienceScreen extends StatefulWidget {
  const RateYourExperienceScreen({
    required this.requestId,
    required this.category,
    required this.worker,
    this.onSubmitReview,
    this.onBackToHome,
    this.enableDemoSubmission = true,
    this.demoSubmissionDuration = const Duration(milliseconds: 450),
    super.key,
  });

  final String requestId;
  final ServiceCategory category;
  final AcceptedWorkerUiModel worker;
  final SubmitServiceReviewCallback? onSubmitReview;
  final VoidCallback? onBackToHome;
  final bool enableDemoSubmission;
  final Duration demoSubmissionDuration;

  @override
  State<RateYourExperienceScreen> createState() =>
      _RateYourExperienceScreenState();
}

class _RateYourExperienceScreenState extends State<RateYourExperienceScreen> {
  static const _ratingDescriptions = <int, String>{
    1: 'Poor',
    2: 'Fair',
    3: 'Good',
    4: 'Great!',
    5: 'Excellent!',
  };

  final TextEditingController _reviewController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating < 1 || _rating > 5 || _submitting) return;
    setState(() => _submitting = true);

    final trimmedReview = _reviewController.text.trim();
    final payload = ServiceReviewPayload(
      requestId: widget.requestId,
      workerId: widget.worker.id,
      categoryId: widget.category.id,
      categorySlug: widget.category.slug,
      rating: _rating,
      reviewText: trimmedReview.isEmpty ? null : trimmedReview,
      submittedAt: DateTime.now(),
    );

    try {
      // BACKEND INTEGRATION:
      // Submit this review using the completed request ID and accepted worker
      // ID. Required values are request ID, worker ID, integer rating from 1
      // to 5, and optional review text. The backend must verify that this
      // completed request belongs to the customer before saving the review.
      // Navigate only after success; on failure stay here and show an error.
      final handler = widget.onSubmitReview;
      final submitted = handler != null
          ? await handler(payload)
          : await _simulateReviewSubmission();
      if (!mounted) return;
      if (!submitted) {
        setState(() => _submitting = false);
        _showError('Could not submit your review. Please try again.');
        return;
      }

      await Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ReviewThankYouScreen(onBackToHome: widget.onBackToHome),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError('Could not submit your review. Please try again.');
    }
  }

  Future<bool> _simulateReviewSubmission() async {
    if (!widget.enableDemoSubmission) return false;
    // FRONTEND DEMO ONLY:
    // This simulated success allows the rating flow to be reviewed without
    // the review API. Replace it with the real review repository callback.
    await Future<void>.delayed(widget.demoSubmissionDuration);
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFFBF9FF),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              20,
              18,
              20,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              children: [
                _RatingHeader(onBack: () => Navigator.pop(context)),
                const SizedBox(height: 18),
                _ReviewCard(
                  worker: widget.worker,
                  category: widget.category,
                  rating: _rating,
                  ratingDescription: _ratingDescriptions[_rating],
                  reviewController: _reviewController,
                  onRatingChanged: (value) => setState(() => _rating = value),
                ),
                const SizedBox(height: 18),
                const _WhyReviewsMatterCard(),
                const SizedBox(height: 22),
                _SubmitReviewButton(
                  enabled: _rating > 0 && !_submitting,
                  loading: _submitting,
                  onPressed: _submitReview,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingHeader extends StatelessWidget {
  const _RatingHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.black),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate Your Experience',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Help us serve you better',
                style: TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.worker,
    required this.category,
    required this.rating,
    required this.ratingDescription,
    required this.reviewController,
    required this.onRatingChanged,
  });

  final AcceptedWorkerUiModel worker;
  final ServiceCategory category;
  final int rating;
  final String? ratingDescription;
  final TextEditingController reviewController;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E3F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C1A1233),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _ReviewWorkerAvatar(worker: worker),
          const SizedBox(height: 10),
          Text(
            worker.name.trim().isEmpty ? 'Assigned professional' : worker.name,
            key: const ValueKey('review-worker-name'),
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            category.name.trim().isEmpty
                ? 'Service Professional'
                : category.name,
            key: const ValueKey('review-category-name'),
            style: const TextStyle(color: AppColors.grey, fontSize: 12),
          ),
          const SizedBox(height: 32),
          const Text(
            'How was your service experience?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var value = 1; value <= 5; value++)
                Semantics(
                  button: true,
                  label: 'Rate $value out of 5 stars',
                  selected: value <= rating,
                  child: IconButton(
                    key: ValueKey('rating-star-$value'),
                    tooltip: '$value star rating',
                    onPressed: () => onRatingChanged(value),
                    iconSize: 42,
                    padding: const EdgeInsets.all(4),
                    icon: TweenAnimationBuilder<double>(
                      key: ValueKey('rating-star-animation-$value-$rating'),
                      tween: Tween(begin: .82, end: 1),
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Icon(
                        value <= rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: value <= rating
                            ? const Color(0xFFFFB817)
                            : const Color(0xFFC9C5D8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(
            height: 26,
            child: Center(
              child: Text(
                ratingDescription ?? '',
                key: const ValueKey('rating-description'),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Share your experience (Optional)',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 9),
          TextField(
            key: const ValueKey('review-text-field'),
            controller: reviewController,
            maxLength: 500,
            maxLines: 5,
            minLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText:
                  'Tell us about the service quality, professionalism, and overall experience...',
              hintStyle: const TextStyle(
                color: Color(0xFF9692AA),
                fontSize: 12,
                height: 1.45,
              ),
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFFE2DEEB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewWorkerAvatar extends StatelessWidget {
  const _ReviewWorkerAvatar({required this.worker});

  final AcceptedWorkerUiModel worker;

  @override
  Widget build(BuildContext context) {
    final network = worker.profileImageUrl?.trim();
    final asset = worker.profileImageAsset?.trim();
    Widget fallback() => const Icon(
      Icons.engineering_rounded,
      color: AppColors.primary,
      size: 40,
    );
    Widget image = fallback();
    if (network != null && network.isNotEmpty) {
      image = Image.network(
        network,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    } else if (asset != null && asset.isNotEmpty) {
      image = Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: const ValueKey('review-worker-avatar'),
          width: 88,
          height: 88,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.lightPurple,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.lightPurple, width: 5),
          ),
          child: image,
        ),
        Positioned(
          right: -1,
          bottom: 1,
          child: Container(
            width: 25,
            height: 25,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ),
      ],
    );
  }
}

class _WhyReviewsMatterCard extends StatelessWidget {
  const _WhyReviewsMatterCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightPurple.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.star_outline_rounded, color: Colors.white),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why reviews matter',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your feedback helps professionals improve and helps other customers make better choices.',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitReviewButton extends StatelessWidget {
  const _SubmitReviewButton({
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [AppColors.primary, Color(0xFF9618F5)],
              )
            : const LinearGradient(
                colors: [Color(0xFFD5D1DE), Color(0xFFC9C5D2)],
              ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          key: const ValueKey('submit-review-button'),
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Submit Review',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}
