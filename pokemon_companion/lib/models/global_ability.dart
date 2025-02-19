class GlobalAbility {
  final String name;
  final String description;

  GlobalAbility({
    required this.name,
    required this.description,
  });

  factory GlobalAbility.fromMap(Map<String, dynamic> map) {
    return GlobalAbility(
      name: (map['name'] ?? '') as String,
      description: (map['description'] ?? '') as String,
    );
  }
}
