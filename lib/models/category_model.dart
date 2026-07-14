class Category {
  final int id;
  final String name;
  final String description;
  final String icon;
  final int displayOrder;

  const Category({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.displayOrder,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'display_order': displayOrder,
    };
  }
}
