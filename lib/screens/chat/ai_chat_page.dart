import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'dart:math' as math;

const Color _themeColor = Color(0xFF00D1FF);

/// AI Chat Page
/// 
/// Chat page for chatting with the AI assistant Subspace.
class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _rotationController;
  final BUserService _userService = BUserService();
  UserModel? _currentUser;
  bool _isLoadingUser = true;
  String _logoUrl = 'https://res.cloudinary.com/dqymvfmbi/image/upload/v1765755084/ai/subspace_logo.jpg';

  // Mock chat messages
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hello! I'm Subspace, your AI assistant. How can I help you today?",
      isFromSubspace: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ChatMessage(
      text: "Hi Subspace! Can you help me find a good apartment?",
      isFromSubspace: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    ChatMessage(
      text: "Of course! I'd be happy to help you find the perfect apartment. What's your budget range and preferred location?",
      isFromSubspace: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
    ChatMessage(
      text: "I'm looking for something around \$800-1200 in the downtown area.",
      isFromSubspace: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    ChatMessage(
      text: "Great! I found several listings in that range. Would you like me to show you the top 5 options?",
      isFromSubspace: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadCurrentUser();
    _messageController.addListener(() {
      setState(() {}); // Rebuild to update send button color
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final userData = await _userService.getUserData(firebaseUser.uid);
        if (userData != null && mounted) {
          setState(() {
            _currentUser = UserModel.fromFirestore(userData, firebaseUser.uid);
            _isLoadingUser = false;
          });
        } else if (mounted) {
          // Fallback: create UserModel from Firebase Auth data
          setState(() {
            _currentUser = UserModel(
              id: firebaseUser.uid,
              displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
              email: firebaseUser.email ?? '',
              profileImageUrl: firebaseUser.photoURL,
            );
            _isLoadingUser = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: _messageController.text.trim(),
          isFromSubspace: false,
          timestamp: DateTime.now(),
        ),
      );
      // Add mock Subspace response
      _messages.add(
        ChatMessage(
          text: "Thanks for your message! I'm here to help you with any questions about listings, rentals, or property management.",
          isFromSubspace: true,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
        ),
      );
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = (isDark ? Colors.grey[300] : Colors.grey[600])!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: textColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            // Subspace AI Avatar
            _buildSubspaceAvatar(isDark),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Subspace',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.6),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 12,
                    color: subtextColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
            color: textColor,
            tooltip: 'Info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, isDark, cardColor, textColor, subtextColor);
              },
            ),
          ),
          // Input Area - Simplified
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 8,
              left: 16,
              right: 16,
              top: 12,
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Text input field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: subtextColor, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        style: TextStyle(color: textColor, fontSize: 15),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                        onSubmitted: (_) {
                          if (_messageController.text.trim().isNotEmpty) {
                            _sendMessage();
                          }
                        },
                      ),
                    ),
                  ),
                  // Send button (icon only, no background)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 8),
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: _messageController.text.trim().isNotEmpty 
                            ? _themeColor 
                            : (isDark ? Colors.grey[600] : Colors.grey[400]),
                        size: 26,
                      ),
                      onPressed: _messageController.text.trim().isNotEmpty 
                          ? _sendMessage 
                          : null,
                      tooltip: 'Send',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubspaceAvatar(bool isDark) {
    // Background color based on theme
    final bgColor = isDark ? Colors.black : Colors.white;
    
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _themeColor.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle rotating glow ring (reduced opacity)
              Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        _themeColor.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Border
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 2.5,
                  ),
                ),
              ),
              // Subspace AI Image with background
              ClipOval(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColor, // Black in dark mode, white in light mode
                  ),
                  child: Image.network(
                    _logoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.smart_toy,
                        color: _themeColor,
                        size: 24,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    final isSubspace = message.isFromSubspace;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        mainAxisAlignment:
            isSubspace ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Profile picture for Subspace messages (left side)
          if (isSubspace) ...[
            _buildSubspaceAvatar(isDark),
            const SizedBox(width: 12),
          ],
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isSubspace
                    ? (isDark ? Colors.grey[800] : Colors.grey[200])
                    : _themeColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isSubspace ? 4 : 20),
                  bottomRight: Radius.circular(isSubspace ? 20 : 4),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: isSubspace ? textColor : Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ),
          // Profile picture for user messages (right side)
          if (!isSubspace && _currentUser != null) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
              backgroundImage: _currentUser!.profileImageUrl != null &&
                      _currentUser!.profileImageUrl!.isNotEmpty
                  ? NetworkImage(_currentUser!.profileImageUrl!)
                  : null,
              child: _currentUser!.profileImageUrl == null ||
                      _currentUser!.profileImageUrl!.isEmpty
                  ? Text(
                      _currentUser!.displayName.isNotEmpty
                          ? _currentUser!.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    )
                  : null,
            ),
          ] else if (!isSubspace) ...[
            // Show placeholder if user not loaded yet
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
              child: Icon(
                Icons.person,
                size: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isFromSubspace;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isFromSubspace,
    required this.timestamp,
  });
}
