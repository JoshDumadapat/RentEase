/// Notification Model
/// 
/// Represents a notification for likes and comments on user's posts/properties.
/// Supports two types: Like and Comment notifications.
class NotificationModel {
  final String id;
  final NotificationType type;
  final String likerName; // For like notifications
  final String commenterName; // For comment notifications
  final String? commentText; // For comment notifications (short preview)
  final String postTitle;
  final String postId;
  final DateTime timestamp;
  final bool read;

  NotificationModel({
    required this.id,
    required this.type,
    this.likerName = '',
    this.commenterName = '',
    this.commentText,
    required this.postTitle,
    required this.postId,
    required this.timestamp,
    this.read = false,
  }) : assert(
          (type == NotificationType.like && likerName.isNotEmpty) ||
              (type == NotificationType.comment &&
                  commenterName.isNotEmpty &&
                  commentText != null),
          'Invalid notification data for type',
        );

  /// Creates a copy of this notification with updated fields
  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? likerName,
    String? commenterName,
    String? commentText,
    String? postTitle,
    String? postId,
    DateTime? timestamp,
    bool? read,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      likerName: likerName ?? this.likerName,
      commenterName: commenterName ?? this.commenterName,
      commentText: commentText ?? this.commentText,
      postTitle: postTitle ?? this.postTitle,
      postId: postId ?? this.postId,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }

  /// Get the name of the person who triggered the notification
  String get actorName {
    return type == NotificationType.like ? likerName : commenterName;
  }

  /// Get mock notifications for testing
  static List<NotificationModel> getMockNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: '1',
        type: NotificationType.like,
        likerName: 'John Doe',
        postTitle: 'Cozy Room Near Downtown',
        postId: '1',
        timestamp: now.subtract(const Duration(minutes: 5)),
        read: false,
      ),
      NotificationModel(
        id: '2',
        type: NotificationType.comment,
        commenterName: 'Anna Smith',
        commentText: 'Is this still available?',
        postTitle: 'Cozy Room Near Downtown',
        postId: '1',
        timestamp: now.subtract(const Duration(minutes: 15)),
        read: false,
      ),
      NotificationModel(
        id: '3',
        type: NotificationType.like,
        likerName: 'Maria Garcia',
        postTitle: '2 Bedroom Apartment for Rent',
        postId: '2',
        timestamp: now.subtract(const Duration(hours: 1)),
        read: true,
      ),
      NotificationModel(
        id: '4',
        type: NotificationType.comment,
        commenterName: 'Robert Johnson',
        commentText: 'Great location! When can I view it?',
        postTitle: 'Spacious 3BR House with Garden',
        postId: '3',
        timestamp: now.subtract(const Duration(hours: 2)),
        read: false,
      ),
      NotificationModel(
        id: '5',
        type: NotificationType.like,
        likerName: 'Sarah Williams',
        postTitle: 'Modern Condo Unit with City View',
        postId: '4',
        timestamp: now.subtract(const Duration(days: 1)),
        read: true,
      ),
      NotificationModel(
        id: '6',
        type: NotificationType.comment,
        commenterName: 'David Brown',
        commentText: 'Interested in this property.',
        postTitle: 'Affordable Boarding House Room',
        postId: '5',
        timestamp: now.subtract(const Duration(days: 2)),
        read: true,
      ),
    ];
  }
}

/// Enum for notification types
enum NotificationType {
  like,
  comment,
}

