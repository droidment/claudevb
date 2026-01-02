import 'package:flutter/material.dart';
import '../../models/scoring_format.dart';
import '../../models/scoring_config.dart';
import '../../services/match_service.dart';
import '../../services/bracket_generator.dart';
import '../../theme/theme.dart';
import 'bracket_screen.dart';

class StandingsScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final int advancedTierSize;
  final int intermediateTierSize;
  final int recreationalTierSize;
  final bool isOrganizer;
  final ScoringFormat scoringFormat;
  final String? venue;
  final TournamentScoringConfig? tournamentScoringConfig;

  const StandingsScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.advancedTierSize = 4,
    this.intermediateTierSize = 8,
    this.recreationalTierSize = 4,
    this.isOrganizer = false,
    this.scoringFormat = ScoringFormat.singleSet,
    this.venue,
    this.tournamentScoringConfig,
  });

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen>
    with SingleTickerProviderStateMixin {
  final MatchService _matchService = MatchService();

  bool _isLoading = true;
  bool _hasBrackets = false;
  Map<String, List<TeamStanding>> _poolStandings = {};
  List<TeamStanding> _overallStandings = [];
  TournamentProgress? _progress;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final poolStandings = await _matchService.calculatePoolStandings(
        widget.tournamentId,
      );
      final overallStandings = await _matchService.getOverallStandings(
        widget.tournamentId,
      );
      final progress = await _matchService.getTournamentProgress(
        widget.tournamentId,
      );

      // Check if bracket matches already exist
      final allMatches = await _matchService.getMatchesForTournament(
        widget.tournamentId,
      );
      final hasBrackets = allMatches.any((m) => m.tier != null);

      if (mounted) {
        setState(() {
          _poolStandings = poolStandings;
          _overallStandings = overallStandings;
          _progress = progress;
          _hasBrackets = hasBrackets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading standings: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  Future<void> _generateBrackets() async {
    // Show configuration dialog
    final config = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _GenerateBracketsDialog(
        advancedTeams: widget.advancedTierSize,
        intermediateTeams: widget.intermediateTierSize,
        recreationalTeams: widget.recreationalTierSize,
      ),
    );

    if (config == null) return;

    try {
      // Show loading
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
                    Text('Generating brackets...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Generate bracket matches
      final bracketMatches = BracketGenerator.generateTieredBrackets(
        tournamentId: widget.tournamentId,
        overallStandings: _overallStandings,
        advancedTierSize: widget.advancedTierSize,
        intermediateTierSize: widget.intermediateTierSize,
        recreationalTierSize: widget.recreationalTierSize,
        startTime: config['startTime'] as DateTime,
        matchDurationMinutes: config['matchDuration'] as int,
        numberOfCourts: config['numberOfCourts'] as int,
        venue: widget.venue,
      );

      // Insert matches
      await _matchService.createMatches(bracketMatches);

      // Close loading
      if (mounted) Navigator.of(context).pop();

      // Reload data
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${bracketMatches.length} bracket matches generated!'),
            backgroundColor: context.colors.success,
          ),
        );

        // Navigate to brackets screen
        _navigateToBrackets();
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating brackets: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  void _navigateToBrackets() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BracketScreen(
          tournamentId: widget.tournamentId,
          tournamentName: widget.tournamentName,
          isOrganizer: widget.isOrganizer,
          scoringFormat: widget.scoringFormat,
          tournamentScoringConfig: widget.tournamentScoringConfig,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Standings'),
        backgroundColor: colors.cardBackground,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pool Standings', icon: Icon(Icons.grid_view)),
            Tab(text: 'Tier Progression', icon: Icon(Icons.trending_up)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPoolStandingsTab(),
                _buildTierProgressionTab(),
              ],
            ),
    );
  }

  Widget _buildPoolStandingsTab() {
    final colors = context.colors;
    if (_poolStandings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_volleyball, size: 64, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No matches played yet',
              style: TextStyle(fontSize: 18, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Standings will appear after matches are completed',
              style: TextStyle(color: colors.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress Overview
          if (_progress != null) _buildProgressOverview(),
          const SizedBox(height: 16),

          // Pool Standings
          ..._poolStandings.entries.map((entry) {
            return _buildPoolCard(entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildProgressOverview() {
    final colors = context.colors;
    final progress = _progress!;
    final percentage = (progress.progressPercentage * 100).toStringAsFixed(0);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  progress.isPoolPlayComplete
                      ? Icons.check_circle
                      : Icons.schedule,
                  color: progress.isPoolPlayComplete
                      ? colors.success
                      : colors.warning,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.isPoolPlayComplete
                            ? 'Pool Play Complete!'
                            : 'Pool Play In Progress',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${progress.completedMatches} of ${progress.totalMatches} matches completed ($percentage%)',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.progressPercentage,
                minHeight: 12,
                backgroundColor: colors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress.isPoolPlayComplete ? colors.success : colors.accent,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pool-by-pool progress
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: progress.totalByPool.entries.map((entry) {
                final completed = progress.completedByPool[entry.key] ?? 0;
                final total = entry.value;
                final poolComplete = completed == total;
                return Chip(
                  avatar: Icon(
                    poolComplete ? Icons.check_circle : Icons.pending,
                    size: 18,
                    color: poolComplete ? colors.success : colors.warning,
                  ),
                  label: Text('Pool ${entry.key}: $completed/$total'),
                  backgroundColor: poolComplete
                      ? colors.successLight
                      : colors.warningLight,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolCard(String poolName, List<TeamStanding> standings) {
    final colors = context.colors;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getPoolColor(poolName),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              'Pool $poolName',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          // Table Header
          Container(
            color: colors.cardBackgroundLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                SizedBox(width: 32), // Rank
                Expanded(flex: 3, child: Text('Team', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 40, child: Text('W', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                SizedBox(width: 40, child: Text('L', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                SizedBox(width: 60, child: Text('+/-', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Team Rows
          ...standings.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final standing = entry.value;
            return _buildTeamRow(rank, standing, standings.length);
          }),
        ],
      ),
    );
  }

  Widget _buildTeamRow(int rank, TeamStanding standing, int totalTeams) {
    final colors = context.colors;
    // Determine tier color based on rank
    Color? rowColor;
    if (_progress?.isPoolPlayComplete == true) {
      // Show tier assignment preview
      final overallRank = _overallStandings.indexWhere((s) => s.teamId == standing.teamId) + 1;
      if (overallRank <= widget.advancedTierSize) {
        rowColor = colors.successLight;
      } else if (overallRank <= widget.advancedTierSize + widget.intermediateTierSize) {
        rowColor = colors.accentLight;
      } else if (overallRank <= widget.advancedTierSize + widget.intermediateTierSize + widget.recreationalTierSize) {
        rowColor = colors.warningLight;
      }
    }

    return Container(
      color: rowColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rank == 1
                    ? colors.warning
                    : rank == 2
                        ? colors.textMuted
                        : rank == 3
                            ? colors.textSecondary
                            : colors.divider,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: rank <= 3 ? colors.textPrimary : colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  standing.teamName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                if (standing.matchesPlayed > 0)
                  Text(
                    '${standing.matchesPlayed} played',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${standing.wins}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.success,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${standing.losses}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.error,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '${standing.pointDifferential > 0 ? '+' : ''}${standing.pointDifferential}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: standing.pointDifferential > 0
                    ? colors.success
                    : standing.pointDifferential < 0
                        ? colors.error
                        : colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierProgressionTab() {
    final colors = context.colors;
    if (_overallStandings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No standings yet',
              style: TextStyle(fontSize: 18, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete pool play matches to see tier assignments',
              style: TextStyle(color: colors.textMuted),
            ),
          ],
        ),
      );
    }

    // Calculate tier boundaries
    final advancedEnd = widget.advancedTierSize;
    final intermediateEnd = advancedEnd + widget.intermediateTierSize;
    final recreationalEnd = intermediateEnd + widget.recreationalTierSize;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress indicator or bracket actions
          if (_progress != null && !_progress!.isPoolPlayComplete)
            Card(
              color: colors.warningLight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info, color: colors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pool play is ${(_progress!.progressPercentage * 100).toStringAsFixed(0)}% complete. '
                        'Tier assignments may change as more matches are completed.',
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_progress != null && _progress!.isPoolPlayComplete)
            Card(
              color: _hasBrackets ? colors.successLight : colors.accentLight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _hasBrackets ? Icons.check_circle : Icons.emoji_events,
                          color: _hasBrackets ? colors.success : colors.accent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _hasBrackets
                                ? 'Tier brackets have been generated!'
                                : 'Pool play complete! Ready to generate tier brackets.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (!_hasBrackets && widget.isOrganizer)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _generateBrackets,
                              icon: const Icon(Icons.account_tree),
                              label: const Text('Generate Brackets'),
                            ),
                          ),
                        if (_hasBrackets) ...[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _navigateToBrackets,
                              icon: const Icon(Icons.account_tree),
                              label: const Text('View Brackets'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (_progress != null)
            const SizedBox(height: 16),

          // Tier Cards
          _buildTierCard(
            'Advanced',
            Icons.star,
            colors.success,
            _overallStandings.take(advancedEnd).toList(),
            1,
          ),
          const SizedBox(height: 16),

          _buildTierCard(
            'Intermediate',
            Icons.trending_up,
            colors.accent,
            _overallStandings.skip(advancedEnd).take(widget.intermediateTierSize).toList(),
            advancedEnd + 1,
          ),
          const SizedBox(height: 16),

          _buildTierCard(
            'Recreational',
            Icons.sports_volleyball,
            colors.warning,
            _overallStandings.skip(intermediateEnd).take(widget.recreationalTierSize).toList(),
            intermediateEnd + 1,
          ),

          // Eliminated teams
          if (_overallStandings.length > recreationalEnd) ...[
            const SizedBox(height: 16),
            _buildTierCard(
              'Eliminated',
              Icons.cancel,
              colors.textMuted,
              _overallStandings.skip(recreationalEnd).toList(),
              recreationalEnd + 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTierCard(
    String tierName,
    IconData icon,
    Color color,
    List<TeamStanding> teams,
    int startRank,
  ) {
    final colors = context.colors;
    return Card(
      elevation: 3,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: colors.textPrimary, size: 28),
                const SizedBox(width: 12),
                Text(
                  '$tierName Tier',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${teams.length} teams',
                    style: TextStyle(color: colors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          if (teams.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No teams assigned yet',
                style: TextStyle(color: colors.textSecondary),
              ),
            )
          else
            ...teams.asMap().entries.map((entry) {
              final index = entry.key;
              final standing = entry.value;
              final rank = startRank + index;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colors.divider),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.2),
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            standing.teamName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Pool ${standing.pool} • ${standing.wins}W-${standing.losses}L',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${standing.pointDifferential > 0 ? '+' : ''}${standing.pointDifferential}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: standing.pointDifferential > 0
                                ? colors.success
                                : standing.pointDifferential < 0
                                    ? colors.error
                                    : colors.textMuted,
                          ),
                        ),
                        Text(
                          'pt diff',
                          style: TextStyle(fontSize: 10, color: colors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _getPoolColor(String poolName) {
    final colors = context.colors;
    switch (poolName.toUpperCase()) {
      case 'A':
        return colors.accent;
      case 'B':
        return Colors.purple;
      case 'C':
        return Colors.teal;
      case 'D':
        return Colors.indigo;
      case 'E':
        return Colors.pink;
      case 'F':
        return Colors.cyan;
      default:
        return colors.textMuted;
    }
  }
}

/// Dialog for configuring bracket generation
class _GenerateBracketsDialog extends StatefulWidget {
  final int advancedTeams;
  final int intermediateTeams;
  final int recreationalTeams;

  const _GenerateBracketsDialog({
    required this.advancedTeams,
    required this.intermediateTeams,
    required this.recreationalTeams,
  });

  @override
  State<_GenerateBracketsDialog> createState() => _GenerateBracketsDialogState();
}

class _GenerateBracketsDialogState extends State<_GenerateBracketsDialog> {
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  int _matchDuration = 45;
  int _numberOfCourts = 2;

  int _getBracketSize(int teamCount) {
    if (teamCount <= 2) return 2;
    if (teamCount <= 4) return 4;
    if (teamCount <= 8) return 8;
    if (teamCount <= 16) return 16;
    return 32;
  }

  String _getRoundInfo(int teamCount) {
    final size = _getBracketSize(teamCount);
    if (size == 2) return 'Finals only';
    if (size == 4) return 'Semi-Finals → Finals';
    if (size == 8) return 'Quarter-Finals → Semi-Finals → Finals';
    return 'Multiple rounds';
  }

  int _getTotalMatches() {
    int total = 0;
    if (widget.advancedTeams > 1) {
      total += _getBracketSize(widget.advancedTeams) - 1;
    }
    if (widget.intermediateTeams > 1) {
      total += _getBracketSize(widget.intermediateTeams) - 1;
    }
    if (widget.recreationalTeams > 1) {
      total += _getBracketSize(widget.recreationalTeams) - 1;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      title: const Text('Generate Tier Brackets'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tier summary
            Card(
              color: colors.accentLight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bracket Summary',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildTierInfo(
                      'Advanced',
                      widget.advancedTeams,
                      colors.success,
                    ),
                    _buildTierInfo(
                      'Intermediate',
                      widget.intermediateTeams,
                      colors.accent,
                    ),
                    _buildTierInfo(
                      'Recreational',
                      widget.recreationalTeams,
                      colors.warning,
                    ),
                    const Divider(),
                    Text(
                      'Total matches: ${_getTotalMatches()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Start time
            const Text(
              'Start Time',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
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
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.divider),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_startTime.month}/${_startTime.day}/${_startTime.year} '
                      'at ${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Match duration
            const Text(
              'Match Duration (minutes)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Slider(
              value: _matchDuration.toDouble(),
              min: 20,
              max: 90,
              divisions: 14,
              label: '$_matchDuration min',
              onChanged: (value) {
                setState(() => _matchDuration = value.round());
              },
            ),
            const SizedBox(height: 8),

            // Number of courts
            const Text(
              'Number of Courts',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Slider(
              value: _numberOfCourts.toDouble(),
              min: 1,
              max: 8,
              divisions: 7,
              label: '$_numberOfCourts courts',
              onChanged: (value) {
                setState(() => _numberOfCourts = value.round());
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop({
              'startTime': _startTime,
              'matchDuration': _matchDuration,
              'numberOfCourts': _numberOfCourts,
            });
          },
          icon: const Icon(Icons.account_tree),
          label: const Text('Generate Brackets'),
        ),
      ],
    );
  }

  Widget _buildTierInfo(String tierName, int teamCount, Color color) {
    if (teamCount <= 0) return const SizedBox.shrink();

    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$tierName: $teamCount teams'),
          ),
          Text(
            _getRoundInfo(teamCount),
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
