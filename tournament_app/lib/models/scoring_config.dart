import 'dart:convert';

/// Tournament phases that can have different scoring configurations
enum TournamentPhase {
  poolPlay,
  quarterFinals,
  semiFinals,
  finals,
}

extension TournamentPhaseExtension on TournamentPhase {
  String get displayName {
    switch (this) {
      case TournamentPhase.poolPlay:
        return 'Pool Play';
      case TournamentPhase.quarterFinals:
        return 'Quarter-Finals';
      case TournamentPhase.semiFinals:
        return 'Semi-Finals';
      case TournamentPhase.finals:
        return 'Finals';
    }
  }

  String get dbValue {
    switch (this) {
      case TournamentPhase.poolPlay:
        return 'pool_play';
      case TournamentPhase.quarterFinals:
        return 'quarter_finals';
      case TournamentPhase.semiFinals:
        return 'semi_finals';
      case TournamentPhase.finals:
        return 'finals';
    }
  }

  static TournamentPhase fromString(String value) {
    switch (value) {
      case 'pool_play':
        return TournamentPhase.poolPlay;
      case 'quarter_finals':
        return TournamentPhase.quarterFinals;
      case 'semi_finals':
        return TournamentPhase.semiFinals;
      case 'finals':
        return TournamentPhase.finals;
      default:
        return TournamentPhase.poolPlay;
    }
  }

  /// Determine the phase from a match round string
  static TournamentPhase fromMatchRound(String? round) {
    if (round == null) return TournamentPhase.poolPlay;

    final lowerRound = round.toLowerCase();
    if (lowerRound.contains('final') && !lowerRound.contains('semi') && !lowerRound.contains('quarter')) {
      return TournamentPhase.finals;
    } else if (lowerRound.contains('semi')) {
      return TournamentPhase.semiFinals;
    } else if (lowerRound.contains('quarter')) {
      return TournamentPhase.quarterFinals;
    }
    return TournamentPhase.poolPlay;
  }
}

/// Scoring configuration for a single phase
class PhaseScoring {
  final int numberOfSets; // 1 for single set, 3 for best of 3
  final int pointsPerSet; // 21, 25, 15 for volleyball; 11, 7 for pickleball
  final int? tiebreakPoints; // Points for final tiebreak set (e.g., 15 for volleyball)

  const PhaseScoring({
    required this.numberOfSets,
    required this.pointsPerSet,
    this.tiebreakPoints,
  });

  /// Get the number of sets needed to win
  int get setsToWin => numberOfSets == 1 ? 1 : 2;

  /// Get the target score for a specific set number
  int targetScoreForSet(int setNumber) {
    if (numberOfSets == 1) return pointsPerSet;
    // For best of 3, use tiebreakPoints for the third set if specified
    if (setNumber == 3 && tiebreakPoints != null) {
      return tiebreakPoints!;
    }
    return pointsPerSet;
  }

  /// Check if a set score is valid (winner must win by 2)
  bool isValidSetScore(int setNumber, int score1, int score2) {
    final target = targetScoreForSet(setNumber);
    final higher = score1 > score2 ? score1 : score2;
    final lower = score1 > score2 ? score2 : score1;

    // Winner must reach target and win by at least 2
    if (higher < target) return false;
    if (higher - lower < 2) return false;

    // If exactly at target, opponent must be at most target-2
    if (higher == target && lower > target - 2) return false;

    return true;
  }

  /// Check if a team has won the match
  bool hasWonMatch(int setsWon) => setsWon >= setsToWin;

  Map<String, dynamic> toJson() => {
        'number_of_sets': numberOfSets,
        'points_per_set': pointsPerSet,
        'tiebreak_points': tiebreakPoints,
      };

  factory PhaseScoring.fromJson(Map<String, dynamic> json) => PhaseScoring(
        numberOfSets: json['number_of_sets'] as int? ?? 1,
        pointsPerSet: json['points_per_set'] as int? ?? 25,
        tiebreakPoints: json['tiebreak_points'] as int?,
      );

