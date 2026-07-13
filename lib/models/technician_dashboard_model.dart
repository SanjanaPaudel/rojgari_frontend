class TechnicianDashboard {
  final String name;
  final double rating;
  final int completedJobs;
  final int reviews;
  final bool online;

  final String profession;
  final String experienceText;
  final bool isVerified;
  final String avatarImage;

  TechnicianDashboard({
    required this.name,
    required this.rating,
    required this.completedJobs,
    required this.reviews,
    required this.online,

    required this.profession,
    required this.experienceText,
    required this.isVerified,
    required this.avatarImage,
  });
}
