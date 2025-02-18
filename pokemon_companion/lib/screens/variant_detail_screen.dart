import 'package:flutter/material.dart';
import '../models/variant.dart';
import '../models/competitive_set.dart';
import '../models/variant_ability.dart';
import '../models/variant_type.dart';
import '../database/database_helper.dart';

class VariantDetailScreen extends StatelessWidget {
  final Variant variant;

  const VariantDetailScreen({super.key, required this.variant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(variant.name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Variant basic details
              Row(
                children: [
                  variant.imageUrl != null && variant.imageUrl!.isNotEmpty
                      ? Image.network(
                          variant.imageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported, size: 100),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variant.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text('HP: ${variant.hp} | ATK: ${variant.attack} | DEF: ${variant.defense}'),
                        Text('Sp. ATK: ${variant.specialAttack} | Sp. DEF: ${variant.specialDefense} | Speed: ${variant.speed}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Display Variant Abilities
              const Text(
                'Abilities:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              FutureBuilder<List<VariantAbility>>(
                future: DatabaseHelper.getAbilitiesForVariant(variant.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No abilities found.');
                  }
                  final abilities = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: abilities.length,
                    itemBuilder: (context, index) {
                      final ability = abilities[index];
                      return ListTile(
                        title: Text(ability.abilityName),
                        subtitle: Text(ability.abilityDescription),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // Display Variant Types
              const Text(
                'Types:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              FutureBuilder<List<VariantType>>(
                future: DatabaseHelper.getTypesForVariant(variant.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No types found.');
                  }
                  final types = snapshot.data!;
                  return Wrap(
                    spacing: 8,
                    children: types.map((type) {
                      return Chip(label: Text(type.typeName));
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Competitive Sets Section
              const Text(
                'Competitive Sets:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              FutureBuilder<List<CompetitiveSet>>(
                future: DatabaseHelper.getCompetitiveSetsForVariant(variant.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No competitive sets found.');
                  }
                  final sets = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sets.length,
                    itemBuilder: (context, index) {
                      final set = sets[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${set.tier.toUpperCase()} - ${set.setName}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text('Moves: ${set.moves.join(', ')}'),
                              Text('Ability: ${set.ability}'),
                              Text('Items: ${set.items.join(', ')}'),
                              Text('Nature: ${set.nature}'),
                              Text('IVs: ${set.ivs}'),
                              Text('EVs: ${set.evs}'),
                              Text('Tera Types: ${set.teratypes.join(', ')}'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
