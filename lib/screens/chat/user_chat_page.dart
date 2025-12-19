import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/services/user_chat_service.dart';
import 'package:flutter/foundation.dart';

const Color _themeColor = Color(0xFF00D1FF);

/// User Chat Page
/// 
/// Individual chat page for chatting with a specific user with real-time updates.
class UserChatPage extends StatefulWidget {
  final UserModel otherUser;

  const UserChatPage({
    super.key,
    required this.otherUser,
  });

  @override
  State<UserChatPage> createState() => _UserChatPageState();
}

class _UserChatPageState extends State<UserChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final BUserService _userService = BUserService();
  final UserChatService _chatService = UserChatService();
  UserModel? _currentUser;
  bool _isLoadingUser = true;
  bool _isSendingMessage = false;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _markAsRead();
    _messageController.addListener(() {
      setState(() {}); // Rebuild to update send button color
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _markAsRead() async {
    try {
      await _chatService.markAsRead(widget.otherUser.id);
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSendingMessage) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSendingMessage = true;
    });

    try {
      await _chatService.sendMessage(widget.otherUser.id, message);
      
      // Scroll to bottom after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            // Profile Picture - Circular
            CircleAvatar(
              radius: 20,
              backgroundColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              backgroundImage: widget.otherUser.profileImageUrl != null &&
                      widget.otherUser.profileImageUrl!.isNotEmpty
                  ? NetworkImage(widget.otherUser.profileImageUrl!)
                  : null,
              child: widget.otherUser.profileImageUrl == null ||
                      widget.otherUser.profileImageUrl!.isEmpty
                  ? Text(
                      widget.otherUser.displayName.isNotEmpty
                          ? widget.otherUser.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300]! : Colors.grey[700]!,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            onPressed: () {},
            color: textColor,
            tooltip: 'Call',
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {},
            color: textColor,
            tooltip: 'Video call',
          ),
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
          // Messages List - Real-time with StreamBuilder
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
              child: StreamBuilder<List<UserChatMessage>>(
                stream: _chatService.getMessagesStream(widget.otherUser.id),
                builder: (context, snapshot) {
                  // Handle connection states
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_themeColor),
                      ),
                    );
                  }

                  // Handle errors gracefully - show empty state instead of error
                  if (snapshot.hasError) {
                    debugPrint('⚠️ [UserChatPage] StreamBuilder error: ${snapshot.error}');
                    // Don't show error UI, just return empty list
                    // The stream's error handler will return empty list on permission errors
                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) {
                      // Show empty state if no messages
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                              backgroundImage: widget.otherUser.profileImageUrl != null &&
                                      widget.otherUser.profileImageUrl!.isNotEmpty
                                  ? NetworkImage(widget.otherUser.profileImageUrl!)
                                  : null,
                              child: widget.otherUser.profileImageUrl == null ||
                                      widget.otherUser.profileImageUrl!.isEmpty
                                  ? Text(
                                      widget.otherUser.displayName.isNotEmpty
                                          ? widget.otherUser.displayName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.grey[300]! : Colors.grey[700]!,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              widget.otherUser.displayName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No messages yet.\nStart the conversation!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }

                  final messages = snapshot.data ?? [];
                  
                  // Show empty state
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                            backgroundImage: widget.otherUser.profileImageUrl != null &&
                                    widget.otherUser.profileImageUrl!.isNotEmpty
                                ? NetworkImage(widget.otherUser.profileImageUrl!)
                                : null,
                            child: widget.otherUser.profileImageUrl == null ||
                                    widget.otherUser.profileImageUrl!.isEmpty
                                ? Text(
                                    widget.otherUser.displayName.isNotEmpty
                                        ? widget.otherUser.displayName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.grey[300]! : Colors.grey[700]!,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            widget.otherUser.displayName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No messages yet.\nStart the conversation!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: subtextColor,
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
                      final isFromMe = message.senderId == _currentUser?.id;
                      return _buildMessageBubble(
                        message,
                        isFromMe,
                        isDark,
                        cardColor,
                        textColor,
                        subtextColor,
                        onLongPress: () => _showMessageOptions(context, message, isFromMe),
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
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
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
                  // Text input field
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
                  // Send button
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

  Widget _buildMessageBubble(
    UserChatMessage message,
    bool isFromMe,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor, {
    VoidCallback? onLongPress,
  }) {
    final timeStr = _formatTime(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        mainAxisAlignment:
            isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Profile picture for received messages (left side)
          if (!isFromMe) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              backgroundImage: widget.otherUser.profileImageUrl != null &&
                      widget.otherUser.profileImageUrl!.isNotEmpty
                  ? NetworkImage(widget.otherUser.profileImageUrl!)
                  : null,
              child: widget.otherUser.profileImageUrl == null ||
                      widget.otherUser.profileImageUrl!.isEmpty
                  ? Text(
                      widget.otherUser.displayName.isNotEmpty
                          ? widget.otherUser.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300]! : Colors.grey[700]!,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: onLongPress,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isFromMe
                          ? _themeColor
                          : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isFromMe ? 20 : 4),
                        bottomRight: Radius.circular(isFromMe ? 4 : 20),
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
                        color: isFromMe ? Colors.white : textColor,
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
          // Profile picture for sent messages (right side)
          if (isFromMe && _currentUser != null) ...[
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
          ] else if (isFromMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              child: Icon(
                Icons.person,
                size: 20,
                color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark, Color cardColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
            backgroundImage: widget.otherUser.profileImageUrl != null &&
                    widget.otherUser.profileImageUrl!.isNotEmpty
                ? NetworkImage(widget.otherUser.profileImageUrl!)
                : null,
            child: widget.otherUser.profileImageUrl == null ||
                    widget.otherUser.profileImageUrl!.isEmpty
                ? Text(
                    widget.otherUser.displayName.isNotEmpty
                        ? widget.otherUser.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
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
                  'Sending...',
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

  void _showMessageOptions(BuildContext context, UserChatMessage message, bool isFromMe) {
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
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete for me'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _chatService.deleteMessageForMe(widget.otherUser.id, message.messageId!);
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
              if (isFromMe)
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
                        await _chatService.deleteMessageForEveryone(widget.otherUser.id, message.messageId!);
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
                CircleAvatar(
                  radius: 30,
                  backgroundColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  backgroundImage: widget.otherUser.profileImageUrl != null &&
                          widget.otherUser.profileImageUrl!.isNotEmpty
                      ? NetworkImage(widget.otherUser.profileImageUrl!)
                      : null,
                  child: widget.otherUser.profileImageUrl == null ||
                          widget.otherUser.profileImageUrl!.isEmpty
                      ? Text(
                          widget.otherUser.displayName.isNotEmpty
                              ? widget.otherUser.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[300]! : Colors.grey[700]!,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.otherUser.displayName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      if (widget.otherUser.email.isNotEmpty)
                        Text(
                          widget.otherUser.email,
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
                    await _chatService.clearChat(widget.otherUser.id);
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
}

