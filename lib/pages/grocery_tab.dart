
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

  Future<void> _showEditModal(GroceryItem item) async {
    final nameController = TextEditingController(text: item.name);
    int quantity = item.quantity;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
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
                    decoration: InputDecoration(
                      labelText: 'Name', 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    autofocus: true,
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
                ],
              ),
            );
          }
        );
      }
    );
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
          IconButton(icon: const Icon(Icons.person_add_alt), onPressed: () {}),
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
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      leading: Checkbox(
                                        value: item.isBought,
                                        onChanged: (_) => _toggleItem(item),
                                        shape: const CircleBorder(),
                                        activeColor: Colors.blueAccent,
                                      ),
                                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('${item.quantity}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 8),
                                            Icon(Icons.shopping_basket, size: 16, color: Theme.of(context).colorScheme.primary),
                                          ],
                                        ),
                                      ),
                                      onTap: () => _showEditModal(item),
                                    ),
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
                          child: Text(AppLocalizations.of(context)!.groceryBoughtItems, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.outline)),
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
                                      decoration: TextDecoration.lineThrough, 
                                      color: Theme.of(context).colorScheme.outline
                                    )
                                  ),
                                  trailing: Text('${item.quantity}', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                                  onTap: () => _showEditModal(item),
                                ),
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
