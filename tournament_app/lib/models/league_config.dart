/// Configuration for Pool Play to Tiered Leagues format
/// Example: 24 teams → 6 pools of 4 → Advanced (top 4-8), Intermediate (middle 8), Recreational (bottom 8)
class LeagueConfig {
  final int numberOfPools;
  final int teamsPerPool;
  final List<LeagueTier> tiers;

  LeagueConfig({
    required this.numberOfPools,
    required this.teamsPerPool,
    required this.tiers,
  });

  int get totalTeams => numberOfPools * teamsPerPool;

  factory LeagueConfig.fromJson(Map<String, dynamic> json) {
    return LeagueConfig(
      numberOfPools: json['number_of_pools'] as int,
      teamsPerPool: json['teams_per_pool'] as int,
      tiers: (json['tiers'] as List)
          .map((t) => LeagueTier.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number_of_pools': numberOfPools,
      'teams_per_pool': teamsPerPool,
      'tiers': tiers.map((t) => t.toJson()).toList(),
    };
  }

  /// Create a default config for 24 teams
  factory LeagueConfig.default24Teams() {
    return LeagueConfig(
      numberOfPools: 6,
      teamsPerPool: 4,
      tiers: [
        LeagueTier(
          name: 'Advanced',
          teamsCount: 8,
          rankingStart: 1,
          rankingEnd: 8,
          playoffFormat: PlayoffFormat.singleElimination,
        ),
        LeagueTier(
          name: 'Intermediate',
          teamsCount: 8,
          rankingStart: 9,
          rankingEnd: 16,
          playoffFormat: PlayoffFormat.singleElimination,
        ),
        LeagueTier(
          name: 'Recreational',
          teamsCount: 8,
          rankingStart: 17,
          rankingEnd: 24,
          playoffFormat: PlayoffFormat.singleElimination,
        ),
      ],
    );
  }

  /// Create a config for 16 teams
  factory LeagueConfig.default16Teams() {
    return LeagueConfig(
      numberOfPools: 4,
      teamsPerPool: 4,
      tiers: [
        LeagueTier(
          name: 'Advanced',
          teamsCount: 4,
          rankingStart: 1,
          rankingEnd: 4,
          playoffFormat: PlayoffFormat.singleElimination,
        ),
        LeagueTier(
          name: 'Intermediate',
          teamsCount: 6,
          rankingStart: 5,
          rankingEnd: 10,
          playoffFormat: PlayoffFormat.singleElimination,
        ),
        LeagueTier(
          name: 'Recreational',
          teamsCount: 6,
          rankingStart: 11,
          rankingEnd: 16,
          playoffFormat: PlayoffFormat.singleElimination,
        ),
      ],
    );
  }

  /// Create a custom config
  factory LeagueConfig.custom({
    required int numberOfPools,
    required int teamsPerPool,
    required int advancedTeams,
    required int intermediateTeams,
    required int recreationalTeams,
  }) {
    final total = numberOfPools * teamsPerPool;
    assert(
      advancedTeams + intermediateTeams + recreationalTeams == total,
      'Tier team counts must equal total teams',
    );

    return LeagueConfig(
      numberOfPools: numberOfPools,
      teamsPerPool: teamsPerPool,
      tiers: [
        LeagueTier(
          name: 'Advanced',
          teamsCount: advancedTeams,
          rankingStart: 1,
          rankingEnd: advancedTeams,
          playoffFormat: PlayoffFormat.singleElimination,
        ),
        LeagueTier(
          name: 'Intermediate',
          teamsCount: intermediateTeams,
          rankingStart: advancedTeams + 1,
          rankingEnd: advancedTeams + intermediateTeams,
          playoffFormat: PlayoffFormat.singleElimination,
        ),
        LeagueTier(
          name: 'Recreational',
          teamsCount: recreationalTeams,
          rankingStart: advancedTeams + intermediateTeams + 1,
          rankingEnd: total,
          playoffFormat: PlayoffFormat.singleElimination,
        ),
      ],
    );
  }
}

/// A single tier/league within the tournament
class LeagueTier {
  final String name;
  final int teamsCount;
  final int rankingStart; // Pool play ranking that enters this tier (1 = best)
  final int rankingEnd;
  final PlayoffFormat playoffFormat;

  LeagueTier({
    required this.name,
    required this.teamsCount,
    required this.rankingStart,
    required this.rankingEnd,
    this.playoffFormat = PlayoffFormat.singleElimination,
  });

  factory LeagueTier.fromJson(Map<String, dynamic> json) {
    return LeagueTier(
      name: json['name'] as String,
      teamsCount: json['teams_count'] as int,
      rankingStart: json['ranking_start'] as int,
      rankingEnd: json['ranking_end'] as int,
      playoffFormat: PlayoffFormatExtension.fromString(
        json['playoff_format'] as String? ?? 'single_elimination',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'teams_count': teamsCount,
      'ranking_start': rankingStart,
      'ranking_end': rankingEnd,
      'playoff_format': playoffFormat.dbValue,
    };
  }
}

enum PlayoffFormat { singleElimination, doubleElimination, roundRobin }

extension PlayoffFormatExtension on PlayoffFormat {
  String get displayName {
    switch (this) {
      case PlayoffFormat.singleElimination:
        return 'Single Elimination';
      case PlayoffFormat.doubleElimination:
        return 'Double Elimination';
      case PlayoffFormat.roundRobin:
        return 'Round Robin';
    }
  }

  String get dbValue {
    switch (this) {
      case PlayoffFormat.singleElimination:
        return 'single_elimination';
      case PlayoffFormat.doubleElimination:
        return 'double_elimination';
      case PlayoffFormat.roundRobin:
        return 'round_robin';
    }
  }

  static PlayoffFormat fromString(String value) {
    switch (value) {
      case 'single_elimination':
        return PlayoffFormat.singleElimination;
      case 'double_elimination':
        return PlayoffFormat.doubleElimination;
      case 'round_robin':
        return PlayoffFormat.roundRobin;
      default:
        return PlayoffFormat.singleElimination;
    }
  }
}
