class Evolution {
  final int id;
  final int pokemonId;
  final int stage;
  final String speciesName;
  final String evolutionDetails; // May contain JSON details or plain text

  Evolution({
    required this.id,
    required this.pokemonId,
    required this.stage,
    required this.speciesName,
    required this.evolutionDetails,
  });

  factory Evolution.fromMap(Map<String, dynamic> map) {
    return Evolution(
      id: map['id'] as int,
      pokemonId: map['pokemon_id'] as int,
      stage: map['stage'] as int,
      speciesName: map['species_name'] as String,
      evolutionDetails: map['evolution_details'] as String,
    );
  }
}
