import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:homeapp/data/grocery_repository.dart';
import 'package:homeapp/data/local_grocery_store.dart';
import 'package:homeapp/models/grocery_item.dart';

class GroceryTab extends StatefulWidget {
  const GroceryTab({super.key});

  @override
  State<GroceryTab> createState() => _GroceryTabState();
}

class _GroceryTabState extends State<GroceryTab> {
  final TextEditingController _textController = TextEditingController();
  late final GroceryRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = GroceryRepository(
      supabase: Supabase.instance.client,
      localStore: LocalGroceryStore(),
    )..init();
  }

  Future<void> _addItem() async {
    final name = _textController.text;
    if (name.trim().isEmpty) return;

    _textController.clear();
    await _repository.addItem(name);
  }

  Future<void> _toggleItem(GroceryItem item) async {
    await _repository.toggleItem(item);
  }

  Future<void> _deleteItem(GroceryItem item) async {
    await _repository.deleteItem(item);
  }

  @override
  void dispose() {
    _repository.dispose();
    _textController.dispose();
    super.dispose();
  }

  // Group items by category.
  Map<String, List<GroceryItem>> _groupItems(List<GroceryItem> items) {
    final map = <String, List<GroceryItem>>{};
    for (var item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _repository,
      builder: (context, _) {
        if (_repository.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_repository.listId == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _repository.lastError ??
                    'Could not load your household grocery list.',
              ),
            ),
          );
        }

        final allItems = _repository.items;
        final toBuyItems = allItems.where((i) => !i.isBought).toList();
        final boughtItems = allItems.where((i) => i.isBought).toList();
        final groupedToBuy = _groupItems(toBuyItems);

        return Column(
          children: [
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_repository.isSyncing)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _repository.lastError == null ? Icons.cloud_done : Icons.cloud_off,
                      size: 16,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _repository.isSyncing
                          ? 'Syncing changes...'
                          : (_repository.lastError == null
                              ? 'Offline edits enabled. Changes sync automatically.'
                              : 'Sync paused: ${_repository.lastError}'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: _repository.isSyncing ? null : _repository.sync,
                    child: const Text('Sync now'),
                  )
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  if (groupedToBuy.isEmpty && boughtItems.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Your list is empty',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ...groupedToBuy.entries.map((entry) {
                    final category = entry.key;
                    final items = entry.value;

                    return SliverMainAxisGroup(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              category,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = items[index];
                                return Card(
                                  elevation: 0,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  child: ListTile(
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _deleteItem(item),
                                    ),
                                    leading: Checkbox(
                                      value: item.isBought,
                                      onChanged: (_) => _toggleItem(item),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    onTap: () => _toggleItem(item),
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
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Recent',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = boughtItems[index];
                            return Card(
                              elevation: 0,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                              ),
                              margin: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                title: Text(
                                  item.name,
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteItem(item),
                                  ),
                                subtitle: Text(
                                  item.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                leading: Checkbox(
                                  value: item.isBought,
                                  onChanged: (_) => _toggleItem(item),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                onTap: () => _toggleItem(item),
                              ),
                            );
                          },
                          childCount: boughtItems.length,
                        ),
                      ),
                    ),
                  ],
                  const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
                ],
              ),
            ),
            SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Add an item...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        onSubmitted: (_) => _addItem(),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    FloatingActionButton(
                      onPressed: _addItem,
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const CircleBorder(),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
