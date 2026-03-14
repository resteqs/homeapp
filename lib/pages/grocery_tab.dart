
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:homeapp/data/grocery_repository.dart';
import 'package:homeapp/data/local_grocery_store.dart';
import 'package:homeapp/models/grocery_item.dart';
import 'package:homeapp/l10n/app_localizations.dart';

class GroceryTab extends StatefulWidget {
  const GroceryTab({super.key});

  @override
  State<GroceryTab> createState() => _GroceryTabState();
}

class _GroceryTabState extends State<GroceryTab> {
  final TextEditingController _textController = TextEditingController();
  late final GroceryRepository _repository;

  bool _showingOverview = true;
  List<Map<String, dynamic>> _lists = [];
  bool _loadingLists = true;

  @override
  void initState() {
    super.initState();
    _repository = GroceryRepository(
      supabase: Supabase.instance.client,
      localStore: LocalGroceryStore(),
    )..init();
    _fetchLists();
  }

  Future<void> _fetchLists() async {
    try {
      final lists = await _repository.fetchGroceryLists();
      if (mounted) {
        setState(() {
          _lists = lists;
          _loadingLists = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingLists = false;
        });
      }
    }
  }

  /// Returns the device's primary language code, e.g. 'en', 'de'.
  String get _locale {
    final tag = Localizations.localeOf(context).languageCode;
    return tag.isNotEmpty ? tag : 'en';
  }

  Future<void> _addItem() async {
    final name = _textController.text;
    if (name.trim().isEmpty) return;
    _textController.clear();
    await _repository.addItem(name, locale: _locale);
    _fetchLists();
  }

  Future<void> _toggleItem(GroceryItem item) async {
    await _repository.toggleItem(item);
    _fetchLists();
  }

  Future<void> _deleteItem(GroceryItem item) async {
    await _repository.deleteItem(item);
    _fetchLists();
  }

  Future<void> _deleteBoughtItems(List<GroceryItem> boughtItems) async {
    await _repository.deleteItems(boughtItems);
    _fetchLists();
  }



  @override
  void dispose() {
    _repository.dispose();
    _textController.dispose();
    super.dispose();
  }

