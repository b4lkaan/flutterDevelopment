import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/pokemon.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon Companion'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Pokémon by name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: filteredPokemon.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredPokemon.length,
                    itemBuilder: (context, index) {
                      final pokemon = filteredPokemon[index];
                      return ListTile(
                        leading: const Icon(Icons.catching_pokemon),
                        title: Text('${pokemon.name} (#${pokemon.dexNumber})'),
                        subtitle: Text('Pokédex ID: ${pokemon.id}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailsScreen(pokemon: pokemon),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
