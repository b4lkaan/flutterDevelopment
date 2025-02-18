import 'package:flutter/material.dart';
import '../models/variant.dart';
import '../models/competitive_set.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display variant details
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
            const Text(
              'Competitive Sets:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: FutureBuilder<List<CompetitiveSet>>(
                future: DatabaseHelper.getCompetitiveSetsForVariant(variant.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No competitive sets found.'));
                  }
                  final sets = snapshot.data!;
                  return ListView.builder(
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
            ),
          ],
        ),
      ),
    );
  }
}
