import 'package:flutter/foundation.dart';
import 'package:rentease_app/models/notification_model.dart';

/// Notification Controller
/// 
/// Manages notification state and business logic.
/// Handles fetching, marking as read, and deleting notifications.
class NotificationController extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  /// Fetch notifications from API or mock data
  /// In a real app, this would make an API call
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      // In production, replace this with actual API call
      _notifications = NotificationModel.getMockNotifications();
      _error = null;
    } catch (e) {
      _error = 'Failed to load notifications';
      if (kDebugMode) {
        print('Error fetching notifications: $e');
      }
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
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      notifyListeners();
    }
  }

  /// Mark a notification as unread
  void markAsUnread(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: false);
      notifyListeners();
    }
  }

  /// Toggle read/unread state
  void toggleReadStatus(String notificationId) {
    final notification = _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => throw Exception('Notification not found'),
    );
    if (notification.read) {
      markAsUnread(notificationId);
    } else {
      markAsRead(notificationId);
    }
  }

  /// Delete a notification
  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  /// Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    _notifications = _notifications
        .map((n) => n.copyWith(read: true))
        .toList();
    notifyListeners();
  }

  /// Initialize controller - fetch notifications on first load
  void initialize() {
    if (_notifications.isEmpty) {
      fetchNotifications();
    }
  }
}

