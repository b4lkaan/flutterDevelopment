class GlobalNature {
  final String name;
  final String increasedStat;
  final String decreasedStat;

  GlobalNature({
    required this.name,
    required this.increasedStat,
    required this.decreasedStat,
  });

  factory GlobalNature.fromMap(Map<String, dynamic> map) {
    return GlobalNature(
      name: (map['name'] ?? '') as String,
      increasedStat: (map['increased_stat'] ?? '') as String,
      decreasedStat: (map['decreased_stat'] ?? '') as String,
    );
  }

  /// Build a simple description from the increased/decreased stats.
  String get description {
    // e.g. "Increases Attack, decreases Defense" or fallback if empty
    if (increasedStat.isEmpty && decreasedStat.isEmpty) {
      return "No nature description available.";
    }
    return "Increases $increasedStat, decreases $decreasedStat";
  }
}
