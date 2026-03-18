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

                    return _OverviewListCard(
                      listId: listId,
                      listName: listName,
                      progress: progress,
                      boughtCount: boughtCount,
                      totalCount: totalCount,
                      onListSelected: onListSelected,
                      onRenameList: onRenameList,
                      onDeleteList: onDeleteList,
                      deleteLabel: l10n.groceryDeleteList,
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

class _OverviewListCard extends StatefulWidget {
  const _OverviewListCard({
    required this.listId,
    required this.listName,
    required this.progress,
    required this.boughtCount,
    required this.totalCount,
    required this.onListSelected,
    required this.onRenameList,
    required this.onDeleteList,
    required this.deleteLabel,
  });

  final String listId;
  final String listName;
  final double progress;
  final int boughtCount;
  final int totalCount;
  final ValueChanged<String> onListSelected;
  final Future<void> Function({
    required String listId,
    required String currentName,
  }) onRenameList;
  final void Function({required String listId, required String listName})
      onDeleteList;
  final String deleteLabel;

  @override
  State<_OverviewListCard> createState() => _OverviewListCardState();
}

class _OverviewListCardState extends State<_OverviewListCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      scale: _pressed ? 0.985 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant
                .withValues(alpha: _pressed ? 0.22 : 0.30),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  colorScheme.shadow.withValues(alpha: _pressed ? 0.06 : 0.12),
              blurRadius: _pressed ? 5 : 10,
              spreadRadius: 0,
              offset: Offset(0, _pressed ? 1 : 4),
            ),
            BoxShadow(
              color:
                  colorScheme.shadow.withValues(alpha: _pressed ? 0.00 : 0.05),
              blurRadius: _pressed ? 0 : 2,
              spreadRadius: _pressed ? 0 : 0.5,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Material(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            splashColor: colorScheme.primary.withValues(alpha: 0.16),
            highlightColor: colorScheme.primary.withValues(alpha: 0.10),
            onHighlightChanged: (isPressed) {
              if (_pressed == isPressed) return;
              setState(() {
                _pressed = isPressed;
              });
            },
            onTap: () => widget.onListSelected(widget.listId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.listName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: widget.progress,
                                  minHeight: 8,
                                  backgroundColor: colorScheme.outline,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${widget.boughtCount}/${widget.totalCount}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
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
                        colorScheme.primaryContainer,
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
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                    menuChildren: [
                      MenuItemButton(
                        trailingIcon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          if (widget.listId.isEmpty) return;
                          await widget.onRenameList(
                            listId: widget.listId,
                            currentName: widget.listName,
                          );
                        },
                        child: const Text('Rename list'),
                      ),
                      MenuItemButton(
                        trailingIcon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          widget.onDeleteList(
                            listId: widget.listId,
                            listName: widget.listName,
                          );
                        },
                        child: Text(widget.deleteLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
