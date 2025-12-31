/// Represents a staff member assigned to a tournament
/// Staff can be either 'admin' (full control) or 'scorer' (score entry only)
class TournamentStaff {
  final String id;
  final String tournamentId;
  final String userId;
  final StaffRole role;
  final String? assignedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional joined data
  final String? userEmail;
  final String? userName;
  final String? assignedByName;

  TournamentStaff({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.role,
    this.assignedBy,
    required this.createdAt,
    required this.updatedAt,
    this.userEmail,
    this.userName,
    this.assignedByName,
  });

  factory TournamentStaff.fromJson(Map<String, dynamic> json) {
    // Handle joined user data
    final userData = json['user'] as Map<String, dynamic>?;
    final assignedByData = json['assigned_by_user'] as Map<String, dynamic>?;

    return TournamentStaff(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      userId: json['user_id'] as String,
      role: StaffRoleExtension.fromString(json['role'] as String),
      assignedBy: json['assigned_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userEmail: userData?['email'] as String?,
      userName: userData?['full_name'] as String?,
      assignedByName: assignedByData?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'user_id': userId,
      'role': role.dbValue,
      'assigned_by': assignedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'tournament_id': tournamentId,
      'user_id': userId,
      'role': role.dbValue,
      'assigned_by': assignedBy,
    };
  }

  TournamentStaff copyWith({
    String? id,
    String? tournamentId,
    String? userId,
    StaffRole? role,
    String? assignedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userEmail,
    String? userName,
    String? assignedByName,
  }) {
    return TournamentStaff(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      assignedBy: assignedBy ?? this.assignedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      assignedByName: assignedByName ?? this.assignedByName,
    );
  }

  /// Display name for the staff member
  String get displayName => userName ?? userEmail ?? 'Unknown User';

  /// Whether this staff member has admin privileges
  bool get isAdmin => role == StaffRole.admin;

  /// Whether this staff member is a scorer
  bool get isScorer => role == StaffRole.scorer;

  /// Whether this staff member can manage scores (both admin and scorer can)
  bool get canManageScores => role == StaffRole.admin || role == StaffRole.scorer;

  /// Whether this staff member can manage tournament settings (admin only)
  bool get canManageTournament => role == StaffRole.admin;
}

/// Staff role for tournament assignments
enum StaffRole {
  admin,
  scorer,
}

extension StaffRoleExtension on StaffRole {
  String get displayName {
    switch (this) {
      case StaffRole.admin:
        return 'Admin';
      case StaffRole.scorer:
        return 'Scorer';
    }
  }

  String get description {
    switch (this) {
      case StaffRole.admin:
        return 'Full tournament control (edit settings, manage teams, enter scores)';
      case StaffRole.scorer:
        return 'Can start matches and enter scores only';
    }
  }

  String get dbValue {
    switch (this) {
      case StaffRole.admin:
        return 'admin';
      case StaffRole.scorer:
        return 'scorer';
    }
  }

  static StaffRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return StaffRole.admin;
      case 'scorer':
        return StaffRole.scorer;
      default:
        return StaffRole.scorer;
    }
  }
}

/// Represents the current user's permissions for a tournament
class TournamentPermissions {
  final bool isOwner; // Original tournament organizer
  final bool isAdmin; // Staff admin
  final bool isScorer; // Staff scorer
  final String? staffId; // Staff record ID if applicable

  const TournamentPermissions({
    this.isOwner = false,
    this.isAdmin = false,
    this.isScorer = false,
    this.staffId,
  });

  /// Whether the user can manage tournament (owner or admin)
  bool get canManageTournament => isOwner || isAdmin;

  /// Whether the user can manage scores (owner, admin, or scorer)
  bool get canManageScores => isOwner || isAdmin || isScorer;

  /// Whether the user has any role in this tournament
  bool get hasAnyRole => isOwner || isAdmin || isScorer;

  /// Descriptive role name for display
  String get roleDescription {
    if (isOwner) return 'Organizer';
    if (isAdmin) return 'Admin';
    if (isScorer) return 'Scorer';
    return 'None';
  }

  static const none = TournamentPermissions();
}
