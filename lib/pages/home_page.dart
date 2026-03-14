import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'home_tab.dart';
import 'grocery_tab.dart'; // Import the new tab
import 'settings_tab.dart';

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
      appBar: AppBar(title: const Text('Home Page')),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_grocery_store),
            label: 'Grocery',
          ),
          NavigationDestination(
            icon: Icon(Icons.cleaning_services),
            label: 'Chore',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money),
            label: 'Finance',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
