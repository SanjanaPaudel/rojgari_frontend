class ServiceReviewPayload {
  const ServiceReviewPayload({
    required this.requestId,
    required this.workerId,
    required this.categoryId,
    required this.categorySlug,
    required this.rating,
    required this.submittedAt,
    this.reviewText,
  });

  final String requestId;
  final String workerId;
  final String categoryId;
  final String categorySlug;
  final int rating;
  final String? reviewText;
  final DateTime submittedAt;

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'workerId': workerId,
    'categoryId': categoryId,
    'categorySlug': categorySlug,
    'rating': rating,
    'reviewText': reviewText,
    'submittedAt': submittedAt.toIso8601String(),
  };
}
