import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/competitive_set.dart';
import '../models/variant.dart';
import '../models/variant_ability.dart';
import '../models/variant_type.dart';

// Global model classes:
import '../models/global_move.dart';
import '../models/global_ability.dart';
import '../models/global_item.dart';
import '../models/global_nature.dart';

/// Capitalize the first letter of a string.
String capitalize(String s) =>
    s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

/// Convert a UI key (e.g. "Weather Ball") into DB-friendly format ("weather-ball").
String _normalizeKey(String key) {
  return key.toLowerCase().replaceAll(" ", "-");
}

/// Check if a string is enclosed in `[ ]`.
bool _isBracketedList(String s) {
  final t = s.trim();
  return t.startsWith('[') && t.endsWith(']');
}

/// Parse a bracketed list string like "[Protect, Knock Off]" or '["Jolly","Adamant"]' 
/// into a `List<String>`. This is a naive parser that splits on commas and trims each element.
List<String> _parseBracketedList(String s) {
  final trimmed = s.trim();
  // Remove the leading '[' and trailing ']'
  final inner = trimmed.substring(1, trimmed.length - 1).trim();
  if (inner.isEmpty) return [];
  return inner.split(',').map((part) {
    // Strip quotes if present
    return part.replaceAll('"', '').replaceAll("'", '').trim();
  }).toList();
}

/// A helper that ensures we always return a `List<String>` even if the underlying
/// data is bracketed, a single string, or already a list of dynamic.
List<String> _extractListFromDynamic(dynamic data) {
  if (data == null) return [];

  // If it's already a List, convert each element to a String.
  if (data is List) {
    return data.map((e) => e.toString()).toList();
  }

  // If it's a string, parse if bracketed, otherwise treat as single-value list.
  if (data is String) {
    final trimmed = data.trim();
    if (_isBracketedList(trimmed)) {
      return _parseBracketedList(trimmed);
    }
    return [trimmed];
  }

  // Fallback: return empty list if type is unexpected
  return [];
}

