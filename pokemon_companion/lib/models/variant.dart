class Variant {
  final int id;
  final int pokemonId;
  final String name;
  final String? imageUrl;
  final int hp;
  final int attack;
  final int defense;
  final int specialAttack;
  final int specialDefense;
  final int speed;

  Variant({
    required this.id,
    required this.pokemonId,
    required this.name,
    this.imageUrl,
    required this.hp,
    required this.attack,
    required this.defense,
    required this.specialAttack,
    required this.specialDefense,
    required this.speed,
  });

  factory Variant.fromMap(Map<String, dynamic> map) {
    return Variant(
      id: map['id'] as int,
      pokemonId: map['pokemon_id'] as int,
      name: map['name'] as String,
      imageUrl: map['image_url'] as String?,
      hp: map['hp'] as int,
      attack: map['attack'] as int,
      defense: map['defense'] as int,
      specialAttack: map['special_attack'] as int,
      specialDefense: map['special_defense'] as int,
      speed: map['speed'] as int,
    );
  }
}
