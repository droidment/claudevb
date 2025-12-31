import '../models/match.dart';
import '../services/match_service.dart';

/// Bracket round types for elimination tournaments
enum BracketRound {
  finals,
  semiFinals,
  quarterFinals,
  roundOf16,
  roundOf32,
}

extension BracketRoundExtension on BracketRound {
  String get displayName {
    switch (this) {
      case BracketRound.finals:
        return 'Finals';
      case BracketRound.semiFinals:
        return 'Semi-Finals';
      case BracketRound.quarterFinals:
        return 'Quarter-Finals';
      case BracketRound.roundOf16:
        return 'Round of 16';
      case BracketRound.roundOf32:
        return 'Round of 32';
    }
  }

  String get shortName {
    switch (this) {
      case BracketRound.finals:
        return 'F';
      case BracketRound.semiFinals:
        return 'SF';
      case BracketRound.quarterFinals:
        return 'QF';
      case BracketRound.roundOf16:
        return 'R16';
      case BracketRound.roundOf32:
        return 'R32';
    }
  }

  int get matchCount {
    switch (this) {
      case BracketRound.finals:
        return 1;
      case BracketRound.semiFinals:
        return 2;
      case BracketRound.quarterFinals:
        return 4;
      case BracketRound.roundOf16:
        return 8;
      case BracketRound.roundOf32:
        return 16;
    }
  }
}

/// Represents a bracket match with seeding information
class BracketMatch {
  final int matchNumber;
  final BracketRound round;
  final String? team1Id;
  final String? team2Id;
  final int? team1Seed;
  final int? team2Seed;
  final int? nextMatchNumber; // Winner advances to this match
  final bool isTopSlot; // True if winner goes to top slot, false for bottom

  BracketMatch({
    required this.matchNumber,
    required this.round,
    this.team1Id,
    this.team2Id,
    this.team1Seed,
    this.team2Seed,
    this.nextMatchNumber,
    this.isTopSlot = true,
  });
}

/// Generates elimination bracket matches for tiered leagues
class BracketGenerator {
  /// Calculate the bracket size needed (next power of 2)
  static int calculateBracketSize(int teamCount) {
    if (teamCount <= 2) return 2;
    if (teamCount <= 4) return 4;
    if (teamCount <= 8) return 8;
    if (teamCount <= 16) return 16;
    return 32;
  }

  /// Get the rounds needed for a bracket of given size
  static List<BracketRound> getRoundsForSize(int bracketSize) {
    switch (bracketSize) {
      case 2:
        return [BracketRound.finals];
      case 4:
        return [BracketRound.semiFinals, BracketRound.finals];
      case 8:
        return [
          BracketRound.quarterFinals,
          BracketRound.semiFinals,
          BracketRound.finals,
        ];
      case 16:
        return [
          BracketRound.roundOf16,
          BracketRound.quarterFinals,
          BracketRound.semiFinals,
          BracketRound.finals,
        ];
      default:
        return [
          BracketRound.roundOf32,
          BracketRound.roundOf16,
          BracketRound.quarterFinals,
          BracketRound.semiFinals,
          BracketRound.finals,
        ];
    }
  }

  /// Generate standard seeding order for bracket (1v8, 4v5, 2v7, 3v6 for 8 teams)
  /// This ensures top seeds don't meet until later rounds
  static List<List<int>> getSeedPairings(int bracketSize) {
    switch (bracketSize) {
      case 2:
        return [
          [1, 2]
        ];
      case 4:
        return [
          [1, 4],
          [2, 3],
        ];
      case 8:
        return [
          [1, 8],
          [4, 5],
          [2, 7],
          [3, 6],
        ];
      case 16:
        return [
          [1, 16],
          [8, 9],
          [4, 13],
          [5, 12],
          [2, 15],
          [7, 10],
          [3, 14],
          [6, 11],
        ];
      default:
        // Generate pairings for larger brackets
        return _generateSeedPairings(bracketSize);
    }
  }

  /// Generate seed pairings dynamically for any bracket size
  static List<List<int>> _generateSeedPairings(int bracketSize) {
    if (bracketSize == 2) {
      return [
        [1, 2]
      ];
    }

    final pairings = <List<int>>[];
    final halfSize = bracketSize ~/ 2;

    // Standard tournament seeding: 1 vs bracketSize, 2 vs bracketSize-1, etc.
    // But arranged so top seeds are separated
    for (int i = 0; i < halfSize; i++) {
      final seed1 = i + 1;
      final seed2 = bracketSize - i;
      pairings.add([seed1, seed2]);
    }

    // Reorder for proper bracket placement (1v16, 8v9, 4v13, 5v12, etc.)
    return _reorderPairingsForBracket(pairings);
  }