  Map<String, List<GroceryItem>> _groupItems(List<GroceryItem> items) {
    final map = <String, List<GroceryItem>>{};
    for (var item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  _CategoryVisual _getCategoryVisual(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('obst') || cat.contains('gemuse') || cat.contains('gemüse') || cat.contains('fruit') || cat.contains('veg') || cat.contains('apple')) {
      return const _CategoryVisual(Icons.eco, Color(0xFF3A9D23));
    } else if (cat.contains('dairy') || cat.contains('milk') || cat.contains('käse') || cat.contains('molk') || cat.contains('milch')) {
      return const _CategoryVisual(Icons.local_drink, Color(0xFF2A76D2));
    } else if (cat.contains('bakery') || cat.contains('bäckerei') || cat.contains('bread') || cat.contains('brot')) {
      return const _CategoryVisual(Icons.bakery_dining, Color(0xFFD18B2A));
    } else if (cat.contains('drink') || cat.contains('getränk') || cat.contains('water') || cat.contains('wasser')) {
      return const _CategoryVisual(Icons.water_drop, Color(0xFF1C9CEB));
    } else if (cat.contains('snack') || cat.contains('süß') || cat.contains('sweet')) {
      return const _CategoryVisual(Icons.cookie, Color(0xFFE07D26));
    } else if (cat.contains('care') || cat.contains('clean') || cat.contains('reinigung') || cat.contains('hygiene') || cat.contains('pflege')) {
      return const _CategoryVisual(Icons.clean_hands, Color(0xFF8E57D6));
    } else if (cat.contains('meat') || cat.contains('fleisch') || cat.contains('fish') || cat.contains('fisch') || cat.contains('deli')) {
      return const _CategoryVisual(Icons.set_meal, Color(0xFFDB4A39));
    }
    return const _CategoryVisual(Icons.category, Color(0xFF5F6D7A));
  }

  Widget _buildItemTile({required GroceryItem item, required bool isBought}) {
    final categoryVisual = _getCategoryVisual(item.category);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      onDismissed: (_) => _deleteItem(item),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Checkbox(
          value: item.isBought,
          onChanged: (_) => _toggleItem(item),
          shape: const CircleBorder(),
          activeColor: Colors.blueAccent,
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: isBought ? FontWeight.w400 : FontWeight.w500,
            fontSize: 16,
            decoration: isBought ? TextDecoration.lineThrough : TextDecoration.none,
            color: isBought ? Theme.of(context).colorScheme.outline : null,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${item.quantity}',
                style: TextStyle(
                  color: isBought
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                categoryVisual.icon,
                size: 18,
                color: isBought
                    ? Theme.of(context).colorScheme.outline
                    : categoryVisual.color,
              ),
            ],
          ),
        ),
        onTap: () => _showEditModal(item),
      ),
    );
  }

  Future<void> _showEditModal(GroceryItem item) async {
    final nameController = TextEditingController(text: item.name);
    final nameFocusNode = FocusNode();
    bool focusScheduled = false;
    int quantity = item.quantity;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        if (!focusScheduled) {
          focusScheduled = true;
          // Delay focus so keyboard animation does not compete with sheet entrance.
          Future<void>.delayed(const Duration(milliseconds: 220), () {
            if (nameFocusNode.canRequestFocus) {
              nameFocusNode.requestFocus();
            }
          });
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 24, right: 24, top: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.groceryEditItem, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      focusNode: nameFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocalizations.of(context)!.groceryQuantity, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: quantity > 1 ? () => setModalState(() => quantity--) : null,
                              ),
                              Container(
                                constraints: const BoxConstraints(minWidth: 32),
                                alignment: Alignment.center,
                                child: Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setModalState(() => quantity++),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: () {
                          if (nameController.text.trim().isNotEmpty) {
                            _repository.updateItemDetails(item, nameController.text.trim(), quantity);
                            Navigator.pop(context);
                            _fetchLists();
                          }
                        },
                        child: Text(AppLocalizations.of(context)!.grocerySaveChanges, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Use a dedicated widget to absorb keyboard insets so that the main form does not rebuild during keyboard animation
                    Builder(
                      builder: (context) => SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );

    nameFocusNode.dispose();
    nameController.dispose();
  }

  Widget _buildOverview() {
    if (_loadingLists) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.groceryMyLists, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: _lists.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.groceryNoLists))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: _lists.length,
              itemBuilder: (context, index) {
                final list = _lists[index];
                final rawItems = list['grocery_list_items'] as List<dynamic>? ?? [];
                final items = rawItems.where((i) => i['deleted_at'] == null).toList();
                final totalCount = items.length;
                final boughtCount = items.where((i) => i['is_bought'] == true).length;
                final progress = totalCount > 0 ? boughtCount / totalCount : 0.0;

                return Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      _repository.setActiveList(list['id']);
                      setState(() => _showingOverview = false);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                list['name'] ?? 'Shopping List',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$boughtCount/$totalCount',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: Text(AppLocalizations.of(context)!.groceryAdd, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }

  Widget _buildDetailedList() {
    final listName = _lists.firstWhere(
      (l) => l['id'] == _repository.listId,
      orElse: () => {'name': 'Shopping list'}
    )['name'];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _fetchLists();
            setState(() => _showingOverview = true);
          },
        ),
        title: Text(listName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: AnimatedBuilder(
        animation: _repository,
        builder: (context, _) {
          if (_repository.isLoading) return const Center(child: CircularProgressIndicator());

          if (_repository.listId == null) {
            return Center(child: Text(_repository.lastError ?? 'Could not load list.'));
          }

          final allItems = _repository.items;
          final toBuyItems = allItems.where((i) => !i.isBought).toList();
          final boughtItems = allItems.where((i) => i.isBought).toList();
          final groupedToBuy = _groupItems(toBuyItems);

          return Column(
            children: [
              if (_repository.isSyncing) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    if (groupedToBuy.isEmpty && boughtItems.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Text(AppLocalizations.of(context)!.groceryEmptyList, style: Theme.of(context).textTheme.bodyLarge),
                        ),
                      ),
                    ...groupedToBuy.entries.map((entry) {
                      final categoryName = entry.key;
                      final items = entry.value;
                      return SliverMainAxisGroup(
                        slivers: [
                          // Category header
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                categoryName,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = items[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: _buildItemTile(item: item, isBought: false),
                                  );
                                },
                                childCount: items.length,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    if (boughtItems.isNotEmpty) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.groceryBoughtItems,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                              TextButton.icon(
                                onPressed: () => _deleteBoughtItems(boughtItems),
                                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                                label: const Text('Delete all'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = boughtItems[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: _buildItemTile(item: item, isBought: true),
                              );
                            },
                            childCount: boughtItems.length,
                          ),
                        ),
                      ),
                    ],
                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                ),
              ),
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        offset: const Offset(0, -4),
                        blurRadius: 10,
                      )
                    ]
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.groceryAddItem,
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.add, color: Colors.grey),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            onSubmitted: (_) => _addItem(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.green,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_upward, color: Colors.white),
                          onPressed: _addItem,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showingOverview ? _buildOverview() : _buildDetailedList(),
    );
  }
}

class _CategoryVisual {
  const _CategoryVisual(this.icon, this.color);

  final IconData icon;
  final Color color;
}
