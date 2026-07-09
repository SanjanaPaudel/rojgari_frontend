


class Skill {
  final int id;
  final String name;
  final String description;
  final String icon;

  const Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
    };
  }
}