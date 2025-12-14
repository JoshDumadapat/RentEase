import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/backend/BUserService.dart';

const Color _themeColor = Color(0xFF00D1FF);

/// User Chat Page
/// 
/// Individual chat page for chatting with a specific user.
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
  final List<ChatMessage> _messages = [];
  final BUserService _userService = BUserService();
  UserModel? _currentUser;
  bool _isLoadingUser = true;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
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

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: _messageController.text.trim(),
          isFromMe: true,
          timestamp: DateTime.now(),
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
            // Profile Picture - Circular
            CircleAvatar(
              radius: 20,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
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
                  // Active status (you can add this later)
                  // Text(
                  //   'Active now',
                  //   style: TextStyle(
                  //     fontSize: 12,
                  //     color: Colors.green,
                  //   ),
                  // ),
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
          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet.\nStart the conversation!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: subtextColor,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(
                        message,
                        isDark,
                        cardColor,
                        textColor,
                        subtextColor,
                      );
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

  Widget _buildMessageBubble(
    ChatMessage message,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    final isFromMe = message.isFromMe;
    final userForAvatar = isFromMe ? _currentUser : widget.otherUser;
    final displayNameForAvatar = userForAvatar?.displayName ?? (isFromMe ? 'You' : widget.otherUser.displayName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        mainAxisAlignment:
            isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Profile picture for received messages (left side)
          if (!isFromMe) ...[
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
                      displayNameForAvatar.isNotEmpty
                          ? displayNameForAvatar[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
          ],
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isFromMe
                    ? _themeColor
                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isFromMe ? 20 : 4),
                  bottomRight: Radius.circular(isFromMe ? 4 : 20),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: isFromMe ? Colors.white : textColor,
                  height: 1.5,
                ),
              ),
            ),
          ),
          // Profile picture for sent messages (right side)
          if (isFromMe && _currentUser != null) ...[
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
          ] else if (isFromMe) ...[
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
  final bool isFromMe;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isFromMe,
    required this.timestamp,
  });
}
