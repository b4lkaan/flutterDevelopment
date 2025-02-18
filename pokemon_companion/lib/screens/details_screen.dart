import 'dart:convert';
import 'package:flutter/material.dart';

// Adjust these imports based on your project folder structure:
import '../database/database_helper.dart';
import '../models/pokemon.dart';
import '../models/variant.dart';
import '../models/evolution.dart';
import 'variant_detail_screen.dart';

/// A helper function to parse JSON from `evolution_details`
/// and return a short text describing the evolution method (e.g., "Level 16").
String parseEvolutionMethod(String evolutionDetailsJson) {
  if (evolutionDetailsJson.isEmpty) return '';
  try {
    final decoded = jsonDecode(evolutionDetailsJson);
    Map<String, dynamic> data;
    // The DB might store an array of conditions. We take the first element if it's a list:
    if (decoded is List && decoded.isNotEmpty) {
      data = decoded.first as Map<String, dynamic>;
    } else if (decoded is Map<String, dynamic>) {
      data = decoded;
    } else {
      // If it's neither a list nor a map, just return the raw string
      return evolutionDetailsJson;
    }

    // The trigger might be an object like { "name": "level-up" }
    String trigger;
    if (data['trigger'] is Map && data['trigger']['name'] != null) {
      trigger = data['trigger']['name'];
    } else {
      trigger = data['trigger']?.toString() ?? '';
    }

    // Handle level-up
    if (trigger == 'level-up' || trigger == 'level_up') {
      final minLevel = data['min_level'];
      if (minLevel != null) {
        if (minLevel is int) {
          return 'Level $minLevel';
        } else if (minLevel is String) {
          return 'Level ${int.tryParse(minLevel) ?? minLevel}';
        }
      }
      // If min_level is null, check for min_happiness
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

    // Handle trade
    if (trigger == 'trade') {
      return 'Trade';
    }

    // Handle use_item (or use-item)
    if (trigger == 'use_item' || trigger == 'use-item') {
      final itemData = data['item'];
      if (itemData is Map<String, dynamic>) {
        // e.g. {"name": "fire-stone", "url": "..."}
        final itemName = itemData['name'] ?? 'an item';
        return 'Use $itemName';
      } else if (itemData is String) {
        // If it's just a string
        return 'Use $itemData';
      }
      return 'Use an item';
    }

    // Fallback: return the trigger if nothing else matched
    return trigger;
  } catch (e) {
    // If the JSON is invalid or something else, return the raw string
    return evolutionDetailsJson;
  }
}

/// A widget that displays the entire evolution chain horizontally,
/// with clickable images for each stage.
class EvolutionChainWidget extends StatelessWidget {
  final int pokemonId;

  const EvolutionChainWidget({super.key, required this.pokemonId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Evolution>>(
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
        // Sort by stage ascending, in case the DB order is different
        evolutions.sort((a, b) => a.stage.compareTo(b.stage));

        // We build a horizontal list: [Stage0] -> [method] -> [Stage1] -> [method] -> ...
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(evolutions.length * 2 - 1, (index) {
              // Even indices = a stage item; odd indices = an arrow/method
              final isStageIndex = index % 2 == 0;
              if (isStageIndex) {
                final evoIndex = index ~/ 2;
                return EvolutionStageItem(evolution: evolutions[evoIndex]);
              } else {
                // Show arrow and method text between stage i and stage i+1
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

/// A widget that shows one stage's image and name. Clicking it navigates
/// to the corresponding Pokémon's `DetailsScreen`.
class EvolutionStageItem extends StatelessWidget {
  final Evolution evolution;

  const EvolutionStageItem({super.key, required this.evolution});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Variant?>(
      future: DatabaseHelper.getFirstVariantForSpecies(evolution.speciesName),
      builder: (context, snapshot) {
        final variant = snapshot.data;
        final imageUrl = variant?.imageUrl;

        return GestureDetector(
          onTap: () async {
            // Find the actual Pokémon record by species name
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
                  evolution.speciesName,
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

/// A small widget to display an arrow and the evolution method text.
class ArrowMethodWidget extends StatelessWidget {
  final String methodText;

  const ArrowMethodWidget({super.key, required this.methodText});

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

/// The main details screen for a given Pokémon. Shows:
/// - Pokémon name and Dex number
/// - Variants
/// - A horizontal evolution chain
class DetailsScreen extends StatelessWidget {
  final Pokemon pokemon;

  const DetailsScreen({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pokemon.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pokemon.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Dex Number: ${pokemon.dexNumber}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // ----- Variants -----
            const Text(
              'Variants:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            FutureBuilder<List<Variant>>(
              future: DatabaseHelper.getVariantsForPokemon(pokemon.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No variants found.');
                }
                final variants = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: variants.length,
                  itemBuilder: (context, index) {
                    final variant = variants[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: variant.imageUrl != null && variant.imageUrl!.isNotEmpty
                            ? Image.network(
                                variant.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported),
                        title: Text(variant.name),
                        subtitle: Text(
                          'HP: ${variant.hp} | ATK: ${variant.attack} | DEF: ${variant.defense}\n'
                          'SP. ATK: ${variant.specialAttack} | SP. DEF: ${variant.specialDefense} | Speed: ${variant.speed}'
                        ),
                        onTap: () {
                          // Navigate to the VariantDetailScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VariantDetailScreen(variant: variant),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),
            // ----- Evolution Chain -----
            const Text(
              'Evolution Chain:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            EvolutionChainWidget(pokemonId: pokemon.id),
          ],
        ),
      ),
    );
  }
}
