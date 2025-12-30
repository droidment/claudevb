import 'package:flutter/material.dart';
import '../../models/match.dart';
import '../../models/match_set.dart';
import '../../models/scoring_format.dart';
import '../../services/match_service.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;
  final bool isOrganizer;
  final ScoringFormat scoringFormat;

  const MatchDetailScreen({
    super.key,
    required this.matchId,
    this.isOrganizer = false,
    this.scoringFormat = ScoringFormat.singleSet,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final _matchService = MatchService();
  Match? _match;
  List<MatchSet> _sets = [];
  String? _team1Name;
  String? _team2Name;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMatchData();
  }

  Future<void> _loadMatchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final matchData = await _matchService.getMatchWithTeams(widget.matchId);
      final sets = await _matchService.getSetsForMatch(widget.matchId);

      final team1Data = matchData['team1'] as Map<String, dynamic>?;
      final team2Data = matchData['team2'] as Map<String, dynamic>?;

      setState(() {
        _match = Match.fromJson(matchData);
        _sets = sets;
        _team1Name = team1Data?['name'] as String? ?? 'Team 1';
        _team2Name = team2Data?['name'] as String? ?? 'Team 2';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addSet() async {
    if (_match == null) return;

    // Check if match is already complete based on scoring format
    final setsToWin = widget.scoringFormat.setsToWin;
    final team1SetsWon = _match!.team1SetsWon;
    final team2SetsWon = _match!.team2SetsWon;

    if (team1SetsWon >= setsToWin || team2SetsWon >= setsToWin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Match is already complete (${widget.scoringFormat.displayName})',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Check if max sets reached
    if (_sets.length >= widget.scoringFormat.maxSets) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Maximum sets reached (${widget.scoringFormat.maxSets})',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final setNumber = _sets.length + 1;
    final targetScore = widget.scoringFormat.targetScoreForSet(setNumber);

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _AddSetDialog(
        setNumber: setNumber,
        team1Name: _team1Name!,
        team2Name: _team2Name!,
        targetScore: targetScore,
        scoringFormat: widget.scoringFormat,
      ),
    );

    if (result == null) return;

    try {
      await _matchService.createMatchSet(
        matchId: widget.matchId,
        setNumber: _sets.length + 1,
        team1Score: result['team1']!,
        team2Score: result['team2']!,
      );

      // Recalculate match winner
      await _matchService.calculateMatchWinner(widget.matchId);

      await _loadMatchData();

      // Check if match should be auto-completed
      _checkAndCompleteMatch();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Set added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding set: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editSet(MatchSet set) async {
    final targetScore = widget.scoringFormat.targetScoreForSet(set.setNumber);

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _AddSetDialog(
        setNumber: set.setNumber,
        team1Name: _team1Name!,
        team2Name: _team2Name!,
        initialTeam1Score: set.team1Score,
        initialTeam2Score: set.team2Score,
        targetScore: targetScore,
        scoringFormat: widget.scoringFormat,
      ),
    );

    if (result == null) return;

    try {
      await _matchService.updateMatchSet(
        setId: set.id,
        team1Score: result['team1']!,
        team2Score: result['team2']!,
      );

      // Recalculate match winner
      await _matchService.calculateMatchWinner(widget.matchId);

      await _loadMatchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Set updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating set: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSet(MatchSet set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Set'),
        content: Text('Are you sure you want to delete Set ${set.setNumber}?'),
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

    if (confirmed != true) return;

    try {
      await _matchService.deleteMatchSet(set.id);

      // Recalculate match winner
      await _matchService.calculateMatchWinner(widget.matchId);

      await _loadMatchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Set deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting set: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _checkAndCompleteMatch() {
    if (_match == null || _sets.length < 2) return;

    // Auto-complete if a team has won best of 3 (2 sets) or best of 5 (3 sets)
    final team1SetsWon = _sets.where((s) => s.winningTeam == 1).length;
    final team2SetsWon = _sets.where((s) => s.winningTeam == 2).length;

    bool shouldComplete = false;
    if (_sets.length >= 2 && (team1SetsWon >= 2 || team2SetsWon >= 2)) {
      shouldComplete = true; // Best of 3
    } else if (_sets.length >= 3 && (team1SetsWon >= 3 || team2SetsWon >= 3)) {
      shouldComplete = true; // Best of 5
    }

    if (shouldComplete && _match!.status != MatchStatus.completed) {
      _updateMatchStatus(MatchStatus.completed);
    }
  }

  Future<void> _updateMatchStatus(MatchStatus newStatus) async {
    try {
      await _matchService.updateMatchStatus(
        matchId: widget.matchId,
        status: newStatus,
      );

      await _loadMatchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Match status updated to ${newStatus.displayName}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_match != null
            ? 'Match #${_match!.matchNumber ?? '?'}'
            : 'Match Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
      floatingActionButton: widget.isOrganizer && _match != null && !_match!.isComplete
          ? FloatingActionButton.extended(
              onPressed: _addSet,
              icon: const Icon(Icons.add),
              label: const Text('Add Set'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _match == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${_error ?? "Match not found"}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMatchData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMatchData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMatchInfoCard(),
          const SizedBox(height: 16),
          _buildTeamsCard(),
          const SizedBox(height: 16),
          _buildSetsCard(),
          const SizedBox(height: 16),
          if (widget.isOrganizer) _buildActionsCard(),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildMatchInfoCard() {
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
                  'Match Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(_match!.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.sports,
              'Round',
              _match!.round ?? 'TBD',
            ),
            if (_match!.scheduledTime != null)
              _buildInfoRow(
                Icons.schedule,
                'Scheduled',
                _formatDateTime(_match!.scheduledTime!),
              ),
            if (_match!.courtNumber != null)
              _buildInfoRow(
                Icons.sports_volleyball,
                'Court',
                'Court ${_match!.courtNumber}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsCard() {
    final team1Wins = _sets.where((s) => s.winningTeam == 1).length;
    final team2Wins = _sets.where((s) => s.winningTeam == 2).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Team 1
            Row(
              children: [
                Expanded(
                  child: Text(
                    _team1Name!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_match!.winnerId == _match!.team1Id)
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
              ],
            ),
            if (_sets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Sets won: $team1Wins',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),

            const SizedBox(height: 16),
            Text(
              'VS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),

            // Team 2
            Row(
              children: [
                if (_match!.winnerId == _match!.team2Id)
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                Expanded(
                  child: Text(
                    _team2Name!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            if (_sets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Sets won: $team2Wins',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Scores',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_sets.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.score, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No sets recorded yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._sets.map((set) => _buildSetTile(set)),
          ],
        ),
      ),
    );
  }

  Widget _buildSetTile(MatchSet set) {
    final isValid = set.isValidVolleyballScore;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: !isValid ? Colors.orange.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: set.winningTeam == 1
              ? Colors.green
              : set.winningTeam == 2
                  ? Colors.blue
                  : Colors.grey,
          child: Text(
            '${set.setNumber}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${set.team1Score}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: set.winningTeam == 1
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('-', style: TextStyle(fontSize: 24)),
            ),
            Text(
              '${set.team2Score}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: set.winningTeam == 2
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: !isValid
            ? const Text(
                'Unusual volleyball score',
                style: TextStyle(color: Colors.orange, fontSize: 11),
                textAlign: TextAlign.center,
              )
            : null,
        trailing: widget.isOrganizer
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editSet(set);
                  } else if (value == 'delete') {
                    _deleteSet(set);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_match!.status == MatchStatus.scheduled)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _updateMatchStatus(MatchStatus.inProgress),
                  icon: const Icon(Icons.play_circle),
                  label: const Text('Start Match'),
                ),
              ),
            if (_match!.status == MatchStatus.inProgress)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _updateMatchStatus(MatchStatus.completed),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete Match'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            if (_match!.status != MatchStatus.cancelled) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _updateMatchStatus(MatchStatus.cancelled),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Match'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} '
        'at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Dialog for adding or editing a set
class _AddSetDialog extends StatefulWidget {
  final int setNumber;
  final String team1Name;
  final String team2Name;
  final int? initialTeam1Score;
  final int? initialTeam2Score;
  final int targetScore;
  final ScoringFormat scoringFormat;

  const _AddSetDialog({
    required this.setNumber,
    required this.team1Name,
    required this.team2Name,
    this.initialTeam1Score,
    this.initialTeam2Score,
    this.targetScore = 25,
    this.scoringFormat = ScoringFormat.singleSet,
  });

  @override
  State<_AddSetDialog> createState() => _AddSetDialogState();
}

class _AddSetDialogState extends State<_AddSetDialog> {
  late TextEditingController _team1Controller;
  late TextEditingController _team2Controller;

  @override
  void initState() {
    super.initState();
    _team1Controller = TextEditingController(
      text: widget.initialTeam1Score?.toString() ?? '',
    );
    _team2Controller = TextEditingController(
      text: widget.initialTeam2Score?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    super.dispose();
  }

  String _getSetInfo() {
    switch (widget.scoringFormat) {
      case ScoringFormat.singleSet:
        return 'Play to ${widget.targetScore} (win by 2)';
      case ScoringFormat.bestOfThree:
        if (widget.setNumber <= 2) {
          return 'Set ${widget.setNumber} of 3 • Play to 21 (win by 2)';
        } else {
          return 'Set 3 (Tiebreaker) • Play to 15 (win by 2)';
        }
      case ScoringFormat.bestOfThreeFull:
        return 'Set ${widget.setNumber} of 3 • Play to 25 (win by 2)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.initialTeam1Score == null ? 'Add' : 'Edit'} Set ${widget.setNumber}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scoring info
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSetInfo(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: _team1Controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: widget.team1Name,
              hintText: '${widget.targetScore}',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.sports_volleyball),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _team2Controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: widget.team2Name,
              hintText: '${widget.targetScore - 2}',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.sports_volleyball),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final team1Score = int.tryParse(_team1Controller.text);
            final team2Score = int.tryParse(_team2Controller.text);

            if (team1Score == null || team2Score == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter valid scores'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (team1Score < 0 || team2Score < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scores must be positive'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Validate the score based on scoring format
            if (!widget.scoringFormat.isValidSetScore(
              widget.setNumber,
              team1Score,
              team2Score,
            )) {
              final target = widget.targetScore;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Invalid score. Winner must reach $target and win by 2 points.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            Navigator.of(context).pop({
              'team1': team1Score,
              'team2': team2Score,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
