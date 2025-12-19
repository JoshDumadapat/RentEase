import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Chat message model
class ChatMessage {
  final String text;
  final bool isFromSubspace;
  final DateTime timestamp;
  final String? messageId;

  ChatMessage({
    required this.text,
    required this.isFromSubspace,
    required this.timestamp,
    this.messageId,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isFromSubspace': isFromSubspace,
      'timestamp': timestamp.toIso8601String(),
      'messageId': messageId,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] ?? '',
      isFromSubspace: map['isFromSubspace'] ?? false,
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      messageId: map['messageId'],
    );
  }
}

/// Chat service for AI interactions
class AIChatService {
  // Set to your backend URL
  // For Android emulator: 'http://10.0.2.2:5000'
  // For iOS simulator: 'http://localhost:5000'
  // For physical device: 'http://YOUR_PC_IP:5000' (e.g., 'http://192.168.100.3:5000')
  static const String? _backendBaseUrl = 'http://192.168.100.3:5000'; // Update with your PC's IP if needed
  final String? backendUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AIChatService({String? backendUrl}) 
      : backendUrl = backendUrl ?? _backendBaseUrl;

  /// Get conversation history for AI context
  Future<List<Map<String, String>>> getConversationHistoryForAI({int limit = 10}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('ai_chat_messages')
          .doc(userId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit * 2) // Get more to account for pairs
          .get();

      final history = <Map<String, String>>[];
      final messages = snapshot.docs.reversed.toList();
      
      for (var doc in messages) {
        final data = doc.data();
        final isFromSubspace = data['isFromSubspace'] ?? false;
        final text = data['text'] as String?;
        if (text != null && text.isNotEmpty) {
          history.add({
            'role': isFromSubspace ? 'assistant' : 'user',
            'content': text,
          });
        }
      }
      
      return history;
    } catch (e) {
      return [];
    }
  }

  /// Send message and save to Firestore in real-time
  Future<void> sendMessage(String message) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return;
    }

    try {
      // Save user message to Firestore immediately
      final userMessageRef = _firestore
          .collection('ai_chat_messages')
          .doc(userId)
          .collection('messages')
          .doc();
      
      final userMessageData = {
        'text': message,
        'isFromSubspace': false,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      await userMessageRef.set(userMessageData);

      // Get AI response
      String aiResponse;
      if (backendUrl == null) {
        aiResponse = _getFallbackResponse(message);
      } else {
        try {
          // Get conversation history for context (limit to 8 for faster processing)
          final history = await getConversationHistoryForAI(limit: 8).timeout(
            const Duration(seconds: 3),
            onTimeout: () => <Map<String, String>>[],
          );
          
          final requestBody = {
            'message': message,
            'conversationHistory': history,
            'userId': userId,
          };

          final response = await http.post(
            Uri.parse('$backendUrl/ai/chat'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          ).timeout(
            const Duration(seconds: 8), // Reduced timeout
            onTimeout: () {
              throw TimeoutException('Request timeout');
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            aiResponse = data['response'] as String? ?? _getFallbackResponse(message);
          } else {
            aiResponse = _getFallbackResponse(message);
          }
        } on TimeoutException {
          aiResponse = _getFallbackResponse(message);
        } catch (e) {
          aiResponse = _getFallbackResponse(message);
        }
      }

      // Save AI response to Firestore
      final aiMessageRef = _firestore
          .collection('ai_chat_messages')
          .doc(userId)
          .collection('messages')
          .doc();
      
      final aiMessageData = {
        'text': aiResponse,
        'isFromSubspace': true,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      await aiMessageRef.set(aiMessageData);
    } catch (e) {
      // Silent error handling - don't crash the app
      // User will see fallback response if needed
    }
  }

  /// Stream of chat messages in real-time
  Stream<List<ChatMessage>> getMessagesStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('ai_chat_messages')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      final messages = <ChatMessage>[];
      final deletedFor = snapshot.metadata.isFromCache ? [] : <String>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final deletedForList = data['deletedFor'] as List<dynamic>?;
        
        // Skip messages deleted for current user
        if (deletedForList != null && deletedForList.contains(userId)) {
          continue;
        }
        
        final timestamp = data['timestamp'] as Timestamp?;
        final createdAt = data['createdAt'] as String?;
        
        messages.add(ChatMessage(
          text: data['text'] ?? '',
          isFromSubspace: data['isFromSubspace'] ?? false,
          timestamp: timestamp != null 
              ? timestamp.toDate()
              : (createdAt != null 
                  ? DateTime.parse(createdAt)
                  : DateTime.now()),
          messageId: doc.id,
        ));
      }
      
      return messages;
    });
  }


  /// Get intelligent fallback response with math and listing knowledge
  String _getFallbackResponse(String message) {
    final messageLower = message.toLowerCase().trim();
    
    // Enhanced math calculations - supports decimals and more operations
    final mathPatterns = [
      RegExp(r'(\d+\.?\d*)\s*\+\s*(\d+\.?\d*)'),
      RegExp(r'(\d+\.?\d*)\s*-\s*(\d+\.?\d*)'),
      RegExp(r'(\d+\.?\d*)\s*\*\s*(\d+\.?\d*)'),
      RegExp(r'(\d+\.?\d*)\s*/\s*(\d+\.?\d*)'),
    ];
    
    for (var i = 0; i < mathPatterns.length; i++) {
      final match = mathPatterns[i].firstMatch(message);
      if (match != null) {
        try {
          final a = double.parse(match.group(1)!);
          final b = double.parse(match.group(2)!);
          double result;
          switch (i) {
            case 0: result = a + b; break;
            case 1: result = a - b; break;
            case 2: result = a * b; break;
            case 3: 
              if (b == 0) return "Cannot divide by zero.";
              result = a / b;
              break;
            default: return _getDefaultResponse();
          }
          return result % 1 == 0 
              ? "The answer is ${result.toInt()}." 
              : "The answer is ${result.toStringAsFixed(2)}.";
        } catch (e) {
          // Continue
        }
      }
    }
    
    // Percentage calculations
    final percentRegex = RegExp(r'(\d+\.?\d*)\s*%\s*of\s*(\d+\.?\d*)', caseSensitive: false);
    final percentMatch = percentRegex.firstMatch(message);
    if (percentMatch != null) {
      try {
        final percent = double.parse(percentMatch.group(1)!);
        final value = double.parse(percentMatch.group(2)!);
        final result = (percent * value / 100);
        return result % 1 == 0
            ? "$percent% of $value is ${result.toInt()}."
            : "$percent% of $value is ${result.toStringAsFixed(2)}.";
      } catch (e) {
        // Continue
      }
    }
    
    // Enhanced rental cost calculations - Yearly/Annual calculations
    if (messageLower.contains('year') || messageLower.contains('annual') || messageLower.contains('per year')) {
      final numbers = RegExp(r'\d+').allMatches(message).map((m) => double.parse(m.group(0)!)).toList();
      if (numbers.isNotEmpty) {
        final monthlyRent = numbers[0];
        final yearlyCost = monthlyRent * 12;
        return "If the monthly rent is ₱${monthlyRent.toStringAsFixed(0)}, you'll spend ₱${yearlyCost.toStringAsFixed(0)} per year (₱${monthlyRent.toStringAsFixed(0)} × 12 months).";
      }
    }
    
    // Monthly calculations (per month, monthly)
    if (messageLower.contains('month') && (messageLower.contains('how much') || messageLower.contains('cost'))) {
      final numbers = RegExp(r'\d+').allMatches(message).map((m) => double.parse(m.group(0)!)).toList();
      if (numbers.isNotEmpty && numbers.length >= 2) {
        final total = numbers[0];
        final months = numbers[1];
        final monthly = total / months;
        return "If you spend ₱${total.toStringAsFixed(0)} over ${months.toStringAsFixed(0)} months, that's ₱${monthly.toStringAsFixed(0)} per month.";
      }
    }
    
    // Enhanced rental cost calculations - First payment (rent + deposit)
    if (messageLower.contains('calculate') || 
        messageLower.contains('total') || 
        messageLower.contains('deposit') ||
        messageLower.contains('advance') ||
        messageLower.contains('first payment')) {
      final numbers = RegExp(r'\d+').allMatches(message).map((m) => int.parse(m.group(0)!)).toList();
      if (numbers.length >= 2) {
        final rent = numbers[0];
        final deposit = numbers[1];
        final total = rent + deposit;
        return "Monthly rent: ₱${rent.toStringAsFixed(0)}\nDeposit: ₱${deposit.toStringAsFixed(0)}\nTotal first payment: ₱${total.toStringAsFixed(0)}";
      } else if (numbers.length == 1) {
        return "For ₱${numbers[0]}, you can find good rental options. Use search filters to browse properties in this price range.";
      }
    }
    
    // Rental cost questions with numbers - smarter detection
    if ((messageLower.contains('how much') || messageLower.contains('cost') || messageLower.contains('spend')) &&
        messageLower.contains('rent')) {
      final numbers = RegExp(r'\d+').allMatches(message).map((m) => double.parse(m.group(0)!)).toList();
      if (numbers.isNotEmpty) {
        // Check for time period keywords
        if (messageLower.contains('year') || messageLower.contains('annual')) {
          final monthlyRent = numbers[0];
          final yearlyCost = monthlyRent * 12;
          return "If the monthly rent is ₱${monthlyRent.toStringAsFixed(0)}, you'll spend ₱${yearlyCost.toStringAsFixed(0)} per year (₱${monthlyRent.toStringAsFixed(0)} × 12 months).";
        } else if (messageLower.contains('month') && numbers.length >= 2) {
          final monthlyRent = numbers[0];
          final months = numbers[1];
          final total = monthlyRent * months;
          return "If the monthly rent is ₱${monthlyRent.toStringAsFixed(0)}, you'll spend ₱${total.toStringAsFixed(0)} over ${months.toStringAsFixed(0)} months.";
        } else {
          final rent = numbers[0];
          return "For ₱${rent.toStringAsFixed(0)} monthly rent, that's ₱${(rent * 12).toStringAsFixed(0)} per year. Use search filters to find properties in this price range.";
        }
      }
    }
    
    // Greetings
    if (messageLower.contains('hello') || 
        messageLower.contains('hi') || 
        messageLower.contains('hey') ||
        messageLower.contains('good morning') ||
        messageLower.contains('good afternoon') ||
        messageLower.contains('good evening')) {
      return "Hello! I'm Subspace, your AI assistant for RentEase. I can help you find rental properties, calculate costs, and answer questions. How can I assist you today?";
    }
    
    // Property types with more context
    if (messageLower.contains('apartment') || 
        messageLower.contains('room') || 
        messageLower.contains('condo') || 
        messageLower.contains('house') ||
        messageLower.contains('dorm') ||
        messageLower.contains('boarding') ||
        messageLower.contains('studio')) {
      return "I can help you find ${messageLower.contains('apartment') ? 'apartments' : messageLower.contains('room') ? 'rooms' : messageLower.contains('condo') ? 'condos' : 'rental properties'}! Use the search feature to browse listings. What's your budget and preferred location?";
    }
    
    // Price/Budget with smarter responses (only if not already handled by calculation logic)
    if ((messageLower.contains('price') || 
        messageLower.contains('cost') || 
        messageLower.contains('rent') || 
        messageLower.contains('budget') ||
        messageLower.contains('affordable') ||
        messageLower.contains('cheap')) &&
        !messageLower.contains('how much') &&
        !messageLower.contains('calculate') &&
        !messageLower.contains('year') &&
        !messageLower.contains('month')) {
      final numbers = RegExp(r'\d+').allMatches(message).map((m) => m.group(0)!).toList();
      if (numbers.isNotEmpty) {
        return "For ₱${numbers[0]}, you can find good options! Use search filters to find properties in your budget range. Prices vary by location, size, and amenities.";
      }
      return "Rental prices vary by location and property type. Use search filters to find properties within your budget. What's your price range?";
    }
    
    // Location with more helpful info
    if (messageLower.contains('location') || 
        messageLower.contains('where') || 
        messageLower.contains('area') ||
        messageLower.contains('near') ||
        messageLower.contains('place')) {
      return "Search by location using the search feature. The app shows properties on a map with filters. What area or landmark are you interested in?";
    }
    
    // Amenities with detailed info
    if (messageLower.contains('amenity') || 
        messageLower.contains('wifi') || 
        messageLower.contains('parking') || 
        messageLower.contains('aircon') || 
        messageLower.contains('kitchen') ||
        messageLower.contains('laundry') ||
        messageLower.contains('security') ||
        messageLower.contains('furnished')) {
      return "Common amenities include: WiFi, Parking, Aircon, Kitchen, Laundry, Security, Furnished options. Use search filters to find properties with specific amenities you need.";
    }
    
    // Help with more specific guidance
    if (messageLower.contains('help') || 
        messageLower.contains('how') || 
        messageLower.contains('what can you') ||
        messageLower.contains('what do you')) {
      return "I help with:\n• Finding rental properties\n• Calculating rental costs\n• Understanding listings\n• Rental advice\n\nWhat do you need help with?";
    }
    
    // Thanks
    if (messageLower.contains('thank')) {
      return "You're welcome! Feel free to ask anytime for help with rentals or RentEase.";
    }
    
    // Questions about RentEase
    if (messageLower.contains('rentease') || 
        messageLower.contains('app') ||
        messageLower.contains('platform')) {
      return "RentEase is a property rental platform. You can search for apartments, rooms, condos, houses, dorms, and boarding houses. Use the search feature to find properties that match your needs!";
    }
    
    return _getDefaultResponse();
  }
  
  String _getDefaultResponse() {
    return "I can help you find rental properties, calculate costs, or answer questions about RentEase. What would you like to know?";
  }

  /// Delete a message (for yourself only)
  Future<void> deleteMessageForMe(String messageId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final messageRef = _firestore
          .collection('ai_chat_messages')
          .doc(userId)
          .collection('messages')
          .doc(messageId);

      // Mark message as deleted for current user
      await messageRef.update({
        'deletedFor': FieldValue.arrayUnion([userId]),
      });
      
      debugPrint('✅ [AIChatService] Message deleted for user: $messageId');
    } catch (e) {
      debugPrint('❌ [AIChatService] Error deleting message: $e');
      rethrow;
    }
  }

  /// Delete a message for everyone (only user messages can be deleted)
  Future<void> deleteMessageForEveryone(String messageId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final messageRef = _firestore
          .collection('ai_chat_messages')
          .doc(userId)
          .collection('messages')
          .doc(messageId);

      // Check if message is from user
      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data();
      if (messageData?['isFromSubspace'] == true) {
        throw Exception('You can only delete your own messages');
      }

      // Delete the message completely
      await messageRef.delete();
      
      debugPrint('✅ [AIChatService] Message deleted for everyone: $messageId');
    } catch (e) {
      debugPrint('❌ [AIChatService] Error deleting message for everyone: $e');
      rethrow;
    }
  }

  /// Clear all messages in the chat
  Future<void> clearChat() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final messagesRef = _firestore
          .collection('ai_chat_messages')
          .doc(userId)
          .collection('messages');

      // Delete all messages
      final messages = await messagesRef.get();
      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      debugPrint('✅ [AIChatService] Chat cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ [AIChatService] Error clearing chat: $e');
      rethrow;
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}

