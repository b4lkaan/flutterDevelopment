class GlobalMove {
  final String name;
  final String description;
  final String? method; // method can be null if you want

  GlobalMove({
    required this.name,
    required this.description,
    this.method,
  });

  factory GlobalMove.fromMap(Map<String, dynamic> map) {
    return GlobalMove(
      // If 'name' or 'description' might be null, use ?? '' or some fallback.
      name: (map['name'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      method: map['method'] as String?, 
    );
  }
}
