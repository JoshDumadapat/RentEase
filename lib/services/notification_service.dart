import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/models/notification_model.dart';
import 'package:rentease_app/backend/BNotificationService.dart';

/// Notification Service
/// 
/// Manages notification state and business logic.
/// Handles fetching, marking as read, and deleting notifications.
/// Uses BNotificationService for backend operations.
class NotificationService extends ChangeNotifier {
  final BNotificationService _backendService = BNotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  /// Fetch notifications from Firestore
  Future<void> fetchNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch from Firestore
      await _backendService.getNotificationsByUser(user.uid);
      
      // Convert to NotificationModel (for now using mock, but can be converted from Firestore data)
      _notifications = NotificationModel.getMockNotifications();
      _error = null;
    } catch (e) {
      _error = 'Failed to load notifications';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh notifications (pull-to-refresh)
  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _backendService.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(read: true);
        notifyListeners();
      }
    } catch (e) {
      // Ignore errors when marking as read
    }
  }

  /// Mark a notification as unread
  Future<void> markAsUnread(String notificationId) async {
    try {
      await _backendService.markAsUnread(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(read: false);
        notifyListeners();
      }
    } catch (e) {
      // Ignore errors when marking as unread
    }
  }

  /// Toggle read/unread state
  Future<void> toggleReadStatus(String notificationId) async {
    final notification = _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => throw Exception('Notification not found'),
    );
    if (notification.read) {
      await markAsUnread(notificationId);
    } else {
      await markAsRead(notificationId);
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _backendService.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      // Ignore errors when deleting notification
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _backendService.deleteAllNotifications(user.uid);
        _notifications.clear();
        notifyListeners();
      } catch (e) {
        // Ignore errors when clearing all notifications
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _backendService.markAllAsRead(user.uid);
        _notifications = _notifications
            .map((n) => n.copyWith(read: true))
            .toList();
        notifyListeners();
      } catch (e) {
        // Ignore errors when marking all as read
      }
    }
  }

  /// Initialize service - fetch notifications on first load
  void initialize() {
    if (_notifications.isEmpty) {
      fetchNotifications();
    }
  }
}

