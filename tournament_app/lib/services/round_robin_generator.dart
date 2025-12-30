/// Team data with pool assignment for pool play tournaments
class PoolTeam {
  final String teamId;
  final String? pool;

  PoolTeam({required this.teamId, this.pool});
}

class RoundRobinGenerator {
  /// Generate pool play matches - round robin within each pool
  ///
  /// [tournamentId] - The tournament ID
  /// [teamsByPool] - Map of pool name to list of team IDs (e.g., {"A": [id1, id2], "B": [id3, id4]})
  /// [startTime] - When the tournament starts
  /// [matchDurationMinutes] - Duration of each match in minutes
  /// [numberOfCourts] - Number of courts available for simultaneous matches
  /// [venue] - Venue name/location (optional)
  ///
  /// Returns a list of match data maps ready for database insertion
  static List<Map<String, dynamic>> generatePoolPlayMatches({
    required String tournamentId,
    required Map<String, List<String>> teamsByPool,
    DateTime? startTime,
    int matchDurationMinutes = 60,
    int numberOfCourts = 2,
    String? venue,
  }) {
    List<Map<String, dynamic>> allMatches = [];
    int globalMatchNumber = 1;

    // Initialize court availability tracking
    Map<int, DateTime> courtAvailability = {};
    final baseTime = startTime ?? DateTime.now();
    for (int court = 1; court <= numberOfCourts; court++) {
      courtAvailability[court] = baseTime;
    }

    // Sort pools alphabetically for consistent ordering
    final pools = teamsByPool.keys.toList()..sort();

    // Generate round robin matches for each pool
    for (final poolName in pools) {
      final teamIds = teamsByPool[poolName]!;
      if (teamIds.length < 2) continue;

      // Create a working copy of team IDs
      List<String?> teams = List.from(teamIds);

      // If odd number of teams, add a BYE (null)
      final hasOddTeams = teams.length % 2 != 0;
      if (hasOddTeams) {
        teams.add(null);
      }

      final numTeams = teams.length;
      final numRounds = numTeams - 1;
      final matchesPerRound = numTeams ~/ 2;

      // Generate matches for each round
      for (int round = 0; round < numRounds; round++) {
        final roundNumber = round + 1;
        final roundName = 'Pool $poolName - Round $roundNumber';

        // Generate pairings for this round using circle method
        for (int match = 0; match < matchesPerRound; match++) {
          int home, away;

          if (match == 0) {
            home = 0;
            away = numTeams - 1;
          } else {
            home = match;
            away = numTeams - 1 - match;
          }

          final team1Id = teams[home];
          final team2Id = teams[away];

          // Skip matches with BYE teams
          if (team1Id == null || team2Id == null) {
            continue;
          }

          // Find the earliest available court
          int assignedCourt = 1;
          DateTime earliestTime = courtAvailability[1]!;

          for (int court = 2; court <= numberOfCourts; court++) {
            if (courtAvailability[court]!.isBefore(earliestTime)) {
              earliestTime = courtAvailability[court]!;
              assignedCourt = court;
            }
          }

          // Create match data with pool information
          // Note: pool info is encoded in the round name (e.g., "Pool A - Round 1")
          // until pool/phase/tier columns are added to the database
          final matchData = {
            'tournament_id': tournamentId,
            'team1_id': team1Id,
            'team2_id': team2Id,
            'scheduled_time': earliestTime.toIso8601String(),
            'court_number': assignedCourt,
            'venue': venue,
            'round': roundName,
            'match_number': globalMatchNumber,
            'team1_score': null,
            'team2_score': null,
            'team1_sets_won': 0,
            'team2_sets_won': 0,
            'winner_id': null,
            'status': 'scheduled',
          };

          allMatches.add(matchData);

          // Update court availability
          courtAvailability[assignedCourt] = earliestTime.add(
            Duration(minutes: matchDurationMinutes),
          );

          globalMatchNumber++;
        }

        // Rotate teams for next round (circle method)
        if (round < numRounds - 1) {
          final temp = teams[numTeams - 1];
          for (int i = numTeams - 1; i > 1; i--) {
            teams[i] = teams[i - 1];
          }
          teams[1] = temp;
        }
      }
    }

    return allMatches;
  }

