import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/competitive_set.dart';
import '../models/variant.dart';
import '../models/variant_ability.dart';
import '../models/variant_type.dart';

// Helper function to capitalize the first letter.
String capitalize(String s) =>
    s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

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

// Helper functions for placeholder descriptions.
String getMoveDescription(String move) => "Description for move: $move";
String getItemDescription(String item) => "Description for item: $item";
String getNatureDescription(String nature) => "Description for nature: $nature";
String getAbilityDescription(String ability) => "Description for ability: $ability";

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
        final appBarColor = snapshot.data ?? Colors.grey;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 250,
                backgroundColor: appBarColor,
                flexibleSpace: FlexibleSpaceBar(
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
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    const SizedBox(height: 16),
                    _buildBasicStatsCard(context),
                    const SizedBox(height: 16),
                    _buildTypesSection(context),
                    const SizedBox(height: 16),
                    _buildAbilitiesSection(context),
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
                    capitalize(widget.variant.name),
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
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ExpansionTile(
                        title: Tooltip(
                          message: ability.abilityDescription,
                          child: Text(
                            capitalize(ability.abilityName),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              ability.abilityDescription,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
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

  // --------------------------------------------------------------------------
  // NEW MODERNIZED COMPETITIVE SETS SECTION WITH HOVER TOOLTIPS
  // --------------------------------------------------------------------------
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
        // Define the desired order mapping.
        final tierOrder = {
          'anythinggoes': 1,
          'ubers': 2,
          'ubersuu': 3,
          'ou': 4,
          'uu': 5,
          'ru': 6,
          'nu': 7,
          'pu': 8,
          'zu': 9,
          'nfe': 10,
          'lc': 11,
        };

        // Sort sets based on the mapping.
        sets.sort((a, b) {
          final aTier = a.tier.toLowerCase();
          final bTier = b.tier.toLowerCase();
          final aOrder = tierOrder[aTier] ?? 1000;
          final bOrder = tierOrder[bTier] ?? 1000;
          return aOrder.compareTo(bOrder);
        });

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                ...sets.map((set) => _buildCompetitiveSetTile(context, set)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// A helper widget that displays one CompetitiveSet in a nicely formatted way.
  Widget _buildCompetitiveSetTile(BuildContext context, CompetitiveSet set) {
    final tierStr = set.tier.toUpperCase();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Text('$tierStr - ${set.setName}'),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Moves (each move is wrapped in a Tooltip, with support for multiple-choice)
          _buildLabeledSection(
            label: 'Moves',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildMoveList(set.moves),
            ),
          ),
          const Divider(),

          // Ability with hover tooltip.
          _buildLabeledSection(
            label: 'Ability',
            child: _buildListWithTooltips([set.ability], getAbilityDescription),
          ),
          const Divider(),

          // Items with hover tooltips.
          _buildLabeledSection(
            label: 'Item(s)',
            child: _buildListWithTooltips(set.items, getItemDescription),
          ),
          const Divider(),

          // Nature with hover tooltip.
          _buildLabeledSection(
            label: 'Nature',
            child: _buildListWithTooltips([set.nature], getNatureDescription),
          ),
          const Divider(),

          // IVs.
          _buildLabeledSection(
            label: 'IVs',
            child: Text(set.ivs.toString()),
          ),
          const Divider(),

          // EVs.
          _buildLabeledSection(
            label: 'EVs',
            child: Text(_formatEVs(set.evs)),
          ),
          const Divider(),

          // Tera Types.
          _buildLabeledSection(
            label: 'Tera Types',
            child: Text(_joinWithOr(set.teratypes)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Builds a small section with a label and some child widget.
  Widget _buildLabeledSection({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  /// Builds a list of moves with bullet points, each wrapped in a Tooltip.
  List<Widget> _buildMoveList(List<dynamic> moves) {
    return moves.map((move) {
      return _buildMoveBullet(move);
    }).toList();
  }

  /// Creates a bullet point widget for a move.
  Widget _buildMoveBullet(dynamic move) {
    if (move is String) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Tooltip(
            message: getMoveDescription(move),
            child: Text(
              move,
              style: const TextStyle(decoration: TextDecoration.underline),
            ),
          ),
        ],
      );
    } else if (move is List) {
      // For multiple-choice moves, each option gets its own tooltip.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Flexible(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: move.asMap().entries.map((entry) {
                int index = entry.key;
                String option = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: getMoveDescription(option),
                      child: Text(
                        option,
                        style:
                            const TextStyle(decoration: TextDecoration.underline),
                      ),
                    ),
                    if (index != move.length - 1)
                      const Text(" or "),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      );
    }
    // Fallback if data is unexpected.
    return const SizedBox.shrink();
  }

  /// Joins a list of strings with “ or ”.
  String _joinWithOr(List<String> choices) {
    final valid = choices.where((c) => c.trim().isNotEmpty).toList();
    return valid.join(' or ');
  }

  /// Converts an EV map like {def: 4, spa: 252, spe: 252} to a friendly string.
  String _formatEVs(dynamic evData) {
    if (evData is Map) {
      final entries = evData.entries
          .where((e) => e.value != null && e.value > 0)
          .map((e) => '${e.value} ${e.key.toString().toUpperCase()}')
          .toList();
      return entries.isEmpty ? '—' : entries.join(' / ');
    }
    return evData.toString();
  }

  /// Builds a widget that displays a list of strings with individual tooltips.
  Widget _buildListWithTooltips(
      List<String> values, String Function(String) getDescription) {
    final valid = values.where((v) => v.trim().isNotEmpty).toList();
    return Wrap(
      children: valid.asMap().entries.map((entry) {
        int index = entry.key;
        String value = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: getDescription(value),
              child: Text(
                value,
                style: const TextStyle(decoration: TextDecoration.underline),
              ),
            ),
            if (index != valid.length - 1) const Text(" or "),
          ],
        );
      }).toList(),
    );
  }
}
