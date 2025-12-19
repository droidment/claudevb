import 'dart:convert';
import 'dart:math' as math;
import 'league_config.dart';

class Tournament {
  final String id;
  final String name;
  final String? description;
  final String sportType;
  final TournamentFormat format;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? registrationDeadline;
  final String? location;
  final String? venueDetails;
  final int? maxTeams;
  final int minTeamSize;
  final int maxTeamSize;
  final double? entryFee;
  final TournamentStatus status;
  final String organizerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LeagueConfig? leagueConfig; // For pool_play_to_leagues format
  final bool isPublic; // If true, public. If false, private (invite only)
  final String? inviteCode; // Unique code for private tournaments
  final double? latitude; // Geo-location latitude
  final double? longitude; // Geo-location longitude

  Tournament({
    required this.id,
    required this.name,
    this.description,
    this.sportType = 'volleyball',
    required this.format,
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.location,
    this.venueDetails,
    this.maxTeams,
    this.minTeamSize = 6,
    this.maxTeamSize = 12,
    this.entryFee,
    required this.status,
    required this.organizerId,
    required this.createdAt,
    required this.updatedAt,
    this.leagueConfig,
    this.isPublic = true,
    this.inviteCode,
    this.latitude,
    this.longitude,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sportType: json['sport_type'] as String? ?? 'volleyball',
      format: TournamentFormatExtension.fromString(json['format'] as String),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      registrationDeadline: json['registration_deadline'] != null
          ? DateTime.parse(json['registration_deadline'] as String)
          : null,
      location: json['location'] as String?,
      venueDetails: json['venue_details'] as String?,
      maxTeams: json['max_teams'] as int?,
      minTeamSize: json['min_team_size'] as int? ?? 6,
      maxTeamSize: json['max_team_size'] as int? ?? 12,
      entryFee: json['entry_fee'] != null
          ? double.parse(json['entry_fee'].toString())
          : null,
      status: TournamentStatusExtension.fromString(
        json['status'] as String? ?? 'registration_open',
      ),
      organizerId: json['organizer_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      leagueConfig: json['league_config'] != null
          ? LeagueConfig.fromJson(
              json['league_config'] is String
                  ? jsonDecode(json['league_config'] as String)
                  : json['league_config'] as Map<String, dynamic>,
            )
          : null,
      isPublic: json['is_public'] as bool? ?? true,
      inviteCode: json['invite_code'] as String?,
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sport_type': sportType,
      'format': format.dbValue,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'registration_deadline': registrationDeadline?.toIso8601String(),
      'location': location,
      'venue_details': venueDetails,
      'max_teams': maxTeams,
      'min_team_size': minTeamSize,
      'max_team_size': maxTeamSize,
      'entry_fee': entryFee,
      'status': status.dbValue,
      'organizer_id': organizerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'league_config': leagueConfig?.toJson(),
      'is_public': isPublic,
      'invite_code': inviteCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'description': description,
      'sport_type': sportType,
      'format': format.dbValue,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'registration_deadline': registrationDeadline?.toIso8601String(),
      'location': location,
      'venue_details': venueDetails,
      'max_teams': maxTeams,
      'min_team_size': minTeamSize,
      'max_team_size': maxTeamSize,
      'entry_fee': entryFee,
      'status': status.dbValue,
      'organizer_id': organizerId,
      'league_config': leagueConfig != null
          ? jsonEncode(leagueConfig!.toJson())
          : null,
      'is_public': isPublic,
      'invite_code': inviteCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Calculate distance from this tournament to given coordinates (in kilometers)
  double? distanceFrom(double? userLat, double? userLon) {
    if (latitude == null || longitude == null || userLat == null || userLon == null) {
      return null;
    }
    return _calculateDistance(userLat, userLon, latitude!, longitude!);
  }

  /// Haversine formula to calculate distance between two points on Earth
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth's radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}

enum TournamentFormat {
  roundRobin,
  singleElimination,
  doubleElimination,
  poolPlay,
  poolPlayToLeagues,
}

extension TournamentFormatExtension on TournamentFormat {
  String get displayName {
    switch (this) {
      case TournamentFormat.roundRobin:
        return 'Round Robin';
      case TournamentFormat.singleElimination:
        return 'Single Elimination';
      case TournamentFormat.doubleElimination:
        return 'Double Elimination';
      case TournamentFormat.poolPlay:
        return 'Pool Play';
      case TournamentFormat.poolPlayToLeagues:
        return 'Pool Play to Tiered Leagues';
    }
  }

  String get dbValue {
    switch (this) {
      case TournamentFormat.roundRobin:
        return 'round_robin';
      case TournamentFormat.singleElimination:
        return 'single_elimination';
      case TournamentFormat.doubleElimination:
        return 'double_elimination';
      case TournamentFormat.poolPlay:
        return 'pool_play';
      case TournamentFormat.poolPlayToLeagues:
        return 'pool_play_to_leagues';
    }
  }

  String get description {
    switch (this) {
      case TournamentFormat.roundRobin:
        return 'Every team plays every other team once';
      case TournamentFormat.singleElimination:
        return 'Lose once and you\'re out';
      case TournamentFormat.doubleElimination:
        return 'Teams get a second chance in losers bracket';
      case TournamentFormat.poolPlay:
        return 'Teams divided into pools, top teams advance to playoffs';
      case TournamentFormat.poolPlayToLeagues:
        return 'Pool play followed by tiered leagues (Advanced, Intermediate, Recreational) with playoffs';
    }
  }

  static TournamentFormat fromString(String value) {
    switch (value) {
      case 'round_robin':
        return TournamentFormat.roundRobin;
      case 'single_elimination':
        return TournamentFormat.singleElimination;
      case 'double_elimination':
        return TournamentFormat.doubleElimination;
      case 'pool_play':
        return TournamentFormat.poolPlay;
      case 'pool_play_to_leagues':
        return TournamentFormat.poolPlayToLeagues;
      default:
        return TournamentFormat.roundRobin;
    }
  }
}

enum TournamentStatus {
  registrationOpen,
  registrationClosed,
  ongoing,
  completed,
  cancelled,
}

extension TournamentStatusExtension on TournamentStatus {
  String get displayName {
    switch (this) {
      case TournamentStatus.registrationOpen:
        return 'Registration Open';
      case TournamentStatus.registrationClosed:
        return 'Registration Closed';
      case TournamentStatus.ongoing:
        return 'Ongoing';
      case TournamentStatus.completed:
        return 'Completed';
      case TournamentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get dbValue {
    switch (this) {
      case TournamentStatus.registrationOpen:
        return 'registration_open';
      case TournamentStatus.registrationClosed:
        return 'registration_closed';
      case TournamentStatus.ongoing:
        return 'ongoing';
      case TournamentStatus.completed:
        return 'completed';
      case TournamentStatus.cancelled:
        return 'cancelled';
    }
  }

  static TournamentStatus fromString(String value) {
    switch (value) {
      case 'registration_open':
        return TournamentStatus.registrationOpen;
      case 'registration_closed':
        return TournamentStatus.registrationClosed;
      case 'ongoing':
        return TournamentStatus.ongoing;
      case 'completed':
        return TournamentStatus.completed;
      case 'cancelled':
        return TournamentStatus.cancelled;
      default:
        return TournamentStatus.registrationOpen;
    }
  }
}
