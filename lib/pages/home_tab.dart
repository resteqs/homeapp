import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple profile summary tab for the authenticated user.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      // Bootstrap first so profile/household records are guaranteed.
      await _supabase.rpc('ensure_user_household_and_default_lists');
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw StateError('No signed in user.');
      }

      final result = await _supabase
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _profile = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Logged In User',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text('Username: ${_profile?['username'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('Email: ${user?.email ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('User ID: ${user?.id ?? 'Unknown'}'),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Profile load error: $_error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
