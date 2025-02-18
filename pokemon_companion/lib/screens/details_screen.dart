import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../models/variant.dart';
import '../database/database_helper.dart';
import 'variant_detail_screen.dart';

class DetailsScreen extends StatelessWidget {
  final Pokemon pokemon;

  const DetailsScreen({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pokemon.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pokemon.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Dex Number: ${pokemon.dexNumber}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Variants:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: FutureBuilder<List<Variant>>(
                future: DatabaseHelper.getVariantsForPokemon(pokemon.id),
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
                          subtitle: Text('HP: ${variant.hp} | ATK: ${variant.attack} | DEF: ${variant.defense}'),
                          onTap: () {
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
            ),
          ],
        ),
      ),
    );
  }
}
