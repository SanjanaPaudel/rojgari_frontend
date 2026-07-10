
// Each Skill object created from
// this class holds one skill's id, name, description, and icon —
// once backend JSON has been converted into it.

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

  factory Skill.fromJson(Map<String, dynamic> json) { //It is a translation step in which the formJson() from factory assigns tha value of the map in json body into respective skill's variable. converts the map into skill obj
    return Skill(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
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