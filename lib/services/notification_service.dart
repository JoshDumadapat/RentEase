import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/models/notification_model.dart';
import 'package:rentease_app/backend/BNotificationService.dart';
import 'dart:async';

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
  StreamSubscription<List<Map<String, dynamic>>>? _notificationStreamSubscription;

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
      debugPrint('📬 [NotificationService] Fetching notifications for user: ${user.uid}');
      
      // Fetch from Firestore
      final firestoreData = await _backendService.getNotificationsByUser(user.uid);
      
      debugPrint('📬 [NotificationService] Fetched ${firestoreData.length} notifications');
      
      // Convert Firestore data to NotificationModel
      final fetchedNotifications = firestoreData
          .map((data) => NotificationModel.fromFirestore(data))
          .where((notification) => notification != null)
          .cast<NotificationModel>()
          .toList();
      
      // Only update if different to avoid unnecessary rebuilds
      if (fetchedNotifications.length != _notifications.length ||
          fetchedNotifications.any((n) => !_notifications.any((existing) => existing.id == n.id))) {
        _notifications = fetchedNotifications;
        debugPrint('📬 [NotificationService] Updated notifications: ${_notifications.length} total, ${unreadCount} unread');
      }
      
      _error = null;
    } catch (e, stackTrace) {
      debugPrint('❌ [NotificationService] Error fetching notifications: $e');
      debugPrint('❌ [NotificationService] Stack trace: $stackTrace');
      _error = 'Failed to load notifications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Setup real-time stream for notifications
  void _setupNotificationStream(String userId) {
    _notificationStreamSubscription?.cancel();
    debugPrint('📬 [NotificationService] Setting up real-time stream for user: $userId');
    
    _notificationStreamSubscription = _backendService
        .getNotificationsByUserStream(userId)
        .listen(
      (firestoreData) {
        debugPrint('📬 [NotificationService] Received ${firestoreData.length} notifications from stream');
        
        // Convert Firestore data to NotificationModel
        final newNotifications = firestoreData
            .map((data) => NotificationModel.fromFirestore(data))
            .where((notification) => notification != null)
            .cast<NotificationModel>()
            .toList();
        
        // Only update if notifications actually changed to avoid unnecessary rebuilds
        final hasChanged = newNotifications.length != _notifications.length ||
            newNotifications.any((n) {
              final existing = _notifications.firstWhere(
                (existing) => existing.id == n.id,
                orElse: () => NotificationModel(
                  id: '',
                  type: NotificationType.comment,
                  actorName: '',
                  timestamp: DateTime.now(),
                  read: false,
                ),
              );
              return existing.id.isEmpty || existing.read != n.read;
            });
        
        if (hasChanged) {
          _notifications = newNotifications;
          _error = null;
          _isLoading = false;
          debugPrint('📬 [NotificationService] Updated notifications: ${_notifications.length} total, ${unreadCount} unread');
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('❌ [NotificationService] Stream error: $error');
        _error = 'Failed to load notifications: $error';
        _isLoading = false;
        notifyListeners();
      },
      cancelOnError: false, // Keep stream alive even on errors
    );
  }

  /// Refresh notifications (pull-to-refresh)
  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }

  /// Mark a notification as read
  /// Note: Notification stays visible, just marked as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _backendService.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(read: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ [NotificationService] Error marking as read: $e');
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

  /// Initialize service - setup real-time stream and fetch notifications
  void initialize() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      debugPrint('📬 [NotificationService] Initializing for user: ${user.uid}');
      
      // Setup real-time stream for automatic updates
      _setupNotificationStream(user.uid);
      
      // Also do initial fetch to ensure we have data immediately
      // The stream will update in real-time after this
      fetchNotifications();
    } else {
      debugPrint('⚠️ [NotificationService] No user logged in, cannot initialize');
    }
  }

  @override
  void dispose() {
    _notificationStreamSubscription?.cancel();
    super.dispose();
  }
}

