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

/// Admin Comments Management Page
/// 
/// Allows admin to view all comments, delete, and flag them
class AdminCommentsPage extends StatefulWidget {
  const AdminCommentsPage({super.key});

  @override
  State<AdminCommentsPage> createState() => _AdminCommentsPageState();
}

class _AdminCommentsPageState extends State<AdminCommentsPage> {
  final BAdminService _adminService = BAdminService();
  final BUserService _userService = BUserService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allComments = [];
  List<Map<String, dynamic>> _filteredComments = [];
  final Map<String, Map<String, dynamic>> _userCache = {};
  final Set<String> _selectedCommentIds = {};
  bool _isLoading = true;
  String _searchQuery = '';
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadComments();
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

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final comments = await _adminService.getAllComments();
      
      // Load user data for all comments
      final userIds = comments
          .map((c) => c['userId'] as String?)
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
        // Remove duplicates based on comment ID
        final seenIds = <String>{};
        final uniqueComments = <Map<String, dynamic>>[];
        for (final comment in comments) {
          final commentId = comment['id'] as String?;
          if (commentId != null && commentId.isNotEmpty && !seenIds.contains(commentId)) {
            seenIds.add(commentId);
            uniqueComments.add(comment);
          }
        }
        
        setState(() {
          _allComments = uniqueComments;
          _filteredComments = uniqueComments;
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
            'Error loading comments: $e',
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
        _filteredComments = _allComments;
      });
      return;
    }

    setState(() {
      _filteredComments = _allComments.where((comment) {
        final text = (comment['text'] as String? ?? '').toLowerCase();
        final username = (comment['username'] as String? ?? '').toLowerCase();
        final searchLower = _searchQuery.toLowerCase();

        return text.contains(searchLower) || username.contains(searchLower);
      }).toList();
    });
  }

  Future<void> _deleteComment(String commentId, String text) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Comment',
      message: 'Are you sure you want to delete this comment?\n\n"${text.length > 50 ? '${text.substring(0, 50)}...' : text}"\n\nThis action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmColor: Colors.red[600],
    );

    if (confirmed != true) return;

    try {
      await _adminService.deleteComment(commentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Comment deleted successfully',
          ),
        );
        _loadComments();
        _selectedCommentIds.remove(commentId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error deleting comment: $e',
          ),
        );
      }
    }
  }

  Future<void> _flagComment(String commentId) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Comment'),
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
      await _adminService.flagComment(commentId, reasonController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Comment flagged successfully',
          ),
        );
        _loadComments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error flagging comment: $e',
          ),
        );
      }
    }
  }

  Future<void> _unflagComment(String commentId) async {
    try {
      await _adminService.unflagComment(commentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Comment unflagged successfully',
          ),
        );
        _loadComments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error unflagging comment: $e',
          ),
        );
      }
    }
  }

  Future<void> _bulkDeleteComments() async {
    if (_selectedCommentIds.isEmpty) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Bulk Delete Comments',
      message: 'Are you sure you want to delete ${_selectedCommentIds.length} comment(s)?\n\nThis action cannot be undone.',
      confirmText: 'Delete All',
      cancelText: 'Cancel',
      confirmColor: Colors.red[600],
    );

    if (confirmed != true) return;

    try {
      await _adminService.bulkDeleteComments(_selectedCommentIds.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            '${_selectedCommentIds.length} comment(s) deleted successfully',
          ),
        );
        setState(() {
          _selectedCommentIds.clear();
          _selectionMode = false;
        });
        _loadComments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error deleting comments: $e',
          ),
        );
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedCommentIds.clear();
      }
    });
  }

  void _toggleCommentSelection(String commentId) {
    setState(() {
      if (_selectedCommentIds.contains(commentId)) {
        _selectedCommentIds.remove(commentId);
      } else {
        _selectedCommentIds.add(commentId);
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
          ? '${_selectedCommentIds.length} selected' 
          : 'Manage Comments'),
        backgroundColor: _themeColorDark,
        foregroundColor: Colors.white,
        actions: [
          if (_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _selectedCommentIds.isEmpty ? null : _bulkDeleteComments,
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
              onPressed: _loadComments,
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
                hintText: 'Search by comment text or username...',
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

          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredComments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 64,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No comments found'
                                  : 'No comments found',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadComments,
                        child: ListView.builder(
                          key: const PageStorageKey<String>('admin_comments_list'),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredComments.length,
                          itemBuilder: (context, index) {
                            final comment = _filteredComments[index];
                            final commentId = comment['id'] as String? ?? '';
                            // Ensure we have a valid ID
                            if (commentId.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final text = comment['text'] as String? ?? '';
                            final username = comment['username'] as String? ?? 'Unknown';
                            final userId = comment['userId'] as String?;
                            final isFlagged = comment['isFlagged'] as bool? ?? false;
                            final createdAt = comment['createdAt'];
                            final isSelected = _selectedCommentIds.contains(commentId);

                            return Card(
                              key: ValueKey('comment_$commentId'),
                              margin: const EdgeInsets.only(bottom: 12),
                              color: isSelected 
                                ? _themeColorDark.withValues(alpha: 0.2)
                                : (isFlagged ? Colors.orange.withValues(alpha: 0.1) : cardColor),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: _selectionMode
                                    ? Checkbox(
                                        value: isSelected,
                                        onChanged: (_) => _toggleCommentSelection(commentId),
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
                                      text,
                                      style: TextStyle(
                                        color: isDark ? Colors.grey[300] : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
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
                                              await _flagComment(commentId);
                                              break;
                                            case 'unflag':
                                              await _unflagComment(commentId);
                                              break;
                                            case 'delete':
                                              await _deleteComment(commentId, text);
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
                                                  Text('Flag Comment', style: TextStyle(color: Colors.orange)),
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
                                                  Text('Unflag Comment'),
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
                                                Text('Delete Comment', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                        child: const Icon(Icons.more_vert),
                                      ),
                                onTap: _selectionMode
                                    ? () => _toggleCommentSelection(commentId)
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

