import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// User Chat Message Model
class UserChatMessage {
  final String text;
  final String senderId;
  final DateTime timestamp;
  final String? messageId;
  final bool isRead;

  UserChatMessage({
    required this.text,
    required this.senderId,
    required this.timestamp,
    this.messageId,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory UserChatMessage.fromMap(Map<String, dynamic> map, String messageId) {
    final timestamp = map['timestamp'] as Timestamp?;
    final createdAt = map['createdAt'] as String?;
    
    return UserChatMessage(
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      timestamp: timestamp != null
          ? timestamp.toDate()
          : (createdAt != null
              ? DateTime.parse(createdAt)
              : DateTime.now()),
      messageId: messageId,
      isRead: map['isRead'] ?? false,
    );
  }
}

/// Chat Thread Model
class ChatThread {
  final String threadId;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final int unreadCount;
  final Map<String, dynamic>? otherUserData;

  ChatThread({
    required this.threadId,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    this.otherUserData,
  });

  factory ChatThread.fromMap(Map<String, dynamic> map, String threadId) {
    final timestamp = map['lastMessageTime'] as Timestamp?;
    final createdAt = map['lastMessageCreatedAt'] as String?;
    
    return ChatThread(
      threadId: threadId,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] as String?,
      lastMessageTime: timestamp != null
          ? timestamp.toDate()
          : (createdAt != null
              ? DateTime.parse(createdAt)
              : null),
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
      unreadCount: (map['unreadCount'] as num?)?.toInt() ?? 0,
      otherUserData: map['otherUserData'] as Map<String, dynamic>?,
    );
  }
}

/// User Chat Service
/// 
/// Handles user-to-user chat functionality with real-time updates
class UserChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate thread ID from two user IDs (sorted for consistency)
  String _generateThreadId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Get or create a chat thread between two users
  Future<String> getOrCreateThread(String otherUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final threadId = _generateThreadId(currentUserId, otherUserId);
    final threadRef = _firestore.collection('chat_threads').doc(threadId);

    // Check if thread exists - use Source.server to get fresh data
    final threadDoc = await threadRef.get(const GetOptions(source: Source.server));
    
    if (!threadDoc.exists) {
      // Create new thread with participants sorted for consistency
      final participants = [currentUserId, otherUserId]..sort();
      try {
        await threadRef.set({
          'participants': participants,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'lastMessageTime': null,
          'lastMessageSenderId': null,
          'lastMessageCreatedAt': null,
          'unreadCount': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ [UserChatService] Created new chat thread: $threadId');
      } catch (e) {
        debugPrint('⚠️ [UserChatService] Error creating thread (may already exist): $e');
        // Thread might have been created by another request, continue
      }
    }

    return threadId;
  }

  /// Send a message to a chat thread
  Future<void> sendMessage(String otherUserId, String message) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    try {
      // Get or create thread first to ensure it exists
      final threadId = await getOrCreateThread(otherUserId);
      final threadRef = _firestore.collection('chat_threads').doc(threadId);
      final messagesRef = threadRef.collection('messages');

      // Add message
      final messageRef = messagesRef.doc();
      final messageData = {
        'text': message.trim(),
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
      };

      await messageRef.set(messageData);

      // Update thread with last message info
      // Note: unreadCount represents unread messages for the current user viewing the thread
      // When you send a message, you don't have unread messages, so we don't increment
      // The unread count will be incremented when the other user sends a message
      await threadRef.update({
        'lastMessage': message.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageCreatedAt': DateTime.now().toIso8601String(),
        'lastMessageSenderId': currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
        // Don't increment unread count when you send a message
        // Unread count is for messages you receive, not send
      });
      
      debugPrint('✅ [UserChatService] Message sent successfully to thread: $threadId');
    } catch (e, stackTrace) {
      debugPrint('❌ [UserChatService] Error sending message: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Stream of messages for a chat thread
  /// Returns real-time updates of messages using StreamBuilder
  Stream<List<UserChatMessage>> getMessagesStream(String otherUserId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    final threadId = _generateThreadId(currentUserId, otherUserId);
    
    // Return stream with proper error handling for StreamBuilder
    // This ensures StreamBuilder gets real-time updates and handles permission errors gracefully
    return _firestore
        .collection('chat_threads')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map<List<UserChatMessage>>((snapshot) {
      try {
        if (snapshot.docs.isEmpty) {
          // Thread doesn't exist yet or no messages - return empty list
          return <UserChatMessage>[];
        }
        
        return snapshot.docs.map((doc) {
          try {
            final data = doc.data();
            if (data.isEmpty) {
              return null;
            }
            
            // Skip messages deleted for current user
            final deletedForList = data['deletedFor'] as List<dynamic>?;
            if (deletedForList != null && deletedForList.contains(currentUserId)) {
              return null;
            }
            
            return UserChatMessage.fromMap(data, doc.id);
          } catch (e) {
            debugPrint('⚠️ [UserChatService] Error parsing message ${doc.id}: $e');
            return null;
          }
        }).whereType<UserChatMessage>().toList();
      } catch (e) {
        debugPrint('⚠️ [UserChatService] Error processing messages: $e');
        return <UserChatMessage>[];
      }
    }).transform(StreamTransformer<List<UserChatMessage>, List<UserChatMessage>>.fromHandlers(
      handleData: (data, sink) {
        sink.add(data);
      },
      handleError: (error, stackTrace, sink) {
        // Convert errors (including permission-denied) to empty list
        debugPrint('⚠️ [UserChatService] Stream error converted to empty list: $error');
        debugPrint('📚 Stack trace: $stackTrace');
        sink.add(<UserChatMessage>[]);
      },
    ));
  }

  /// Stream of chat threads for current user
  Stream<List<ChatThread>> getChatThreadsStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // Note: This query requires a Firestore composite index
    // Create index: participants (Array) + lastMessageTime (Descending)
    // Or use a workaround: fetch all and sort in memory
    return _firestore
        .collection('chat_threads')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .handleError((error, stackTrace) {
      debugPrint('⚠️ [UserChatService] Error in chat threads stream: $error');
      debugPrint('📚 Stack trace: $stackTrace');
    }).asyncMap((snapshot) async {
      final threads = <ChatThread>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        
        // Get the other user's ID
        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );
        
        if (otherUserId.isEmpty) continue;

        // Fetch other user's data
        try {
          final userDoc = await _firestore.collection('users').doc(otherUserId).get();
          final otherUserData = userDoc.exists ? userDoc.data() : null;
          
          final thread = ChatThread.fromMap(data, doc.id);
          threads.add(ChatThread(
            threadId: thread.threadId,
            participants: thread.participants,
            lastMessage: thread.lastMessage,
            lastMessageTime: thread.lastMessageTime,
            lastMessageSenderId: thread.lastMessageSenderId,
            unreadCount: thread.unreadCount,
            otherUserData: otherUserData,
          ));
        } catch (e) {
          debugPrint('Error fetching user data: $e');
          // Add thread without user data
          threads.add(ChatThread.fromMap(data, doc.id));
        }
      }
      
      // Sort by lastMessageTime in memory (since composite index may not exist)
      threads.sort((a, b) {
        final timeA = a.lastMessageTime;
        final timeB = b.lastMessageTime;
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA); // Descending (newest first)
      });
      
      return threads;
    }).transform(StreamTransformer<List<ChatThread>, List<ChatThread>>.fromHandlers(
      handleData: (data, sink) {
        sink.add(data);
      },
      handleError: (error, stackTrace, sink) {
        // Convert errors to empty list so StreamBuilder doesn't show error
        debugPrint('⚠️ [UserChatService] Chat threads stream error converted to empty list: $error');
        sink.add(<ChatThread>[]);
      },
    ));
  }

