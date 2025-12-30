import 'package:flutter/material.dart';
import '../../services/match_service.dart';

class StandingsScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final int advancedTierSize;
  final int intermediateTierSize;
  final int recreationalTierSize;

  const StandingsScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.advancedTierSize = 4,
    this.intermediateTierSize = 8,
    this.recreationalTierSize = 4,
  });

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen>
    with SingleTickerProviderStateMixin {
  final MatchService _matchService = MatchService();

  bool _isLoading = true;
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

      if (mounted) {
        setState(() {
          _poolStandings = poolStandings;
          _overallStandings = overallStandings;
          _progress = progress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading standings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Standings'),
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
    if (_poolStandings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_volleyball, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No matches played yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Standings will appear after matches are completed',
              style: TextStyle(color: Colors.grey),
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
                      ? Colors.green
                      : Colors.orange,
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
                        style: TextStyle(color: Colors.grey[600]),
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
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress.isPoolPlayComplete ? Colors.green : Colors.blue,
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
                    color: poolComplete ? Colors.green : Colors.orange,
                  ),
                  label: Text('Pool ${entry.key}: $completed/$total'),
                  backgroundColor: poolComplete
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolCard(String poolName, List<TeamStanding> standings) {
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Table Header
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 32), // Rank
                const Expanded(flex: 3, child: Text('Team', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 40, child: Text('W', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                const SizedBox(width: 40, child: Text('L', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                const SizedBox(width: 60, child: Text('+/-', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
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
    // Determine tier color based on rank
    Color? rowColor;
    if (_progress?.isPoolPlayComplete == true) {
      // Show tier assignment preview
      final overallRank = _overallStandings.indexWhere((s) => s.teamId == standing.teamId) + 1;
      if (overallRank <= widget.advancedTierSize) {
        rowColor = Colors.green.shade50;
      } else if (overallRank <= widget.advancedTierSize + widget.intermediateTierSize) {
        rowColor = Colors.blue.shade50;
      } else if (overallRank <= widget.advancedTierSize + widget.intermediateTierSize + widget.recreationalTierSize) {
        rowColor = Colors.orange.shade50;
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
                    ? Colors.amber
                    : rank == 2
                        ? Colors.grey[400]
                        : rank == 3
                            ? Colors.brown[300]
                            : Colors.grey[200],
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: rank <= 3 ? Colors.white : Colors.black,
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
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
                color: Colors.green[700],
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
                color: Colors.red[700],
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
                    ? Colors.green[700]
                    : standing.pointDifferential < 0
                        ? Colors.red[700]
                        : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierProgressionTab() {
    if (_overallStandings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No standings yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Complete pool play matches to see tier assignments',
              style: TextStyle(color: Colors.grey),
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
          // Progress indicator
          if (_progress != null && !_progress!.isPoolPlayComplete)
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pool play is ${(_progress!.progressPercentage * 100).toStringAsFixed(0)}% complete. '
                        'Tier assignments may change as more matches are completed.',
                        style: TextStyle(color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_progress != null && !_progress!.isPoolPlayComplete)
            const SizedBox(height: 16),

          // Tier Cards
          _buildTierCard(
            'Advanced',
            Icons.star,
            Colors.green,
            _overallStandings.take(advancedEnd).toList(),
            1,
          ),
          const SizedBox(height: 16),

          _buildTierCard(
            'Intermediate',
            Icons.trending_up,
            Colors.blue,
            _overallStandings.skip(advancedEnd).take(widget.intermediateTierSize).toList(),
            advancedEnd + 1,
          ),
          const SizedBox(height: 16),

          _buildTierCard(
            'Recreational',
            Icons.sports_volleyball,
            Colors.orange,
            _overallStandings.skip(intermediateEnd).take(widget.recreationalTierSize).toList(),
            intermediateEnd + 1,
          ),

          // Eliminated teams
          if (_overallStandings.length > recreationalEnd) ...[
            const SizedBox(height: 16),
            _buildTierCard(
              'Eliminated',
              Icons.cancel,
              Colors.grey,
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
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  '$tierName Tier',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${teams.length} teams',
                    style: const TextStyle(color: Colors.white),
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
                style: TextStyle(color: Colors.grey[600]),
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
                    bottom: BorderSide(color: Colors.grey.shade200),
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
                              color: Colors.grey[600],
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
                                ? Colors.green
                                : standing.pointDifferential < 0
                                    ? Colors.red
                                    : Colors.grey,
                          ),
                        ),
                        Text(
                          'pt diff',
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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
    switch (poolName.toUpperCase()) {
      case 'A':
        return Colors.blue;
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
        return Colors.blueGrey;
    }
  }
}