  /// Generate all round robin matches for a tournament (non-pool play)
  ///
  /// [tournamentId] - The tournament ID
  /// [teamIds] - List of team IDs participating
  /// [startTime] - When the tournament starts (optional)
  /// [matchDurationMinutes] - Duration of each match in minutes
  /// [numberOfCourts] - Number of courts available for simultaneous matches
  /// [venue] - Venue name/location (optional)
  ///
  /// Returns a list of match data maps ready for database insertion
  static List<Map<String, dynamic>> generateMatches({
    required String tournamentId,
    required List<String> teamIds,
    DateTime? startTime,
    int matchDurationMinutes = 60,
    int numberOfCourts = 2,
    String? venue,
  }) {
    if (teamIds.length < 2) {
      throw Exception('At least 2 teams are required for round robin');
    }

    // Create a working copy of team IDs
    List<String?> teams = List.from(teamIds);

    // If odd number of teams, add a BYE (null)
    final hasOddTeams = teams.length % 2 != 0;
    if (hasOddTeams) {
      teams.add(null); // null represents BYE
    }

    final numTeams = teams.length;
    final numRounds = numTeams - 1;
    final matchesPerRound = numTeams ~/ 2;

    List<Map<String, dynamic>> allMatches = [];
    int globalMatchNumber = 1;

    // Initialize court availability tracking
    // Map of courtNumber -> nextAvailableTime
    Map<int, DateTime> courtAvailability = {};
    final baseTime = startTime ?? DateTime.now();
    for (int court = 1; court <= numberOfCourts; court++) {
      courtAvailability[court] = baseTime;
    }

    // Generate matches for each round
    for (int round = 0; round < numRounds; round++) {
      final roundNumber = round + 1;
      final roundName = 'Round $roundNumber';

      // Generate pairings for this round using circle method
      for (int match = 0; match < matchesPerRound; match++) {
        int home, away;

        if (match == 0) {
          // First match: fixed position vs last position
          home = 0;
          away = numTeams - 1;
        } else {
          // Other matches: pair teams across the circle
          home = match;
          away = numTeams - 1 - match;
        }

        final team1Id = teams[home];
        final team2Id = teams[away];

        // Skip matches with BYE teams
        if (team1Id == null || team2Id == null) {
          continue;
        }

        // Find the earliest available court
        int assignedCourt = 1;
        DateTime earliestTime = courtAvailability[1]!;

        for (int court = 2; court <= numberOfCourts; court++) {
          if (courtAvailability[court]!.isBefore(earliestTime)) {
            earliestTime = courtAvailability[court]!;
            assignedCourt = court;
          }
        }

        // Create match data
        final matchData = {
          'tournament_id': tournamentId,
          'team1_id': team1Id,
          'team2_id': team2Id,
          'scheduled_time': earliestTime.toIso8601String(),
          'court_number': assignedCourt,
          'venue': venue,
          'round': roundName,
          'match_number': globalMatchNumber,
          'team1_score': null,
          'team2_score': null,
          'team1_sets_won': 0,
          'team2_sets_won': 0,
          'winner_id': null,
          'status': 'scheduled',
        };

        allMatches.add(matchData);

        // Update court availability
        courtAvailability[assignedCourt] = earliestTime.add(
          Duration(minutes: matchDurationMinutes),
        );

        globalMatchNumber++;
      }

      // Rotate teams for next round (circle method)
      // Keep first team fixed, rotate others clockwise
      if (round < numRounds - 1) {
        final temp = teams[numTeams - 1];
        for (int i = numTeams - 1; i > 1; i--) {
          teams[i] = teams[i - 1];
        }
        teams[1] = temp;
      }
    }

    return allMatches;
  }

  /// Calculate the total number of matches for pool play
  /// For each pool: n * (n - 1) / 2 matches
  static int calculatePoolPlayTotalMatches(Map<String, int> teamsPerPool) {
    int total = 0;
    for (final count in teamsPerPool.values) {
      if (count >= 2) {
        total += (count * (count - 1)) ~/ 2;
      }
    }
    return total;
  }

  /// Calculate the total number of matches for a given number of teams
  /// Formula: n * (n - 1) / 2
  static int calculateTotalMatches(int numberOfTeams) {
    if (numberOfTeams < 2) return 0;
    return (numberOfTeams * (numberOfTeams - 1)) ~/ 2;
  }

  /// Calculate the number of rounds needed
  /// For even teams: n - 1 rounds
  /// For odd teams: n rounds (each team gets 1 bye)
  static int calculateNumberOfRounds(int numberOfTeams) {
    if (numberOfTeams < 2) return 0;
    return numberOfTeams % 2 == 0 ? numberOfTeams - 1 : numberOfTeams;
  }

  /// Estimate tournament duration for pool play
  /// Returns duration in minutes
  static int estimatePoolPlayDuration({
    required Map<String, int> teamsPerPool,
    required int matchDurationMinutes,
    required int numberOfCourts,
  }) {
    final totalMatches = calculatePoolPlayTotalMatches(teamsPerPool);
    // Simple estimate: total matches / courts * duration
    return ((totalMatches / numberOfCourts).ceil()) * matchDurationMinutes;
  }

  /// Estimate tournament duration
  /// Returns duration in minutes
  static int estimateTournamentDuration({
    required int numberOfTeams,
    required int matchDurationMinutes,
    required int numberOfCourts,
  }) {
    if (numberOfTeams < 2) return 0;

    final matchesPerRound = (numberOfTeams / 2).ceil();
    final numberOfRounds = calculateNumberOfRounds(numberOfTeams);

    // Calculate how many "time slots" we need
    // Each time slot can have up to numberOfCourts matches
    int totalTimeSlots = 0;
    for (int round = 0; round < numberOfRounds; round++) {
      final matchesInRound = numberOfTeams % 2 == 0
          ? matchesPerRound
          : (matchesPerRound - (round % numberOfTeams == 0 ? 1 : 0));
      totalTimeSlots += (matchesInRound / numberOfCourts).ceil();
    }

    return totalTimeSlots * matchDurationMinutes;
  }

  /// Validate tournament configuration
  /// Returns null if valid, error message if invalid
  static String? validateConfiguration({
    required int numberOfTeams,
    required int numberOfCourts,
    required int matchDurationMinutes,
  }) {
    if (numberOfTeams < 2) {
      return 'At least 2 teams are required';
    }

    if (numberOfCourts < 1) {
      return 'At least 1 court is required';
    }

    if (matchDurationMinutes < 1) {
      return 'Match duration must be at least 1 minute';
    }

    if (numberOfCourts > numberOfTeams / 2) {
      return 'Warning: You have more courts than simultaneous matches. Some courts will be unused.';
    }

    return null; // Valid
  }
}
