import 'package:flutter/material.dart';
import 'package:homeapp/l10n/app_localizations.dart';
import 'package:homeapp/models/grocery_item.dart';
import 'package:homeapp/data/grocery_repository.dart';
import 'package:homeapp/utils/category_utils.dart';
import 'package:homeapp/pages/grocery/widgets/grocery_item_tile.dart';
import 'package:homeapp/pages/grocery/widgets/grocery_edit_sheet.dart';

enum SelectionAction { delete, move, cancel }
enum DetailedListMenuAction { delete }

class GroceryDetailedList extends StatefulWidget {
  final List<Map<String, dynamic>> lists;
  final GroceryRepository repository;
  final VoidCallback onBack;
  final Future<void> Function() onFetchLists;
  final void Function({required String listId, required String listName}) onDeleteList;

  const GroceryDetailedList({
    super.key,
    required this.lists,
    required this.repository,
    required this.onBack,
    required this.onFetchLists,
    required this.onDeleteList,
  });

  @override
  State<GroceryDetailedList> createState() => _GroceryDetailedListState();
}

class _GroceryDetailedListState extends State<GroceryDetailedList> {
  final TextEditingController _textController = TextEditingController();
  bool _selectionMode = false;
  final Set<String> _selectedItemIds = <String>{};

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String get _locale {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode.isNotEmpty ? languageCode : 'en';
  }

  Future<void> _addItem() async {
    final name = _textController.text.trim();
    if (name.isEmpty) return;

    _textController.clear();
    await widget.repository.addItem(name, locale: _locale);
    await widget.onFetchLists();
  }

  Future<void> _toggleItem(GroceryItem item) async {
    await widget.repository.toggleItem(item);
    await widget.onFetchLists();
  }

  Future<void> _deleteItem(GroceryItem item) async {
    await widget.repository.deleteItem(item);
    await widget.onFetchLists();
  }

  Future<void> _deleteBoughtItems(List<GroceryItem> boughtItems) async {
    if (boughtItems.isEmpty) return;
    await widget.repository.deleteItems(boughtItems);
    await widget.onFetchLists();
  }

  List<GroceryItem> get _selectedItems => widget.repository.items
      .where((item) => _selectedItemIds.contains(item.id))
      .toList(growable: false);

  void _clearSelection() {
    if (!_selectionMode && _selectedItemIds.isEmpty) return;
    setState(() {
      _selectionMode = false;
      _selectedItemIds.clear();
    });
  }

