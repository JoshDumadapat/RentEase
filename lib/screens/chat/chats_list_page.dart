import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/screens/chat/user_chat_page.dart';
import 'package:rentease_app/screens/chat/ai_chat_page.dart';
import 'package:rentease_app/utils/time_ago.dart';
import 'dart:math' as math;

const Color _themeColorDark = Color(0xFF00B8E6);
const Color _themeColor = Color(0xFF00D1FF);

/// Chats List Page
/// 
/// Shows a list of all users you can chat with, similar to Facebook Messenger.
/// Includes a search bar and list of chat threads.
class ChatsListPage extends StatefulWidget {
  const ChatsListPage({super.key});

  @override
  State<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  final TextEditingController _searchController = TextEditingController();
  final BUserService _userService = BUserService();
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get all users (you might want to filter this to only users you've chatted with)
      // For now, we'll get all users
      final usersData = await _userService.getAllUsers();
      
      // Convert to UserModel and exclude current user
      final users = usersData
          .map((data) {
            final id = data['id'] as String? ?? '';
            if (id.isEmpty || id == currentUser.uid) return null;
            return UserModel.fromFirestore(data, id);
          })
          .whereType<UserModel>()
          .toList();

      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _isLoading = false;
        });
        _applySearch();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
    _applySearch();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredUsers = _allUsers;
      });
      return;
    }

    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = user.displayName.toLowerCase();
        final username = (user.username ?? '').toLowerCase();
        final email = user.email.toLowerCase();
        return name.contains(_searchQuery) ||
            username.contains(_searchQuery) ||
            email.contains(_searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

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
              // New chat action
            },
            tooltip: 'New message',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
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

          // Subspace AI Chat Item (always shown first)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _SubspaceAIChatItem(
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

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
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
                              'No users found',
                              style: TextStyle(
                                fontSize: 16,
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return _ChatListItem(
                              user: user,
                              isDark: isDark,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserChatPage(
                                      otherUser: user,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SubspaceAIChatItem extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _SubspaceAIChatItem({
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SubspaceAIChatItem> createState() => _SubspaceAIChatItemState();
}

class _SubspaceAIChatItemState extends State<_SubspaceAIChatItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  String _logoUrl = 'https://res.cloudinary.com/dqymvfmbi/image/upload/v1765755084/ai/subspace_logo.jpg';

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final subtextColor = widget.isDark ? Colors.grey[400] : Colors.grey[600];
    final bgColor = widget.isDark ? Colors.black : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
          child: Row(
            children: [
              // Subspace AI Avatar with animation
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _themeColor.withValues(alpha: 0.15),
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
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  Colors.transparent,
                                  _themeColor.withValues(alpha: 0.2),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // Background circle
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: bgColor,
                            border: Border.all(
                              color: _themeColor,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              _logoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.smart_toy,
                                  color: _themeColor,
                                  size: 32,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 18),
              // AI Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Subspace',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                    const SizedBox(height: 6),
                    Text(
                      'AI Assistant',
                      style: TextStyle(
                        fontSize: 14,
                        color: subtextColor,
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
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final UserModel user;
  final bool isDark;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.user,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
          child: Row(
            children: [
              // Profile Picture - Circular
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
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
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          )
                        : null,
                  ),
                  // Active status indicator (optional - you can add this later)
                  // Positioned(
                  //   right: 0,
                  //   bottom: 0,
                  //   child: Container(
                  //     width: 14,
                  //     height: 14,
                  //     decoration: BoxDecoration(
                  //       color: Colors.green,
                  //       shape: BoxShape.circle,
                  //       border: Border.all(
                  //         color: isDark ? Colors.grey[900] : Colors.white,
                  //         width: 2,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(width: 18),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.displayName,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Last message time (you can add this when you have chat messages)
                        // Text(
                        //   '1:00 pm',
                        //   style: TextStyle(
                        //     fontSize: 12,
                        //     color: subtextColor,
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Last message preview (you can add this when you have chat messages)
                    Text(
                      'Tap to start chatting',
                      style: TextStyle(
                        fontSize: 14,
                        color: subtextColor,
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
    );
  }
}
