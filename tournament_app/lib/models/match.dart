/// Tournament phases for pool play to tiered leagues format
enum TournamentPhase {
  poolPlay,
  tieredLeague,
}

extension TournamentPhaseExtension on TournamentPhase {
  String get displayName {
    switch (this) {
      case TournamentPhase.poolPlay:
        return 'Pool Play';
      case TournamentPhase.tieredLeague:
        return 'Tiered League';
    }
  }

  String get dbValue {
    switch (this) {
      case TournamentPhase.poolPlay:
        return 'pool_play';
      case TournamentPhase.tieredLeague:
        return 'tiered_league';
    }
  }

  static TournamentPhase fromString(String value) {
    switch (value) {
      case 'pool_play':
        return TournamentPhase.poolPlay;
      case 'tiered_league':
        return TournamentPhase.tieredLeague;
      default:
        return TournamentPhase.poolPlay;
    }
  }
}

class Match {
  final String id;
  final String tournamentId;
  final String? team1Id;
  final String? team2Id;
  final DateTime? scheduledTime;
  final int? courtNumber;
  final String? venue;
  final String? round;
  final int? matchNumber;
  final int? team1Score;
  final int? team2Score;
  final int team1SetsWon;
  final int team2SetsWon;
  final String? winnerId;
  final MatchStatus status;
  final String? pool; // Pool assignment (e.g., "A", "B", "C", "D")
  final TournamentPhase? phase; // Pool play or tiered league phase
  final String? tier; // For tiered leagues: "Advanced", "Intermediate", "Recreational"
  final DateTime createdAt;
  final DateTime updatedAt;

  Match({
    required this.id,
    required this.tournamentId,
    this.team1Id,
    this.team2Id,
    this.scheduledTime,
    this.courtNumber,
    this.venue,
    this.round,
    this.matchNumber,
    this.team1Score,
    this.team2Score,
    this.team1SetsWon = 0,
    this.team2SetsWon = 0,
    this.winnerId,
    this.status = MatchStatus.scheduled,
    this.pool,
    this.phase,
    this.tier,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if match is complete
  bool get isComplete => status == MatchStatus.completed && winnerId != null;

  /// Check if match has started
  bool get isInProgress => status == MatchStatus.inProgress;

  /// Check if match is scheduled
  bool get isScheduled => status == MatchStatus.scheduled;

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      team1Id: json['team1_id'] as String?,
      team2Id: json['team2_id'] as String?,
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'] as String)
          : null,
      courtNumber: json['court_number'] as int?,
      venue: json['venue'] as String?,
      round: json['round'] as String?,
      matchNumber: json['match_number'] as int?,
      team1Score: json['team1_score'] as int?,
      team2Score: json['team2_score'] as int?,
      team1SetsWon: json['team1_sets_won'] as int? ?? 0,
      team2SetsWon: json['team2_sets_won'] as int? ?? 0,
      winnerId: json['winner_id'] as String?,
      status: MatchStatusExtension.fromString(
        json['status'] as String? ?? 'scheduled',
      ),
      pool: json['pool'] as String?,
      phase: json['phase'] != null
          ? TournamentPhaseExtension.fromString(json['phase'] as String)
          : null,
      tier: json['tier'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'team1_id': team1Id,
      'team2_id': team2Id,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'court_number': courtNumber,
      'venue': venue,
      'round': round,
      'match_number': matchNumber,
      'team1_score': team1Score,
      'team2_score': team2Score,
      'team1_sets_won': team1SetsWon,
      'team2_sets_won': team2SetsWon,
      'winner_id': winnerId,
      'status': status.dbValue,
      'pool': pool,
      'phase': phase?.dbValue,
      'tier': tier,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'tournament_id': tournamentId,
      'team1_id': team1Id,
      'team2_id': team2Id,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'court_number': courtNumber,
      'venue': venue,
      'round': round,
      'match_number': matchNumber,
      'team1_score': team1Score,
      'team2_score': team2Score,
      'team1_sets_won': team1SetsWon,
      'team2_sets_won': team2SetsWon,
      'winner_id': winnerId,
      'status': status.dbValue,
      'pool': pool,
      'phase': phase?.dbValue,
      'tier': tier,
    };
  }

  Match copyWith({
    String? id,
    String? tournamentId,
    String? team1Id,
    String? team2Id,
    DateTime? scheduledTime,
    int? courtNumber,
    String? venue,
    String? round,
    int? matchNumber,
    int? team1Score,
    int? team2Score,
    int? team1SetsWon,
    int? team2SetsWon,
    String? winnerId,
    MatchStatus? status,
    String? pool,
    TournamentPhase? phase,
    String? tier,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Match(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      courtNumber: courtNumber ?? this.courtNumber,
      venue: venue ?? this.venue,
      round: round ?? this.round,
      matchNumber: matchNumber ?? this.matchNumber,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      team1SetsWon: team1SetsWon ?? this.team1SetsWon,
      team2SetsWon: team2SetsWon ?? this.team2SetsWon,
      winnerId: winnerId ?? this.winnerId,
      status: status ?? this.status,
      pool: pool ?? this.pool,
      phase: phase ?? this.phase,
      tier: tier ?? this.tier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum MatchStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

extension MatchStatusExtension on MatchStatus {
  String get displayName {
    switch (this) {
      case MatchStatus.scheduled:
        return 'Scheduled';
      case MatchStatus.inProgress:
        return 'In Progress';
      case MatchStatus.completed:
        return 'Completed';
      case MatchStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get dbValue {
    switch (this) {
      case MatchStatus.scheduled:
        return 'scheduled';
      case MatchStatus.inProgress:
        return 'in_progress';
      case MatchStatus.completed:
        return 'completed';
      case MatchStatus.cancelled:
        return 'cancelled';
    }
  }

  static MatchStatus fromString(String value) {
    switch (value) {
      case 'scheduled':
        return MatchStatus.scheduled;
      case 'in_progress':
        return MatchStatus.inProgress;
      case 'completed':
        return MatchStatus.completed;
      case 'cancelled':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.scheduled;
    }
  }
}
