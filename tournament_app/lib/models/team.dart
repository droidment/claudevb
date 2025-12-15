class Team {
  final String id;
  final String name;
  final String captainId;
  final String? logoUrl;
  final String? homeCity;
  final String? teamColor;
  final DateTime createdAt;
  final DateTime updatedAt;

  Team({
    required this.id,
    required this.name,
    required this.captainId,
    this.logoUrl,
    this.homeCity,
    this.teamColor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      captainId: json['captain_id'] as String,
      logoUrl: json['logo_url'] as String?,
      homeCity: json['home_city'] as String?,
      teamColor: json['team_color'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'captain_id': captainId,
      'logo_url': logoUrl,
      'home_city': homeCity,
      'team_color': teamColor,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'captain_id': captainId,
      'logo_url': logoUrl,
      'home_city': homeCity,
      'team_color': teamColor,
    };
  }
}
