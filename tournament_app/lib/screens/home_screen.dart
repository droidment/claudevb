import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/auth_service.dart';
import '../services/match_service.dart';
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
  final _matchService = MatchService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  int _selectedIndex = 0;
  Map<String, dynamic>? _upcomingMatch;
  List<Map<String, dynamic>> _recentActivity = [];

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
      // Load upcoming matches and recent activity
      _loadUpcomingMatch();
      _loadRecentActivity();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUpcomingMatch() async {
    try {
      final matches = await _matchService.getUpcomingMatches(limit: 1);
      if (matches.isNotEmpty && mounted) {
        setState(() {
          _upcomingMatch = matches.first;
        });
      }
    } catch (e) {
      // Silently fail - upcoming match is optional
    }
  }

  Future<void> _loadRecentActivity() async {
    try {
      final activity = await _matchService.getRecentCompletedMatches(limit: 5);
      if (mounted) {
        setState(() {
          _recentActivity = activity;
        });
      }
    } catch (e) {
      // Silently fail - recent activity is optional
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
        icon: Icon(Icons.calendar_month),
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
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              Text(
                'Welcome back, ${_userProfile?.fullName?.split(' ').first ?? 'Coach'}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ready for the next game?',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              // Upcoming match card
              if (_upcomingMatch != null) _buildUpcomingMatchCard(),
              if (_upcomingMatch == null) _buildNoUpcomingMatchCard(),
              const SizedBox(height: 28),

              // Quick Actions section
              const Text(
                'QUICK ACTIONS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              // Join Private Tournament card
              _buildQuickActionCard(
                icon: Icons.vpn_key_outlined,
                iconColor: AppColors.accent,
                title: 'Join Private Tournament',
                subtitle: 'Enter a code to join an existing bracket',
                imagePath: 'lock',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const JoinByInviteScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Manage Teams card (if captain)
              if (_userProfile?.isCaptain == true) ...[
                _buildQuickActionCard(
                  icon: Icons.groups_outlined,
                  iconColor: AppColors.accent,
                  title: 'Manage Teams',
                  subtitle: 'Edit rosters and player stats',
                  imagePath: 'teams',
                  onTap: () {
                    final teamsIndex = _getNavigationDestinations()
                        .indexWhere((d) => d.label == 'My Teams');
                    if (teamsIndex != -1) {
                      setState(() => _selectedIndex = teamsIndex);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Create Tournament card (if organizer)
              if (_userProfile?.isOrganizer == true) ...[
                _buildQuickActionCard(
                  icon: Icons.emoji_events_outlined,
                  iconColor: AppColors.accent,
                  title: 'Create Tournament',
                  subtitle: 'Set up brackets, rules & schedules',
                  imagePath: 'trophy',
                  highlighted: true,
                  onTap: () {
                    final organizerIndex = _getNavigationDestinations()
                        .indexWhere((d) => d.label == 'Organize');
                    if (organizerIndex != -1) {
                      setState(() => _selectedIndex = organizerIndex);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Discover Tournaments card
              _buildQuickActionCard(
                icon: Icons.explore_outlined,
                iconColor: AppColors.accent,
                title: 'Discover Tournaments',
                subtitle: 'Find public tournaments near you',
                imagePath: 'discover',
                onTap: () {
                  setState(() => _selectedIndex = 1);
                },
              ),
              const SizedBox(height: 28),

              // Recent Activity section
              const Text(
                'RECENT ACTIVITY',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              if (_recentActivity.isEmpty)
                _buildEmptyActivityCard()
              else
                ..._recentActivity.map((activity) => _buildActivityItem(activity)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingMatchCard() {
    final team1 = _upcomingMatch!['team1'] as Map<String, dynamic>?;
    final team2 = _upcomingMatch!['team2'] as Map<String, dynamic>?;
    final team1Name = team1?['name'] as String? ?? 'Team 1';
    final team2Name = team2?['name'] as String? ?? 'Team 2';
    final scheduledTime = _upcomingMatch!['scheduled_time'] as String?;
    final venue = _upcomingMatch!['venue'] as String? ?? 'Main Arena';

    String timeDisplay = 'Upcoming';
    if (scheduledTime != null) {
      final dateTime = DateTime.parse(scheduledTime);
      final now = DateTime.now();
      final diff = dateTime.difference(now);
      if (diff.inDays == 0) {
        timeDisplay = 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        timeDisplay = 'Tomorrow at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} PM';
      } else {
        timeDisplay = '${dateTime.month}/${dateTime.day} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        'UPCOMING',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$team1Name vs. $team2Name',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$timeDisplay • $venue',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Match image placeholder
          Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sports_volleyball,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUpcomingMatchCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'NO UPCOMING',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No matches scheduled',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Join a tournament to see upcoming matches',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sports_volleyball,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String imagePath,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: highlighted
                ? Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(icon, color: iconColor, size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action image placeholder
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardBackgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildActionImage(imagePath),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionImage(String imagePath) {
    IconData iconData;
    Color iconColor;

    switch (imagePath) {
      case 'lock':
        iconData = Icons.lock_outline;
        iconColor = AppColors.accent;
        break;
      case 'teams':
        iconData = Icons.groups;
        iconColor = AppColors.warning;
        break;
      case 'trophy':
        iconData = Icons.emoji_events;
        iconColor = AppColors.warning;
        break;
      case 'discover':
        iconData = Icons.explore;
        iconColor = AppColors.success;
        break;
      default:
        iconData = Icons.sports_volleyball;
        iconColor = AppColors.textMuted;
    }

    return Icon(iconData, size: 36, color: iconColor);
  }

  Widget _buildEmptyActivityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 40,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 12),
            Text(
              'No recent activity',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final team1 = activity['team1'] as Map<String, dynamic>?;
    final team2 = activity['team2'] as Map<String, dynamic>?;
    final team1Name = team1?['name'] as String? ?? 'Team 1';
    final team2Name = team2?['name'] as String? ?? 'Team 2';
    final team1SetsWon = activity['team1_sets_won'] as int? ?? 0;
    final team2SetsWon = activity['team2_sets_won'] as int? ?? 0;
    final winnerId = activity['winner_id'] as String?;
    final team1Id = activity['team1_id'] as String?;

    final team1Won = winnerId == team1Id;
    final winnerName = team1Won ? team1Name : team2Name;
    final winnerColor = team1?['team_color'] as String? ?? team2?['team_color'] as String?;

    Color avatarColor = AppColors.accent;
    if (winnerColor != null) {
      try {
        avatarColor = Color(int.parse(winnerColor.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Winner avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: avatarColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: avatarColor, width: 2),
            ),
            child: Center(
              child: Text(
                winnerName.isNotEmpty ? winnerName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: avatarColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$team1Name vs $team2Name',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$winnerName won',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$team1SetsWon - $team2SetsWon',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
    return Container(
      color: AppColors.background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 3),
                ),
                child: Center(
                  child: Text(
                    _userProfile?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _userProfile?.fullName ?? 'User',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _userProfile?.email ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _userProfile?.role == 'captain'
                      ? 'Team Captain'
                      : _userProfile?.role == 'organizer'
                          ? 'Tournament Organizer'
                          : 'User',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
              if (_userProfile?.phone != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        _userProfile!.phone!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final destinations = _getNavigationDestinations();
    final currentLabel = destinations[_selectedIndex].label;
    final showAppBar = currentLabel != 'Home';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: showAppBar
          ? AppBar(
              title: Text(currentLabel),
              backgroundColor: AppColors.cardBackground,
              foregroundColor: AppColors.textPrimary,
              actions: currentLabel == 'Profile'
                  ? [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                      ),
                    ]
                  : null,
            )
          : AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              title: const Text(
                'Tournament Hub',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.accent),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: const Icon(Icons.person_outline, color: AppColors.accent, size: 18),
                  ),
                  onPressed: () {
                    final profileIndex = _getNavigationDestinations()
                        .indexWhere((d) => d.label == 'Profile');
                    if (profileIndex != -1) {
                      setState(() => _selectedIndex = profileIndex);
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: _getSelectedScreen(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.cardBackground,
        indicatorColor: AppColors.accent.withValues(alpha: 0.2),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: destinations,
      ),
    );
  }
}