  String get displayName {
    if (numberOfSets == 1) {
      return 'Single Set to $pointsPerSet';
    } else if (tiebreakPoints != null && tiebreakPoints != pointsPerSet) {
      return 'Best of 3 ($pointsPerSet-$pointsPerSet-$tiebreakPoints)';
    } else {
      return 'Best of 3 (all to $pointsPerSet)';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhaseScoring &&
        other.numberOfSets == numberOfSets &&
        other.pointsPerSet == pointsPerSet &&
        other.tiebreakPoints == tiebreakPoints;
  }

  @override
  int get hashCode => Object.hash(numberOfSets, pointsPerSet, tiebreakPoints);
}

/// Complete scoring configuration for a tournament
class TournamentScoringConfig {
  final String sportType; // 'volleyball' or 'pickleball'
  final PhaseScoring poolPlay;
  final PhaseScoring quarterFinals;
  final PhaseScoring semiFinals;
  final PhaseScoring finals;

  const TournamentScoringConfig({
    required this.sportType,
    required this.poolPlay,
    required this.quarterFinals,
    required this.semiFinals,
    required this.finals,
  });

  /// Get scoring for a specific phase
  PhaseScoring getScoringForPhase(TournamentPhase phase) {
    switch (phase) {
      case TournamentPhase.poolPlay:
        return poolPlay;
      case TournamentPhase.quarterFinals:
        return quarterFinals;
      case TournamentPhase.semiFinals:
        return semiFinals;
      case TournamentPhase.finals:
        return finals;
    }
  }

  /// Get scoring based on match round string
  PhaseScoring getScoringForRound(String? round) {
    final phase = TournamentPhaseExtension.fromMatchRound(round);
    return getScoringForPhase(phase);
  }

