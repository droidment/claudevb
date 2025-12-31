import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/tournament.dart';
import '../../models/tournament_registration.dart';
import '../../models/scoring_format.dart';
import '../../models/tournament_staff.dart';
import '../../services/tournament_service.dart';
import '../../services/match_service.dart';
import '../../services/tournament_staff_service.dart';
import '../../services/round_robin_generator.dart';
import '../matches/matches_screen.dart';
import '../matches/standings_screen.dart';
import '../matches/bracket_screen.dart';
import '../matches/tournament_results_screen.dart';
import 'edit_tournament_screen.dart';
import 'add_teams_screen.dart';
import 'manage_seeds_screen.dart';
import 'manage_lunches_screen.dart';
import 'scoring_config_screen.dart';
import 'manage_staff_screen.dart';
import '../../models/scoring_config.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;
  final bool isOrganizer;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
    this.isOrganizer = false,
  });

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  final _tournamentService = TournamentService();
  final _matchService = MatchService();
  final _staffService = TournamentStaffService();
  Tournament? _tournament;
  List<Map<String, dynamic>> _registeredTeams = [];
  bool _isLoading = true;
  bool _isLoadingTeams = false;
  bool _hasMatches = false;
  int _matchCount = 0;
  String? _error;
  ScoringFormat _scoringFormat = ScoringFormat.singleSet;
  TournamentPermissions _permissions = TournamentPermissions.none;

  /// Check if current user is the organizer of this tournament
  bool get _isCurrentUserOrganizer {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || _tournament == null) return false;
    return _tournament!.organizerId == currentUserId || widget.isOrganizer;
  }

  /// Check if current user can manage the tournament (owner or admin)
  bool get _canManageTournament => _permissions.canManageTournament || _isCurrentUserOrganizer;

  /// Check if current user can manage scores (owner, admin, or scorer)
  bool get _canManageScores => _permissions.canManageScores || _isCurrentUserOrganizer;

  /// Check if tournament format supports schedule generation
  /// Round robin, pool play, and pool play to leagues all use round robin scheduling
  bool get _supportsScheduleGeneration {
    if (_tournament == null) return false;
    return _tournament!.format == TournamentFormat.roundRobin ||
        _tournament!.format == TournamentFormat.poolPlay ||
        _tournament!.format == TournamentFormat.poolPlayToLeagues;
  }

  @override
  void initState() {
    super.initState();
    _loadTournament();
  }

  Future<void> _loadTournament() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tournament = await _tournamentService.getTournament(
        widget.tournamentId,
      );

      // Load user's permissions for this tournament
      final permissions = await _staffService.getPermissionsForTournament(
        widget.tournamentId,
      );

      setState(() {
        _tournament = tournament;
        _permissions = permissions;
        _isLoading = false;
      });
      // Load teams after tournament loads
      _loadRegisteredTeams();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRegisteredTeams() async {
    if (!_canManageTournament) return;

    setState(() => _isLoadingTeams = true);

    try {
      final teams = await _tournamentService.getTournamentTeams(
        widget.tournamentId,
      );

      // Check if matches exist
      final hasMatches = await _matchService.hasTournamentMatches(
        widget.tournamentId,
      );
      final matchCount = await _matchService.getMatchCount(
        widget.tournamentId,
      );

      setState(() {
        _registeredTeams = teams;
        _hasMatches = hasMatches;
        _matchCount = matchCount;
        _isLoadingTeams = false;
      });
    } catch (e) {
      setState(() => _isLoadingTeams = false);
      // Silently fail - teams section will show error state
    }
  }

  Future<void> _updateStatus(TournamentStatus newStatus) async {
    try {
      await _tournamentService.updateTournamentStatus(
        widget.tournamentId,
        newStatus,
      );
      await _loadTournament();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Check if tournament is pool play format (requires pool assignments)
  bool get _isPoolPlayFormat {
    if (_tournament == null) return false;
    return _tournament!.format == TournamentFormat.poolPlay ||
        _tournament!.format == TournamentFormat.poolPlayToLeagues;
  }

  /// Group registered teams by pool assignment
  Map<String, List<String>> get _teamsByPool {
    final Map<String, List<String>> grouped = {};
    for (final reg in _registeredTeams) {
      final poolAssignment = reg['pool_assignment'] as String?;
      final teamId = (reg['teams'] as Map<String, dynamic>)['id'] as String;

      if (poolAssignment != null && poolAssignment.isNotEmpty) {
        grouped.putIfAbsent(poolAssignment, () => []);
        grouped[poolAssignment]!.add(teamId);
      }
    }
    return grouped;
  }

  /// Get teams without pool assignment
  List<String> get _teamsWithoutPool {
    return _registeredTeams
        .where((reg) {
          final poolAssignment = reg['pool_assignment'] as String?;
          return poolAssignment == null || poolAssignment.isEmpty;
        })
        .map((reg) => (reg['teams'] as Map<String, dynamic>)['id'] as String)
        .toList();
  }

  Future<void> _generateSchedule() async {
    if (_tournament == null || _registeredTeams.isEmpty) return;

    if (_registeredTeams.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('At least 2 teams are required to generate matches'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // For pool play formats, check that teams have pool assignments
    if (_isPoolPlayFormat) {
      final teamsWithoutPool = _teamsWithoutPool;
      if (teamsWithoutPool.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${teamsWithoutPool.length} team(s) have no pool assignment. '
                'Please assign all teams to pools first.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final teamsByPool = _teamsByPool;
      // Check that each pool has at least 2 teams
      for (final entry in teamsByPool.entries) {
        if (entry.value.length < 2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Pool ${entry.key} has only ${entry.value.length} team(s). '
                  'Each pool needs at least 2 teams.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }
    }

    // Show configuration dialog
    final config = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _GenerateScheduleDialog(
        numberOfTeams: _registeredTeams.length,
        tournamentFormat: _tournament!.format,
        teamsByPool: _isPoolPlayFormat ? _teamsByPool : null,
      ),
    );

    if (config == null) return; // User cancelled

    // Store the scoring format for later use when navigating to matches
    setState(() {
      _scoringFormat = config['scoringFormat'] as ScoringFormat;
    });

    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating matches...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      List<Map<String, dynamic>> matchesData;

      if (_isPoolPlayFormat) {
        // Generate pool play matches (round robin within each pool)
        matchesData = RoundRobinGenerator.generatePoolPlayMatches(
          tournamentId: widget.tournamentId,
          teamsByPool: _teamsByPool,
          startTime: config['startTime'] as DateTime,
          matchDurationMinutes: config['matchDuration'] as int,
          numberOfCourts: config['numberOfCourts'] as int,
          venue: _tournament!.location,
        );
      } else {
        // Generate regular round robin matches (all teams play each other)
        final teamIds = _registeredTeams
            .map((reg) => (reg['teams'] as Map<String, dynamic>)['id'] as String)
            .toList();

        matchesData = RoundRobinGenerator.generateMatches(
          tournamentId: widget.tournamentId,
          teamIds: teamIds,
          startTime: config['startTime'] as DateTime,
          matchDurationMinutes: config['matchDuration'] as int,
          numberOfCourts: config['numberOfCourts'] as int,
          venue: _tournament!.location,
        );
      }

      // Insert matches into database
      await _matchService.createMatches(matchesData);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Reload teams to update match count
      await _loadRegisteredTeams();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${matchesData.length} matches generated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to matches screen
        _navigateToMatches();
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToMatches() async {
    if (_tournament == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchesScreen(
          tournamentId: widget.tournamentId,
          tournamentName: _tournament!.name,
          isOrganizer: _canManageScores, // Allow admins and scorers to manage scores
          scoringFormat: _scoringFormat,
          tournamentScoringConfig: _tournament!.scoringConfig,
        ),
      ),
    );

    // Refresh match count when returning
    await _loadRegisteredTeams();
  }

  Future<void> _navigateToStandings() async {
    if (_tournament == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StandingsScreen(
          tournamentId: widget.tournamentId,
          tournamentName: _tournament!.name,
          isOrganizer: _canManageScores, // Allow admins and scorers to manage scores
          scoringFormat: _scoringFormat,
          venue: _tournament!.location,
          tournamentScoringConfig: _tournament!.scoringConfig,
        ),
      ),
    );
  }

  Future<void> _navigateToBrackets() async {
    if (_tournament == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BracketScreen(
          tournamentId: widget.tournamentId,
          tournamentName: _tournament!.name,
          isOrganizer: _canManageScores, // Allow admins and scorers to manage scores
          scoringFormat: _scoringFormat,
          tournamentScoringConfig: _tournament!.scoringConfig,
        ),
      ),
    );
  }

  Future<void> _navigateToResults() async {
    if (_tournament == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TournamentResultsScreen(
          tournamentId: widget.tournamentId,
          tournamentName: _tournament!.name,
          isOrganizer: _canManageTournament, // Only admins can close tournament
        ),
      ),
    );

    // Refresh tournament data when returning (in case tournament was closed)
    await _loadTournament();
  }

  Future<void> _editTournament() async {
    if (_tournament == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditTournamentScreen(tournament: _tournament!),
      ),
    );

    if (result == true) {
      await _loadTournament();
    }
  }

  Future<void> _navigateToAddTeams() async {
    if (_tournament == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddTeamsScreen(
          tournamentId: _tournament!.id,
          tournamentName: _tournament!.name,
        ),
      ),
    );

    if (result == true) {
      await _loadRegisteredTeams();
    }
  }

  Future<void> _navigateToManageSeeds() async {
    if (_tournament == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManageSeedsScreen(
          tournamentId: _tournament!.id,
          tournamentName: _tournament!.name,
        ),
      ),
    );

    // Refresh teams after returning from manage seeds
    await _loadRegisteredTeams();
  }

  Future<void> _navigateToManageLunches() async {
    if (_tournament == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManageLunchesScreen(
          tournamentId: _tournament!.id,
          tournamentName: _tournament!.name,
        ),
      ),
    );

    // Refresh teams after returning from manage lunches
    await _loadRegisteredTeams();
  }

  Future<void> _navigateToScoringConfig() async {
    if (_tournament == null) return;

    final newConfig = await Navigator.of(context).push<TournamentScoringConfig>(
      MaterialPageRoute(
        builder: (context) => ScoringConfigScreen(
          sportType: _tournament!.sportType,
          initialConfig: _tournament!.scoringConfig,
        ),
      ),
    );

    if (newConfig != null) {
      try {
        await _tournamentService.updateTournament(
          _tournament!.id,
          {'scoring_config': newConfig.toJsonString()},
        );
        await _loadTournament();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scoring configuration saved'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving scoring config: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToManageStaff() async {
    if (_tournament == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManageStaffScreen(
          tournamentId: _tournament!.id,
          tournamentName: _tournament!.name,
        ),
      ),
    );

    // Reload permissions in case they changed
    await _loadTournament();
  }

  Future<void> _removeTeamFromTournament(String teamId, String teamName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Team'),
        content: Text(
          'Are you sure you want to remove "$teamName" from this tournament?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _tournamentService.removeTeamFromTournament(
          tournamentId: widget.tournamentId,
          teamId: teamId,
        );
        await _loadRegisteredTeams();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$teamName removed from tournament'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing team: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteTournament() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tournament'),
        content: const Text(
          'Are you sure you want to delete this tournament? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _tournamentService.deleteTournament(widget.tournamentId);
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tournament deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting tournament: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showStatusMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: TournamentStatus.values.map((status) {
            return ListTile(
              leading: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
              ),
              title: Text(status.displayName),
              selected: _tournament?.status == status,
              onTap: () {
                Navigator.of(context).pop();
                _updateStatus(status);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.registrationOpen:
        return Colors.green;
      case TournamentStatus.registrationClosed:
        return Colors.orange;
      case TournamentStatus.ongoing:
        return Colors.blue;
      case TournamentStatus.completed:
        return Colors.grey;
      case TournamentStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.registrationOpen:
        return Icons.how_to_reg;
      case TournamentStatus.registrationClosed:
        return Icons.lock;
      case TournamentStatus.ongoing:
        return Icons.play_circle;
      case TournamentStatus.completed:
        return Icons.check_circle;
      case TournamentStatus.cancelled:
        return Icons.cancel;
    }
  }

  IconData _getSportIcon(String sportType) {
    return sportType == 'volleyball'
        ? Icons.sports_volleyball
        : Icons.sports_tennis;
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not set';
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: _isCurrentUserOrganizer
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editTournament,
                  tooltip: 'Edit Tournament',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteTournament();
                    } else if (value == 'status') {
                      _showStatusMenu();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'status',
                      child: ListTile(
                        leading: Icon(Icons.sync),
                        title: Text('Change Status'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _tournament == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${_error ?? "Tournament not found"}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTournament,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTournament,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getSportIcon(_tournament!.sportType),
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tournament!.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _tournament!.format.displayName,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: widget.isOrganizer ? _showStatusMenu : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          _tournament!.status,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStatusColor(_tournament!.status),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(_tournament!.status),
                            color: _getStatusColor(_tournament!.status),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _tournament!.status.displayName,
                            style: TextStyle(
                              color: _getStatusColor(_tournament!.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.isOrganizer) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              color: _getStatusColor(_tournament!.status),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_tournament!.description != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      _tournament!.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Privacy & Invite Code Card (for organizers of private tournaments)
          if (widget.isOrganizer &&
              !_tournament!.isPublic &&
              _tournament!.inviteCode != null)
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Private Tournament',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Share this invite code with teams:',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _tournament!.inviteCode!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _tournament!.inviteCode!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Invite code copied to clipboard!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            tooltip: 'Copy invite code',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.isOrganizer &&
              !_tournament!.isPublic &&
              _tournament!.inviteCode != null)
            const SizedBox(height: 16),

          // Privacy Status Card (for all users)
          if (!_tournament!.isPublic)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Private Tournament',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This tournament is invite-only',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!_tournament!.isPublic) const SizedBox(height: 16),

          // Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tournament Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.sports,
                    'Sport',
                    _tournament!.sportType.toUpperCase(),
                  ),
                  _buildDetailRow(
                    Icons.format_list_numbered,
                    'Format',
                    _tournament!.format.displayName,
                  ),
                  if (_tournament!.location != null)
                    _buildDetailRow(
                      Icons.location_on,
                      'Location',
                      _tournament!.location!,
                    ),
                  if (_tournament!.venueDetails != null)
                    _buildDetailRow(
                      Icons.info,
                      'Venue',
                      _tournament!.venueDetails!,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dates Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Important Dates',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.how_to_reg,
                    'Registration Deadline',
                    _formatDateTime(_tournament!.registrationDeadline),
                  ),
                  _buildDetailRow(
                    Icons.play_circle,
                    'Start Date',
                    _formatDateTime(_tournament!.startDate),
                  ),
                  _buildDetailRow(
                    Icons.stop_circle,
                    'End Date',
                    _formatDateTime(_tournament!.endDate),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Team Settings Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Requirements',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_tournament!.maxTeams != null)
                    _buildDetailRow(
                      Icons.groups,
                      'Maximum Teams',
                      '${_tournament!.maxTeams}',
                    ),
                  _buildDetailRow(
                    Icons.person,
                    'Team Size',
                    '${_tournament!.minTeamSize} - ${_tournament!.maxTeamSize} players',
                  ),
                  if (_tournament!.entryFee != null)
                    _buildDetailRow(
                      Icons.attach_money,
                      'Entry Fee',
                      '\$${_tournament!.entryFee!.toStringAsFixed(2)}',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Registrations section
          if (_canManageTournament) _buildTeamsSection(),
        ],
      ),
    );
  }

  Widget _buildTeamsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Registered Teams',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        '${_registeredTeams.length} team${_registeredTeams.length == 1 ? '' : 's'}',
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: _navigateToAddTeams,
                      tooltip: 'Add Teams',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingTeams)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_registeredTeams.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.group_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'No teams registered yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _navigateToAddTeams,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Teams'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  // Action buttons row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _navigateToManageSeeds,
                          icon: const Icon(Icons.format_list_numbered),
                          label: const Text('Manage Seeds'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _navigateToAddTeams,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Teams'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _navigateToManageLunches,
                          icon: const Icon(Icons.restaurant_menu),
                          label: const Text('Lunches'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _navigateToScoringConfig,
                          icon: const Icon(Icons.scoreboard),
                          label: const Text('Scoring'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                            side: const BorderSide(color: Colors.deepPurple),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Manage Staff button - only for tournament owner
                  if (_isCurrentUserOrganizer)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _navigateToManageStaff,
                        icon: const Icon(Icons.group),
                        label: const Text('Manage Staff (Admins & Scorers)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo,
                          side: const BorderSide(color: Colors.indigo),
                        ),
                      ),
                    ),
                  if (_isCurrentUserOrganizer) const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_hasMatches)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _navigateToMatches,
                            icon: const Icon(Icons.calendar_month),
                            label: Text('View Schedule ($_matchCount)'),
                          ),
                        )
                      else if (_supportsScheduleGeneration)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _generateSchedule,
                            icon: const Icon(Icons.auto_fix_high),
                            label: const Text('Generate Schedule'),
                          ),
                        ),
                    ],
                  ),
                  // Standings button - show when matches exist
                  if (_hasMatches && _isPoolPlayFormat) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _navigateToStandings,
                        icon: const Icon(Icons.leaderboard),
                        label: const Text('View Standings & Tier Progression'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple,
                          side: const BorderSide(color: Colors.purple),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _navigateToBrackets,
                            icon: const Icon(Icons.account_tree),
                            label: const Text('Brackets'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal,
                              side: const BorderSide(color: Colors.teal),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _navigateToResults,
                            icon: const Icon(Icons.emoji_events),
                            label: const Text('Results'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amber.shade700,
                              side: BorderSide(color: Colors.amber.shade700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  ..._registeredTeams.map((reg) => _buildTeamTile(reg)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamTile(Map<String, dynamic> registration) {
    final teamData = registration['teams'] as Map<String, dynamic>?;
    if (teamData == null) return const SizedBox.shrink();

    final teamName = teamData['name'] as String? ?? 'Unknown Team';
    final teamId = teamData['id'] as String;
    final homeCity = teamData['home_city'] as String?;
    final teamColor = teamData['team_color'] as String?;
    // Use registration payment_status, not team's registration_paid
    final paymentStatus =
        registration['payment_status'] as String? ?? 'pending';
    final isPaid = paymentStatus == 'paid';
    final poolAssignment = registration['pool_assignment'] as String?;
    final seedNumber = registration['seed_number'] as int?;

    // Lunch info
    final lunchNonveg = registration['lunch_nonveg_count'] as int? ?? 0;
    final lunchVeg = registration['lunch_veg_count'] as int? ?? 0;
    final totalLunches = lunchNonveg + lunchVeg;
    final lunchPaymentStatusStr =
        registration['lunch_payment_status'] as String? ?? 'not_paid';
    final lunchPaymentStatus = LunchPaymentStatusExtension.fromString(
      lunchPaymentStatusStr,
    );

    Color avatarColor = Colors.blue;
    if (teamColor != null) {
      try {
        avatarColor = Color(int.parse(teamColor.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Seed badge
            if (seedNumber != null)
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Center(
                  child: Text(
                    '$seedNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ),
            CircleAvatar(
              backgroundColor: avatarColor.withOpacity(0.2),
              child: Text(
                teamName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: avatarColor,
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(child: Text(teamName)),
            if (isPaid)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PAID',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'UNPAID',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            if (homeCity != null) ...[
              Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 2),
              Text(
                homeCity,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (poolAssignment != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Pool $poolAssignment',
                  style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                ),
              ),
            ],
            if (seedNumber != null) ...[
              const SizedBox(width: 4),
              Text(
                '#$seedNumber',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            // Lunch info badge
            if (totalLunches > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: lunchPaymentStatus.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: lunchPaymentStatus.color.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 10,
                      color: lunchPaymentStatus.color,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$totalLunches',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: lunchPaymentStatus.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'remove') {
              _removeTeamFromTournament(teamId, teamName);
            } else if (value == 'edit') {
              _editTeamRegistration(registration);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Registration'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.remove_circle, color: Colors.red),
                title: Text('Remove', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTeamRegistration(Map<String, dynamic> registration) async {
    final teamData = registration['teams'] as Map<String, dynamic>?;
    if (teamData == null) return;

    final teamId = teamData['id'] as String;
    final teamName = teamData['name'] as String? ?? 'Team';
    String? poolAssignment = registration['pool_assignment'] as String?;
    int? seedNumber = registration['seed_number'] as int?;
    final paymentStatusStr =
        registration['payment_status'] as String? ?? 'pending';
    PaymentStatus paymentStatus = PaymentStatusExtension.fromString(
      paymentStatusStr,
    );

    final poolController = TextEditingController(text: poolAssignment ?? '');
    final seedController = TextEditingController(
      text: seedNumber?.toString() ?? '',
    );

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        PaymentStatus dialogPaymentStatus = paymentStatus;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Edit $teamName'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Status Toggle
                  Card(
                    color: dialogPaymentStatus == PaymentStatus.paid
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            dialogPaymentStatus == PaymentStatus.paid
                                ? Icons.check_circle
                                : Icons.pending,
                            color: dialogPaymentStatus == PaymentStatus.paid
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Payment Status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  dialogPaymentStatus.displayName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        dialogPaymentStatus ==
                                            PaymentStatus.paid
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: dialogPaymentStatus == PaymentStatus.paid,
                            activeThumbColor: Colors.green,
                            onChanged: (value) {
                              setDialogState(() {
                                dialogPaymentStatus = value
                                    ? PaymentStatus.paid
                                    : PaymentStatus.pending;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Seed Number
                  TextField(
                    controller: seedController,
                    decoration: const InputDecoration(
                      labelText: 'Seed Number',
                      hintText: 'e.g., 1, 2, 3',
                      helperText: 'Lower number = stronger team',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.format_list_numbered),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Pool Assignment
                  TextField(
                    controller: poolController,
                    decoration: const InputDecoration(
                      labelText: 'Pool Assignment',
                      hintText: 'e.g., A, B, C',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.grid_view),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop({'paymentStatus': dialogPaymentStatus, 'save': true}),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null && result['save'] == true) {
      try {
        final newPaymentStatus = result['paymentStatus'] as PaymentStatus;
        await _tournamentService.updateRegistration(
          tournamentId: widget.tournamentId,
          teamId: teamId,
          poolAssignment: poolController.text.isNotEmpty
              ? poolController.text.toUpperCase()
              : null,
          seedNumber: int.tryParse(seedController.text),
          paymentStatus: newPaymentStatus,
        );
        await _loadRegisteredTeams();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$teamName registration updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating registration: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    poolController.dispose();
    seedController.dispose();
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for configuring schedule generation
class _GenerateScheduleDialog extends StatefulWidget {
  final int numberOfTeams;
  final TournamentFormat tournamentFormat;
  final Map<String, List<String>>? teamsByPool; // For pool play formats

  const _GenerateScheduleDialog({
    required this.numberOfTeams,
    required this.tournamentFormat,
    this.teamsByPool,
  });

  /// Check if this is pool play format
  bool get isPoolPlay => teamsByPool != null && teamsByPool!.isNotEmpty;

  @override
  State<_GenerateScheduleDialog> createState() =>
      _GenerateScheduleDialogState();
}

class _GenerateScheduleDialogState extends State<_GenerateScheduleDialog> {
  DateTime _startTime = DateTime.now().add(const Duration(days: 1));
  int _matchDuration = 60;
  int _numberOfCourts = 2;
  ScoringFormat _scoringFormat = ScoringFormat.singleSet;

  /// Calculate total matches based on format
  int get _totalMatches {
    if (widget.isPoolPlay) {
      // Pool play: sum of round robin matches within each pool
      final teamsPerPool = widget.teamsByPool!.map(
        (key, value) => MapEntry(key, value.length),
      );
      return RoundRobinGenerator.calculatePoolPlayTotalMatches(teamsPerPool);
    } else {
      // Regular round robin: all teams play each other
      return RoundRobinGenerator.calculateTotalMatches(widget.numberOfTeams);
    }
  }

  /// Estimate duration based on format
  int get _estimatedDuration {
    if (widget.isPoolPlay) {
      final teamsPerPool = widget.teamsByPool!.map(
        (key, value) => MapEntry(key, value.length),
      );
      return RoundRobinGenerator.estimatePoolPlayDuration(
        teamsPerPool: teamsPerPool,
        matchDurationMinutes: _matchDuration,
        numberOfCourts: _numberOfCourts,
      );
    } else {
      return RoundRobinGenerator.estimateTournamentDuration(
        numberOfTeams: widget.numberOfTeams,
        matchDurationMinutes: _matchDuration,
        numberOfCourts: _numberOfCourts,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMatches = _totalMatches;
    final estimatedDuration = _estimatedDuration;

    return AlertDialog(
      title: Text(
        widget.isPoolPlay
            ? 'Generate Pool Play Schedule'
            : 'Generate Tournament Schedule',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pool play info
            if (widget.isPoolPlay) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.grid_view, color: Colors.purple.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Pool Play Format',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Teams play round robin within their pool:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...widget.teamsByPool!.entries.map((entry) {
                      final poolMatches =
                          RoundRobinGenerator.calculateTotalMatches(
                        entry.value.length,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text(
                          '• Pool ${entry.key}: ${entry.value.length} teams → $poolMatches matches',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              'This will create $totalMatches matches for ${widget.numberOfTeams} teams.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Start Date & Time
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Start Date & Time'),
                subtitle: Text(
                  '${_startTime.month}/${_startTime.day}/${_startTime.year} '
                  'at ${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );

                  if (date != null && mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_startTime),
                    );

                    if (time != null) {
                      setState(() {
                        _startTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Match Duration
            Text(
              'Match Duration',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _matchDuration.toDouble(),
                    min: 30,
                    max: 120,
                    divisions: 9,
                    label: '$_matchDuration min',
                    onChanged: (value) {
                      setState(() => _matchDuration = value.toInt());
                    },
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '$_matchDuration min',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Number of Courts
            Text(
              'Number of Courts',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _numberOfCourts.toDouble(),
                    min: 1,
                    max: 8,
                    divisions: 7,
                    label: '$_numberOfCourts',
                    onChanged: (value) {
                      setState(() => _numberOfCourts = value.toInt());
                    },
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '$_numberOfCourts courts',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scoring Format
            Text(
              'Scoring Format',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...ScoringFormat.values.map((format) {
              final isSelected = _scoringFormat == format;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isSelected ? Colors.blue.shade50 : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () => setState(() => _scoringFormat = format),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Radio<ScoringFormat>(
                          value: format,
                          groupValue: _scoringFormat,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _scoringFormat = value);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                format.displayName,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              Text(
                                format.shortDescription,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Estimated Duration
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Duration',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(estimatedDuration / 60).toStringAsFixed(1)} hours',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop({
              'startTime': _startTime,
              'matchDuration': _matchDuration,
              'numberOfCourts': _numberOfCourts,
              'scoringFormat': _scoringFormat,
            });
          },
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('Generate'),
        ),
      ],
    );
  }
}
