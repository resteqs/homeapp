import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:homeapp/globals/transitions.dart';
import 'home_tab.dart';
import 'grocery_tab.dart';
import 'settings_tab.dart';
import 'package:homeapp/l10n/app_localizations.dart';

/// Top-level authenticated shell with bottom navigation.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Manages the selected tab index for [HomePage].
class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 420),
          transitionBuilder: zoomFadeTransitionBuilder,
          child: switch (_currentIndex) {
            0 => const HomeTab(),
            1 => const GroceryTab(),
            2 => const Center(child: Text('Chore Tab')),
            3 => const Center(child: Text('Finance Tab')),
            4 => const SettingsTab(),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_grocery_store),
            label: AppLocalizations.of(context)!.navGrocery,
          ),
          NavigationDestination(
            icon: const Icon(Icons.cleaning_services),
            label: AppLocalizations.of(context)!.navChore,
          ),
          NavigationDestination(
            icon: const Icon(Icons.attach_money),
            label: AppLocalizations.of(context)!.navFinance,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.navSettings,
          ),
        ],
      ),
    );
  }
}
