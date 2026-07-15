
// Each Skill object created from
// this class holds one skill's id, name, description, and icon —
// once backend JSON has been converted into it.

class Skill {
  final int id;
  final String name;
  final String? description; // nullable — backend may return null
  final String? icon;        // nullable — backend returns null for most skills

  const Skill({
    required this.id,
    required this.name,
    this.description,
    this.icon,
  });

  factory Skill.fromJson(Map<String, dynamic> json) { //It is a translation step in which the formJson() from factory assigns tha value of the map in json body into respective skill's variable. converts the map into skill obj
    return Skill(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,  // null-safe cast
      icon: json['icon'] as String?,                 // null-safe cast
    );
  }

  Map<String, dynamic> toJson() { // Turns the skill obj into json map .  in case you ever need to send it back to the server as JSON
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
    };
  }
}