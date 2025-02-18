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
  
  final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.deepPurple[700],
    colorScheme: ColorScheme.dark(
      primary: Colors.deepPurple[700]!,
      secondary: Colors.amber,
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.deepPurple[700],
    ),
    textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
  );
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokevision',
      theme: ThemeData.light(),
      darkTheme: darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}
