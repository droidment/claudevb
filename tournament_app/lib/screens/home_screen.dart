import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import 'tournaments/organize_screen.dart';
import 'tournaments/tournaments_list_screen.dart';
import 'tournaments/join_by_invite_screen.dart';
import 'teams/teams_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getCurrentUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  List<NavigationDestination> _getNavigationDestinations() {
    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
      const NavigationDestination(
        icon: Icon(Icons.emoji_events),
        label: 'Tournaments',
      ),
    ];

    if (_userProfile?.isCaptain == true) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.groups),
          label: 'My Teams',
        ),
      );
    }

    if (_userProfile?.isOrganizer == true) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Organize',
        ),
      );
    }

    destinations.add(
      const NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
    );

    return destinations;
  }

  Widget _getSelectedScreen() {
    final destinations = _getNavigationDestinations();
    final selectedLabel = destinations[_selectedIndex].label;

    switch (selectedLabel) {
      case 'Home':
        return _buildHomeContent();
      case 'Tournaments':
        return _buildTournamentsContent();
      case 'My Teams':
        return _buildMyTeamsContent();
      case 'Organize':
        return _buildOrganizeContent();
      case 'Profile':
        return _buildProfileContent();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_volleyball, size: 100, color: Colors.blue),
          const SizedBox(height: 24),
          Text(
            'Welcome, ${_userProfile?.fullName ?? 'User'}!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _userProfile?.role == 'captain'
                ? 'Team Captain'
                : _userProfile?.role == 'organizer'
                ? 'Tournament Organizer'
                : 'User',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 48),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: Colors.orange.shade50,
            child: ListTile(
              leading: Icon(Icons.vpn_key, color: Colors.orange.shade700),
              title: const Text(
                'Join Private Tournament',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Have an invite code? Join here'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const JoinByInviteScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (_userProfile?.isCaptain == true) ...[
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: ListTile(
                leading: const Icon(Icons.groups),
                title: const Text('Manage Teams'),
                subtitle: const Text('Create and manage your teams'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  setState(() => _selectedIndex = 2);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_userProfile?.isOrganizer == true) ...[
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: ListTile(
                leading: const Icon(Icons.add_circle),
                title: const Text('Create Tournament'),
                subtitle: const Text('Organize a new tournament'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  final organizerIndex = _getNavigationDestinations()
                      .indexWhere((d) => d.label == 'Organize');
                  if (organizerIndex != -1) {
                    setState(() => _selectedIndex = organizerIndex);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTournamentsContent() {
    return const TournamentsListScreen();
  }

  Widget _buildMyTeamsContent() {
    return const TeamsListScreen();
  }

  Widget _buildOrganizeContent() {
    return const OrganizeScreen();
  }

  Widget _buildProfileContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Text(
              _userProfile?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(fontSize: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _userProfile?.fullName ?? 'User',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _userProfile?.email ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(
              _userProfile?.role == 'captain'
                  ? 'Team Captain'
                  : _userProfile?.role == 'organizer'
                  ? 'Tournament Organizer'
                  : 'User',
            ),
          ),
          if (_userProfile?.phone != null) ...[
            const SizedBox(height: 16),
            Text(
              _userProfile!.phone!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Scheduler'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _getSelectedScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: _getNavigationDestinations(),
      ),
    );
  }
}
