import 'dart:convert';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/pokemon.dart';
import '../models/variant.dart';
import 'variant_detail_screen.dart';

// Helper function to capitalize the first letter.
String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

String parseEvolutionMethod(String evolutionDetailsJson) {
  if (evolutionDetailsJson.isEmpty) return '';
  try {
    final decoded = jsonDecode(evolutionDetailsJson);
    Map<String, dynamic> data;
    if (decoded is List && decoded.isNotEmpty) {
      data = decoded.first as Map<String, dynamic>;
    } else if (decoded is Map<String, dynamic>) {
      data = decoded;
    } else {
      return evolutionDetailsJson;
    }
    String trigger;
    if (data['trigger'] is Map && data['trigger']['name'] != null) {
      trigger = data['trigger']['name'];
    } else {
      trigger = data['trigger']?.toString() ?? '';
    }
    if (trigger == 'level-up' || trigger == 'level_up') {
      final minLevel = data['min_level'];
      if (minLevel != null) {
        if (minLevel is int) {
          return 'Level $minLevel';
        } else if (minLevel is String) {
          return 'Level ${int.tryParse(minLevel) ?? minLevel}';
        }
      }
      final minHappiness = data['min_happiness'];
      if (minHappiness != null) {
        if (minHappiness is int) {
          return 'Happiness $minHappiness';
        } else if (minHappiness is String) {
          return 'Happiness ${int.tryParse(minHappiness) ?? minHappiness}';
        }
      }
      return 'Level Up';
    }
    if (trigger == 'trade') {
      return 'Trade';
    }
    if (trigger == 'use_item' || trigger == 'use-item') {
      final itemData = data['item'];
      if (itemData is Map<String, dynamic>) {
        final itemName = itemData['name'] ?? 'an item';
        return 'Use $itemName';
      } else if (itemData is String) {
        return 'Use $itemData';
      }
      return 'Use an item';
    }
    return trigger;
  } catch (e) {
    return evolutionDetailsJson;
  }
}

class EvolutionChainWidget extends StatelessWidget {
  final int pokemonId;

  const EvolutionChainWidget({Key? key, required this.pokemonId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: DatabaseHelper.getEvolutionChain(pokemonId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No evolution chain found.');
        }
        final evolutions = snapshot.data!;
        evolutions.sort((a, b) => a.stage.compareTo(b.stage));
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(evolutions.length * 2 - 1, (index) {
              final isStageIndex = index % 2 == 0;
              if (isStageIndex) {
                final evoIndex = index ~/ 2;
                return EvolutionStageItem(evolution: evolutions[evoIndex]);
              } else {
                final nextIndex = (index ~/ 2) + 1;
                final methodJson = evolutions[nextIndex].evolutionDetails;
                final methodText = parseEvolutionMethod(methodJson);
                return ArrowMethodWidget(methodText: methodText);
              }
            }),
          ),
        );
      },
    );
  }
}

class EvolutionStageItem extends StatelessWidget {
  final dynamic evolution; // adjust the type if you have a specific model

  const EvolutionStageItem({Key? key, required this.evolution})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Variant?>(
      future: DatabaseHelper.getFirstVariantForSpecies(evolution.speciesName),
      builder: (context, snapshot) {
        final variant = snapshot.data;
        final imageUrl = variant?.imageUrl;
        return GestureDetector(
          onTap: () async {
            final tappedPokemon =
                await DatabaseHelper.getPokemonByName(evolution.speciesName);
            if (tappedPokemon != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailsScreen(pokemon: tappedPokemon),
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image_not_supported, size: 60),
                const SizedBox(height: 4),
                Text(
                  capitalize(evolution.speciesName),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ArrowMethodWidget extends StatelessWidget {
  final String methodText;

  const ArrowMethodWidget({Key? key, required this.methodText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.arrow_right_alt, size: 30),
        Text(methodText),
        const SizedBox(width: 8),
      ],
    );
  }
}

class DetailsScreen extends StatefulWidget {
  final Pokemon pokemon;

  const DetailsScreen({Key? key, required this.pokemon}) : super(key: key);

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<List<Variant>>? _variantsFuture;

  @override
  void initState() {
    super.initState();
    // Only two tabs: Variants and Evolution
    _tabController = TabController(length: 2, vsync: this);
    _variantsFuture = DatabaseHelper.getVariantsForPokemon(widget.pokemon.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget buildHeroImage() {
    return FutureBuilder<Variant?>(
      future: DatabaseHelper.getFirstVariantForSpecies(widget.pokemon.name),
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.imageUrl != null &&
            snapshot.data!.imageUrl!.isNotEmpty) {
          return Hero(
            tag: 'pokemonAvatar_${widget.pokemon.id}',
            child: Image.network(
              snapshot.data!.imageUrl!,
              fit: BoxFit.cover,
            ),
          );
        } else {
          return Hero(
            tag: 'pokemonAvatar_${widget.pokemon.id}',
            child: Container(
              color: Colors.grey[300],
            ),
          );
        }
      },
    );
  }

  Widget buildVariantsTab() {
    return FutureBuilder<List<Variant>>(
      future: _variantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No variants found.'));
        }
        final variants = snapshot.data!;
        return ListView.builder(
          itemCount: variants.length,
          itemBuilder: (context, index) {
            final variant = variants[index];
            return Card(
              margin:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: variant.imageUrl != null &&
                        variant.imageUrl!.isNotEmpty
                    ? Image.network(
                        variant.imageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image_not_supported),
                title: Text(capitalize(variant.name)),
                subtitle: Text(
                    'HP: ${variant.hp} | ATK: ${variant.attack} | DEF: ${variant.defense}\n'
                    'Sp. ATK: ${variant.specialAttack} | Sp. DEF: ${variant.specialDefense} | Speed: ${variant.speed}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VariantDetailScreen(variant: variant),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget buildEvolutionTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Evolution Chain:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          EvolutionChainWidget(pokemonId: widget.pokemon.id),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: buildHeroImage(),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Variants'),
                Tab(text: 'Evolution'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            buildVariantsTab(),
            buildEvolutionTab(),
          ],
        ),
      ),
    );
  }
}