  /// Reorder pairings so top seeds meet in later rounds
  static List<List<int>> _reorderPairingsForBracket(List<List<int>> pairings) {
    if (pairings.length <= 2) return pairings;

    final result = <List<int>>[];
    final queue = [pairings];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current.length == 1) {
        result.add(current[0]);
      } else {
        final mid = current.length ~/ 2;
        final top = current.sublist(0, mid);
        final bottom = current.sublist(mid);
        queue.add(top);
        queue.add(bottom.reversed.toList());
      }
    }

    return result;
  }

  /// Generate bracket matches for a tier
  /// Returns list of match data ready for database insertion
  static List<Map<String, dynamic>> generateBracketMatches({
    required String tournamentId,
    required String tierName,
    required List<TeamStanding> teams,
    required DateTime startTime,
    required int matchDurationMinutes,
    required int numberOfCourts,
    String? venue,
    int startingMatchNumber = 1,
  }) {
    if (teams.isEmpty) return [];

    final teamCount = teams.length;
    final bracketSize = calculateBracketSize(teamCount);
    final rounds = getRoundsForSize(bracketSize);
    final seedPairings = getSeedPairings(bracketSize);

    final matches = <Map<String, dynamic>>[];
    int matchNumber = startingMatchNumber;
    DateTime currentTime = startTime;
    int currentCourt = 1;

    // Track match numbers for advancement
    final Map<String, int> roundStartMatch = {};

    // Generate matches for each round
    for (int roundIndex = 0; roundIndex < rounds.length; roundIndex++) {
      final round = rounds[roundIndex];
      roundStartMatch[round.displayName] = matchNumber;

      final matchesInRound =
          roundIndex == 0 ? seedPairings.length : round.matchCount;

      for (int i = 0; i < matchesInRound; i++) {
        String? team1Id;
        String? team2Id;
        int? team1Seed;
        int? team2Seed;

        // Only assign teams to first round matches
        if (roundIndex == 0 && i < seedPairings.length) {
          final pairing = seedPairings[i];
          team1Seed = pairing[0];
          team2Seed = pairing[1];

          // Get actual team IDs based on seeding
          if (team1Seed <= teamCount) {
            team1Id = teams[team1Seed - 1].teamId;
          }
          if (team2Seed <= teamCount) {
            team2Id = teams[team2Seed - 1].teamId;
          }
        }

        matches.add({
          'tournament_id': tournamentId,
          'team1_id': team1Id,
          'team2_id': team2Id,
          'scheduled_time': currentTime.toIso8601String(),
          'court_number': currentCourt,
          'venue': venue,
          'round': '$tierName - ${round.displayName}',
          'match_number': matchNumber,
          'status': 'scheduled',
          'phase': 'tiered_league',
          'tier': tierName,
        });

        matchNumber++;
        currentCourt++;
        if (currentCourt > numberOfCourts) {
          currentCourt = 1;
          currentTime = currentTime.add(Duration(minutes: matchDurationMinutes));
        }
      }

      // Add break between rounds
      if (roundIndex < rounds.length - 1) {
        currentTime = currentTime.add(Duration(minutes: matchDurationMinutes));
        currentCourt = 1;
      }
    }

    return matches;
  }

  /// Generate bracket matches for all tiers in a tournament
  /// Takes the overall standings and splits into tiers
  static List<Map<String, dynamic>> generateTieredBrackets({
    required String tournamentId,
    required List<TeamStanding> overallStandings,
    required int advancedTierSize,
    required int intermediateTierSize,
    required int recreationalTierSize,
    required DateTime startTime,
    required int matchDurationMinutes,
    required int numberOfCourts,
    String? venue,
  }) {
    final allMatches = <Map<String, dynamic>>[];
    int matchNumber = 1;
    DateTime currentTime = startTime;

    // Split teams into tiers
    final advancedTeams = overallStandings.take(advancedTierSize).toList();
    final intermediateTeams = overallStandings
        .skip(advancedTierSize)
        .take(intermediateTierSize)
        .toList();
    final recreationalTeams = overallStandings
        .skip(advancedTierSize + intermediateTierSize)
        .take(recreationalTierSize)
        .toList();

    // Generate Advanced tier bracket
    if (advancedTeams.isNotEmpty) {
      final advancedMatches = generateBracketMatches(
        tournamentId: tournamentId,
        tierName: 'Advanced',
        teams: advancedTeams,
        startTime: currentTime,
        matchDurationMinutes: matchDurationMinutes,
        numberOfCourts: numberOfCourts,
        venue: venue,
        startingMatchNumber: matchNumber,
      );
      allMatches.addAll(advancedMatches);
      matchNumber += advancedMatches.length;

      // Calculate end time for advanced tier
      if (advancedMatches.isNotEmpty) {
        final lastMatch = advancedMatches.last;
        currentTime =
            DateTime.parse(lastMatch['scheduled_time'] as String)
                .add(Duration(minutes: matchDurationMinutes * 2));
      }
    }

    // Generate Intermediate tier bracket
    if (intermediateTeams.isNotEmpty) {
      final intermediateMatches = generateBracketMatches(
        tournamentId: tournamentId,
        tierName: 'Intermediate',
        teams: intermediateTeams,
        startTime: currentTime,
        matchDurationMinutes: matchDurationMinutes,
        numberOfCourts: numberOfCourts,
        venue: venue,
        startingMatchNumber: matchNumber,
      );
      allMatches.addAll(intermediateMatches);
      matchNumber += intermediateMatches.length;

      if (intermediateMatches.isNotEmpty) {
        final lastMatch = intermediateMatches.last;
        currentTime =
            DateTime.parse(lastMatch['scheduled_time'] as String)
                .add(Duration(minutes: matchDurationMinutes * 2));
      }
    }

    // Generate Recreational tier bracket
    if (recreationalTeams.isNotEmpty) {
      final recreationalMatches = generateBracketMatches(
        tournamentId: tournamentId,
        tierName: 'Recreational',
        teams: recreationalTeams,
        startTime: currentTime,
        matchDurationMinutes: matchDurationMinutes,
        numberOfCourts: numberOfCourts,
        venue: venue,
        startingMatchNumber: matchNumber,
      );
      allMatches.addAll(recreationalMatches);
    }

    return allMatches;
  }

  /// Get bracket structure info for display
  static Map<String, dynamic> getBracketInfo(int teamCount) {
    final bracketSize = calculateBracketSize(teamCount);
    final rounds = getRoundsForSize(bracketSize);
    final byes = bracketSize - teamCount;

    return {
      'teamCount': teamCount,
      'bracketSize': bracketSize,
      'rounds': rounds.map((r) => r.displayName).toList(),
      'totalMatches': bracketSize - 1,
      'byes': byes,
      'firstRoundMatches': bracketSize ~/ 2,
    };
  }

  /// Calculate total matches needed for tiered brackets
  static int calculateTotalTieredMatches({
    required int advancedTierSize,
    required int intermediateTierSize,
    required int recreationalTierSize,
  }) {
    int total = 0;

    if (advancedTierSize > 1) {
      total += calculateBracketSize(advancedTierSize) - 1;
    }
    if (intermediateTierSize > 1) {
      total += calculateBracketSize(intermediateTierSize) - 1;
    }
    if (recreationalTierSize > 1) {
      total += calculateBracketSize(recreationalTierSize) - 1;
    }

    return total;
  }
}

/// Represents a complete bracket with matches organized by round
class Bracket {
  final String tierName;
  final int bracketSize;
  final List<BracketRound> rounds;
  final Map<BracketRound, List<Match>> matchesByRound;

  Bracket({
    required this.tierName,
    required this.bracketSize,
    required this.rounds,
    required this.matchesByRound,
  });

  /// Get all matches in the bracket
  List<Match> get allMatches {
    final all = <Match>[];
    for (final round in rounds) {
      all.addAll(matchesByRound[round] ?? []);
    }
    return all;
  }

  /// Check if bracket is complete (all matches have winners)
  bool get isComplete {
    final finals = matchesByRound[BracketRound.finals];
    if (finals == null || finals.isEmpty) return false;
    return finals.first.isComplete;
  }

  /// Get the champion team ID
  String? get championId {
    final finals = matchesByRound[BracketRound.finals];
    if (finals == null || finals.isEmpty) return null;
    return finals.first.winnerId;
  }
}
