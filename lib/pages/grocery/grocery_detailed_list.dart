import 'package:flutter/material.dart';
import 'package:homeapp/globals/themes.dart';
import 'package:homeapp/l10n/app_localizations.dart';
import 'package:homeapp/models/grocery_item.dart';
import 'package:homeapp/data/grocery_repository.dart';
import 'package:homeapp/pages/grocery/widgets/grocery_item_tile.dart';
import 'package:homeapp/pages/grocery/widgets/grocery_edit_sheet.dart';
import 'package:homeapp/pages/grocery/widgets/grocery_add_product_sheet.dart';

enum SelectionAction { delete, move, cancel }

enum DetailedListMenuAction { rename, add, delete }

enum BoughtItemsAction { deleteAll }

/// Detailed grocery list screen with grouping, editing, and batch actions.
class GroceryDetailedList extends StatefulWidget {
  final List<Map<String, dynamic>> lists;
  final GroceryRepository repository;
  final VoidCallback onBack;
  final Future<void> Function() onFetchLists;
  final Future<void> Function() onCreateList;
  final Future<void> Function({
    required String listId,
    required String currentName,
  }) onRenameList;
  final void Function({required String listId, required String listName})
      onDeleteList;

  const GroceryDetailedList({
    super.key,
    required this.lists,
    required this.repository,
    required this.onBack,
    required this.onFetchLists,
    required this.onCreateList,
    required this.onRenameList,
    required this.onDeleteList,
  });

  @override
  State<GroceryDetailedList> createState() => _GroceryDetailedListState();
}

class _GroceryDetailedListState extends State<GroceryDetailedList> {
  bool _selectionMode = false;
  final Set<String> _selectedItemIds = <String>{};

  @override
  void dispose() {
    super.dispose();
  }

  String get _locale {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode.isNotEmpty ? languageCode : 'en';
  }

  Future<void> _toggleItem(GroceryItem item) async {
    await widget.repository.toggleItem(item);
  }

  Future<void> _deleteItem(GroceryItem item) async {
    await widget.repository.deleteItem(item);
  }

  Future<void> _deleteBoughtItems(List<GroceryItem> boughtItems) async {
    if (boughtItems.isEmpty) return;
    await widget.repository.deleteItems(boughtItems);
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
                final name =
                    list['name']?.toString() ?? l10n.groceryDefaultListName;
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
    _clearSelection();
  }

  Future<void> _showEditModal(GroceryItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          AppColors.transparent, // Let the sheet set its own background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: GroceryEditSheet(
            item: item,
            onSave: (editedItem, newName, quantity, unit, notes, badgeEmoji) async {
              await widget.repository.updateItemDetails(
                editedItem,
                newName,
                quantity,
                unit,
                notes,
                badgeEmoji,
                locale: _locale,
              );
            },
            onDelete: (itemToDelete) async {
              await _deleteItem(itemToDelete);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listName = widget.lists
            .firstWhere(
              (list) => list['id']?.toString() == widget.repository.listId,
              orElse: () =>
                  <String, dynamic>{'name': l10n.groceryDefaultListName},
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
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final currentListId = widget.repository.listId;
                  if (currentListId == null) return;
                  await widget.onRenameList(
                    listId: currentListId,
                    currentName: listName,
                  );
                },
                child: Text(
                  listName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
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
              onSelected: (action) async {
                if (action == DetailedListMenuAction.rename) {
                  final currentListId = widget.repository.listId;
                  if (currentListId == null) return;
                  await widget.onRenameList(
                    listId: currentListId,
                    currentName: listName,
                  );
                  return;
                }
                if (action == DetailedListMenuAction.add) {
                  await widget.onCreateList();
                  return;
                }
                if (action == DetailedListMenuAction.delete) {
                  final currentListId = widget.repository.listId;
                  if (currentListId == null) return;
                  widget.onDeleteList(
                      listId: currentListId, listName: listName);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<DetailedListMenuAction>(
                  value: DetailedListMenuAction.rename,
                  child: Text('Rename list'),
                ),
                const PopupMenuItem<DetailedListMenuAction>(
                  value: DetailedListMenuAction.add,
                  child: Text('New list'),
                ),
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
          final toBuyItems =
              allItems.where((item) => !item.isBought).toList(growable: false);
          final boughtItems =
              allItems.where((item) => item.isBought).toList(growable: false);

          return Column(
            children: [
              if (widget.repository.isSyncing)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    if (toBuyItems.isEmpty && boughtItems.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Text(
                            l10n.groceryEmptyList,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    if (toBuyItems.isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = toBuyItems[index];
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
                          childCount: toBuyItems.length,
                        ),
                      ),
                    if (boughtItems.isNotEmpty) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '(${boughtItems.length}) ${l10n.groceryBoughtItems}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                PopupMenuButton<BoughtItemsAction>(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    size: 20,
                                  ),
                                  onSelected: (action) async {
                                    if (action == BoughtItemsAction.deleteAll) {
                                      await _deleteBoughtItems(boughtItems);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem<BoughtItemsAction>(
                                      value: BoughtItemsAction.deleteAll,
                                      child: Text(l10n.groceryDeleteAll),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverList(
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
                    ],
                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => GroceryAddProductSheet(
              repository: widget.repository,
              locale: _locale,
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.groceryAddProduct),
      ),
    );
  }
}
