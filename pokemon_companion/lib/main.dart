import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.init(); // Ensure the database is initialized
  runApp(const PokemonApp());
}

class PokemonApp extends StatefulWidget {
  const PokemonApp({super.key});
  
  @override
  State<PokemonApp> createState() => _PokemonAppState();
}

class _PokemonAppState extends State<PokemonApp> {
  bool _isDarkMode = false;
  
  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon Companion',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}
