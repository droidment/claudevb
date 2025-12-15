class Player {
  final String id;
  final String teamId;
  final String name;
  final String? email;
  final String? phone;
  final int? jerseyNumber;
  final String? position;
  final int? heightInches;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Player({
    required this.id,
    required this.teamId,
    required this.name,
    this.email,
    this.phone,
    this.jerseyNumber,
    this.position,
    this.heightInches,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      jerseyNumber: json['jersey_number'] as int?,
      position: json['position'] as String?,
      heightInches: json['height_inches'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'name': name,
      'email': email,
      'phone': phone,
      'jersey_number': jerseyNumber,
      'position': position,
      'height_inches': heightInches,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'team_id': teamId,
      'name': name,
      'email': email,
      'phone': phone,
      'jersey_number': jerseyNumber,
      'position': position,
      'height_inches': heightInches,
      'is_active': isActive,
    };
  }

  String get heightFormatted {
    if (heightInches == null) return 'N/A';
    final feet = heightInches! ~/ 12;
    final inches = heightInches! % 12;
    return '$feet\'$inches"';
  }
}

enum VolleyballPosition {
  setter,
  outsideHitter,
  middleBlocker,
  libero,
  opposite,
  defensiveSpecialist,
}

extension VolleyballPositionExtension on VolleyballPosition {
  String get displayName {
    switch (this) {
      case VolleyballPosition.setter:
        return 'Setter';
      case VolleyballPosition.outsideHitter:
        return 'Outside Hitter';
      case VolleyballPosition.middleBlocker:
        return 'Middle Blocker';
      case VolleyballPosition.libero:
        return 'Libero';
      case VolleyballPosition.opposite:
        return 'Opposite';
      case VolleyballPosition.defensiveSpecialist:
        return 'Defensive Specialist';
    }
  }

  String get dbValue {
    switch (this) {
      case VolleyballPosition.setter:
        return 'setter';
      case VolleyballPosition.outsideHitter:
        return 'outside_hitter';
      case VolleyballPosition.middleBlocker:
        return 'middle_blocker';
      case VolleyballPosition.libero:
        return 'libero';
      case VolleyballPosition.opposite:
        return 'opposite';
      case VolleyballPosition.defensiveSpecialist:
        return 'defensive_specialist';
    }
  }

  static VolleyballPosition? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'setter':
        return VolleyballPosition.setter;
      case 'outside_hitter':
        return VolleyballPosition.outsideHitter;
      case 'middle_blocker':
        return VolleyballPosition.middleBlocker;
      case 'libero':
        return VolleyballPosition.libero;
      case 'opposite':
        return VolleyballPosition.opposite;
      case 'defensive_specialist':
        return VolleyballPosition.defensiveSpecialist;
      default:
        return null;
    }
  }
}
