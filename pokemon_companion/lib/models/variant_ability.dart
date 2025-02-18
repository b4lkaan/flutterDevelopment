class VariantAbility {
  final int id;
  final int variantId;
  final String abilityName;
  final String abilityDescription;

  VariantAbility({
    required this.id,
    required this.variantId,
    required this.abilityName,
    required this.abilityDescription,
  });

  factory VariantAbility.fromMap(Map<String, dynamic> map) {
    return VariantAbility(
      id: map['id'] as int,
      variantId: map['variant_id'] as int,
      abilityName: map['ability_name'] as String,
      abilityDescription: map['ability_description'] as String,
    );
  }
}
