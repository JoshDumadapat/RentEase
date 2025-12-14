import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/admin/utils/admin_auth_utils.dart';
import 'package:rentease_app/backend/BAdminService.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';
import 'package:rentease_app/dialogs/confirmation_dialog.dart';
import 'package:rentease_app/admin/admin_user_detail_page.dart';

// Theme color constants
const Color _themeColorDark = Color(0xFF00B8E6);

/// Admin Looking For Posts Management Page
/// 
/// Allows admin to view all looking-for posts, delete, and flag them
class AdminLookingForPage extends StatefulWidget {
  const AdminLookingForPage({super.key});

  @override
  State<AdminLookingForPage> createState() => _AdminLookingForPageState();
}

class _AdminLookingForPageState extends State<AdminLookingForPage> {
  final BAdminService _adminService = BAdminService();
  final BUserService _userService = BUserService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allPosts = [];
  List<Map<String, dynamic>> _filteredPosts = [];
  final Map<String, Map<String, dynamic>> _userCache = {};
  final Set<String> _selectedPostIds = {};
  bool _isLoading = true;
  String _searchQuery = '';
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadPosts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAccess() async {
    final userModel = await AdminAuthUtils.verifyAdminAccess();
    if (userModel == null) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Access denied. Admin privileges required.',
          ),
        );
      }
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final posts = await _adminService.getAllLookingForPosts();
      
      // Load user data for all posts
      final userIds = posts
          .map((p) => p['userId'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      
      for (final userId in userIds) {
        try {
          final userData = await _userService.getUserData(userId);
          if (userData != null) {
            _userCache[userId] = userData;
          }
        } catch (e) {
          debugPrint('Error loading user $userId: $e');
        }
      }
      
      if (mounted) {
        // Remove duplicates based on post ID
        final seenIds = <String>{};
        final uniquePosts = <Map<String, dynamic>>[];
        for (final post in posts) {
          final postId = post['id'] as String?;
          if (postId != null && postId.isNotEmpty && !seenIds.contains(postId)) {
            seenIds.add(postId);
            uniquePosts.add(post);
          }
        }
        
        setState(() {
          _allPosts = uniquePosts;
          _filteredPosts = uniquePosts;
          _isLoading = false;
        });
        _applySearch();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error loading posts: $e',
          ),
        );
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
        _filteredPosts = _allPosts;
      });
      return;
    }

    setState(() {
      _filteredPosts = _allPosts.where((post) {
        final description = (post['description'] as String? ?? '').toLowerCase();
        final location = (post['location'] as String? ?? '').toLowerCase();
        final username = (post['username'] as String? ?? '').toLowerCase();
        final budget = (post['budget'] as String? ?? '').toLowerCase();
        final searchLower = _searchQuery.toLowerCase();

        return description.contains(searchLower) ||
            location.contains(searchLower) ||
            username.contains(searchLower) ||
            budget.contains(searchLower);
      }).toList();
    });
  }

  Future<void> _deletePost(String postId, String description) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Post',
      message: 'Are you sure you want to delete this post?\n\n"${description.length > 50 ? '${description.substring(0, 50)}...' : description}"\n\nThis action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmColor: Colors.red[600],
    );

    if (confirmed != true) return;

    try {
      await _adminService.deleteLookingForPost(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Post deleted successfully',
          ),
        );
        _loadPosts();
        _selectedPostIds.remove(postId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error deleting post: $e',
          ),
        );
      }
    }
  }

  Future<void> _flagPost(String postId) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter reason for flagging:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason (e.g., Spam, Inappropriate, etc.)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Flag'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) return;

    try {
      await _adminService.flagLookingForPost(postId, reasonController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Post flagged successfully',
          ),
        );
        _loadPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error flagging post: $e',
          ),
        );
      }
    }
  }

  Future<void> _unflagPost(String postId) async {
    try {
      await _adminService.unflagLookingForPost(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Post unflagged successfully',
          ),
        );
        _loadPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error unflagging post: $e',
          ),
        );
      }
    }
  }

  Future<void> _bulkDeletePosts() async {
    if (_selectedPostIds.isEmpty) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Bulk Delete Posts',
      message: 'Are you sure you want to delete ${_selectedPostIds.length} post(s)?\n\nThis action cannot be undone.',
      confirmText: 'Delete All',
      cancelText: 'Cancel',
      confirmColor: Colors.red[600],
    );

    if (confirmed != true) return;

    try {
      await _adminService.bulkDeleteLookingForPosts(_selectedPostIds.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            '${_selectedPostIds.length} post(s) deleted successfully',
          ),
        );
        setState(() {
          _selectedPostIds.clear();
          _selectionMode = false;
        });
        _loadPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error deleting posts: $e',
          ),
        );
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedPostIds.clear();
      }
    });
  }

  void _togglePostSelection(String postId) {
    setState(() {
      if (_selectedPostIds.contains(postId)) {
        _selectedPostIds.remove(postId);
      } else {
        _selectedPostIds.add(postId);
      }
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Unknown time';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode 
          ? '${_selectedPostIds.length} selected' 
          : 'Manage Looking For Posts'),
        backgroundColor: _themeColorDark,
        foregroundColor: Colors.white,
        actions: [
          if (_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _selectedPostIds.isEmpty ? null : _bulkDeletePosts,
              tooltip: 'Delete Selected',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
              tooltip: 'Cancel Selection',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: 'Select Multiple',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPosts,
              tooltip: 'Refresh',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by description, location, username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Posts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPosts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_outlined,
                              size: 64,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No posts found'
                                  : 'No posts found',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPosts,
                        child: ListView.builder(
                          key: const PageStorageKey<String>('admin_looking_for_list'),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredPosts.length,
                          itemBuilder: (context, index) {
                            final post = _filteredPosts[index];
                            final postId = post['id'] as String? ?? '';
                            // Ensure we have a valid ID
                            if (postId.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final description = post['description'] as String? ?? '';
                            final location = post['location'] as String? ?? '';
                            final budget = post['budget'] as String? ?? '';
                            final propertyType = post['propertyType'] as String? ?? '';
                            final username = post['username'] as String? ?? 'Unknown';
                            final userId = post['userId'] as String?;
                            final isFlagged = post['isFlagged'] as bool? ?? false;
                            final likeCount = post['likeCount'] as int? ?? 0;
                            final commentCount = post['commentCount'] as int? ?? 0;
                            final createdAt = post['createdAt'];
                            final isSelected = _selectedPostIds.contains(postId);

                            return Card(
                              key: ValueKey('post_$postId'),
                              margin: const EdgeInsets.only(bottom: 12),
                              color: isSelected 
                                ? _themeColorDark.withValues(alpha: 0.2)
                                : (isFlagged ? Colors.orange.withValues(alpha: 0.1) : cardColor),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: _selectionMode
                                    ? Checkbox(
                                        value: isSelected,
                                        onChanged: (_) => _togglePostSelection(postId),
                                      )
                                    : CircleAvatar(
                                        radius: 24,
                                        backgroundColor: isFlagged
                                            ? Colors.orange[300]
                                            : _themeColorDark,
                                        child: Text(
                                          username.isNotEmpty 
                                            ? username.substring(0, 1).toUpperCase()
                                            : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        username,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (isFlagged)
                                      Container(
                                        margin: const EdgeInsets.only(left: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'FLAGGED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      description.length > 100 
                                        ? '${description.substring(0, 100)}...' 
                                        : description,
                                      style: TextStyle(
                                        color: isDark ? Colors.grey[300] : Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          location,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.attach_money,
                                          size: 14,
                                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          budget,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          propertyType,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: _themeColorDark,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.favorite,
                                          size: 14,
                                          color: Colors.red[300],
                                        ),
                                        Text(
                                          '$likeCount',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.comment,
                                          size: 14,
                                          color: _themeColorDark,
                                        ),
                                        Text(
                                          '$commentCount',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: _selectionMode
                                    ? null
                                    : PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          switch (value) {
                                            case 'view_user':
                                              if (userId != null) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => AdminUserDetailPage(userId: userId),
                                                  ),
                                                );
                                              }
                                              break;
                                            case 'flag':
                                              await _flagPost(postId);
                                              break;
                                            case 'unflag':
                                              await _unflagPost(postId);
                                              break;
                                            case 'delete':
                                              await _deletePost(postId, description);
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          if (userId != null)
                                            const PopupMenuItem(
                                              value: 'view_user',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.person, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('View User'),
                                                ],
                                              ),
                                            ),
                                          if (userId != null) const PopupMenuDivider(),
                                          if (!isFlagged)
                                            const PopupMenuItem(
                                              value: 'flag',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.flag, size: 20, color: Colors.orange),
                                                  SizedBox(width: 8),
                                                  Text('Flag Post', style: TextStyle(color: Colors.orange)),
                                                ],
                                              ),
                                            ),
                                          if (isFlagged)
                                            const PopupMenuItem(
                                              value: 'unflag',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.flag_outlined, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Unflag Post'),
                                                ],
                                              ),
                                            ),
                                          const PopupMenuDivider(),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete Post', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                        child: const Icon(Icons.more_vert),
                                      ),
                                onTap: _selectionMode
                                    ? () => _togglePostSelection(postId)
                                    : null,
                              ),
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

