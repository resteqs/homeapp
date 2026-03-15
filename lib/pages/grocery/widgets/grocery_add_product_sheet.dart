import 'package:flutter/material.dart';
import 'package:homeapp/l10n/app_localizations.dart';
import 'package:homeapp/models/grocery_item.dart';
import 'package:homeapp/data/grocery_repository.dart';
import 'package:homeapp/data/grocery_catalog.dart';

class GroceryAddProductSheet extends StatefulWidget {
  final GroceryRepository repository;
  final String locale;

  const GroceryAddProductSheet({
    super.key,
    required this.repository,
    required this.locale,
  });

  @override
  State<GroceryAddProductSheet> createState() => _GroceryAddProductSheetState();
}

class _GroceryAddProductSheetState extends State<GroceryAddProductSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredRecommendations = [];
  final FocusNode _focusNode = FocusNode();
  // Locale-specific offline catalog. Cached once in initState to avoid work
  // on every keystroke.
  late final List<String> _catalog;
  // Keeps canonical display names for lowercased user input.
  final Map<String, String> _lowerToDisplayName = <String, String>{};

  late List<String> _baseRecommendations;

  @override
  void initState() {
    super.initState();

    _catalog = List<String>.from(
      groceryCatalog[widget.locale] ?? groceryCatalog['en'] ?? const <String>[],
    );
    for (final name in _catalog) {
      _lowerToDisplayName[name.toLowerCase()] = name;
    }

    // Set base recommendations depending on locale
    if (widget.locale == 'de') {
      _baseRecommendations = [
        'Milch',
        'Eier',
        'Brot',
        'Toilettenpapier',
        'Wasser',
        'Tomaten',
        'Bier',
        'Kaffee',
        'Sahne',
        'Joghurt',
        'Ketchup',
      ];
    } else {
      _baseRecommendations = [
        'Milk',
        'Eggs',
        'Bread',
        'Toilet Paper',
        'Water',
        'Tomatoes',
        'Beer',
        'Coffee',
        'Cream',
        'Yogurt',
        'Ketchup',
      ];
    }

    _filteredRecommendations = List.from(_baseRecommendations);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRecommendations = List.from(_baseRecommendations);
      } else {
        // Substring filtering is done against local in-memory data to keep
        // typing responsive and avoid per-keystroke backend calls.
        final matches = _catalog
            .where((item) => item.toLowerCase().contains(query))
            .toList();

        // Sort items so exact substring matches or "starts with" matches appear higher
        matches.sort((a, b) {
          final aLower = a.toLowerCase();
          final bLower = b.toLowerCase();
          final aStarts = aLower.startsWith(query);
          final bStarts = bLower.startsWith(query);
          if (aStarts && !bStarts) return -1;
          if (!aStarts && bStarts) return 1;
          return aLower.compareTo(bLower);
        });

        _filteredRecommendations = matches;

        if (!_filteredRecommendations
                .any((item) => item.toLowerCase() == query) &&
            query.isNotEmpty) {
          _filteredRecommendations.insert(0, _searchController.text.trim());
        }
      }
    });
  }

  // Built once per frame and reused for all visible rows.
  Set<String> get _activeItemNamesLower => widget.repository.items
      .where((item) => !item.isBought)
      .map((item) => item.name.toLowerCase())
      .toSet();

  GroceryItem? _getItemFromList(String name) {
    try {
      return widget.repository.items.firstWhere((item) =>
          item.name.toLowerCase() == name.toLowerCase() && !item.isBought);
    } catch (e) {
      return null;
    }
  }

  void _toggleProduct(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return;

    // Use canonical catalog casing where possible to keep names consistent.
    final canonical =
        _lowerToDisplayName[normalized.toLowerCase()] ?? normalized;
    final item = _getItemFromList(canonical);
    if (item != null) {
      await widget.repository.deleteItem(item);
    } else {
      await widget.repository.addItem(canonical, locale: widget.locale);
      // Clear the visible input but keep the current filtered list until
      // the user starts typing again.
      _searchController.removeListener(_onSearchChanged);
      _searchController.clear();
      _searchController.addListener(_onSearchChanged);
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: widget.repository,
      builder: (context, _) {
        final activeItemNamesLower = _activeItemNamesLower;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.groceryAddItem,
                    border: InputBorder.none,
                    icon: Icon(Icons.search,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ),
          body: ListView.builder(
            itemCount: _filteredRecommendations.length,
            itemBuilder: (context, index) {
              final product = _filteredRecommendations[index];
              final isInList =
                  activeItemNamesLower.contains(product.toLowerCase());

              return ListTile(
                leading: isInList
                    ? CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.outlineVariant,
                        child: Icon(Icons.check,
                            color: colorScheme.onSurface, size: 20),
                      )
                    : CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.primary,
                        child: Icon(Icons.add,
                            color: colorScheme.onPrimary, size: 20),
                      ),
                title: Text(
                  product,
                  style: TextStyle(
                    color:
                        isInList ? colorScheme.outline : colorScheme.onSurface,
                  ),
                ),
                trailing: isInList
                    ? IconButton(
                        icon: Icon(Icons.close, color: colorScheme.error),
                        onPressed: () => _toggleProduct(product),
                      )
                    : null,
                onTap: () => _toggleProduct(product),
              );
            },
          ),
        );
      },
    );
  }
}
