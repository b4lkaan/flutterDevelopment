import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/pokemon.dart';
import '../models/variant.dart';
import 'details_screen.dart';

// Helper function to capitalize the first letter.
String capitalize(String s) =>
    s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

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
  List<Pokemon> filteredPokemon = [];
  final TextEditingController _searchController = TextEditingController();

  // Advanced filter state
  String _nameQuery = "";
  String _selectedType = "All";
  String _selectedTier = "All";
  bool _useFuzzy = false;

  // Dropdown options
  final List<String> _types = [
    "All",
    "Normal",
    "Fire",
    "Water",
    "Electric",
    "Grass",
    "Ice",
    "Fighting",
    "Poison",
    "Ground",
    "Flying",
    "Psychic",
    "Bug",
    "Rock",
    "Ghost",
    "Dragon",
    "Dark",
    "Steel",
    "Fairy"
  ];

  // Note: For tiers, we now use values that will map to the stored version.
  // For example, "Anything Goes" maps to "anythinggoes" and "Ubers" maps to "ubersuu".
  final List<String> _tiers = [
    "All",
    "Anything Goes",
    "Ubers",
    "OU",
    "UU",
    "RU",
    "NU",
    "PU",
    "ZU",
    "NFE",
    "LC"
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchFilteredPokemon();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Called whenever the search field changes.
  void _onSearchChanged() {
    setState(() {
      _nameQuery = _searchController.text;
    });
    _fetchFilteredPokemon();
  }

  // Fetch Pokémon from the database based on current filters.
  Future<void> _fetchFilteredPokemon() async {
    final results = await DatabaseHelper.getFilteredPokemon(
      nameQuery: _nameQuery,
      type: _selectedType,
      tier: _selectedTier,
      fuzzy: _useFuzzy,
    );
    setState(() {
      filteredPokemon = results;
    });
  }

  // Opens a filter dialog.
  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempSelectedType = _selectedType;
        String tempSelectedTier = _selectedTier;
        bool tempUseFuzzy = _useFuzzy;
        return AlertDialog(
          title: const Text('Advanced Filters'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type filter
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Type'),
                  value: tempSelectedType,
                  items: _types
                      .map((type) => DropdownMenuItem(
                          value: type, child: Text(capitalize(type))))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) tempSelectedType = value;
                  },
                ),
                const SizedBox(height: 8),
                // Tier filter
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Competitive Tier'),
                  value: tempSelectedTier,
                  items: _tiers
                      .map((tier) =>
                          DropdownMenuItem(value: tier, child: Text(tier)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) tempSelectedTier = value;
                  },
                ),
                const SizedBox(height: 8),
                // Fuzzy search toggle
                Row(
                  children: [
                    const Text('Use Fuzzy Search'),
                    Switch(
                      value: tempUseFuzzy,
                      onChanged: (value) {
                        setState(() {
                          tempUseFuzzy = value;
                        });
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Clear Filters'),
              onPressed: () {
                setState(() {
                  tempSelectedType = "All";
                  tempSelectedTier = "All";
                  tempUseFuzzy = false;
                });
              },
            ),
            TextButton(
              child: const Text('Apply'),
              onPressed: () {
                setState(() {
                  _selectedType = tempSelectedType;
                  _selectedTier = tempSelectedTier;
                  _useFuzzy = tempUseFuzzy;
                });
                _fetchFilteredPokemon();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/final_logo.png',
              height: 30,
            ),
            const SizedBox(width: 8),
            const Text('Pokevision'),
          ],
        ),
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _openFilterDialog,
          ),
          // Dark mode toggle
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
            padding: const EdgeInsets.only(top: 100),
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
                                style: const TextStyle(fontWeight: FontWeight.bold),
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
                  hintText: 'Search Pokémon by name...',
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
