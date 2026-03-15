import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:homeapp/l10n/app_localizations.dart';
import 'package:homeapp/globals/app_state.dart';

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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.settingsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.settingsLanguage,
                  style: const TextStyle(fontSize: 16)),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                      value: 'en',
                      label: Text(AppLocalizations.of(context)!.langEnglish)),
                  ButtonSegment(
                      value: 'de',
                      label: Text(AppLocalizations.of(context)!.langGerman)),
                ],
                selected: {AppState.of(context).locale.languageCode},
                onSelectionChanged: (Set<String> newSelection) {
                  AppState.of(context, listen: false)
                      .setLocale(Locale(newSelection.first));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsAttributions),
            leading: const Icon(Icons.info_outline),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title:
                      Text(AppLocalizations.of(context)!.settingsAttributions),
                  content: const SelectableText(
                      'Icons by Icons8 (https://icons8.com)'),
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
            label: Text(_isSigningOut
                ? AppLocalizations.of(context)!.settingsLoggingOut
                : AppLocalizations.of(context)!.settingsLogout),
          ),
        ],
      ),
    );
  }
}
