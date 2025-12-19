import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification Model
/// 
/// Represents a notification for social media interactions.
/// Supports multiple types: Reaction, Friend Request, Comment, Mention, and Review.
class NotificationModel {
  final String id;
  final NotificationType type;
  final String actorName; // Name of the person who triggered the notification
  final String? actorAvatarUrl; // Optional profile picture URL
  final String? reactionEmoji; // For reaction notifications (e.g., "😂")
  final String? commentText; // For comment/mention notifications
  final String? postTitle; // Title or preview of the post
  final String? postId; // ID of the related post
  final String? postType; // 'listing' or 'lookingFor' - distinguishes between listing and looking-for post
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
    this.postType, // 'listing' or 'lookingFor'
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
    String? postType,
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
      postType: postType ?? this.postType,
      otherActors: otherActors ?? this.otherActors,
      reactionCount: reactionCount ?? this.reactionCount,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      requestRemoved: requestRemoved ?? this.requestRemoved,
    );
  }

  /// Create NotificationModel from Firestore data
  static NotificationModel? fromFirestore(Map<String, dynamic> data) {
    try {
      final id = data['id'] as String? ?? '';
      if (id.isEmpty) return null;

      // Parse notification type
      final typeString = data['type'] as String? ?? '';
      NotificationType type;
      switch (typeString) {
        case 'reaction':
          type = NotificationType.reaction;
          break;
        case 'friendRequest':
          type = NotificationType.friendRequest;
          break;
        case 'comment':
          type = NotificationType.comment;
          break;
        case 'mention':
          type = NotificationType.mention;
          break;
        case 'review':
          type = NotificationType.review;
          break;
        case 'follow':
          type = NotificationType.follow;
          break;
        default:
          type = NotificationType.comment; // Default fallback
      }

      // Parse timestamp
      DateTime timestamp;
      if (data['createdAt'] != null) {
        if (data['createdAt'] is Timestamp) {
          timestamp = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is DateTime) {
          timestamp = data['createdAt'] as DateTime;
        } else {
          // Fallback to current time if parsing fails
          timestamp = DateTime.now();
        }
      } else {
        timestamp = DateTime.now();
      }

      return NotificationModel(
        id: id,
        type: type,
        actorName: data['actorName'] as String? ?? 'Unknown',
        actorAvatarUrl: data['actorAvatarUrl'] as String?,
        reactionEmoji: data['reactionEmoji'] as String?,
        commentText: data['commentText'] as String?,
        postTitle: data['postTitle'] as String?,
        postId: data['postId'] as String?,
        postType: data['postType'] as String?, // 'listing' or 'lookingFor'
        otherActors: data['otherActors'] != null
            ? List<String>.from(data['otherActors'] as List)
            : null,
        reactionCount: data['reactionCount'] as int?,
        timestamp: timestamp,
        read: data['read'] as bool? ?? false,
        requestRemoved: data['requestRemoved'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('❌ [NotificationModel] Error parsing from Firestore: $e');
      return null;
    }
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
  review, // Reviewed a listing
  follow, // Started following you
}

