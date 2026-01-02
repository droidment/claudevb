import 'package:flutter/material.dart';
import '../../models/team.dart';
import '../../services/team_service.dart';
import '../../theme/theme.dart';
import 'create_team_screen.dart';
import 'import_teams_screen.dart';
import 'team_detail_screen.dart';

class TeamsListScreen extends StatefulWidget {
  const TeamsListScreen({super.key});

  @override
  State<TeamsListScreen> createState() => _TeamsListScreenState();
}

class _TeamsListScreenState extends State<TeamsListScreen> {
  final _teamService = TeamService();
  List<Team> _teams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeams();
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
    final colors = context.colors;
    if (teamColor == null) return colors.accent;
    try {
      return Color(int.parse(teamColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return colors.accent;
    }
  }

  Future<void> _navigateToImportTeams() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const ImportTeamsScreen()),
    );

    if (result == true) {
      _loadTeams();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('My Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import from CSV',
            onPressed: _navigateToImportTeams,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateTeam,
        icon: const Icon(Icons.add),
        label: const Text('Create Team'),
      ),
    );
  }

  Widget _buildBody() {
    final colors = context.colors;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadTeams, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 100, color: colors.textMuted),
            const SizedBox(height: 24),
            Text(
              'No Teams Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first team to get started!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _navigateToCreateTeam,
              icon: const Icon(Icons.add),
              label: const Text('Create Team'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _teams.length,
        itemBuilder: (context, index) {
          final team = _teams[index];
          return _buildTeamCard(team);
        },
      ),
    );
  }

  Widget _buildTeamCard(Team team) {
    final colors = context.colors;
    final teamColor = _getTeamColor(team.teamColor);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: colors.cardBackground,
      child: InkWell(
        onTap: () => _navigateToTeamDetail(team.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Team Color Circle with paid indicator
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: teamColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: teamColor, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        team.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: teamColor,
                        ),
                      ),
                    ),
                  ),
                  if (team.registrationPaid)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: colors.success,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: colors.isDark ? Colors.white : Colors.white,
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                          ),
                        ),
                        if (team.registrationPaid)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.successLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'PAID',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colors.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (team.homeCity != null || team.captainPhone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (team.homeCity != null) ...[
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              team.homeCity!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (team.captainPhone != null || team.lunchCount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (team.captainPhone != null) ...[
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: colors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              team.captainPhone!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.textMuted),
                            ),
                          ],
                          if (team.lunchCount > 0) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.restaurant,
                              size: 14,
                              color: colors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${team.lunchCount} lunches',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.warning),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
