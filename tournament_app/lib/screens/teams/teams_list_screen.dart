import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/team.dart';
import '../../services/team_service.dart';
import 'create_team_screen.dart';
import 'team_detail_screen.dart';

class TeamsListScreen extends StatefulWidget {
  const TeamsListScreen({super.key});

  @override
  State<TeamsListScreen> createState() => _TeamsListScreenState();
}

class _TeamsListScreenState extends State<TeamsListScreen> {
  final _teamService = TeamService();
  final _searchController = TextEditingController();
  List<Team> _teams = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final teams = await _teamService.getMyTeams();
      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToCreateTeam() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const CreateTeamScreen()),
    );

    if (result == true) {
      _loadTeams();
    }
  }

  void _navigateToTeamDetail(String teamId) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => TeamDetailScreen(teamId: teamId),
          ),
        )
        .then((_) => _loadTeams());
  }

  Color _getTeamColor(String? teamColor) {
    if (teamColor == null) return AppColors.accent;
    try {
      return Color(int.parse(teamColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.accent;
    }
  }

  List<Team> _getFilteredTeams() {
    var filtered = _teams;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((team) {
        final query = _searchQuery.toLowerCase();
        return team.name.toLowerCase().contains(query) ||
            (team.homeCity?.toLowerCase().contains(query) ?? false) ||
            (team.captainName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  String _getTeamStatus(Team team) {
    // Determine team status based on various factors
    if (team.registrationPaid) {
      return 'Active';
    }
    return 'Draft';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'Registered':
        return AppColors.accent;
      case 'Draft':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'My Teams',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () {
              // Settings
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadTeams,
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeams,
      color: AppColors.accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search teams...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
            const SizedBox(height: 24),

            // Your Squads Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'YOUR SQUADS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _showArchived = !_showArchived);
                  },
                  child: Text(
                    _showArchived ? 'Hide Archived' : 'View Archived',
                    style: const TextStyle(color: AppColors.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Teams List
            if (_getFilteredTeams().isEmpty)
              _buildEmptyState()
            else
              ..._getFilteredTeams().map((team) => _buildTeamCard(team)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 40,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Teams Yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first team to get started!',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _navigateToCreateTeam,
              icon: const Icon(Icons.add),
              label: const Text('Create Team'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(Team team) {
    final teamColor = _getTeamColor(team.teamColor);
    final status = _getTeamStatus(team);
    final statusColor = _getStatusColor(status);
    final sportType = team.sportType;
    final memberCount = team.playerCount;

    return GestureDetector(
      onTap: () => _navigateToTeamDetail(team.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Team Avatar with sport icon and status indicator
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          teamColor.withValues(alpha: 0.8),
                          teamColor.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        sportType == 'volleyball'
                            ? Icons.sports_volleyball
                            : Icons.sports_tennis,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  // Status indicator dot
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.cardBackground,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Team Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            team.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Sport & Members
                    Row(
                      children: [
                        Text(
                          '${sportType[0].toUpperCase()}${sportType.substring(1)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '•',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${memberCount ?? 0} Members',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: _navigateToCreateTeam,
          icon: const Icon(Icons.add),
          label: const Text(
            'Create Team',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
