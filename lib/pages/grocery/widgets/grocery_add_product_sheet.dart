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

  late List<String> _baseRecommendations;

  @override
  void initState() {
    super.initState();
    
    // Set base recommendations depending on locale
    if (widget.locale == 'de') {
      _baseRecommendations = [
        'Milch', 'Eier', 'Brot', 'Toilettenpapier', 'Wasser',
        'Tomaten', 'Bier', 'Kaffee', 'Sahne', 'Joghurt', 'Ketchup',
      ];
    } else {
      _baseRecommendations = [
        'Milk', 'Eggs', 'Bread', 'Toilet Paper', 'Water',
        'Tomatoes', 'Beer', 'Coffee', 'Cream', 'Yogurt', 'Ketchup',
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
        final catalog = groceryCatalog[widget.locale] ?? groceryCatalog['en'] ?? [];
        
        final matches = catalog
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

  bool _isItemInList(String name) {
    return widget.repository.items.any((item) =>
        item.name.toLowerCase() == name.toLowerCase() && !item.isBought);
  }

  GroceryItem? _getItemFromList(String name) {
    try {
      return widget.repository.items.firstWhere((item) =>
          item.name.toLowerCase() == name.toLowerCase() && !item.isBought);
    } catch (e) {
      return null;
    }
  }

  void _toggleProduct(String name) async {
    final item = _getItemFromList(name);
    if (item != null) {
      await widget.repository.deleteItem(item);
    } else {
      await widget.repository.addItem(name, locale: widget.locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: widget.repository,
      builder: (context, _) {
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
              final isInList = _isItemInList(product);

              return ListTile(
                leading: isInList
                    ? CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.shade400,
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 20),
                      )
                    : CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 20),
                      ),
                title: Text(
                  product,
                  style: TextStyle(
                    color: isInList
                        ? Colors.grey
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: isInList
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
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