  void _toggleSelection(GroceryItem item) {
    setState(() {
      _selectionMode = true;
      if (_selectedItemIds.contains(item.id)) {
        _selectedItemIds.remove(item.id);
      } else {
        _selectedItemIds.add(item.id);
      }

      if (_selectedItemIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  Future<void> _startSelection(GroceryItem item) async {
    setState(() {
      _selectionMode = true;
      _selectedItemIds.add(item.id);
    });
    await _showSelectionMenu();
  }

  Future<void> _showSelectionMenu() async {
    if (_selectedItemIds.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;

    final action = await showModalBottomSheet<SelectionAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  l10n.groceryItemsSelected(_selectedItemIds.length),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: Text(l10n.groceryDeleteSelected),
                onTap: () => Navigator.of(context).pop(SelectionAction.delete),
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_move_outline),
                title: Text(l10n.groceryMoveToAnotherList),
                onTap: () => Navigator.of(context).pop(SelectionAction.move),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(l10n.groceryCancel),
                onTap: () => Navigator.of(context).pop(SelectionAction.cancel),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null || action == SelectionAction.cancel) {
      return;
    }

    if (action == SelectionAction.delete) {
      final selected = _selectedItems;
      await widget.repository.deleteItems(selected);
      await widget.onFetchLists();
      _clearSelection();
      return;
    }

    if (action == SelectionAction.move) {
      await _showMoveSelectedItemsDialog();
    }
  }

  Future<void> _showMoveSelectedItemsDialog() async {
    final selected = _selectedItems;
    if (selected.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final currentListId = widget.repository.listId;
    final candidateLists = widget.lists
        .where((list) => list['id']?.toString() != currentListId)
        .toList(growable: false);

    if (candidateLists.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.groceryNoOtherListAvailable)),
      );
      return;
    }

    final targetListId = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.grocerySelectDestinationList,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              ...candidateLists.map((list) {
                final id = list['id']?.toString() ?? '';
                final name = list['name']?.toString() ?? l10n.groceryDefaultListName;
                return ListTile(
                  leading: const Icon(Icons.list_alt_outlined),
                  title: Text(name),
                  onTap: () => Navigator.of(context).pop(id),
                );
              }),
            ],
          ),
        );
      },
    );

    if (targetListId == null || targetListId.isEmpty) return;

    await widget.repository.moveItemsToList(selected, targetListId);
    await widget.onFetchLists();
    _clearSelection();
  }

  Future<void> _showEditModal(GroceryItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Let the sheet set its own background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: GroceryEditSheet(
            item: item,
            onSave: (editedItem, newName, quantity) async {
              await widget.repository.updateItemDetails(
                editedItem,
                newName,
                quantity,
                locale: _locale,
              );
              if (mounted) {
                await widget.onFetchLists();
              }
            },
            onDelete: (itemToDelete) async {
              await _deleteItem(itemToDelete);
            },
          ),
        );
      },
    );
  }

  Map<String, List<GroceryItem>> _groupItems(List<GroceryItem> items) {
    final grouped = <String, List<GroceryItem>>{};
    for (final item in items) {
      final key = CategoryUtils.categoryKeyFromRaw(item.category);
      grouped.putIfAbsent(key, () => <GroceryItem>[]).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listName = widget.lists
        .firstWhere(
          (list) => list['id']?.toString() == widget.repository.listId,
          orElse: () => <String, dynamic>{'name': l10n.groceryDefaultListName},
        )['name']
        ?.toString() ??
        l10n.groceryDefaultListName;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _clearSelection();
            widget.onBack();
          },
        ),
        title: _selectionMode
            ? Text(l10n.groceryItemsSelected(_selectedItemIds.length))
            : Text(listName, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: _showSelectionMenu,
            ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelection,
            ),
          if (!_selectionMode)
            PopupMenuButton<DetailedListMenuAction>(
              onSelected: (action) {
                if (action == DetailedListMenuAction.delete) {
                  final currentListId = widget.repository.listId;
                  if (currentListId == null) return;
                  widget.onDeleteList(listId: currentListId, listName: listName);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<DetailedListMenuAction>(
                  value: DetailedListMenuAction.delete,
                  child: Text(l10n.groceryDeleteList),
                ),
              ],
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.repository,
        builder: (context, _) {
          if (widget.repository.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.repository.listId == null) {
            return Center(
              child: Text(
                widget.repository.lastError ?? l10n.groceryCouldNotLoadList,
              ),
            );
          }

          final allItems = widget.repository.items;
          final toBuyItems = allItems.where((item) => !item.isBought).toList(growable: false);
          final boughtItems = allItems.where((item) => item.isBought).toList(growable: false);
          final groupedToBuy = _groupItems(toBuyItems);

          return Column(
            children: [
              if (widget.repository.isSyncing) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    if (groupedToBuy.isEmpty && boughtItems.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Text(
                            l10n.groceryEmptyList,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ...groupedToBuy.entries.map((entry) {
                      final categoryKey = entry.key;
                      final items = entry.value;

                      return SliverMainAxisGroup(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                CategoryUtils.localizedCategoryName(context, categoryKey),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = items[index];
                                  return GroceryItemTile(
                                    item: item,
                                    isBought: false,
                                    isSelected: _selectedItemIds.contains(item.id),
                                    selectionMode: _selectionMode,
                                    onToggle: _toggleItem,
                                    onDelete: _deleteItem,
                                    onLongPress: _startSelection,
                                    onTap: (selectedItem) {
                                      if (_selectionMode) {
                                        _toggleSelection(selectedItem);
                                        return;
                                      }
                                      _showEditModal(selectedItem);
                                    },
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
                                l10n.groceryBoughtItems,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                              TextButton.icon(
                                onPressed: () => _deleteBoughtItems(boughtItems),
                                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                                label: Text(l10n.groceryDeleteAll),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = boughtItems[index];
                              return GroceryItemTile(
                                item: item,
                                isBought: true,
                                isSelected: _selectedItemIds.contains(item.id),
                                selectionMode: _selectionMode,
                                onToggle: _toggleItem,
                                onDelete: _deleteItem,
                                onLongPress: _startSelection,
                                onTap: (selectedItem) {
                                  if (_selectionMode) {
                                    _toggleSelection(selectedItem);
                                    return;
                                  }
                                  _showEditModal(selectedItem);
                                },
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: l10n.groceryAddItem,
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.add, color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
}
