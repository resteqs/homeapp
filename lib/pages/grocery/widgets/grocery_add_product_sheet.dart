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

  Map<String, String> get _knownDisplayNamesByLower {
    final namesByLower = <String, String>{};

    void addName(String rawName) {
      final trimmed = rawName.trim();
      if (trimmed.isEmpty) return;
      namesByLower.putIfAbsent(trimmed.toLowerCase(), () => trimmed);
    }

    for (final name in _catalog) {
      addName(name);
    }
    for (final name in widget.repository.customItemNames) {
      addName(name);
    }
    for (final item in widget.repository.items) {
      addName(item.name);
    }

    return namesByLower;
  }

  List<String> get _allSuggestionCandidates =>
      _knownDisplayNamesByLower.values.toList(growable: false);

  Set<String> get _customItemNamesLower =>
      widget.repository.customItemNames.map((name) => name.toLowerCase()).toSet();

  Map<String, DateTime> get _lastUsedAtByNameLower {
    final lastUsedByName = <String, DateTime>{};
    for (final item in widget.repository.items) {
      final key = item.name.trim().toLowerCase();
      if (key.isEmpty) continue;

      final current = lastUsedByName[key];
      if (current == null || item.updatedAt.isAfter(current)) {
        lastUsedByName[key] = item.updatedAt;
      }
    }
    return lastUsedByName;
  }

  int _compareSuggestionPriority(
    String a,
    String b,
    String query,
    Set<String> customNamesLower,
    Map<String, DateTime> lastUsedAtByNameLower,
  ) {
    final aLower = a.toLowerCase();
    final bLower = b.toLowerCase();

    final aStarts = aLower.startsWith(query);
    final bStarts = bLower.startsWith(query);
    if (aStarts != bStarts) return aStarts ? -1 : 1;

    final aIsCustom = customNamesLower.contains(aLower);
    final bIsCustom = customNamesLower.contains(bLower);
    if (aIsCustom != bIsCustom) return aIsCustom ? -1 : 1;

    final aUsedAt = lastUsedAtByNameLower[aLower];
    final bUsedAt = lastUsedAtByNameLower[bLower];
    if (aUsedAt != null || bUsedAt != null) {
      if (aUsedAt == null) return 1;
      if (bUsedAt == null) return -1;
      final recencyCompare = bUsedAt.compareTo(aUsedAt);
      if (recencyCompare != 0) return recencyCompare;
    }

    return aLower.compareTo(bLower);
  }

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
        final customNamesLower = _customItemNamesLower;
        final lastUsedAtByNameLower = _lastUsedAtByNameLower;

        // Substring filtering is done against local in-memory data to keep
        // typing responsive and avoid per-keystroke backend calls.
        final matches = _allSuggestionCandidates
            .where((item) => item.toLowerCase().contains(query))
            .toList();

        // Rank local matches for fast picking: prefix match, then family custom
        // products, then recently used products, then alphabetically.
        matches.sort((a, b) {
          return _compareSuggestionPriority(
            a,
            b,
            query,
            customNamesLower,
            lastUsedAtByNameLower,
          );
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

  String _capitalizeFirstLetter(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  void _increaseProduct(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return;

    // Use canonical catalog casing where possible to keep names consistent.
    final canonical = _knownDisplayNamesByLower[normalized.toLowerCase()] ??
        _capitalizeFirstLetter(normalized);
    final item = _getItemFromList(canonical);
    if (item != null) {
      await widget.repository.updateItemDetails(
        item,
        item.name,
        item.quantity + 1,
        item.unit,
        item.notes,
        item.badgeEmoji,
        locale: widget.locale,
      );
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

  void _decreaseProduct(String name) async {
    final item = _getItemFromList(name);
    if (item == null) return;

    if (item.quantity <= 1) {
      await widget.repository.deleteItem(item);
      return;
    }

    await widget.repository.updateItemDetails(
      item,
      item.name,
      item.quantity - 1,
      item.unit,
      item.notes,
      item.badgeEmoji,
      locale: widget.locale,
    );
  }

  void _removeProduct(String name) async {
    final item = _getItemFromList(name);
    if (item == null) return;
    await widget.repository.deleteItem(item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: widget.repository,
      builder: (context, _) {
        final activeItemNamesLower = _activeItemNamesLower;
        final activeItemsByNameLower = <String, GroceryItem>{
          for (final item in widget.repository.items.where((item) => !item.isBought))
            item.name.toLowerCase(): item,
        };

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
                  textCapitalization: TextCapitalization.sentences,
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
              final activeItem = activeItemsByNameLower[product.toLowerCase()];
              final isInList =
                  activeItemNamesLower.contains(product.toLowerCase());

              return ListTile(
                leading: isInList
                    ? SizedBox(
                        width: 72,
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 16,
                                color: colorScheme.onSurfaceVariant,
                                icon: const Icon(Icons.add),
                                onPressed: () => _increaseProduct(product),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 16,
                                color: colorScheme.onSurfaceVariant,
                                icon: const Icon(Icons.remove),
                                onPressed: () => _decreaseProduct(product),
                              ),
                            ),
                          ],
                        ),
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
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (activeItem != null &&
                              (activeItem.quantity > 1 ||
                                  (activeItem.unit != null &&
                                      activeItem.unit!.trim().isNotEmpty)))
                            Text(
                              '${activeItem.quantity}${activeItem.unit != null && activeItem.unit!.trim().isNotEmpty ? ' ${activeItem.unit}' : ''}',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (activeItem != null &&
                              (activeItem.quantity > 1 ||
                                  (activeItem.unit != null &&
                                      activeItem.unit!.trim().isNotEmpty)))
                            const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(Icons.close, color: colorScheme.error),
                            onPressed: () => _removeProduct(product),
                          ),
                        ],
                      )
                    : null,
                onTap: isInList ? null : () => _increaseProduct(product),
              );
            },
          ),
        );
      },
    );
  }
}
