import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:homeapp/data/grocery_repository.dart';
import 'package:homeapp/data/local_grocery_store.dart';
import 'package:homeapp/l10n/app_localizations.dart';
import 'package:homeapp/pages/grocery/grocery_overview.dart';
import 'package:homeapp/pages/grocery/grocery_detailed_list.dart';
import 'package:animations/animations.dart';
import 'package:homeapp/globals/transitions.dart';

/// Grocery feature host widget.
///
/// Owns one repository instance and switches between overview and detailed list
/// views.
class GroceryTab extends StatefulWidget {
  const GroceryTab({super.key});

  @override
  State<GroceryTab> createState() => _GroceryTabState();
}

class _GroceryTabState extends State<GroceryTab> {
  late final GroceryRepository _repository;

  bool _showingOverview = true;
  bool _loadingLists = true;
  List<Map<String, dynamic>> _lists = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _repository = GroceryRepository(
      supabase: Supabase.instance.client,
      localStore: LocalGroceryStore(),
    )..init();
    _fetchLists();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  Future<void> _fetchLists() async {
    if (mounted) {
      setState(() {
        _loadingLists = true;
      });
    }

    try {
      final lists = await _repository.fetchGroceryLists();
      if (!mounted) return;
      setState(() {
        _lists = lists;
      });
    } catch (_) {
      // Keep existing list state on fetch failures.
    } finally {
      if (mounted) {
        setState(() {
          _loadingLists = false;
        });
      }
    }
  }

  Future<void> _showDeleteListDialog(
      {required String listId, required String listName}) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.groceryDeleteListQuestion),
          content: Text(
            l10n.groceryDeleteListWarning(listName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.groceryCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.groceryDelete),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final activeListId = _repository.listId;
    await _repository.deleteList(listId);
    await _fetchLists();

    if (!mounted) return;

    final deletedActiveList = activeListId == listId;
    if (deletedActiveList) {
      if (_lists.isNotEmpty) {
        await _repository.setActiveList(_lists.first['id'].toString());
      }
      setState(() {
        _showingOverview = true;
      });
    }
  }

  Future<String?> _promptForListName({
    required String title,
    required String actionLabel,
    String initialValue = '',
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        var draftName = initialValue;
        return AlertDialog(
          title: Text(title),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return TextFormField(
                initialValue: initialValue,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  setStateDialog(() {
                    draftName = value;
                  });
                },
                onFieldSubmitted: (value) =>
                    Navigator.of(context).pop(value.trim()),
                decoration: const InputDecoration(
                  hintText: 'List name',
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(draftName.trim()),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
    return result?.trim();
  }

  Future<void> _showCreateListDialog() async {
    final name = await _promptForListName(
      title: 'Create new list',
      actionLabel: 'Create',
    );
    if (name == null || name.isEmpty) return;

    try {
      final created = await _repository.createList(name);
      await _fetchLists();
      final createdId = created['id']?.toString();
      if (createdId != null && createdId.isNotEmpty) {
        await _repository.setActiveList(createdId);
      }
      if (!mounted) return;
      setState(() {
        _showingOverview = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create list: $error')),
      );
    }
  }

  Future<void> _showRenameListDialog({
    required String listId,
    required String currentName,
  }) async {
    final name = await _promptForListName(
      title: 'Rename list',
      actionLabel: 'Save',
      initialValue: currentName,
    );
    if (name == null || name.isEmpty || name == currentName) return;

    try {
      await _repository.renameList(listId, name);
      await _fetchLists();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not rename list.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 420),
      reverse: _showingOverview,
      transitionBuilder: zoomFadeTransitionBuilder,
      child: _showingOverview
          ? GroceryOverview(
              lists: _lists,
              loadingLists: _loadingLists,
              onListSelected: (listId) async {
                await _repository.setActiveList(listId);
                if (!mounted) return;
                setState(() => _showingOverview = false);
              },
              onRenameList: _showRenameListDialog,
              onCreateList: _showCreateListDialog,
              onDeleteList: _showDeleteListDialog,
            )
          : GroceryDetailedList(
              lists: _lists,
              repository: _repository,
              onBack: () {
                _fetchLists();
                setState(() => _showingOverview = true);
              },
              onFetchLists: _fetchLists,
              onCreateList: _showCreateListDialog,
              onRenameList: _showRenameListDialog,
              onDeleteList: _showDeleteListDialog,
            ),
    );
  }
}