  Map<String, dynamic> toJson() => {
        'sport_type': sportType,
        'pool_play': poolPlay.toJson(),
        'quarter_finals': quarterFinals.toJson(),
        'semi_finals': semiFinals.toJson(),
        'finals': finals.toJson(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory TournamentScoringConfig.fromJson(Map<String, dynamic> json) {
    return TournamentScoringConfig(
      sportType: json['sport_type'] as String? ?? 'volleyball',
      poolPlay: PhaseScoring.fromJson(
          json['pool_play'] as Map<String, dynamic>? ?? {}),
      quarterFinals: PhaseScoring.fromJson(
          json['quarter_finals'] as Map<String, dynamic>? ?? {}),
      semiFinals: PhaseScoring.fromJson(
          json['semi_finals'] as Map<String, dynamic>? ?? {}),
      finals:
          PhaseScoring.fromJson(json['finals'] as Map<String, dynamic>? ?? {}),
    );
  }

  factory TournamentScoringConfig.fromJsonString(String jsonString) {
    return TournamentScoringConfig.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Default volleyball configuration
  /// Pool play: Single set to 25
  /// Quarter-Finals: Single set to 25
  /// Semi-Finals: Best of 3 (21-21-15)
  /// Finals: Best of 3 (21-21-15)
  factory TournamentScoringConfig.volleyballDefault() {
    return const TournamentScoringConfig(
      sportType: 'volleyball',
      poolPlay: PhaseScoring(numberOfSets: 1, pointsPerSet: 25),
      quarterFinals: PhaseScoring(numberOfSets: 1, pointsPerSet: 25),
      semiFinals: PhaseScoring(
          numberOfSets: 3, pointsPerSet: 21, tiebreakPoints: 15),
      finals:
          PhaseScoring(numberOfSets: 3, pointsPerSet: 21, tiebreakPoints: 15),
    );
  }

  /// Alternative volleyball configuration - all best of 3
  factory TournamentScoringConfig.volleyballBestOfThree() {
    return const TournamentScoringConfig(
      sportType: 'volleyball',
      poolPlay:
          PhaseScoring(numberOfSets: 3, pointsPerSet: 21, tiebreakPoints: 15),
      quarterFinals:
          PhaseScoring(numberOfSets: 3, pointsPerSet: 21, tiebreakPoints: 15),
      semiFinals:
          PhaseScoring(numberOfSets: 3, pointsPerSet: 21, tiebreakPoints: 15),
      finals:
          PhaseScoring(numberOfSets: 3, pointsPerSet: 21, tiebreakPoints: 15),
    );
  }

  /// Default pickleball configuration
  /// Pool play: Single game to 11
  /// Quarter-Finals: Single game to 11
  /// Semi-Finals: Best of 3 to 11
  /// Finals: Best of 3 to 11
  factory TournamentScoringConfig.pickleballDefault() {
    return const TournamentScoringConfig(
      sportType: 'pickleball',
      poolPlay: PhaseScoring(numberOfSets: 1, pointsPerSet: 11),
      quarterFinals: PhaseScoring(numberOfSets: 1, pointsPerSet: 11),
      semiFinals: PhaseScoring(numberOfSets: 3, pointsPerSet: 11),
      finals: PhaseScoring(numberOfSets: 3, pointsPerSet: 11),
    );
  }

  /// Casual pickleball configuration with games to 7
  factory TournamentScoringConfig.pickleballCasual() {
    return const TournamentScoringConfig(
      sportType: 'pickleball',
      poolPlay: PhaseScoring(numberOfSets: 1, pointsPerSet: 7),
      quarterFinals: PhaseScoring(numberOfSets: 1, pointsPerSet: 7),
      semiFinals: PhaseScoring(numberOfSets: 3, pointsPerSet: 7),
      finals: PhaseScoring(numberOfSets: 3, pointsPerSet: 11),
    );
  }

  /// Copy with modified values
  TournamentScoringConfig copyWith({
    String? sportType,
    PhaseScoring? poolPlay,
    PhaseScoring? quarterFinals,
    PhaseScoring? semiFinals,
    PhaseScoring? finals,
  }) {
    return TournamentScoringConfig(
      sportType: sportType ?? this.sportType,
      poolPlay: poolPlay ?? this.poolPlay,
      quarterFinals: quarterFinals ?? this.quarterFinals,
      semiFinals: semiFinals ?? this.semiFinals,
      finals: finals ?? this.finals,
    );
  }
}

/// Common volleyball scoring presets
class VolleyballScoringPresets {
  static const singleSet25 = PhaseScoring(numberOfSets: 1, pointsPerSet: 25);
  static const singleSet21 = PhaseScoring(numberOfSets: 1, pointsPerSet: 21);
  static const singleSet15 = PhaseScoring(numberOfSets: 1, pointsPerSet: 15);
  static const bestOf3_21_21_15 =
      PhaseScoring(numberOfSets: 3, pointsPerSet: 21, tiebreakPoints: 15);
  static const bestOf3_25_25_25 =
      PhaseScoring(numberOfSets: 3, pointsPerSet: 25);
  static const bestOf3_25_25_15 =
      PhaseScoring(numberOfSets: 3, pointsPerSet: 25, tiebreakPoints: 15);

  static List<PhaseScoring> get all => [
        singleSet25,
        singleSet21,
        singleSet15,
        bestOf3_21_21_15,
        bestOf3_25_25_25,
        bestOf3_25_25_15,
      ];
}

/// Common pickleball scoring presets
class PickleballScoringPresets {
  static const singleGame11 = PhaseScoring(numberOfSets: 1, pointsPerSet: 11);
  static const singleGame7 = PhaseScoring(numberOfSets: 1, pointsPerSet: 7);
  static const bestOf3_11 = PhaseScoring(numberOfSets: 3, pointsPerSet: 11);
  static const bestOf3_7 = PhaseScoring(numberOfSets: 3, pointsPerSet: 7);

  static List<PhaseScoring> get all => [
        singleGame11,
        singleGame7,
        bestOf3_11,
        bestOf3_7,
      ];
}
