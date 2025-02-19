class GlobalItem {
  final String name;
  final String description;

  GlobalItem({
    required this.name,
    required this.description,
  });

  factory GlobalItem.fromMap(Map<String, dynamic> map) {
    return GlobalItem(
      name: (map['name'] ?? '') as String,
      description: (map['description'] ?? '') as String,
    );
  }
}
