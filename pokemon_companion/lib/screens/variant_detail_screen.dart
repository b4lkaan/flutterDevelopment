import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/competitive_set.dart';
import '../models/variant.dart';
import '../models/variant_ability.dart';
import '../models/variant_type.dart';

// A helper map for type-based colors (expand as needed).
Color _typeToColor(String typeName) {
  switch (typeName.toLowerCase()) {
    case 'normal':
      return Colors.brown.shade400;
    case 'fire':
      return Colors.redAccent;
    case 'water':
      return Colors.blueAccent;
    case 'electric':
      return Colors.amber;
    case 'grass':
      return Colors.green;
    case 'ice':
      return Colors.lightBlueAccent;
    case 'fighting':
      return Colors.orangeAccent;
    case 'poison':
      return Colors.deepPurpleAccent;
    case 'ground':
      return Colors.brown;
    case 'flying':
      return Colors.indigoAccent;
    case 'psychic':
      return Colors.pinkAccent;
    case 'bug':
      return Colors.lightGreen;
    case 'rock':
      return Colors.grey;
    case 'ghost':
      return Colors.deepPurple;
    case 'dragon':
      return Colors.indigo;
    case 'dark':
      return Colors.black87;
    case 'steel':
      return Colors.blueGrey;
    case 'fairy':
      return Colors.pink;
    default:
      return Colors.grey;
  }
}


class VariantDetailScreen extends StatefulWidget {
  const VariantDetailScreen({super.key, required this.variant});
  final Variant variant;

  @override
  State<VariantDetailScreen> createState() => _VariantDetailScreenState();
}

class _VariantDetailScreenState extends State<VariantDetailScreen> {
  late Future<List<VariantAbility>> _abilitiesFuture;
  late Future<List<VariantType>> _typesFuture;
  late Future<List<CompetitiveSet>> _competitiveSetsFuture;
  late Future<Color> _primaryTypeColorFuture;

  @override
  void initState() {
    super.initState();
    _abilitiesFuture =
        DatabaseHelper.getAbilitiesForVariant(widget.variant.id);
    _typesFuture = DatabaseHelper.getTypesForVariant(widget.variant.id);
    _competitiveSetsFuture =
        DatabaseHelper.getCompetitiveSetsForVariant(widget.variant.id);
    _primaryTypeColorFuture = _fetchPrimaryTypeColor();
  }

  /// Fetches the variant's first type to color the SliverAppBar background.
  /// Defaults to grey if no types found.
  Future<Color> _fetchPrimaryTypeColor() async {
    final types = await DatabaseHelper.getTypesForVariant(widget.variant.id);
    if (types.isNotEmpty) {
      return _typeToColor(types.first.typeName);
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Color>(
      future: _primaryTypeColorFuture,
      builder: (context, snapshot) {
        // Default color if not loaded yet
        final appBarColor = snapshot.data ?? Colors.grey;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Collapsing SliverAppBar with Hero Image
              SliverAppBar(
                pinned: true,
                expandedHeight: 250,
                backgroundColor: appBarColor,
                flexibleSpace: FlexibleSpaceBar(
                  // We omit the title here to avoid overlay text on the image
                  background: Hero(
                    tag: 'variantHero_${widget.variant.id}',
                    child: widget.variant.imageUrl != null &&
                            widget.variant.imageUrl!.isNotEmpty
                        ? Image.network(
                            widget.variant.imageUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(color: Colors.grey),
                  ),
                ),
              ),

              // The rest of the content is in a SliverList
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    const SizedBox(height: 16),
                    _buildBasicStatsCard(context),
                    const SizedBox(height: 16),
                    _buildAbilitiesSection(context),
                    const SizedBox(height: 16),
                    _buildTypesSection(context),
                    const SizedBox(height: 16),
                    _buildCompetitiveSetsSection(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Card with the variant’s name and base stats (HP, ATK, DEF, etc.).
  Widget _buildBasicStatsCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            widget.variant.imageUrl != null &&
                    widget.variant.imageUrl!.isNotEmpty
                ? Image.network(
                    widget.variant.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image_not_supported, size: 80),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.variant.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'HP: ${widget.variant.hp} | ATK: ${widget.variant.attack} | DEF: ${widget.variant.defense}',
                  ),
                  Text(
                    'Sp. ATK: ${widget.variant.specialAttack} | Sp. DEF: ${widget.variant.specialDefense} | Speed: ${widget.variant.speed}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the variant’s abilities in a modern, card-based layout.
  Widget _buildAbilitiesSection(BuildContext context) {
    return FutureBuilder<List<VariantAbility>>(
      future: _abilitiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No abilities found.'),
          );
        }

        final abilities = snapshot.data!;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Abilities',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Column(
                  children: abilities.map((ability) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ability.abilityName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ability.abilityDescription,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows the variant’s types in a card, using color-coded chips.
  Widget _buildTypesSection(BuildContext context) {
    return FutureBuilder<List<VariantType>>(
      future: _typesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No types found.'),
          );
        }

        final types = snapshot.data!;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 8,
              children: types.map((type) {
                final color = _typeToColor(type.typeName);
                return Chip(
                  backgroundColor: color.withAlpha(51),
                  label: Text(
                    type.typeName,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  /// Shows the variant’s competitive sets in an ExpansionTile list.
  Widget _buildCompetitiveSetsSection(BuildContext context) {
    return FutureBuilder<List<CompetitiveSet>>(
      future: _competitiveSetsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No competitive sets found.'),
          );
        }

        final sets = snapshot.data!;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  'Competitive Sets',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...sets.map((set) {
                  final tierStr = set.tier.toString();
                  return ExpansionTile(
                    title: Text('${tierStr.toUpperCase()} - ${set.setName}'),
                    children: [
                      ListTile(
                        title: const Text('Moves'),
                        subtitle: Text(set.moves.join(', ')),
                      ),
                      ListTile(
                        title: const Text('Ability'),
                        subtitle: Text(set.ability),
                      ),
                      ListTile(
                        title: const Text('Items'),
                        subtitle: Text(set.items.join(', ')),
                      ),
                      ListTile(
                        title: const Text('Nature'),
                        subtitle: Text(set.nature),
                      ),
                      ListTile(
                        title: const Text('IVs'),
                        subtitle: Text(set.ivs.toString()),
                      ),
                      ListTile(
                        title: const Text('EVs'),
                        subtitle: Text(set.evs.toString()),
                      ),
                      ListTile(
                        title: const Text('Tera Types'),
                        subtitle: Text(set.teratypes.join(', ')),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
