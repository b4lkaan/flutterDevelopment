import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/pokemon.dart';
import '../models/variant.dart';
import 'details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
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
    // Adjust crossAxisCount based on screen width for responsiveness.
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon Companion'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Pokémon...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: filteredPokemon.isEmpty
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
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Use a FutureBuilder to fetch the first variant image.
                        FutureBuilder<Variant?>(
                          future: DatabaseHelper.getFirstVariantForSpecies(
                              pokemon.name),
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
                                      snapshot.data!.imageUrl!),
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
                                    pokemon.name[0].toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pokemon.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('#${pokemon.dexNumber}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
