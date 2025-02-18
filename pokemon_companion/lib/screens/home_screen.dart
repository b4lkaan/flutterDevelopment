import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/pokemon.dart';
import '../models/variant.dart';
import 'details_screen.dart';

// Helper function to capitalize the first letter.
String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Pokemon> allPokemon = [];
  List<Pokemon> filteredPokemon = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPokemon();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadPokemon() async {
    allPokemon = await DatabaseHelper.getAllPokemon();
    setState(() {
      filteredPokemon = allPokemon;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredPokemon = allPokemon
          .where((pokemon) => pokemon.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        // A Row with the logo and "Pokevision" text
        title: Row(
          children: [
            Image.asset(
              'assets/final_logo.png',
              height: 30, // Adjust as desired
            ),
            const SizedBox(width: 8),
            const Text('Pokevision'),
          ],
        ),
        actions: [
          // Dark mode toggle switch
          Switch(
            value: widget.isDarkMode,
            onChanged: widget.onThemeChanged,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Grid of Pokémon cards
          Padding(
            padding: const EdgeInsets.only(top: 100), // space for search bar
            child: filteredPokemon.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWideScreen ? 4 : 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: filteredPokemon.length,
                    itemBuilder: (context, index) {
                      final pokemon = filteredPokemon[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailsScreen(pokemon: pokemon),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FutureBuilder<Variant?>(
                                future: DatabaseHelper.getFirstVariantForSpecies(
                                  pokemon.name,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data != null &&
                                      snapshot.data!.imageUrl != null &&
                                      snapshot.data!.imageUrl!.isNotEmpty) {
                                    return Hero(
                                      tag: 'pokemonAvatar_${pokemon.id}',
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundImage: NetworkImage(
                                          snapshot.data!.imageUrl!,
                                        ),
                                        backgroundColor: Colors.grey[300],
                                      ),
                                    );
                                  } else {
                                    return Hero(
                                      tag: 'pokemonAvatar_${pokemon.id}',
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.grey[300],
                                        child: Text(
                                          capitalize(pokemon.name)[0],
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                capitalize(pokemon.name),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('#${pokemon.dexNumber}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Floating Search Bar
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(30),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Pokémon...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
