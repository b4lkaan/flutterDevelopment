import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/pokemon.dart';
import '../models/variant.dart';
import '../models/competitive_set.dart';
import '../models/evolution.dart';
import '../models/variant_ability.dart';
import '../models/variant_type.dart';

class DatabaseHelper {
  static const String dbName = "pokemon.db";
  static Database? _database;
  
  static Future<void> init() async {
    if (!kIsWeb) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    }
    await database;
  }
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    await Directory(databasesPath).create(recursive: true);
    final path = join(databasesPath, dbName);
    final exists = await databaseExists(path);
    debugPrint('Database path: $path');
    debugPrint('Database exists? $exists');
    if (!exists) {
      try {
        debugPrint('Copying database from assets...');
        final data = await rootBundle.load('assets/$dbName');
        debugPrint('Asset loaded. Byte length: ${data.lengthInBytes}');
        final bytes = data.buffer.asUint8List();
        await File(path).writeAsBytes(bytes, flush: true);
        final fileSize = await File(path).length();
        debugPrint('Database copied successfully. File size on disk: $fileSize bytes');
      } catch (e) {
        debugPrint("Error copying database: $e");
      }
    } else {
      debugPrint('Database already exists at $path');
    }
    final db = await openDatabase(path, readOnly: false);
    final tableList = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    debugPrint('Tables in the database: $tableList');
    return db;
  }
  
  static Future<List<Pokemon>> getAllPokemon() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query("Pokemon");
    return results.map((map) => Pokemon.fromMap(map)).toList();
  }
  
  static Future<List<Variant>> getVariantsForPokemon(int pokemonId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      "Variant",
      where: "pokemon_id = ?",
      whereArgs: [pokemonId],
    );
    return results.map((map) => Variant.fromMap(map)).toList();
  }
  
  // Retrieves competitive sets for a given variant.
  static Future<List<CompetitiveSet>> getCompetitiveSetsForVariant(int variantId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      "CompetitiveSet",
      where: "variant_id = ?",
      whereArgs: [variantId],
    );
    return results.map((map) => CompetitiveSet.fromMap(map)).toList();
  }
  
  // Retrieves the evolution chain for a given Pokémon.
  static Future<List<Evolution>> getEvolutionChain(int pokemonId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      "Evolution",
      where: "pokemon_id = ?",
      whereArgs: [pokemonId],
      orderBy: "stage",
    );
    return results.map((map) => Evolution.fromMap(map)).toList();
  }
  
  // Retrieves abilities for a given variant.
  static Future<List<VariantAbility>> getAbilitiesForVariant(int variantId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      "VariantAbility",
      where: "variant_id = ?",
      whereArgs: [variantId],
    );
    return results.map((map) => VariantAbility.fromMap(map)).toList();
  }
  
  // Retrieves types for a given variant.
  static Future<List<VariantType>> getTypesForVariant(int variantId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      "VariantType",
      where: "variant_id = ?",
      whereArgs: [variantId],
    );
    return results.map((map) => VariantType.fromMap(map)).toList();
  }
  
  // Retrieves a Pokemon by species name.
  static Future<Pokemon?> getPokemonByName(String speciesName) async {
    final db = await database;
    final results = await db.query(
      "Pokemon",
      where: "name = ?",
      whereArgs: [speciesName.toLowerCase()],
    );
    if (results.isNotEmpty) {
      return Pokemon.fromMap(results.first);
    }
    return null;
  }
  
  // Get a single Variant (e.g. first form) for a species by name.
  static Future<Variant?> getFirstVariantForSpecies(String speciesName) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT Variant.*
      FROM Pokemon
      JOIN Variant ON Pokemon.id = Variant.pokemon_id
      WHERE LOWER(Pokemon.name) = LOWER(?)
      ORDER BY Variant.id
      LIMIT 1
    ''', [speciesName]);
    if (results.isNotEmpty) {
      return Variant.fromMap(results.first);
    }
    return null;
  }
  
  /// --- New Advanced Search Functions ---
  
  /// A simple fuzzy-match helper: returns true if all characters in [pattern]
  /// appear (in order) in [text] (case insensitive).
  static bool fuzzyMatch(String pattern, String text) {
    int j = 0;
    for (int i = 0; i < text.length && j < pattern.length; i++) {
      if (text[i].toLowerCase() == pattern[j].toLowerCase()) {
        j++;
      }
    }
    return j == pattern.length;
  }
  
  /// Maps the user-visible tier to the stored value.
  /// For example, "Ubers" becomes "ubersuu", and spaces are removed.
  static String _mapTierValue(String tier) {
    String t = tier.toLowerCase().replaceAll(" ", "");
    if (t == "ubers") return "ubersuu";
    return t;
  }
  
  /// Retrieves Pokémon matching advanced criteria.
  ///
  /// [nameQuery] filters the Pokémon name.
  /// [type] filters by the Pokémon’s type (via its variants)
  /// and [tier] filters by the competitive set tier.
  ///
  /// If [fuzzy] is true and a [nameQuery] is provided, the query is done loosely
  /// (using SQL LIKE for the name if fuzzy is false) and then further filtered in
  /// memory using a fuzzy match.
  static Future<List<Pokemon>> getFilteredPokemon({
    String? nameQuery,
    String? type,
    String? tier,
    bool fuzzy = false,
  }) async {
    final db = await database;
    String sql = "SELECT DISTINCT Pokemon.* FROM Pokemon ";
    List<dynamic> args = [];
    
    // Determine which additional tables to join.
    bool joinVariant = false;
    bool joinVariantType = false;
    bool joinCompetitiveSet = false;
    
    if (type != null && type.toLowerCase() != "all" && type.isNotEmpty) {
      joinVariant = true;
      joinVariantType = true;
    }
    String? mappedTier;
    if (tier != null && tier.toLowerCase() != "all" && tier.isNotEmpty) {
      joinVariant = true;
      joinCompetitiveSet = true;
      mappedTier = _mapTierValue(tier);
    }
    
    // Always join Variant only once if needed.
    if (joinVariant) {
      sql += "JOIN Variant ON Pokemon.id = Variant.pokemon_id ";
    }
    
    // Join VariantType if filtering by type.
    if (joinVariantType) {
      sql += "JOIN VariantType ON Variant.id = VariantType.variant_id ";
      sql += "AND LOWER(VariantType.type_name) = ? ";
      args.add(type!.toLowerCase());
    }
    
    // Join CompetitiveSet if filtering by tier.
    if (joinCompetitiveSet) {
      sql += "JOIN CompetitiveSet ON Variant.id = CompetitiveSet.variant_id ";
      sql += "AND LOWER(REPLACE(CompetitiveSet.tier, ' ', '')) = ? ";
      args.add(mappedTier);
    }
    
    // Name filter.
    if (!fuzzy && nameQuery != null && nameQuery.isNotEmpty) {
      sql += (sql.contains("WHERE") ? "AND " : "WHERE ") +
          "LOWER(Pokemon.name) LIKE ? ";
      args.add("%${nameQuery.toLowerCase()}%");
    }
    
    final results = await db.rawQuery(sql, args);
    List<Pokemon> pokemons = results.map((map) => Pokemon.fromMap(map)).toList();
    
    // If fuzzy search is enabled for name, filter in memory.
    if (fuzzy && nameQuery != null && nameQuery.isNotEmpty) {
      pokemons = pokemons.where((pokemon) => fuzzyMatch(nameQuery, pokemon.name)).toList();
    }
    
    return pokemons;
  }
}
