import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/screens/chat/user_chat_page.dart';
import 'package:rentease_app/screens/chat/ai_chat_page.dart';
import 'package:rentease_app/services/user_chat_service.dart';
import 'package:rentease_app/utils/time_ago.dart';
import 'dart:math' as math;

const Color _themeColorDark = Color(0xFF00B8E6);
const Color _themeColor = Color(0xFF00D1FF);

/// Chats List Page
/// 
/// Shows a list of all chat conversations dynamically, similar to Messenger/Instagram.
/// Conversations appear when you chat with someone.
class ChatsListPage extends StatefulWidget {
  const ChatsListPage({super.key});

  @override
  State<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  final TextEditingController _searchController = TextEditingController();
  final BUserService _userService = BUserService();
  final UserChatService _chatService = UserChatService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _deleteChat(ChatThread thread, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
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
        final otherUserId = _chatService.getOtherUserId(thread.threadId);
        if (otherUserId != null) {
          await _chatService.deleteChatThread(otherUserId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chat deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting chat: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = (isDark ? Colors.grey[400] : Colors.grey[600])!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // Show user selection dialog for new chat
              _showNewChatDialog(context);
            },
            tooltip: 'New message',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]!,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: subtextColor),
                      prefixIcon: Icon(Icons.search, color: subtextColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(color: textColor),
                  ),
                ),
              ),

              // Chat Threads List - Real-time with StreamBuilder
              Expanded(
            child: StreamBuilder<List<ChatThread>>(
              stream: _chatService.getChatThreadsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading chats',
                          style: TextStyle(color: subtextColor),
                        ),
                      ],
                    ),
                  );
                }

                final threads = snapshot.data ?? [];
                
                // Filter threads based on search query
                final filteredThreads = _searchQuery.isEmpty
                    ? threads
                    : threads.where((thread) {
                        final otherUserData = thread.otherUserData;
                        if (otherUserData == null) return false;
                        
                        final name = (otherUserData['displayName'] ?? '').toString().toLowerCase();
                        final email = (otherUserData['email'] ?? '').toString().toLowerCase();
                        final username = (otherUserData['username'] ?? '').toString().toLowerCase();
                        
                        return name.contains(_searchQuery) ||
                            email.contains(_searchQuery) ||
                            username.contains(_searchQuery);
                      }).toList();

                if (filteredThreads.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: subtextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No chats found',
                          style: TextStyle(
                            fontSize: 16,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredThreads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: subtextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: subtextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start chatting with someone!',
                          style: TextStyle(
                            fontSize: 14,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredThreads.length,
                  itemBuilder: (context, index) {
                    final thread = filteredThreads[index];
                    return _ChatThreadItem(
                      thread: thread,
                      isDark: isDark,
                      onTap: () {
                        final otherUserData = thread.otherUserData;
                        if (otherUserData != null) {
                          final otherUser = UserModel.fromFirestore(
                            otherUserData,
                            _chatService.getOtherUserId(thread.threadId) ?? '',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserChatPage(
                                otherUser: otherUser,
                              ),
                            ),
                          );
                        }
                      },
                      onDelete: () => _deleteChat(thread, context),
                    );
                  },
                );
              },
            ),
          ),
            ],
          ),
          
          // Floating AI Assistant Button (Bottom Right)
          Positioned(
            right: 20,
            bottom: 20,
            child: _FloatingAIChatButton(
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AIChatPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNewChatDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = (isDark ? Colors.grey[400] : Colors.grey[600])!;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final usersData = await _userService.getAllUsers();
      final users = usersData
          .map((data) {
            final id = data['id'] as String? ?? '';
            if (id.isEmpty || id == currentUser.uid) return null;
            return UserModel.fromFirestore(data, id);
          })
          .whereType<UserModel>()
          .toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('New Message'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.profileImageUrl != null &&
                            user.profileImageUrl!.isNotEmpty
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null ||
                            user.profileImageUrl!.isEmpty
                        ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                          )
                        : null,
                  ),
                  title: Text(user.displayName),
                  subtitle: Text(user.email),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserChatPage(otherUser: user),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Floating AI Chat Button
/// 
/// Floating button at bottom left of chat list screen with shimmer effect
class _FloatingAIChatButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _FloatingAIChatButton({
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_FloatingAIChatButton> createState() => _FloatingAIChatButtonState();
}

class _FloatingAIChatButtonState extends State<_FloatingAIChatButton>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _rotationController;
  String _logoUrl = 'https://res.cloudinary.com/dqymvfmbi/image/upload/v1765755084/ai/subspace_logo.jpg';

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? Colors.black : Colors.white;
    final lightBlue = Colors.lightBlue;

    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Radial light blue glow
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        lightBlue.withValues(alpha: 0.0),
                        lightBlue.withValues(alpha: 0.15),
                        lightBlue.withValues(alpha: 0.25),
                        lightBlue.withValues(alpha: 0.15),
                        lightBlue.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.4, 0.6, 0.8, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: lightBlue.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: lightBlue.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
                // Main button with animated circling border
                Container(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated circling border
                      Transform.rotate(
                        angle: _rotationController.value * 2 * math.pi,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Colors.transparent,
                                lightBlue.withValues(alpha: 0.6),
                                lightBlue.withValues(alpha: 0.9),
                                lightBlue.withValues(alpha: 0.6),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: bgColor,
                            ),
                          ),
                        ),
                      ),
                      // Logo
                      ClipOval(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: bgColor,
                          ),
                          child: Image.network(
                            _logoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.smart_toy,
                                color: _themeColor,
                                size: 28,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatThreadItem extends StatelessWidget {
  final ChatThread thread;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChatThreadItem({
    required this.thread,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = (isDark ? Colors.grey[400] : Colors.grey[600])!;
    final otherUserData = thread.otherUserData;
    
    if (otherUserData == null) {
      return const SizedBox.shrink();
    }

    final displayName = otherUserData['displayName'] ?? 'Unknown User';
    final profileImageUrl = otherUserData['profileImageUrl'] as String?;
    final lastMessage = thread.lastMessage ?? 'No messages yet';
    final lastMessageTime = thread.lastMessageTime;
    final unreadCount = thread.unreadCount;
    final isUnread = unreadCount > 0;

    return Dismissible(
      key: Key(thread.threadId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Chat'),
            content: const Text('Are you sure you want to delete this conversation?'),
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
        ) ?? false;
      },
      onDismissed: (direction) {
        onDelete();
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      backgroundImage: profileImageUrl != null &&
                              profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl == null || profileImageUrl.isEmpty
                          ? Text(
                              displayName.toString().isNotEmpty
                                  ? displayName.toString()[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[300]! : Colors.grey[700]!,
                              ),
                            )
                          : null,
                    ),
                    if (isUnread)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _themeColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.grey[900]! : Colors.white,
                              width: 2,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName.toString(),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastMessageTime != null)
                            Text(
                              _formatTime(lastMessageTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: subtextColor,
                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lastMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: isUnread ? textColor : subtextColor,
                          fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = timestamp.hour;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