/// Convert a Pokémon type name to a color (expand as needed).
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
  // Variant-specific data futures
  late Future<List<VariantAbility>> _abilitiesFuture;
  late Future<List<VariantType>> _typesFuture;
  late Future<List<CompetitiveSet>> _competitiveSetsFuture;
  late Future<Color> _primaryTypeColorFuture;

  // Global data futures
  Future<Map<String, GlobalMove>> _globalMovesFuture = Future.value({});
  Future<Map<String, GlobalAbility>> _globalAbilitiesFuture = Future.value({});
  Future<Map<String, GlobalItem>> _globalItemsFuture = Future.value({});
  Future<Map<String, GlobalNature>> _globalNaturesFuture = Future.value({});

  // Once loaded, store them here
  Map<String, GlobalMove>? _globalMoves;
  Map<String, GlobalAbility>? _globalAbilities;
  Map<String, GlobalItem>? _globalItems;
  Map<String, GlobalNature>? _globalNatures;

  @override
  void initState() {
    super.initState();
    // Load variant-specific data
    _abilitiesFuture = DatabaseHelper.getAbilitiesForVariant(widget.variant.id);
    _typesFuture = DatabaseHelper.getTypesForVariant(widget.variant.id);
    _competitiveSetsFuture =
        DatabaseHelper.getCompetitiveSetsForVariant(widget.variant.id);
    _primaryTypeColorFuture = _fetchPrimaryTypeColor();

    // Load global data
    _globalMovesFuture = DatabaseHelper.getAllGlobalMoves();
    _globalAbilitiesFuture = DatabaseHelper.getAllGlobalAbilities();
    _globalItemsFuture = DatabaseHelper.getAllGlobalItems();
    _globalNaturesFuture = DatabaseHelper.getAllGlobalNatures();
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
    return FutureBuilder(
      future: Future.wait([
        _primaryTypeColorFuture,
        _abilitiesFuture,
        _typesFuture,
        _competitiveSetsFuture,
        _globalMovesFuture,
        _globalAbilitiesFuture,
        _globalItemsFuture,
        _globalNaturesFuture,
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        // Unpack the results
        final color = snapshot.data![0] as Color;
        final abilities = snapshot.data![1] as List<VariantAbility>;
        final types = snapshot.data![2] as List<VariantType>;
        final compSets = snapshot.data![3] as List<CompetitiveSet>;
        _globalMoves = snapshot.data![4] as Map<String, GlobalMove>;
        _globalAbilities = snapshot.data![5] as Map<String, GlobalAbility>;
        _globalItems = snapshot.data![6] as Map<String, GlobalItem>;
        _globalNatures = snapshot.data![7] as Map<String, GlobalNature>;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 250,
                backgroundColor: color,
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
                    _buildTypesSection(types),
                    const SizedBox(height: 16),
                    _buildAbilitiesSection(abilities),
                    const SizedBox(height: 16),
                    _buildCompetitiveSetsSection(compSets),
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

  Widget _buildTypesSection(List<VariantType> types) {
    if (types.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No types found.'),
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 8,
          children: types.map((type) {
            final chipColor = _typeToColor(type.typeName);
            return Chip(
              backgroundColor: chipColor.withAlpha(51),
              label: Text(
                type.typeName,
                style: TextStyle(
                  color: chipColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAbilitiesSection(List<VariantAbility> abilities) {
    if (abilities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No abilities found.'),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                // Lookup the global description if available
                final globalAbility = _globalAbilities?[_normalizeKey(ability.abilityName)];
                final realDescription =
                    globalAbility?.description ?? ability.abilityDescription;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Tooltip(
                      message: realDescription,
                      child: Text(
                        capitalize(ability.abilityName),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitiveSetsSection(List<CompetitiveSet> sets) {
    if (sets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No competitive sets found.'),
      );
    }

    // Define a custom tier sort order
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

    // Sort sets based on the mapping
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
            ...sets.map((set) => _buildCompetitiveSetTile(set)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitiveSetTile(CompetitiveSet set) {
    final tierStr = set.tier.toUpperCase();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Text('$tierStr - ${set.setName}'),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildLabeledSection(
            label: 'Moves',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildMoveList(set.moves),
            ),
          ),
          const Divider(),
          _buildLabeledSection(
            label: 'Ability',
            child: _buildListWithTooltips(
              _extractListFromDynamic(set.ability),
              (abilityName) => _getAbilityDescription(abilityName),
            ),
          ),
          const Divider(),
          _buildLabeledSection(
            label: 'Item(s)',
            child: _buildListWithTooltips(
              _extractListFromDynamic(set.items),
              (itemName) => _getItemDescription(itemName),
            ),
          ),
          const Divider(),
          _buildLabeledSection(
            label: 'Nature',
            child: _buildListWithTooltips(
              _extractListFromDynamic(set.nature),
              (natureName) => _getNatureDescription(natureName),
            ),
          ),
          const Divider(),
          _buildLabeledSection(
            label: 'IVs',
            child: Text(set.ivs.toString()),
          ),
          const Divider(),
          _buildLabeledSection(
            label: 'EVs',
            child: Text(_formatEVs(set.evs)),
          ),
          const Divider(),
          _buildLabeledSection(
            label: 'Tera Types',
            child: Text(_joinWithOr(set.teratypes)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Helper method that displays a label next to some child widget (used in expansions).
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

  /// Build a list of moves with bullet points. Each element can be a single move or a bracketed list of moves.
  List<Widget> _buildMoveList(List<dynamic> moves) {
    return moves.map((move) {
      return _buildMoveBullet(move);
    }).toList();
  }

  /// Display a single move or multi-move with bullet points.
  Widget _buildMoveBullet(dynamic move) {
    if (move is List) {
      // Already a list of moves
      return _buildMoveRowForList(move.map((e) => e.toString()).toList());
    } else if (move is String) {
      // Possibly bracketed
      final trimmed = move.trim();
      if (_isBracketedList(trimmed)) {
        final parsed = _parseBracketedList(trimmed);
        return _buildMoveRowForList(parsed);
      }
      // Single move
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Tooltip(
            message: _getMoveDescription(move),
            child: Text(move),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  /// Helper that displays multiple moves joined by " or " in one bullet line.
  Widget _buildMoveRowForList(List<String> moveList) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
        Flexible(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: moveList.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: _getMoveDescription(option),
                    child: Text(option),
                  ),
                  if (index != moveList.length - 1) const Text(" or "),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Build a widget that displays a `List<String>` with individual tooltips, joined by " or ".
  Widget _buildListWithTooltips(
    List<String> values,
    String Function(String) getDescription,
  ) {
    final valid = values.where((v) => v.trim().isNotEmpty).toList();
    if (valid.isEmpty) {
      return const Text('—');
    }
    return Wrap(
      children: valid.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: getDescription(value),
              child: Text(value),
            ),
            if (index != valid.length - 1) const Text(" or "),
          ],
        );
      }).toList(),
    );
  }

  /// Join a list of strings with " or ".
  String _joinWithOr(List<String> choices) {
    final valid = choices.where((c) => c.trim().isNotEmpty).toList();
    return valid.join(' or ');
  }

  /// Convert an EV map (e.g. {def: 4, spa: 252, spe: 252}) to a readable string.
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

  /// Look up a move description in the global map.
  String _getMoveDescription(String moveName) {
    if (_globalMoves == null) return moveName;
    final normalizedName = _normalizeKey(moveName);
    final globalMove = _globalMoves![normalizedName];
    if (globalMove == null) {
      return "No move description found for $moveName";
    }
    return globalMove.description;
  }

  /// Look up an ability description in the global map.
  String _getAbilityDescription(String abilityName) {
    if (_globalAbilities == null) return abilityName;
    final normalizedName = _normalizeKey(abilityName);
    final globalAbility = _globalAbilities![normalizedName];
    if (globalAbility == null) {
      return "No ability description found for $abilityName";
    }
    return globalAbility.description;
  }

  /// Look up an item description in the global map.
  String _getItemDescription(String itemName) {
    if (_globalItems == null) return itemName;
    final normalizedName = _normalizeKey(itemName);
    final globalItem = _globalItems![normalizedName];
    if (globalItem == null) {
      return "No item description found for $itemName";
    }
    return globalItem.description;
  }

  /// Look up a nature description in the global map.
  String _getNatureDescription(String natureName) {
    if (_globalNatures == null) return natureName;
    final normalizedName = _normalizeKey(natureName);
    final globalNature = _globalNatures![normalizedName];
    if (globalNature == null) {
      return "No nature data found for $natureName";
    }
    return globalNature.description;
  }
}
