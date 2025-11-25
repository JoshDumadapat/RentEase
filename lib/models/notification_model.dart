/// Notification Model
/// 
/// Represents a notification for social media interactions.
/// Supports multiple types: Reaction, Friend Request, Comment, and Mention.
class NotificationModel {
  final String id;
  final NotificationType type;
  final String actorName; // Name of the person who triggered the notification
  final String? actorAvatarUrl; // Optional profile picture URL
  final String? reactionEmoji; // For reaction notifications (e.g., "😂")
  final String? commentText; // For comment/mention notifications
  final String? postTitle; // Title or preview of the post
  final String? postId; // ID of the related post
  final List<String>? otherActors; // For multiple people (e.g., "X and 7 others")
  final int? reactionCount; // For grouped reactions
  final DateTime timestamp;
  final bool read;
  final bool? requestRemoved; // For friend requests that were removed

  NotificationModel({
    required this.id,
    required this.type,
    required this.actorName,
    this.actorAvatarUrl,
    this.reactionEmoji,
    this.commentText,
    this.postTitle,
    this.postId,
    this.otherActors,
    this.reactionCount,
    required this.timestamp,
    this.read = false,
    this.requestRemoved = false,
  });

  /// Creates a copy of this notification with updated fields
  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? actorName,
    String? actorAvatarUrl,
    String? reactionEmoji,
    String? commentText,
    String? postTitle,
    String? postId,
    List<String>? otherActors,
    int? reactionCount,
    DateTime? timestamp,
    bool? read,
    bool? requestRemoved,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      actorName: actorName ?? this.actorName,
      actorAvatarUrl: actorAvatarUrl ?? this.actorAvatarUrl,
      reactionEmoji: reactionEmoji ?? this.reactionEmoji,
      commentText: commentText ?? this.commentText,
      postTitle: postTitle ?? this.postTitle,
      postId: postId ?? this.postId,
      otherActors: otherActors ?? this.otherActors,
      reactionCount: reactionCount ?? this.reactionCount,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      requestRemoved: requestRemoved ?? this.requestRemoved,
    );
  }

  /// Get mock notifications using property-renting app data
  static List<NotificationModel> getMockNotifications() {
    final now = DateTime.now();
    return [
      // New section
      NotificationModel(
        id: '1',
        type: NotificationType.reaction,
        actorName: 'Maria Garcia',
        reactionEmoji: '❤️',
        postTitle: 'Cozy Studio Room Near University',
        postId: '3',
        timestamp: now.subtract(const Duration(minutes: 8)),
        read: false,
      ),
      // Friend requests section
      NotificationModel(
        id: '2',
        type: NotificationType.friendRequest,
        actorName: 'Anna Lee',
        timestamp: now.subtract(const Duration(days: 6)),
        read: false,
        requestRemoved: false,
      ),
      NotificationModel(
        id: '3',
        type: NotificationType.friendRequest,
        actorName: 'Anna Lee',
        timestamp: now.subtract(const Duration(days: 6)),
        read: true,
        requestRemoved: true,
      ),
      // Today section
      NotificationModel(
        id: '4',
        type: NotificationType.comment,
        actorName: 'John Doe',
        commentText: 'Is this property still available?',
        postTitle: '2 Bedroom Apartment for Rent',
        postId: '1',
        timestamp: now.subtract(const Duration(hours: 15)),
        read: false,
      ),
      NotificationModel(
        id: '5',
        type: NotificationType.reaction,
        actorName: 'Sarah Williams',
        reactionEmoji: '❤️',
        postTitle: 'Spacious 3BR House with Garden',
        postId: '2',
        otherActors: ['Robert Johnson'],
        reactionCount: 9,
        timestamp: now.subtract(const Duration(hours: 5)),
        read: false,
      ),
      // Earlier section
      NotificationModel(
        id: '6',
        type: NotificationType.reaction,
        actorName: 'David Brown',
        reactionEmoji: '❤️',
        postTitle: 'Modern Condo Unit with City View',
        postId: '4',
        otherActors: ['Jane Smith', 'Luis Rodriguez'],
        reactionCount: 3,
        timestamp: now.subtract(const Duration(days: 1)),
        read: true,
      ),
      NotificationModel(
        id: '7',
        type: NotificationType.comment,
        actorName: 'Robert Johnson',
        commentText: 'Great location! When can I schedule a viewing?',
        postTitle: 'Affordable Boarding House Room',
        postId: '5',
        timestamp: now.subtract(const Duration(days: 1)),
        read: true,
      ),
    ];
  }
}

/// Enum for notification types
enum NotificationType {
  reaction, // Reacted to a post/photo
  friendRequest, // Sent a friend request
  comment, // Commented on a post
  mention, // Mentioned you in a comment
}

