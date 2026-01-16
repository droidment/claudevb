/// Scoring format for volleyball/pickleball matches
enum ScoringFormat {
  singleSet,       // One set to 25 (or 21) determines winner
  bestOfThree,     // Best of 3 sets: first two to 21, third to 15
  bestOfThreeFull, // Best of 3 sets: all to 25
}

extension ScoringFormatExtension on ScoringFormat {
  String get displayName {
    switch (this) {
      case ScoringFormat.singleSet:
        return 'Single Set (to 25)';
      case ScoringFormat.bestOfThree:
        return 'Best of 3 (21-21-15)';
      case ScoringFormat.bestOfThreeFull:
        return 'Best of 3 (25-25-25)';
    }
  }

  String get shortDescription {
    switch (this) {
      case ScoringFormat.singleSet:
        return 'One set to 25 points determines the winner';
      case ScoringFormat.bestOfThree:
        return 'First two sets to 21, third set to 15 if needed';
      case ScoringFormat.bestOfThreeFull:
        return 'All sets played to 25 points';
    }
  }

  String get dbValue {
    switch (this) {
      case ScoringFormat.singleSet:
        return 'single_set';
      case ScoringFormat.bestOfThree:
        return 'best_of_three';
      case ScoringFormat.bestOfThreeFull:
        return 'best_of_three_full';
    }
  }

  int get setsToWin {
    switch (this) {
      case ScoringFormat.singleSet:
        return 1;
      case ScoringFormat.bestOfThree:
      case ScoringFormat.bestOfThreeFull:
        return 2;
    }
  }

  int get maxSets {
    switch (this) {
      case ScoringFormat.singleSet:
        return 1;
      case ScoringFormat.bestOfThree:
      case ScoringFormat.bestOfThreeFull:
        return 3;
    }
  }

  /// Get target score for a given set number
  int targetScoreForSet(int setNumber) {
    switch (this) {
      case ScoringFormat.singleSet:
        return 25;
      case ScoringFormat.bestOfThree:
        return setNumber <= 2 ? 21 : 15;
      case ScoringFormat.bestOfThreeFull:
        return 25;
    }
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

  /// Check if a team has won the match based on sets won
  bool hasWonMatch(int setsWon) {
    return setsWon >= setsToWin;
  }

  static ScoringFormat fromString(String value) {
    switch (value) {
      case 'single_set':
        return ScoringFormat.singleSet;
      case 'best_of_three':
        return ScoringFormat.bestOfThree;
      case 'best_of_three_full':
        return ScoringFormat.bestOfThreeFull;
      default:
        return ScoringFormat.singleSet;
    }
  }
}
