import 'package:flutter/material.dart';
import '../../models/match.dart';
import '../../services/match_service.dart';
import '../../services/tournament_service.dart';
import '../../models/tournament.dart';

class TournamentResultsScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final bool isOrganizer;

  const TournamentResultsScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.isOrganizer = false,
  });

  @override
  State<TournamentResultsScreen> createState() => _TournamentResultsScreenState();
}

class _TournamentResultsScreenState extends State<TournamentResultsScreen> {
  final MatchService _matchService = MatchService();
  final TournamentService _tournamentService = TournamentService();

  bool _isLoading = true;
  Map<String, TierResult> _tierResults = {};
  List<String> _tiers = [];
  Tournament? _tournament;
  bool _allBracketsComplete = false;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);

    try {
      // Load tournament info
      final tournament = await _tournamentService.getTournament(widget.tournamentId);

      // Load all bracket matches
      final allMatches = await _matchService.getMatchesWithTeams(widget.tournamentId);

      // Filter for tiered league matches only
      final bracketMatches = allMatches.where((m) {
        final phase = m['phase'] as String?;
        return phase == 'tiered_league';
      }).toList();

      // Group by tier and analyze results
      final Map<String, TierResult> tierResults = {};
      final tierOrder = ['Advanced', 'Intermediate', 'Recreational'];

      for (final match in bracketMatches) {
        final tier = match['tier'] as String? ?? 'Unknown';
        tierResults.putIfAbsent(tier, () => TierResult(tierName: tier));
        tierResults[tier]!.addMatch(match);
      }

      // Sort tiers
      final tiers = tierResults.keys.toList()
        ..sort((a, b) {
          final aIndex = tierOrder.indexOf(a);
          final bIndex = tierOrder.indexOf(b);
          if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
          if (aIndex == -1) return 1;
          if (bIndex == -1) return -1;
          return aIndex.compareTo(bIndex);
        });

      // Check if all brackets are complete
      final allComplete = tierResults.values.every((tier) => tier.isComplete);

      if (mounted) {
        setState(() {
          _tournament = tournament;
          _tierResults = tierResults;
          _tiers = tiers;
          _allBracketsComplete = allComplete;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading results: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _closeTournament() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Tournament'),
        content: const Text(
          'This will mark the tournament as completed. This action signifies that all matches are done and the tournament is officially over.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Close Tournament'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _tournamentService.updateTournamentStatus(
        widget.tournamentId,
        TournamentStatus.completed,
      );

      await _loadResults();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament closed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error closing tournament: $e'),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tournament Results'),
            Text(
              widget.tournamentName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadResults,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tiers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No bracket results yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete bracket matches to see results',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final isCompleted = _tournament?.status == TournamentStatus.completed;

    return RefreshIndicator(
      onRefresh: _loadResults,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tournament status card
          _buildStatusCard(isCompleted),
          const SizedBox(height: 24),

          // Results by tier
          ..._tiers.map((tier) => _buildTierResults(tier)),

          // Close tournament button
          if (widget.isOrganizer && _allBracketsComplete && !isCompleted) ...[
            const SizedBox(height: 24),
            _buildCloseTournamentButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isCompleted) {
    return Card(
      color: isCompleted ? Colors.green.shade50 : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.sports_volleyball,
              color: isCompleted ? Colors.green : Colors.blue,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCompleted ? 'Tournament Completed' : 'Tournament In Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCompleted ? Colors.green.shade900 : Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted
                        ? 'All matches have been completed and results are final.'
                        : _allBracketsComplete
                            ? 'All bracket matches are complete. Ready to close tournament.'
                            : 'Some bracket matches are still in progress.',
                    style: TextStyle(
                      color: isCompleted ? Colors.green.shade700 : Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierResults(String tier) {
    final result = _tierResults[tier];
    if (result == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getTierColor(tier),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  '$tier Tier',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                if (result.isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Complete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Results content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Champion
                if (result.champion != null)
                  _buildPlacementRow(
                    placement: 1,
                    teamName: result.champion!,
                    icon: Icons.emoji_events,
                    iconColor: Colors.amber,
                    backgroundColor: Colors.amber.shade50,
                  ),

                // Runner-up
                if (result.runnerUp != null)
                  _buildPlacementRow(
                    placement: 2,
                    teamName: result.runnerUp!,
                    icon: Icons.workspace_premium,
                    iconColor: Colors.grey.shade600,
                    backgroundColor: Colors.grey.shade100,
                  ),

                // Semi-finalists
                if (result.semiFinalists.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Semi-Finalists',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...result.semiFinalists.map((team) => _buildPlacementRow(
                        placement: 3,
                        teamName: team,
                        icon: Icons.military_tech,
                        iconColor: Colors.brown,
                        backgroundColor: Colors.brown.shade50,
                        showPlacement: false,
                      )),
                ],

                // Match summary
                const Divider(),
                const SizedBox(height: 8),
                _buildMatchSummary(result),

                // Finals score if available
                if (result.finalsMatch != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildFinalsScore(result.finalsMatch!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementRow({
    required int placement,
    required String teamName,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    bool showPlacement = true,
    String? teamColor,
  }) {
    // Parse team color or use a default based on placement
    Color avatarColor;
    if (teamColor != null) {
      try {
        avatarColor = Color(int.parse(teamColor.replaceFirst('#', '0xFF')));
      } catch (_) {
        avatarColor = _getPlacementAvatarColor(placement);
      }
    } else {
      avatarColor = _getPlacementAvatarColor(placement);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Placement number badge
          if (showPlacement)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '$placement',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: iconColor,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 32),
          const SizedBox(width: 12),
          // Team trophy/medal icon
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          // Team avatar
          _buildTeamAvatar(teamName, avatarColor),
          const SizedBox(width: 12),
          // Team name
          Expanded(
            child: Text(
              teamName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a circular team avatar with the team's initial
  Widget _buildTeamAvatar(String teamName, Color color) {
    final initial = teamName.isNotEmpty ? teamName[0].toUpperCase() : '?';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
      ),
    );
  }

  /// Get avatar color based on placement
  Color _getPlacementAvatarColor(int placement) {
    switch (placement) {
      case 1:
        return Colors.amber.shade700;
      case 2:
        return Colors.blueGrey.shade600;
      case 3:
        return Colors.brown.shade600;
      default:
        return Colors.blue;
    }
  }

  Widget _buildMatchSummary(TierResult result) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          label: 'Total Matches',
          value: '${result.totalMatches}',
          icon: Icons.sports_volleyball,
        ),
        _buildStatItem(
          label: 'Completed',
          value: '${result.completedMatches}',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _buildStatItem(
          label: 'Remaining',
          value: '${result.totalMatches - result.completedMatches}',
          icon: Icons.pending,
          color: result.isComplete ? Colors.grey : Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFinalsScore(Map<String, dynamic> finalsMatch) {
    final match = Match.fromJson(finalsMatch);
    final team1 = finalsMatch['team1'] as Map<String, dynamic>?;
    final team2 = finalsMatch['team2'] as Map<String, dynamic>?;

    final team1Name = team1?['name'] as String? ?? 'TBD';
    final team2Name = team2?['name'] as String? ?? 'TBD';
    final team1Color = team1?['team_color'] as String?;
    final team2Color = team2?['team_color'] as String?;

    final team1Won = match.winnerId == match.team1Id;
    final team2Won = match.winnerId == match.team2Id;

    // Parse team colors
    Color team1AvatarColor;
    Color team2AvatarColor;
    try {
      team1AvatarColor = team1Color != null
          ? Color(int.parse(team1Color.replaceFirst('#', '0xFF')))
          : Colors.blue;
    } catch (_) {
      team1AvatarColor = Colors.blue;
    }
    try {
      team2AvatarColor = team2Color != null
          ? Color(int.parse(team2Color.replaceFirst('#', '0xFF')))
          : Colors.red;
    } catch (_) {
      team2AvatarColor = Colors.red;
    }

    return Column(
      children: [
        Text(
          'Finals',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              // Team 1
              Expanded(
                child: Column(
                  children: [
                    // Team avatar with winner indicator
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: team1AvatarColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: team1Won ? Colors.amber : team1AvatarColor,
                              width: team1Won ? 3 : 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              team1Name.isNotEmpty ? team1Name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: team1AvatarColor,
                              ),
                            ),
                          ),
                        ),
                        if (team1Won)
                          Positioned(
                            top: -8,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Icon(
                                Icons.emoji_events,
                                color: Colors.amber.shade700,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      team1Name,
                      style: TextStyle(
                        fontWeight: team1Won ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                        color: team1Won ? Colors.green.shade700 : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${match.team1SetsWon} - ${match.team2SetsWon}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              // Team 2
              Expanded(
                child: Column(
                  children: [
                    // Team avatar with winner indicator
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: team2AvatarColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: team2Won ? Colors.amber : team2AvatarColor,
                              width: team2Won ? 3 : 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              team2Name.isNotEmpty ? team2Name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: team2AvatarColor,
                              ),
                            ),
                          ),
                        ),
                        if (team2Won)
                          Positioned(
                            top: -8,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Icon(
                                Icons.emoji_events,
                                color: Colors.amber.shade700,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      team2Name,
                      style: TextStyle(
                        fontWeight: team2Won ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                        color: team2Won ? Colors.green.shade700 : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCloseTournamentButton() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.flag, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            const Text(
              'All bracket matches are complete!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Close the tournament to finalize results.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _closeTournament,
              icon: const Icon(Icons.check_circle),
              label: const Text('Close Tournament'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Advanced':
        return Colors.green;
      case 'Intermediate':
        return Colors.blue;
      case 'Recreational':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

/// Helper class to track results for a tier
class TierResult {
  final String tierName;
  final List<Map<String, dynamic>> matches = [];

  TierResult({required this.tierName});

  void addMatch(Map<String, dynamic> match) {
    matches.add(match);
  }

  int get totalMatches => matches.length;

  int get completedMatches => matches.where((m) {
        final status = m['status'] as String?;
        return status == 'completed';
      }).length;

  bool get isComplete => totalMatches > 0 && completedMatches == totalMatches;

  Map<String, dynamic>? get finalsMatch {
    try {
      return matches.firstWhere((m) {
        final round = m['round'] as String? ?? '';
        return round.contains('Finals') && !round.contains('Semi');
      });
    } catch (e) {
      return null;
    }
  }

  String? get champion {
    final finals = finalsMatch;
    if (finals == null) return null;

    final match = Match.fromJson(finals);
    if (match.winnerId == null) return null;

    final team1 = finals['team1'] as Map<String, dynamic>?;
    final team2 = finals['team2'] as Map<String, dynamic>?;

    if (match.winnerId == match.team1Id) {
      return team1?['name'] as String?;
    } else if (match.winnerId == match.team2Id) {
      return team2?['name'] as String?;
    }
    return null;
  }

  String? get runnerUp {
    final finals = finalsMatch;
    if (finals == null) return null;

    final match = Match.fromJson(finals);
    if (match.winnerId == null) return null;

    final team1 = finals['team1'] as Map<String, dynamic>?;
    final team2 = finals['team2'] as Map<String, dynamic>?;

    // Runner-up is the team that lost the finals
    if (match.winnerId == match.team1Id) {
      return team2?['name'] as String?;
    } else if (match.winnerId == match.team2Id) {
      return team1?['name'] as String?;
    }
    return null;
  }

  List<String> get semiFinalists {
    // Teams that lost in the semi-finals
    final semiFinals = matches.where((m) {
      final round = m['round'] as String? ?? '';
      return round.contains('Semi-Finals');
    }).toList();

    final losers = <String>[];
    for (final sf in semiFinals) {
      final match = Match.fromJson(sf);
      if (match.winnerId == null) continue;

      final team1 = sf['team1'] as Map<String, dynamic>?;
      final team2 = sf['team2'] as Map<String, dynamic>?;

      // Add the losing team
      if (match.winnerId == match.team1Id && team2 != null) {
        final name = team2['name'] as String?;
        if (name != null) losers.add(name);
      } else if (match.winnerId == match.team2Id && team1 != null) {
        final name = team1['name'] as String?;
        if (name != null) losers.add(name);
      }
    }
    return losers;
  }
}
