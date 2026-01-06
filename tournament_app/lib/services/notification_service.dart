import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';

/// Service for managing in-app notifications with local storage
class NotificationService extends ChangeNotifier {
  static const String _storageKey = 'app_notifications';
  static const int _maxNotifications = 50;

  List<AppNotification> _notifications = [];
  bool _isInitialized = false;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isInitialized => _isInitialized;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  NotificationService() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _notifications = jsonList
            .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
            .toList();
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      _notifications = [];
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      // Silently fail on storage errors
    }
  }

  /// Add a new notification
  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification);

    if (_notifications.length > _maxNotifications) {
      _notifications = _notifications.take(_maxNotifications).toList();
    }

    await _saveNotifications();
    notifyListeners();
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _saveNotifications();
    notifyListeners();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    notifyListeners();
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  // ========================================
  // Factory methods for creating notifications
  // ========================================

  static String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  /// Create notification for team registration
  AppNotification createTeamRegisteredNotification({
    required String tournamentId,
    required String tournamentName,
    required String teamName,
  }) {
    return AppNotification(
      id: _generateId(),
      type: NotificationType.teamRegistered,
      title: 'Team Registered',
      message: '$teamName has been registered for $tournamentName',
      tournamentId: tournamentId,
      tournamentName: tournamentName,
      teamName: teamName,
      createdAt: DateTime.now(),
    );
  }

  /// Create notification for registration status change
  AppNotification createRegistrationStatusNotification({
    required String tournamentId,
    required String tournamentName,
    required String teamName,
    required String newStatus,
  }) {
    final type = newStatus == 'approved'
        ? NotificationType.registrationApproved
        : newStatus == 'rejected'
            ? NotificationType.registrationRejected
            : NotificationType.teamRemoved;

    final action = newStatus == 'approved'
        ? 'approved'
        : newStatus == 'rejected'
            ? 'rejected'
            : 'withdrawn';

    return AppNotification(
      id: _generateId(),
      type: type,
      title: 'Registration ${action[0].toUpperCase()}${action.substring(1)}',
      message: '$teamName registration for $tournamentName has been $action',
      tournamentId: tournamentId,
      tournamentName: tournamentName,
      teamName: teamName,
      createdAt: DateTime.now(),
    );
  }

  /// Create notification for team removal
  AppNotification createTeamRemovedNotification({
    required String tournamentId,
    required String tournamentName,
    required String teamName,
  }) {
    return AppNotification(
      id: _generateId(),
      type: NotificationType.teamRemoved,
      title: 'Team Removed',
      message: '$teamName has been removed from $tournamentName',
      tournamentId: tournamentId,
      tournamentName: tournamentName,
      teamName: teamName,
      createdAt: DateTime.now(),
    );
  }

  /// Create notification for schedule generation
  AppNotification createScheduleGeneratedNotification({
    required String tournamentId,
    required String tournamentName,
    required int matchCount,
  }) {
    return AppNotification(
      id: _generateId(),
      type: NotificationType.scheduleGenerated,
      title: 'Schedule Generated',
      message: '$matchCount matches have been scheduled for $tournamentName',
      tournamentId: tournamentId,
      tournamentName: tournamentName,
      createdAt: DateTime.now(),
    );
  }

  /// Create notification for tournament status change
  AppNotification createTournamentStatusNotification({
    required String tournamentId,
    required String tournamentName,
    required String newStatus,
  }) {
    return AppNotification(
      id: _generateId(),
      type: NotificationType.tournamentStatusChanged,
      title: 'Tournament Update',
      message: '$tournamentName is now ${_formatStatus(newStatus)}',
      tournamentId: tournamentId,
      tournamentName: tournamentName,
      createdAt: DateTime.now(),
    );
  }

  static String _formatStatus(String status) {
    switch (status) {
      case 'registration_open':
        return 'open for registration';
      case 'registration_closed':
        return 'closed for registration';
      case 'ongoing':
      case 'in_progress':
        return 'in progress';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      default:
        return status.replaceAll('_', ' ');
    }
  }
}
