class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug};
}
