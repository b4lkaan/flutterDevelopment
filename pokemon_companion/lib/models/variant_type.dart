class VariantType {
  final int id;
  final int variantId;
  final String typeName;

  VariantType({
    required this.id,
    required this.variantId,
    required this.typeName,
  });

  factory VariantType.fromMap(Map<String, dynamic> map) {
    return VariantType(
      id: map['id'] as int,
      variantId: map['variant_id'] as int,
      typeName: map['type_name'] as String,
    );
  }
}
