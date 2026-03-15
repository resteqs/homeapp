import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:homeapp/l10n/app_localizations.dart';
import 'package:homeapp/globals/app_state.dart';
import 'package:homeapp/utils/category_utils.dart';

/// Settings tab for language, attribution, and sign-out actions.
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    if (_isSigningOut) return;

    setState(() => _isSigningOut = true);
    try {
      // Router listens to auth state and will redirect back to auth screen.
      await Supabase.instance.client.auth.signOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .authSignoutError(error.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final l10n = AppLocalizations.of(context)!;
    final categoryOrder = appState.categoryOrder;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text(
            l10n.settingsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.settingsLanguage, style: const TextStyle(fontSize: 16)),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'en', label: Text(l10n.langEnglish)),
                  ButtonSegment(value: 'de', label: Text(l10n.langGerman)),
                ],
                selected: {appState.locale.languageCode},
                onSelectionChanged: (Set<String> newSelection) {
                  AppState.of(context, listen: false)
                      .setLocale(Locale(newSelection.first));
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.settingsGroceryCategoryOrder,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsGroceryCategoryOrderHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          ReorderableListView.builder(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryOrder.length,
            onReorder: (oldIndex, newIndex) {
              final nextOrder = List<String>.from(categoryOrder);
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }

              final movedCategory = nextOrder.removeAt(oldIndex);
              nextOrder.insert(newIndex, movedCategory);
              AppState.of(context, listen: false).setCategoryOrder(nextOrder);
            },
            itemBuilder: (context, index) {
              final categoryKey = categoryOrder[index];
              final categoryVisual = CategoryUtils.getCategoryVisual(categoryKey);

              return Card(
                key: ValueKey(categoryKey),
                margin: EdgeInsets.only(
                  bottom: index == categoryOrder.length - 1 ? 0 : 8,
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor:
                        categoryVisual.color.withValues(alpha: 0.18),
                    child: FaIcon(
                      categoryVisual.icon,
                      size: 16,
                      color: categoryVisual.color,
                    ),
                  ),
                  title: Text(
                    CategoryUtils.localizedCategoryName(context, categoryKey),
                  ),
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          ListTile(
            title: Text(l10n.settingsAttributions),
            leading: const Icon(Icons.info_outline),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.settingsAttributions),
                  content: const SelectableText(
                    'Icons by Icons8 (https://icons8.com)',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isSigningOut ? null : _signOut,
            icon: const Icon(Icons.logout),
            label: Text(
              _isSigningOut ? l10n.settingsLoggingOut : l10n.settingsLogout,
            ),
          ),
        ],
      ),
    );
  }
}
