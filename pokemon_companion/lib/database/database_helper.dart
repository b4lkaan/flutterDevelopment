import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/pokemon.dart';
import '../models/variant.dart';
import '../models/competitive_set.dart';

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

  // New method to retrieve variants for a given Pokémon
  static Future<List<Variant>> getVariantsForPokemon(int pokemonId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      "Variant",
      where: "pokemon_id = ?",
      whereArgs: [pokemonId],
    );
    return results.map((map) => Variant.fromMap(map)).toList();
  }
  
  // New method: Retrieves competitive sets for a given variant.
  static Future<List<CompetitiveSet>> getCompetitiveSetsForVariant(int variantId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      "CompetitiveSet",
      where: "variant_id = ?",
      whereArgs: [variantId],
    );
    return results.map((map) => CompetitiveSet.fromMap(map)).toList();
}
}