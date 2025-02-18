class Pokemon {
  final int id;
  final int dexNumber;
  final String name;
  
  Pokemon({
    required this.id,
    required this.dexNumber,
    required this.name,
  });
  
  // Converts a SQLite row into a Pokemon object
  factory Pokemon.fromMap(Map<String, dynamic> map) {
    return Pokemon(
      id: map['id'] as int,
      dexNumber: map['dex_number'] as int,
      name: map['name'] as String,
    );
  }
}
