/// Response model for GET /api/auth/worker/dashboard/
///
/// Example response shape:
/// {
///   "worker": {
///     "full_name": "Test",
///     "phone_number": "9807078737",
///     "profile_photo": null,
///     "skills": ["Mechanic", "Carpainter", "Gardener"],
///     "years_of_experience": 0,
///     "verified": false,
///     "is_online": false,
///     "stats": { "jobs_done": 28, "skills": 3, "reviews": 12, "rating": 4.8 }
///   },
///   "notifications": 3,
///   "messages": 2,
///   "incoming_request_count": 0
/// }

class WorkerStats {
  const WorkerStats({
    required this.jobsDone,
    required this.skills,
    required this.reviews,
    required this.rating,
  });

  final int jobsDone;
  final int skills;
  final int reviews;
  final double rating;

  factory WorkerStats.fromJson(Map<String, dynamic> json) {
    return WorkerStats(
      jobsDone: (json['jobs_done'] as num?)?.toInt() ?? 0,
      skills: (json['skills'] as num?)?.toInt() ?? 0,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WorkerInfo {
  const WorkerInfo({
    required this.fullName,
    required this.phoneNumber,
    this.profilePhoto,
    required this.skills,
    required this.yearsOfExperience,
    required this.verified,
    required this.isOnline,
    required this.stats,
  });

  final String fullName;
  final String phoneNumber;

  /// Nullable — backend returns null when no photo has been uploaded.
  /// When non-null, this is a full media URL (e.g. http://127.0.0.1:8000/media/...).
  final String? profilePhoto;

  final List<String> skills;
  final int yearsOfExperience;
  final bool verified;
  final bool isOnline;
  final WorkerStats stats;

  factory WorkerInfo.fromJson(Map<String, dynamic> json) {
    return WorkerInfo(
      fullName: (json['full_name'] as String?) ?? '',
      phoneNumber: (json['phone_number'] as String?) ?? '',
      profilePhoto: json['profile_photo'] as String?,
      skills: List<String>.from((json['skills'] as List<dynamic>?) ?? []),
      yearsOfExperience: (json['years_of_experience'] as num?)?.toInt() ?? 0,
      verified: (json['verified'] as bool?) ?? false,
      isOnline: (json['is_online'] as bool?) ?? false,
      stats: WorkerStats.fromJson(
        (json['stats'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  WorkerInfo copyWith({String? fullName, String? profilePhoto}) {
    return WorkerInfo(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      skills: skills,
      yearsOfExperience: yearsOfExperience,
      verified: verified,
      isOnline: isOnline,
      stats: stats,
    );
  }
}

class WorkerDashboardResponse {
  const WorkerDashboardResponse({
    required this.worker,
    required this.notifications,
    required this.messages,
    required this.incomingRequestCount,
  });

  final WorkerInfo worker;
  final int notifications;
  final int messages;
  final int incomingRequestCount;

  factory WorkerDashboardResponse.fromJson(Map<String, dynamic> json) {
    return WorkerDashboardResponse(
      worker: WorkerInfo.fromJson(
        (json['worker'] as Map<String, dynamic>?) ?? {},
      ),
      notifications: (json['notifications'] as num?)?.toInt() ?? 0,
      messages: (json['messages'] as num?)?.toInt() ?? 0,
      incomingRequestCount:
          (json['incoming_request_count'] as num?)?.toInt() ?? 0,
    );
  }
}
