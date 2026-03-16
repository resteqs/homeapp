import 'package:flutter/material.dart';
import 'package:homeapp/l10n/app_localizations.dart';

enum ListMenuAction { rename, delete }

/// Overview screen listing all grocery lists and completion progress.
class GroceryOverview extends StatelessWidget {
  final List<Map<String, dynamic>> lists;
  final bool loadingLists;
  final ValueChanged<String> onListSelected;
  final Future<void> Function({
    required String listId,
    required String currentName,
  }) onRenameList;
  final Future<void> Function() onCreateList;
  final void Function({required String listId, required String listName})
      onDeleteList;

  const GroceryOverview({
    super.key,
    required this.lists,
    required this.loadingLists,
    required this.onListSelected,
    required this.onRenameList,
    required this.onCreateList,
    required this.onDeleteList,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groceryMyLists),
      ),
      body: loadingLists
          ? const Center(child: CircularProgressIndicator())
          : lists.isEmpty
              ? Center(child: Text(l10n.groceryNoLists))
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final list = lists[index];
                    final listId = list['id']?.toString() ?? '';
                    final listName =
                        list['name']?.toString() ?? l10n.groceryDefaultListName;

                    final rawItems =
                        list['grocery_list_items'] as List<dynamic>? ??
                            <dynamic>[];
                    final items = rawItems
                        .where((row) => row['deleted_at'] == null)
                        .toList();
                    final totalCount = items.length;
                    final boughtCount =
                        items.where((row) => row['is_bought'] == true).length;
                    final progress =
                        totalCount > 0 ? boughtCount / totalCount : 0.0;

                    return Card(
                      elevation: 1,
                      shadowColor: Theme.of(context)
                          .colorScheme
                          .shadow
                          .withValues(alpha: 0.1),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onListSelected(listId),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      listName,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 8,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primary),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          '$boughtCount/$totalCount',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              MenuAnchor(
                                alignmentOffset: const Offset(-24, 0),
                                style: MenuStyle(
                                  shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  backgroundColor: WidgetStatePropertyAll(
                                    Theme.of(context).colorScheme.primaryContainer,
                                  ),
                                ),
                                builder: (context, controller, child) {
                                  return IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      if (controller.isOpen) {
                                        controller.close();
                                      } else {
                                        controller.open();
                                      }
                                    },
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  );
                                },
                                menuChildren: [
                                  MenuItemButton(
                                    trailingIcon: const Icon(Icons.edit_outlined),
                                    onPressed: () async {
                                      if (listId.isEmpty) return;
                                      await onRenameList(
                                        listId: listId,
                                        currentName: listName,
                                      );
                                    },
                                    child: const Text('Rename list'),
                                  ),
                                  MenuItemButton(
                                    trailingIcon: const Icon(Icons.delete_outline),
                                    onPressed: () {
                                      onDeleteList(
                                          listId: listId, listName: listName);
                                    },
                                    child: Text(l10n.groceryDeleteList),
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
        onPressed: onCreateList,
        icon: const Icon(Icons.add),
        label: const Text('New list'),
      ),
    );
  }
}
