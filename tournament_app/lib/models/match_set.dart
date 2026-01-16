class MatchSet {
  final String id;
  final String matchId;
  final int setNumber;
  final int team1Score;
  final int team2Score;
  final DateTime createdAt;

  MatchSet({
    required this.id,
    required this.matchId,
    required this.setNumber,
    required this.team1Score,
    required this.team2Score,
    required this.createdAt,
  });

  /// Returns the winning team's ID (1 or 2) based on scores
  /// Returns 0 if tied (which shouldn't happen in volleyball)
  int get winningTeam {
    if (team1Score > team2Score) return 1;
    if (team2Score > team1Score) return 2;
    return 0; // Tie (shouldn't happen in volleyball)
  }

  /// Check if this is a valid volleyball set score
  /// Returns true if scores follow typical volleyball rules:
  /// - Regular set: First to 25 with 2-point lead
  /// - Tiebreak set: First to 15 with 2-point lead
  bool get isValidVolleyballScore {
    final diff = (team1Score - team2Score).abs();
    final maxScore = team1Score > team2Score ? team1Score : team2Score;
    final minScore = team1Score < team2Score ? team1Score : team2Score;

    // Must have at least 2-point lead
    if (diff < 2) return false;

    // Regular set (25 points)
    if (maxScore == 25 && minScore < 25) return true;
    if (maxScore > 25 && diff == 2) return true; // Extended set

    // Tiebreak set (15 points)
    if (maxScore == 15 && minScore < 15) return true;
    if (maxScore > 15 && diff == 2) return true; // Extended tiebreak

    return false;
  }

  factory MatchSet.fromJson(Map<String, dynamic> json) {
    return MatchSet(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      setNumber: json['set_number'] as int,
      team1Score: json['team1_score'] as int,
      team2Score: json['team2_score'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'set_number': setNumber,
      'team1_score': team1Score,
      'team2_score': team2Score,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'match_id': matchId,
      'set_number': setNumber,
      'team1_score': team1Score,
      'team2_score': team2Score,
    };
  }

  MatchSet copyWith({
    String? id,
    String? matchId,
    int? setNumber,
    int? team1Score,
    int? team2Score,
    DateTime? createdAt,
  }) {
    return MatchSet(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      setNumber: setNumber ?? this.setNumber,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
