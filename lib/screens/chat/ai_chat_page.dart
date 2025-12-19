import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/services/ai_chat_service.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

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
  final AIChatService _aiChatService = AIChatService();
  UserModel? _currentUser;
  bool _isLoadingUser = true;
  bool _isSendingMessage = false;
  String _logoUrl = 'https://res.cloudinary.com/dqymvfmbi/image/upload/v1765755084/ai/subspace_logo.jpg';

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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSendingMessage) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSendingMessage = true;
    });

    try {
      // Get conversation history from stream (we'll pass empty for now, backend will handle it)
      await _aiChatService.sendMessage(userMessage);
      
      // Scroll to bottom after a short delay to allow message to appear
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
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
    final backgroundColor = isDark ? Colors.grey[900]! : Colors.white;
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
            onPressed: () {
              _showInfoScreen(context);
            },
            color: textColor,
            tooltip: 'Info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List - Messenger style
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.grey[900]!,
                          Colors.grey[900]!,
                        ],
                      )
                    : null,
                color: isDark ? null : Colors.grey[50],
              ),
              child: StreamBuilder<List<ChatMessage>>(
                stream: _aiChatService.getMessagesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(_themeColor),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading conversation...',
                            style: TextStyle(color: subtextColor),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading messages',
                            style: TextStyle(color: subtextColor),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];
                  
                  // Show welcome message if no messages
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSubspaceAvatar(isDark),
                          const SizedBox(height: 24),
                          Text(
                            "Hello! I'm Subspace",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your AI assistant for RentEase',
                            style: TextStyle(
                              fontSize: 16,
                              color: subtextColor,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "I can help you find rental properties, calculate costs, answer questions about listings, and perform simple math. How can I assist you today?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Auto-scroll when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollToBottom();
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length + (_isSendingMessage ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && _isSendingMessage) {
                        return _buildTypingIndicator(isDark, cardColor, textColor);
                      }
                      final message = messages[index];
                      return _buildMessageBubble(
                        message, 
                        isDark, 
                        cardColor, 
                        textColor, 
                        subtextColor,
                        onLongPress: () => _showMessageOptions(context, message),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          // Input Area - Modern Messenger Style
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 4,
              left: 8,
              right: 8,
              top: 8,
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Plus/Attachment button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: textColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Text input field - Messenger style
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark 
                              ? Colors.grey[700]!.withValues(alpha: 0.5)
                              : Colors.grey[300]!.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: subtextColor, 
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        style: TextStyle(
                          color: textColor, 
                          fontSize: 15,
                          height: 1.4,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                        onSubmitted: (_) {
                          if (_messageController.text.trim().isNotEmpty && !_isSendingMessage) {
                            _sendMessage();
                          }
                        },
                        enabled: !_isSendingMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button - Messenger style circular button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, right: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _messageController.text.trim().isNotEmpty && !_isSendingMessage
                            ? _sendMessage 
                            : null,
                        borderRadius: BorderRadius.circular(24),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _messageController.text.trim().isNotEmpty && !_isSendingMessage
                                ? _themeColor 
                                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                            shape: BoxShape.circle,
                            boxShadow: _messageController.text.trim().isNotEmpty && !_isSendingMessage
                                ? [
                                    BoxShadow(
                                      color: _themeColor.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: _isSendingMessage
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark ? Colors.grey[500]! : Colors.grey[500]!,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  color: _messageController.text.trim().isNotEmpty && !_isSendingMessage
                                      ? Colors.white 
                                      : (isDark ? Colors.grey[500] : Colors.grey[500]),
                                  size: 20,
                                ),
                        ),
                      ),
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
                color: _themeColor.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 1.5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle rotating glow ring
              Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        _themeColor.withValues(alpha: 0.35),
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
    Color subtextColor, {
    VoidCallback? onLongPress,
  }) {
    final isSubspace = message.isFromSubspace;
    final timeStr = _formatTime(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        mainAxisAlignment:
            isSubspace ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Profile picture for Subspace messages (left side)
          if (isSubspace) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: _buildSubspaceAvatar(isDark),
            ),
          ],
          // Message bubble - Enhanced Messenger style
          Flexible(
            child: Column(
              crossAxisAlignment: isSubspace ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onLongPress: onLongPress,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSubspace
                          ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
                          : _themeColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isSubspace ? 4 : 20),
                        bottomRight: Radius.circular(isSubspace ? 20 : 4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: SelectableText(
                      message.text,
                      style: TextStyle(
                        fontSize: 15,
                        color: isSubspace ? textColor : Colors.white,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtextColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Profile picture for user messages (right side)
          if (!isSubspace && _currentUser != null) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _themeColor.withValues(alpha: 0.3),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _themeColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _themeColor,
                        ),
                      )
                    : null,
              ),
            ),
          ] else if (!isSubspace) ...[
            // Show placeholder if user not loaded yet
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Widget _buildTypingIndicator(bool isDark, Color cardColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: _buildSubspaceAvatar(isDark),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Subspace is typing...',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, ChatMessage message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!message.isFromSubspace) ...[
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete for me'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await _aiChatService.deleteMessageForMe(message.messageId!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message deleted'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete for everyone'),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Message'),
                        content: const Text('Are you sure you want to delete this message for everyone? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      try {
                        await _aiChatService.deleteMessageForEveryone(message.messageId!);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Message deleted'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
              ListTile(
                leading: Icon(Icons.copy, color: textColor),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  // Copy functionality would go here
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoScreen(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = (isDark ? Colors.grey[300] : Colors.grey[600])!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildSubspaceAvatar(isDark),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subspace',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'AI Assistant',
                        style: TextStyle(
                          fontSize: 14,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Subspace is your AI assistant for RentEase. I can help you find rental properties, calculate costs, answer questions about listings, and perform simple math calculations.',
              style: TextStyle(
                fontSize: 14,
                color: subtextColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Capabilities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildCapabilityItem(Icons.search, 'Find rental properties', subtextColor),
            _buildCapabilityItem(Icons.calculate, 'Calculate rental costs', subtextColor),
            _buildCapabilityItem(Icons.help_outline, 'Answer questions', subtextColor),
            _buildCapabilityItem(Icons.calculate_outlined, 'Perform math calculations', subtextColor),
            const SizedBox(height: 24),
            Divider(color: subtextColor.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Clear Chat'),
              subtitle: const Text('Delete all messages in this conversation'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Chat'),
                    content: const Text('Are you sure you want to delete all messages? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  try {
                    await _aiChatService.clearChat();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chat cleared successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ChatMessage class is imported from ai_chat_service.dart
