import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:homeapp/data/grocery_repository.dart';
import 'package:homeapp/data/local_grocery_store.dart';
import 'package:homeapp/l10n/app_localizations.dart';
import 'package:homeapp/pages/grocery/grocery_overview.dart';
import 'package:homeapp/pages/grocery/grocery_detailed_list.dart';

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

  Future<void> _showDeleteListDialog({required String listId, required String listName}) async {
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

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _showingOverview
          ? GroceryOverview(
              lists: _lists,
              loadingLists: _loadingLists,
              onListSelected: (listId) async {
                await _repository.setActiveList(listId);
                if (!mounted) return;
                setState(() => _showingOverview = false);
              },
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
              onDeleteList: _showDeleteListDialog,
            ),
    );
  }
}
