import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:homeapp/globals/app_state.dart';
import 'package:homeapp/main.dart';
import 'grocery_tab.dart';
import 'settings_tab.dart';

/// Top-level authenticated shell with tile-based home dashboard.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loadingFamily = true;
  String? _familyName;
  String? _error;
  List<_FamilyMember> _familyMembers = const [];
  String _userInitials = 'U';
  String _userDisplayName = 'User';
  String _userEmail = '';

  bool _isEditingTiles = false;
  late final AnimationController _jiggleController;

  static const String _tileOrderPrefKey = 'homeDashboardTileOrder';

  static const List<_DashboardTileConfig> _availableTiles = [
    _DashboardTileConfig(
      key: _DashboardTile.groceries,
      title: 'Groceries',
      subtitle: 'Manage your shopping lists',
      icon: Icons.local_grocery_store,
      iconColor: Color(0xFF40C4FF),
    ),
    _DashboardTileConfig(
      key: _DashboardTile.finance,
      title: 'Finance',
      subtitle: 'Track family budgets',
      icon: Icons.account_balance_wallet_outlined,
      iconColor: Color(0xFF34D399),
    ),
    _DashboardTileConfig(
      key: _DashboardTile.chores,
      title: 'Chores',
      subtitle: 'Organize tasks and routines',
      icon: Icons.cleaning_services_outlined,
      iconColor: Color(0xFFF59E0B),
    ),
    _DashboardTileConfig(
      key: _DashboardTile.notes,
      title: 'Notes',
      subtitle: 'Capture shared notes quickly',
      icon: Icons.sticky_note_2_outlined,
      iconColor: Color(0xFF818CF8),
    ),
  ];

  late List<_DashboardTileConfig> _tileOrder;

  @override
  void initState() {
    super.initState();
    _tileOrder = _loadTileOrder();
    _jiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _loadFamilyContext();
  }

  @override
  void dispose() {
    _jiggleController.dispose();
    super.dispose();
  }

  List<_DashboardTileConfig> _loadTileOrder() {
    final saved = sharedPrefs.getStringList(_tileOrderPrefKey) ?? const [];
    final byKey = {
      for (final tile in _availableTiles) tile.key.name: tile,
    };

    final ordered = <_DashboardTileConfig>[];
    for (final key in saved) {
      final tile = byKey.remove(key);
      if (tile != null) {
        ordered.add(tile);
      }
    }

    ordered.addAll(byKey.values);
    return ordered;
  }

  Future<void> _saveTileOrder() async {
    await sharedPrefs.setStringList(
      _tileOrderPrefKey,
      _tileOrder.map((tile) => tile.key.name).toList(growable: false),
    );
  }

  void _startEditingTiles() {
    setState(() {
      _isEditingTiles = true;
      _jiggleController.repeat(reverse: true);
    });
  }

  void _stopEditingTiles() {
    setState(() {
      _isEditingTiles = false;
      _jiggleController.stop();
      _jiggleController.reset();
    });
    _saveTileOrder();
  }

  void _moveTile(_DashboardTile draggedKey, int targetIndex) {
    final fromIndex = _tileOrder.indexWhere((tile) => tile.key == draggedKey);
    if (fromIndex == -1 || fromIndex == targetIndex) return;

    final next = List<_DashboardTileConfig>.from(_tileOrder);
    final moved = next.removeAt(fromIndex);

    int insertIndex = targetIndex;
    if (fromIndex < targetIndex) {
      insertIndex -= 1;
    }
    next.insert(insertIndex, moved);

    setState(() {
      _tileOrder = next;
    });
  }

  Future<void> _loadFamilyContext() async {
    try {
      final user = _supabase.auth.currentUser;
      final userId = user?.id;
      if (userId == null) {
        throw StateError('No signed in user.');
      }

      final profile = await _supabase
          .from('profiles')
          .select('id,first_name,last_name')
          .eq('id', userId)
          .maybeSingle();

      final membership = await _supabase
          .from('household_members')
          .select('household_id')
          .eq('user_id', userId)
          .maybeSingle();

      final householdId = membership?['household_id']?.toString();
      String resolvedFamilyName = 'My Family';
      List<_FamilyMember> resolvedMembers = const [];

      if (householdId != null && householdId.isNotEmpty) {
        final household = await _supabase
            .from('households')
            .select('name')
            .eq('id', householdId)
            .maybeSingle();

        final householdName = household?['name']?.toString().trim();
        if (householdName != null && householdName.isNotEmpty) {
          resolvedFamilyName = householdName;
        }

        final membersRaw = await _supabase
            .from('household_members')
            .select('user_id')
            .eq('household_id', householdId);

        final memberIds = membersRaw
            .map((entry) => entry['user_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList(growable: false);

        if (memberIds.isNotEmpty) {
          final profilesRaw = await _supabase
              .from('profiles')
              .select('id,first_name,last_name')
              .inFilter('id', memberIds);

          final profileById = <String, Map<String, dynamic>>{
            for (final entry in profilesRaw)
              entry['id']?.toString() ?? '':
                  Map<String, dynamic>.from(entry as Map),
          };

          resolvedMembers = memberIds.map((memberId) {
            final memberProfile = profileById[memberId];
            final firstName =
                memberProfile?['first_name']?.toString().trim() ?? '';
            final lastName =
                memberProfile?['last_name']?.toString().trim() ?? '';
            final fullName = [firstName, lastName]
                .where((part) => part.isNotEmpty)
                .join(' ');
            return _FamilyMember(
              id: memberId,
              displayName: fullName.isEmpty ? 'Member' : fullName,
            );
          }).toList(growable: false);
        }
      }

      final initials = _buildInitials(
        firstName: profile?['first_name']?.toString(),
        lastName: profile?['last_name']?.toString(),
        email: user?.email,
      );
      final firstName = profile?['first_name']?.toString().trim() ?? '';
      final lastName = profile?['last_name']?.toString().trim() ?? '';
      final fullName =
          [firstName, lastName].where((part) => part.isNotEmpty).join(' ');

      if (!mounted) return;
      setState(() {
        _familyName = resolvedFamilyName;
        _familyMembers = resolvedMembers;
        _userInitials = initials;
        _userDisplayName = fullName.isEmpty ? 'User' : fullName;
        _userEmail = user?.email ?? '';
        _loadingFamily = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingFamily = false;
        _error = error.toString();
      });
    }
  }

  String _buildInitials({
    required String? firstName,
    required String? lastName,
    required String? email,
  }) {
    final first = (firstName ?? '').trim();
    final last = (lastName ?? '').trim();
    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    if (first.isNotEmpty) {
      return first.substring(0, first.length >= 2 ? 2 : 1).toUpperCase();
    }
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'U';
  }

  Future<void> _openFamilyMembersMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final members = _familyMembers;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _familyName ?? 'My Family',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (members.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'No members yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  ...members.map(
                    (member) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(
                          member.initials,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(member.displayName),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Add user flow is not implemented yet.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add user'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSettingsScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: const SafeArea(child: SettingsTab()),
          );
        },
      ),
    );
  }

  Future<void> _showThemeMenu() async {
    final appState = AppState.of(context, listen: false);
    ThemeMode selected = appState.themeMode;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {selected},
                      onSelectionChanged: (newSelection) {
                        final next = newSelection.first;
                        setModalState(() => selected = next);
                        appState.setThemeMode(next);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showLanguageMenu() async {
    final appState = AppState.of(context, listen: false);
    String selected = appState.locale.languageCode;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Language',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'en', label: Text('English')),
                        ButtonSegment(value: 'de', label: Text('Deutsch')),
                      ],
                      selected: {selected},
                      onSelectionChanged: (newSelection) {
                        final next = newSelection.first;
                        setModalState(() => selected = next);
                        appState.setLocale(Locale(next));
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showAttributionsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Attributions'),
          content: const SelectableText(
            'Icons by Icons8 (https://icons8.com)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not sign out: $error')),
      );
    }
  }

  Future<void> _openAccountMenu() async {
    final action = await Navigator.of(context).push<_AccountMenuAction>(
      MaterialPageRoute<_AccountMenuAction>(
        builder: (context) => _AccountMenuScreen(
          initials: _userInitials,
          displayName: _userDisplayName,
          email: _userEmail,
          themeMode: AppState.of(context).themeMode,
          languageCode: AppState.of(context).locale.languageCode,
        ),
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _AccountMenuAction.homeTileOrder:
        _startEditingTiles();
      case _AccountMenuAction.theme:
        await _showThemeMenu();
      case _AccountMenuAction.language:
        await _showLanguageMenu();
      case _AccountMenuAction.groceryCategoryOrder:
        await _openSettingsScreen();
      case _AccountMenuAction.attributions:
        await _showAttributionsDialog();
      case _AccountMenuAction.signOut:
        await _signOut();
    }
  }

  Future<void> _openFeature(_DashboardTile tile) async {
    switch (tile) {
      case _DashboardTile.groceries:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const Scaffold(
              body: SafeArea(child: GroceryTab()),
            ),
          ),
        );
      case _DashboardTile.finance:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const _PlaceholderFeatureScreen(
              title: 'Finance',
            ),
          ),
        );
      case _DashboardTile.chores:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const _PlaceholderFeatureScreen(
              title: 'Chores',
            ),
          ),
        );
      case _DashboardTile.notes:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const _PlaceholderFeatureScreen(
              title: 'Notes',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyName = (_familyName == null || _familyName!.trim().isEmpty)
        ? 'My Family'
        : _familyName!.trim();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      textStyle: Theme.of(context).textTheme.headlineSmall,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: _openFamilyMembersMenu,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    label: Text(
                      familyName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  if (_isEditingTiles)
                    FilledButton(
                      onPressed: _stopEditingTiles,
                      child: const Text('Done'),
                    )
                  else
                    InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _openAccountMenu,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          _userInitials,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loadingFamily) const LinearProgressIndicator(),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  itemCount: _tileOrder.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.12,
                  ),
                  itemBuilder: (context, index) {
                    final tile = _tileOrder[index];
                    final phase = index.isEven ? 1.0 : -1.0;
                    final screenWidth = MediaQuery.sizeOf(context).width;
                    const horizontalPadding = 32.0;
                    const spacing = 14.0;
                    final tileWidth =
                        (screenWidth - horizontalPadding - spacing) / 2;

                    return DragTarget<_DashboardTile>(
                      onWillAcceptWithDetails: (details) =>
                          details.data != tile.key,
                      onAcceptWithDetails: (details) {
                        _moveTile(details.data, index);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final highlighted = candidateData.isNotEmpty;
                        final card = _DashboardTileCard(
                          config: tile,
                          isEditing: _isEditingTiles,
                          highlighted: highlighted,
                          onTap: _isEditingTiles
                              ? null
                              : () => _openFeature(tile.key),
                          onLongPress:
                              _isEditingTiles ? null : _startEditingTiles,
                        );

                        if (!_isEditingTiles) {
                          return card;
                        }

                        return Draggable<_DashboardTile>(
                          data: tile.key,
                          feedback: SizedBox(
                            width: tileWidth,
                            height: tileWidth / 1.12,
                            child: Material(
                              color: Colors.transparent,
                              child: _DashboardTileCard(
                                config: tile,
                                isEditing: true,
                                highlighted: true,
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.28,
                            child: _DashboardTileCard(
                              config: tile,
                              isEditing: true,
                            ),
                          ),
                          child: AnimatedBuilder(
                            animation: _jiggleController,
                            builder: (context, child) {
                              final value = (_jiggleController.value - 0.5) * 2;
                              final angle = value * 0.012 * phase;
                              return Transform.rotate(
                                angle: angle,
                                child: child,
                              );
                            },
                            child: card,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTileCard extends StatelessWidget {
  const _DashboardTileCard({
    required this.config,
    this.onTap,
    this.onLongPress,
    this.isEditing = false,
    this.highlighted = false,
  });

  final _DashboardTileConfig config;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isEditing;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: highlighted
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: highlighted
            ? BorderSide(
                color: colorScheme.primary,
                width: 1.5,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                config.subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isEditing)
                    Icon(
                      Icons.drag_indicator,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  const Spacer(),
                  Icon(
                    config.icon,
                    size: 40,
                    color: config.iconColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderFeatureScreen extends StatelessWidget {
  const _PlaceholderFeatureScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title is coming soon.'),
      ),
    );
  }
}

enum _DashboardTile {
  groceries,
  finance,
  chores,
  notes,
}

class _DashboardTileConfig {
  const _DashboardTileConfig({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  final _DashboardTile key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
}

enum _AccountMenuAction {
  homeTileOrder,
  theme,
  language,
  groceryCategoryOrder,
  attributions,
  signOut,
}

class _AccountMenuScreen extends StatelessWidget {
  const _AccountMenuScreen({
    required this.initials,
    required this.displayName,
    required this.email,
    required this.themeMode,
    required this.languageCode,
  });

  final String initials;
  final String displayName;
  final String email;
  final ThemeMode themeMode;
  final String languageCode;

  String get themeLabel {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  child: Text(
                    initials,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email.isEmpty ? 'No email available' : email,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.grid_view_rounded),
            title: const Text('Home Tile Order'),
            subtitle: const Text('Drag to reorder dashboard modules'),
            onTap: () =>
                Navigator.of(context).pop(_AccountMenuAction.homeTileOrder),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(themeLabel),
            onTap: () => Navigator.of(context).pop(_AccountMenuAction.theme),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(languageCode.toUpperCase()),
            onTap: () => Navigator.of(context).pop(_AccountMenuAction.language),
          ),
          ListTile(
            leading: const Icon(Icons.grid_view_rounded),
            title: const Text('Grocery Category Order'),
            subtitle: const Text('Reorder grocery categories'),
            onTap: () => Navigator.of(
              context,
            ).pop(_AccountMenuAction.groceryCategoryOrder),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Attributions'),
            onTap: () =>
                Navigator.of(context).pop(_AccountMenuAction.attributions),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.tonalIcon(
              onPressed: () =>
                  Navigator.of(context).pop(_AccountMenuAction.signOut),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyMember {
  const _FamilyMember({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;

  String get initials {
    final parts = displayName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'M';
    if (parts.length == 1) {
      final value = parts.first.trim();
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
