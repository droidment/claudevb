import 'package:flutter/material.dart';
import '../../models/match.dart';
import '../../models/scoring_format.dart';
import '../../models/scoring_config.dart';
import '../../services/match_service.dart';
import 'match_detail_screen.dart';
import 'tournament_results_screen.dart';

class BracketScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final bool isOrganizer;
  final ScoringFormat scoringFormat;
  final TournamentScoringConfig? tournamentScoringConfig;

  const BracketScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.isOrganizer = false,
    this.scoringFormat = ScoringFormat.singleSet,
    this.tournamentScoringConfig,
  });

  @override
  State<BracketScreen> createState() => _BracketScreenState();
}

class _BracketScreenState extends State<BracketScreen>
    with SingleTickerProviderStateMixin {
  final MatchService _matchService = MatchService();
  late TabController _tabController;

  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _matchesByTier = {};
  List<String> _tiers = [];

  @override
  void initState() {
    super.initState();
    _loadBracketMatches();
  }

  Future<void> _loadBracketMatches() async {
    setState(() => _isLoading = true);

    try {
      final allMatches = await _matchService.getMatchesWithTeams(
        widget.tournamentId,
      );

      // Filter for tiered league matches only
      final bracketMatches = allMatches.where((m) {
        final phase = m['phase'] as String?;
        return phase == 'tiered_league';
      }).toList();

      // Group by tier
      final Map<String, List<Map<String, dynamic>>> byTier = {};
      for (final match in bracketMatches) {
        final tier = match['tier'] as String? ?? 'Unknown';
        byTier.putIfAbsent(tier, () => []);
        byTier[tier]!.add(match);
      }

      // Sort tiers in order: Advanced, Intermediate, Recreational
      final tierOrder = ['Advanced', 'Intermediate', 'Recreational'];
      final tiers = byTier.keys.toList()
        ..sort((a, b) {
          final aIndex = tierOrder.indexOf(a);
          final bIndex = tierOrder.indexOf(b);
          if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
          if (aIndex == -1) return 1;
          if (bIndex == -1) return -1;
          return aIndex.compareTo(bIndex);
        });

      if (mounted) {
        setState(() {
          _matchesByTier = byTier;
          _tiers = tiers;
          _tabController = TabController(
            length: tiers.isEmpty ? 1 : tiers.length,
            vsync: this,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading brackets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_tiers.isNotEmpty) {
      _tabController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Brackets'),
            Text(
              widget.tournamentName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: _tiers.length > 1
            ? TabBar(
                controller: _tabController,
                tabs: _tiers.map((tier) => Tab(text: tier)).toList(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: _navigateToResults,
            tooltip: 'View Results',
          ),
          if (widget.isOrganizer)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _advanceAllWinners,
              tooltip: 'Advance Winners',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBracketMatches,
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
            Icon(Icons.account_tree, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No bracket matches yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete pool play to generate tier brackets',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_tiers.length == 1) {
      return _buildTierBracket(_tiers.first);
    }

    return TabBarView(
      controller: _tabController,
      children: _tiers.map((tier) => _buildTierBracket(tier)).toList(),
    );
  }

  Widget _buildTierBracket(String tier) {
    final matches = _matchesByTier[tier] ?? [];

    if (matches.isEmpty) {
      return Center(
        child: Text(
          'No matches in $tier tier',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    // Group matches by round
    final Map<String, List<Map<String, dynamic>>> matchesByRound = {};
    for (final match in matches) {
      final round = match['round'] as String? ?? 'Unknown';
      // Extract just the round name (e.g., "Advanced - Semi-Finals" -> "Semi-Finals")
      final roundName = round.contains(' - ')
          ? round.split(' - ').last
          : round;
      matchesByRound.putIfAbsent(roundName, () => []);
      matchesByRound[roundName]!.add(match);
    }

    // Order rounds correctly
    final roundOrder = [
      'Round of 32',
      'Round of 16',
      'Quarter-Finals',
      'Semi-Finals',
      'Finals',
    ];
    final orderedRounds = matchesByRound.keys.toList()
      ..sort((a, b) {
        final aIndex = roundOrder.indexOf(a);
        final bIndex = roundOrder.indexOf(b);
        if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
        if (aIndex == -1) return -1;
        if (bIndex == -1) return 1;
        return aIndex.compareTo(bIndex);
      });

    return RefreshIndicator(
      onRefresh: _loadBracketMatches,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: orderedRounds.map((round) {
              final roundMatches = matchesByRound[round]!;
              return _buildRoundColumn(round, roundMatches, tier);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundColumn(
    String roundName,
    List<Map<String, dynamic>> matches,
    String tier,
  ) {
    // Calculate spacing based on round
    final roundIndex = [
      'Round of 32',
      'Round of 16',
      'Quarter-Finals',
      'Semi-Finals',
      'Finals',
    ].indexOf(roundName);

    final spacingMultiplier = roundIndex >= 0 ? (1 << roundIndex) : 1;
    final topPadding = (spacingMultiplier - 1) * 40.0;

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 24),
      child: Column(
        children: [
          // Round header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _getTierColor(tier),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              roundName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16 + topPadding),
          // Matches
          ...matches.map((match) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: 16.0 + (spacingMultiplier - 1) * 80.0,
              ),
              child: _buildMatchCard(match),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> matchData) {
    final match = Match.fromJson(matchData);
    final team1 = matchData['team1'] as Map<String, dynamic>?;
    final team2 = matchData['team2'] as Map<String, dynamic>?;

    final team1Name = team1?['name'] as String? ?? 'TBD';
    final team2Name = team2?['name'] as String? ?? 'TBD';

    final isComplete = match.status == MatchStatus.completed;
    final team1Won = match.winnerId == match.team1Id;
    final team2Won = match.winnerId == match.team2Id;

    return GestureDetector(
      onTap: () => _navigateToMatchDetail(matchData),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isComplete ? Colors.green : Colors.grey.shade300,
            width: isComplete ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Team 1
            _buildTeamRow(
              team1Name,
              match.team1SetsWon,
              team1Won,
              isComplete,
              true,
            ),
            Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
            // Team 2
            _buildTeamRow(
              team2Name,
              match.team2SetsWon,
              team2Won,
              isComplete,
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(
    String teamName,
    int setsWon,
    bool isWinner,
    bool isComplete,
    bool isTopTeam,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isWinner ? Colors.green.shade50 : null,
        borderRadius: BorderRadius.only(
          topLeft: isTopTeam ? const Radius.circular(7) : Radius.zero,
          topRight: isTopTeam ? const Radius.circular(7) : Radius.zero,
          bottomLeft: !isTopTeam ? const Radius.circular(7) : Radius.zero,
          bottomRight: !isTopTeam ? const Radius.circular(7) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          if (isWinner)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.emoji_events, size: 16, color: Colors.amber),
            ),
          Expanded(
            child: Text(
              teamName,
              style: TextStyle(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
                color: teamName == 'TBD' ? Colors.grey : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isComplete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isWinner ? Colors.green : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$setsWon',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isWinner ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToResults() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TournamentResultsScreen(
          tournamentId: widget.tournamentId,
          tournamentName: widget.tournamentName,
          isOrganizer: widget.isOrganizer,
        ),
      ),
    );
  }

  Future<void> _advanceAllWinners() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advance Winners'),
        content: const Text(
          'This will advance all winners from completed bracket matches to their next round matches. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Advance'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final advancedCount = await _matchService.advanceAllBracketWinners(
        widget.tournamentId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Advanced winners from $advancedCount matches'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBracketMatches();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error advancing winners: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToMatchDetail(Map<String, dynamic> matchData) async {
    final match = Match.fromJson(matchData);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchDetailScreen(
          matchId: match.id,
          isOrganizer: widget.isOrganizer,
          scoringFormat: widget.scoringFormat,
          tournamentScoringConfig: widget.tournamentScoringConfig,
        ),
      ),
    );

    // Refresh when returning
    _loadBracketMatches();
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