  /// Mark messages as read
  Future<void> markAsRead(String otherUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final threadId = _generateThreadId(currentUserId, otherUserId);
      final threadRef = _firestore.collection('chat_threads').doc(threadId);
      
      // Check if thread exists first
      final threadDoc = await threadRef.get();
      if (!threadDoc.exists) {
        // Thread doesn't exist yet - nothing to mark as read
        return;
      }
      
      final messagesRef = threadRef.collection('messages');

      // Get unread messages from the other user
      final unreadMessages = await messagesRef
          .where('senderId', isEqualTo: otherUserId)
          .where('isRead', isEqualTo: false)
          .get(const GetOptions(source: Source.server));

      if (unreadMessages.docs.isEmpty) return;

      // Mark all as read
      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Reset unread count (only if messages were actually marked as read)
      await threadRef.update({
        'unreadCount': 0,
      });
    } catch (e) {
      debugPrint('⚠️ [UserChatService] Error marking messages as read: $e');
      // Don't throw - marking as read is not critical
    }
  }

  /// Delete a chat thread
  Future<void> deleteChatThread(String otherUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final threadId = _generateThreadId(currentUserId, otherUserId);
    final threadRef = _firestore.collection('chat_threads').doc(threadId);
    final messagesRef = threadRef.collection('messages');

    // Delete all messages
    final messages = await messagesRef.get();
    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Delete thread
    await threadRef.delete();
  }

  /// Delete a message (for yourself only)
  Future<void> deleteMessageForMe(String otherUserId, String messageId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final threadId = _generateThreadId(currentUserId, otherUserId);
      final messageRef = _firestore
          .collection('chat_threads')
          .doc(threadId)
          .collection('messages')
          .doc(messageId);

      // Mark message as deleted for current user
      await messageRef.update({
        'deletedFor': FieldValue.arrayUnion([currentUserId]),
      });
      
      debugPrint('✅ [UserChatService] Message deleted for user: $messageId');
    } catch (e) {
      debugPrint('❌ [UserChatService] Error deleting message: $e');
      rethrow;
    }
  }

  /// Delete a message for everyone
  Future<void> deleteMessageForEveryone(String otherUserId, String messageId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final threadId = _generateThreadId(currentUserId, otherUserId);
      final messageRef = _firestore
          .collection('chat_threads')
          .doc(threadId)
          .collection('messages')
          .doc(messageId);

      // Check if message is from current user
      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data();
      if (messageData?['senderId'] != currentUserId) {
        throw Exception('You can only delete your own messages for everyone');
      }

      // Delete the message completely
      await messageRef.delete();
      
      debugPrint('✅ [UserChatService] Message deleted for everyone: $messageId');
    } catch (e) {
      debugPrint('❌ [UserChatService] Error deleting message for everyone: $e');
      rethrow;
    }
  }

  /// Clear all messages in a chat thread
  Future<void> clearChat(String otherUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final threadId = _generateThreadId(currentUserId, otherUserId);
      final threadRef = _firestore.collection('chat_threads').doc(threadId);
      final messagesRef = threadRef.collection('messages');

      // Delete all messages
      final messages = await messagesRef.get();
      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Update thread metadata
      await threadRef.update({
        'lastMessage': null,
        'lastMessageTime': null,
        'lastMessageCreatedAt': null,
        'lastMessageSenderId': null,
        'unreadCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ [UserChatService] Chat cleared: $threadId');
    } catch (e) {
      debugPrint('❌ [UserChatService] Error clearing chat: $e');
      rethrow;
    }
  }

  /// Get other user ID from thread
  String? getOtherUserId(String threadId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return null;

    // Extract user IDs from thread ID (format: userId1_userId2)
    final parts = threadId.split('_');
    if (parts.length >= 2) {
      if (parts[0] == currentUserId) {
        return parts.sublist(1).join('_');
      } else {
        return parts[0];
      }
    }
    return null;
  }
}

