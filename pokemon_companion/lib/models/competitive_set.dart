import 'dart:convert';

class CompetitiveSet {
  final int id;
  final int variantId;
  final String tier;
  final String setName;
  final List<String> moves;
  final String ability;
  final List<String> items;
  final String nature;
  final Map<String, dynamic> ivs;
  final dynamic evs; // Can be a Map or List depending on the JSON structure
  final List<String> teratypes;

  CompetitiveSet({
    required this.id,
    required this.variantId,
    required this.tier,
    required this.setName,
    required this.moves,
    required this.ability,
    required this.items,
    required this.nature,
    required this.ivs,
    required this.evs,
    required this.teratypes,
  });

  // Helper functions to parse JSON strings
  static List<String> _parseStringList(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return List<String>.from(decoded.map((item) => item.toString()));
      }
    } catch (e) {
      // If error, return an empty list
    }
    return [];
  }

  static Map<String, dynamic> _parseJsonObject(String jsonStr) {
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  static String _parseString(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is String) return decoded;
    } catch (e) {
      // If not valid JSON, return the original string
    }
    return jsonStr;
  }

  factory CompetitiveSet.fromMap(Map<String, dynamic> map) {
    return CompetitiveSet(
      id: map['id'] as int,
      variantId: map['variant_id'] as int,
      tier: map['tier'] as String,
      setName: map['set_name'] as String,
      moves: _parseStringList(map['moves'] as String),
      ability: _parseString(map['ability'] as String),
      items: _parseStringList(map['item'] as String),
      nature: _parseString(map['nature'] as String),
      ivs: _parseJsonObject(map['ivs'] as String),
      evs: jsonDecode(map['evs'] as String),
      teratypes: _parseStringList(map['teratypes'] as String),
    );
  }
}
