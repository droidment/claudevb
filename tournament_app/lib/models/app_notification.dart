import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Represents an in-app notification for tournament updates
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String? tournamentId;
  final String? tournamentName;
  final String? teamId;
  final String? teamName;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.tournamentId,
    this.tournamentName,
    this.teamId,
    this.teamName,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationTypeExtension.fromString(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      tournamentId: json['tournament_id'] as String?,
      tournamentName: json['tournament_name'] as String?,
      teamId: json['team_id'] as String?,
      teamName: json['team_name'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.dbValue,
      'title': title,
      'message': message,
      'tournament_id': tournamentId,
      'tournament_name': tournamentName,
      'team_id': teamId,
      'team_name': teamName,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    String? tournamentId,
    String? tournamentName,
    String? teamId,
    String? teamName,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      tournamentId: tournamentId ?? this.tournamentId,
      tournamentName: tournamentName ?? this.tournamentName,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Types of notifications
enum NotificationType {
  teamRegistered,
  registrationApproved,
  registrationRejected,
  teamRemoved,
  scheduleGenerated,
  tournamentStatusChanged,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.teamRegistered:
        return 'Team Registered';
      case NotificationType.registrationApproved:
        return 'Registration Approved';
      case NotificationType.registrationRejected:
        return 'Registration Rejected';
      case NotificationType.teamRemoved:
        return 'Team Removed';
      case NotificationType.scheduleGenerated:
        return 'Schedule Generated';
      case NotificationType.tournamentStatusChanged:
        return 'Tournament Update';
    }
  }

  String get dbValue => name;

  IconData get icon {
    switch (this) {
      case NotificationType.teamRegistered:
        return Icons.how_to_reg;
      case NotificationType.registrationApproved:
        return Icons.check_circle;
      case NotificationType.registrationRejected:
        return Icons.cancel;
      case NotificationType.teamRemoved:
        return Icons.person_remove;
      case NotificationType.scheduleGenerated:
        return Icons.calendar_month;
      case NotificationType.tournamentStatusChanged:
        return Icons.update;
    }
  }

  Color getColor(AppColorPalette colors) {
    switch (this) {
      case NotificationType.teamRegistered:
      case NotificationType.registrationApproved:
      case NotificationType.scheduleGenerated:
        return colors.success;
      case NotificationType.registrationRejected:
      case NotificationType.teamRemoved:
        return colors.error;
      case NotificationType.tournamentStatusChanged:
        return colors.accent;
    }
  }

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => NotificationType.tournamentStatusChanged,
    );
  }
}
