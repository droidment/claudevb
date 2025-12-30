import '../core/supabase_client.dart';
import '../models/match.dart';
import '../models/match_set.dart';

class MatchService {
  /// Get all matches for a tournament
  Future<List<Match>> getMatchesForTournament(String tournamentId) async {
    final response = await supabase
        .from('matches')
        .select()
        .eq('tournament_id', tournamentId)
        .order('scheduled_time', ascending: true);

    return (response as List).map((json) => Match.fromJson(json)).toList();
  }

  /// Get matches for a tournament with team details
  Future<List<Map<String, dynamic>>> getMatchesWithTeams(
    String tournamentId,
  ) async {
    final response = await supabase
        .from('matches')
        .select('''
          *,
          team1:team1_id (id, name, home_city, team_color),
          team2:team2_id (id, name, home_city, team_color)
        ''')
        .eq('tournament_id', tournamentId)
        .order('scheduled_time', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Get a single match by ID
  Future<Match> getMatch(String matchId) async {
    final response = await supabase
        .from('matches')
        .select()
        .eq('id', matchId)
        .single();

    return Match.fromJson(response);
  }

  /// Get a match with team details
  Future<Map<String, dynamic>> getMatchWithTeams(String matchId) async {
    final response = await supabase
        .from('matches')
        .select('''
          *,
          team1:team1_id (id, name, home_city, team_color),
          team2:team2_id (id, name, home_city, team_color)
        ''')
        .eq('id', matchId)
        .single();

    return response;
  }

  /// Get all sets for a match
  Future<List<MatchSet>> getSetsForMatch(String matchId) async {
    final response = await supabase
        .from('match_sets')
        .select()
        .eq('match_id', matchId)
        .order('set_number', ascending: true);

    return (response as List).map((json) => MatchSet.fromJson(json)).toList();
  }

  /// Create multiple matches (batch insert)
  Future<List<Match>> createMatches(
    List<Map<String, dynamic>> matchesData,
  ) async {
    final response = await supabase
        .from('matches')
        .insert(matchesData)
        .select();

    return (response as List).map((json) => Match.fromJson(json)).toList();
  }

  /// Create a single match
  Future<Match> createMatch(Map<String, dynamic> matchData) async {
    final response = await supabase
        .from('matches')
        .insert(matchData)
        .select()
        .single();

    return Match.fromJson(response);
  }

  /// Update match score and winner
  Future<Match> updateMatchScore({
    required String matchId,
    required int team1Score,
    required int team2Score,
    String? winnerId,
  }) async {
    final updates = {
      'team1_score': team1Score,
      'team2_score': team2Score,
      'winner_id': winnerId,
    };

    final response = await supabase
        .from('matches')
        .update(updates)
        .eq('id', matchId)
        .select()
        .single();

    return Match.fromJson(response);
  }

  /// Update match sets won counts
  Future<Match> updateMatchSetsWon({
    required String matchId,
    required int team1SetsWon,
    required int team2SetsWon,
  }) async {
    final updates = {
      'team1_sets_won': team1SetsWon,
      'team2_sets_won': team2SetsWon,
    };

    final response = await supabase
        .from('matches')
        .update(updates)
        .eq('id', matchId)
        .select()
        .single();

    return Match.fromJson(response);
  }

  /// Update match status
  Future<Match> updateMatchStatus({
    required String matchId,
    required MatchStatus status,
  }) async {
    final response = await supabase
        .from('matches')
        .update({'status': status.dbValue})
        .eq('id', matchId)
        .select()
        .single();

    return Match.fromJson(response);
  }

  /// Update match (generic)
  Future<Match> updateMatch(
    String matchId,
    Map<String, dynamic> updates,
  ) async {
    final response = await supabase
        .from('matches')
        .update(updates)
        .eq('id', matchId)
        .select()
        .single();

    return Match.fromJson(response);
  }

  /// Delete a match
  Future<void> deleteMatch(String matchId) async {
    await supabase.from('matches').delete().eq('id', matchId);
  }

  /// Delete all matches for a tournament
  Future<void> deleteMatchesForTournament(String tournamentId) async {
    await supabase
        .from('matches')
        .delete()
        .eq('tournament_id', tournamentId);
  }

  /// Create a match set
  Future<MatchSet> createMatchSet({
    required String matchId,
    required int setNumber,
    required int team1Score,
    required int team2Score,
  }) async {
    final data = {
      'match_id': matchId,
      'set_number': setNumber,
      'team1_score': team1Score,
      'team2_score': team2Score,
    };

    final response = await supabase
        .from('match_sets')
        .insert(data)
        .select()
        .single();

    return MatchSet.fromJson(response);
  }

  /// Update a match set
  Future<MatchSet> updateMatchSet({
    required String setId,
    required int team1Score,
    required int team2Score,
  }) async {
    final updates = {
      'team1_score': team1Score,
      'team2_score': team2Score,
    };

    final response = await supabase
        .from('match_sets')
        .update(updates)
        .eq('id', setId)
        .select()
        .single();

    return MatchSet.fromJson(response);
  }

  /// Delete a match set
  Future<void> deleteMatchSet(String setId) async {
    await supabase.from('match_sets').delete().eq('id', setId);
  }

  /// Calculate and update match winner based on sets won
  /// Returns the updated match
  Future<Match> calculateMatchWinner(String matchId) async {
    // Get all sets for this match
    final sets = await getSetsForMatch(matchId);

    // Count sets won by each team
    int team1SetsWon = 0;
    int team2SetsWon = 0;

    for (final set in sets) {
      if (set.winningTeam == 1) {
        team1SetsWon++;
      } else if (set.winningTeam == 2) {
        team2SetsWon++;
      }
    }

    // Get the match to determine team IDs
    final match = await getMatch(matchId);

    // Determine winner
    String? winnerId;
    if (team1SetsWon > team2SetsWon) {
      winnerId = match.team1Id;
    } else if (team2SetsWon > team1SetsWon) {
      winnerId = match.team2Id;
    }

    // Calculate total match scores (sum of all sets)
    int team1TotalScore = sets.fold(0, (sum, set) => sum + set.team1Score);
    int team2TotalScore = sets.fold(0, (sum, set) => sum + set.team2Score);

    // Update match with sets won, total scores, and winner
    final updates = {
      'team1_sets_won': team1SetsWon,
      'team2_sets_won': team2SetsWon,
      'team1_score': team1TotalScore,
      'team2_score': team2TotalScore,
      'winner_id': winnerId,
    };

    final response = await supabase
        .from('matches')
        .update(updates)
        .eq('id', matchId)
        .select()
        .single();

    return Match.fromJson(response);
  }

  /// Check if a tournament has any matches generated
  Future<bool> hasTournamentMatches(String tournamentId) async {
    final response = await supabase
        .from('matches')
        .select('id')
        .eq('tournament_id', tournamentId)
        .limit(1);

    return (response as List).isNotEmpty;
  }

  /// Get match count for a tournament
  Future<int> getMatchCount(String tournamentId) async {
    final response = await supabase
        .from('matches')
        .select('id')
        .eq('tournament_id', tournamentId);

    return (response as List).length;
  }

  /// Calculate pool standings for a tournament
  /// Returns a map of pool name to list of team standings
  Future<Map<String, List<TeamStanding>>> calculatePoolStandings(
    String tournamentId,
  ) async {
    // Get all matches with team details
    final matches = await getMatchesWithTeams(tournamentId);

    // Group matches by pool (extracted from round name like "Pool A - Round 1")
    final Map<String, List<Map<String, dynamic>>> matchesByPool = {};
    final Map<String, Map<String, TeamStanding>> standingsByPool = {};

    for (final match in matches) {
      final round = match['round'] as String? ?? '';
      String? poolName;

      // Extract pool name from round (e.g., "Pool A - Round 1" -> "A")
      if (round.startsWith('Pool ')) {
        final parts = round.split(' - ');
        if (parts.isNotEmpty) {
          poolName = parts[0].replaceFirst('Pool ', '');
        }
      }

      if (poolName == null) continue;

      // Now poolName is guaranteed to be non-null
      final pool = poolName;

      matchesByPool.putIfAbsent(pool, () => []);
      matchesByPool[pool]!.add(match);

      // Initialize standings for teams in this pool
      standingsByPool.putIfAbsent(pool, () => {});

      final team1 = match['team1'] as Map<String, dynamic>?;
      final team2 = match['team2'] as Map<String, dynamic>?;

      if (team1 != null) {
        final team1Id = team1['id'] as String;
        standingsByPool[pool]!.putIfAbsent(
          team1Id,
          () => TeamStanding(
            teamId: team1Id,
            teamName: team1['name'] as String? ?? 'Unknown',
            pool: pool,
          ),
        );
      }

      if (team2 != null) {
        final team2Id = team2['id'] as String;
        standingsByPool[pool]!.putIfAbsent(
          team2Id,
          () => TeamStanding(
            teamId: team2Id,
            teamName: team2['name'] as String? ?? 'Unknown',
            pool: pool,
          ),
        );
      }

      // Update standings based on match result
      if (match['status'] == 'completed') {
        final winnerId = match['winner_id'] as String?;
        final team1Score = match['team1_score'] as int? ?? 0;
        final team2Score = match['team2_score'] as int? ?? 0;
        final team1SetsWon = match['team1_sets_won'] as int? ?? 0;
        final team2SetsWon = match['team2_sets_won'] as int? ?? 0;

        if (team1 != null) {
          final standing = standingsByPool[pool]![team1['id'] as String]!;
          standing.matchesPlayed++;
          standing.pointsFor += team1Score;
          standing.pointsAgainst += team2Score;
          standing.setsWon += team1SetsWon;
          standing.setsLost += team2SetsWon;

          if (winnerId == team1['id']) {
            standing.wins++;
          } else if (winnerId != null) {
            standing.losses++;
          }
        }

        if (team2 != null) {
          final standing = standingsByPool[pool]![team2['id'] as String]!;
          standing.matchesPlayed++;
          standing.pointsFor += team2Score;
          standing.pointsAgainst += team1Score;
          standing.setsWon += team2SetsWon;
          standing.setsLost += team1SetsWon;

          if (winnerId == team2['id']) {
            standing.wins++;
          } else if (winnerId != null) {
            standing.losses++;
          }
        }
      }
    }

    // Convert to sorted lists
    final Map<String, List<TeamStanding>> result = {};
    for (final entry in standingsByPool.entries) {
      final standings = entry.value.values.toList();
      // Sort by: wins (desc), point differential (desc), points for (desc)
      standings.sort((a, b) {
        if (a.wins != b.wins) return b.wins.compareTo(a.wins);
        if (a.pointDifferential != b.pointDifferential) {
          return b.pointDifferential.compareTo(a.pointDifferential);
        }
        return b.pointsFor.compareTo(a.pointsFor);
      });
      result[entry.key] = standings;
    }

    return result;
  }

  /// Get overall standings across all pools for tier assignment
  Future<List<TeamStanding>> getOverallStandings(String tournamentId) async {
    final poolStandings = await calculatePoolStandings(tournamentId);

    // Flatten all standings
    final allStandings = <TeamStanding>[];
    for (final standings in poolStandings.values) {
      allStandings.addAll(standings);
    }

    // Sort by: wins (desc), point differential (desc), points for (desc)
    allStandings.sort((a, b) {
      if (a.wins != b.wins) return b.wins.compareTo(a.wins);
      if (a.pointDifferential != b.pointDifferential) {
        return b.pointDifferential.compareTo(a.pointDifferential);
      }
      return b.pointsFor.compareTo(a.pointsFor);
    });

    return allStandings;
  }

  /// Get tournament progress stats
  Future<TournamentProgress> getTournamentProgress(String tournamentId) async {
    final matches = await getMatchesForTournament(tournamentId);

    int totalMatches = matches.length;
    int completedMatches = matches.where((m) => m.status == MatchStatus.completed).length;
    int inProgressMatches = matches.where((m) => m.status == MatchStatus.inProgress).length;
    int scheduledMatches = matches.where((m) => m.status == MatchStatus.scheduled).length;

    // Count matches by pool
    final Map<String, int> totalByPool = {};
    final Map<String, int> completedByPool = {};

    for (final match in matches) {
      final round = match.round ?? '';
      String? poolName;

      if (round.startsWith('Pool ')) {
        final parts = round.split(' - ');
        if (parts.isNotEmpty) {
          poolName = parts[0].replaceFirst('Pool ', '');
        }
      }

      if (poolName != null) {
        totalByPool[poolName] = (totalByPool[poolName] ?? 0) + 1;
        if (match.status == MatchStatus.completed) {
          completedByPool[poolName] = (completedByPool[poolName] ?? 0) + 1;
        }
      }
    }

    return TournamentProgress(
      totalMatches: totalMatches,
      completedMatches: completedMatches,
      inProgressMatches: inProgressMatches,
      scheduledMatches: scheduledMatches,
      totalByPool: totalByPool,
      completedByPool: completedByPool,
    );
  }
}

/// Team standing in a pool
class TeamStanding {
  final String teamId;
  final String teamName;
  final String pool;
  int matchesPlayed = 0;
  int wins = 0;
  int losses = 0;
  int pointsFor = 0;
  int pointsAgainst = 0;
  int setsWon = 0;
  int setsLost = 0;

  TeamStanding({
    required this.teamId,
    required this.teamName,
    required this.pool,
  });

  int get pointDifferential => pointsFor - pointsAgainst;
  int get setDifferential => setsWon - setsLost;
  double get winPercentage => matchesPlayed > 0 ? wins / matchesPlayed : 0;
}

/// Tournament progress stats
class TournamentProgress {
  final int totalMatches;
  final int completedMatches;
  final int inProgressMatches;
  final int scheduledMatches;
  final Map<String, int> totalByPool;
  final Map<String, int> completedByPool;

  TournamentProgress({
    required this.totalMatches,
    required this.completedMatches,
    required this.inProgressMatches,
    required this.scheduledMatches,
    required this.totalByPool,
    required this.completedByPool,
  });

  double get progressPercentage =>
      totalMatches > 0 ? completedMatches / totalMatches : 0;

  bool get isPoolPlayComplete =>
      totalMatches > 0 && completedMatches == totalMatches;
}
