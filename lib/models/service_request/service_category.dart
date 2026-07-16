class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.iconUrl,
    this.displayOrder = 0,
  });

  final int id;
  final String name;
  final String slug;
  final String description;
  final String? iconUrl;
  final int displayOrder;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '');
    if (parsedId == null || parsedId <= 0) {
      throw const FormatException('Service category has an invalid id.');
    }
    final name = json['name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      throw const FormatException('Service category has no name.');
    }
    final backendSlug = json['slug']?.toString().trim();
    return ServiceCategory(
      id: parsedId,
      name: name,
      slug: backendSlug == null || backendSlug.isEmpty
          ? slugFromName(name)
          : backendSlug,
      description: json['description']?.toString() ?? '',
      iconUrl: _nullableString(json['icon']),
      displayOrder: _parseDisplayOrder(json['display_order']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'description': description,
    'icon': iconUrl,
    'display_order': displayOrder,
  };

  ServiceCategory copyWith({String? name, String? slug}) => ServiceCategory(
    id: id,
    name: name ?? this.name,
    slug: slug ?? this.slug,
    description: description,
    iconUrl: iconUrl,
    displayOrder: displayOrder,
  );

  static String slugFromName(String name) => name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _parseDisplayOrder(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
