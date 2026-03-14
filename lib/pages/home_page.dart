import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'home_tab.dart';
import 'grocery_tab.dart'; // Import the new tab
import 'settings_tab.dart';
import 'package:homeapp/l10n/app_localizations.dart';

@NowaGenerated()
class HomePage extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            const HomeTab(),
            const GroceryTab(),
            const Center(child: Text('Chore Tab')),
            const Center(child: Text('Finance Tab')),
            const SettingsTab(),
          ],
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
