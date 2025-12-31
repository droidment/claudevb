import 'package:flutter/material.dart';
import '../../models/match.dart';
import '../../models/scoring_format.dart';
import '../../services/match_service.dart';
import 'match_detail_screen.dart';

class MatchesScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final bool isOrganizer;
  final ScoringFormat scoringFormat;

  const MatchesScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.isOrganizer = false,
    this.scoringFormat = ScoringFormat.singleSet,
  });

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _matchService = MatchService();
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'all'; // all, scheduled, in_progress, completed

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final matches = await _matchService.getMatchesWithTeams(
        widget.tournamentId,
      );

      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredMatches {
    if (_filterStatus == 'all') return _matches;

    return _matches.where((m) {
      final match = Match.fromJson(m);
      switch (_filterStatus) {
        case 'scheduled':
          return match.status == MatchStatus.scheduled;
        case 'in_progress':
          return match.status == MatchStatus.inProgress;
        case 'completed':
          return match.status == MatchStatus.completed;
        default:
          return true;
      }
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _matchesByRound {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final matchData in _filteredMatches) {
      final match = Match.fromJson(matchData);
      final round = match.round ?? 'Unassigned';

      if (!grouped.containsKey(round)) {
        grouped[round] = [];
      }
      grouped[round]!.add(matchData);
    }

    return grouped;
  }

  Future<void> _navigateToMatchDetail(Map<String, dynamic> matchData) async {
    final match = Match.fromJson(matchData);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchDetailScreen(
          matchId: match.id,
          isOrganizer: widget.isOrganizer,
          scoringFormat: widget.scoringFormat,
        ),
      ),
    );

    // Refresh matches when returning
    _loadMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tournament Schedule'),
            Text(
              widget.tournamentName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMatches,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No matches scheduled yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filter chips
        _buildFilterChips(),

        // Matches list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadMatches,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: _buildMatchesGroupedByRound(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Scheduled', 'scheduled'),
            const SizedBox(width: 8),
            _buildFilterChip('In Progress', 'in_progress'),
            const SizedBox(width: 8),
            _buildFilterChip('Completed', 'completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  List<Widget> _buildMatchesGroupedByRound() {
    final grouped = _matchesByRound;
    final rounds = grouped.keys.toList()..sort();

    return rounds.map((round) {
      final matches = grouped[round]!;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    round,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text('${matches.length} matches'),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
          ),
          ...matches.map((matchData) => _buildMatchCard(matchData)),
          const SizedBox(height: 16),
        ],
      );
    }).toList();
  }

  Widget _buildMatchCard(Map<String, dynamic> matchData) {
    final match = Match.fromJson(matchData);
    final team1Data = matchData['team1'] as Map<String, dynamic>?;
    final team2Data = matchData['team2'] as Map<String, dynamic>?;

    final team1Name = team1Data?['name'] as String? ?? 'TBD';
    final team2Name = team2Data?['name'] as String? ?? 'TBD';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _navigateToMatchDetail(matchData),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match number and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Match #${match.matchNumber ?? '?'}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _buildStatusBadge(match.status),
                ],
              ),
              const SizedBox(height: 12),

              // Teams and score
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team1Name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (match.isComplete && match.team1SetsWon > 0)
                          Text(
                            'Sets won: ${match.team1SetsWon}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      match.isComplete
                          ? '${match.team1SetsWon} - ${match.team2SetsWon}'
                          : 'vs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: match.isComplete
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          team2Name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                        if (match.isComplete && match.team2SetsWon > 0)
                          Text(
                            'Sets won: ${match.team2SetsWon}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.right,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Time and court info
              Row(
                children: [
                  if (match.scheduledTime != null) ...[
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(match.scheduledTime!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (match.courtNumber != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.sports_volleyball, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Court ${match.courtNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MatchStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case MatchStatus.scheduled:
        color = Colors.blue;
        icon = Icons.schedule;
        break;
      case MatchStatus.inProgress:
        color = Colors.orange;
        icon = Icons.play_circle;
        break;
      case MatchStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case MatchStatus.cancelled:
        color = Colors.red;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$month/$day at $hour:$minute';
  }
}
