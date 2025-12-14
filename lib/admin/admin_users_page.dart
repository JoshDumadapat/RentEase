import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/admin/utils/admin_auth_utils.dart';
import 'package:rentease_app/backend/BAdminService.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';
import 'package:rentease_app/dialogs/confirmation_dialog.dart';
import 'package:rentease_app/admin/admin_user_detail_page.dart';

// Theme color constants
const Color _themeColorDark = Color(0xFF00B8E6);

/// Admin Users Management Page
/// 
/// Allows admin to view all users, ban/unban, verify/unverify
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final BAdminService _adminService = BAdminService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadUsers();
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

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _adminService.getAllUsers();
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
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error loading users: $e',
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
        _filteredUsers = _allUsers;
      });
      return;
    }

    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final email = (user['email'] as String? ?? '').toLowerCase();
        final fname = (user['fname'] as String? ?? '').toLowerCase();
        final lname = (user['lname'] as String? ?? '').toLowerCase();
        final displayName = (user['displayName'] as String? ?? '').toLowerCase();
        final searchLower = _searchQuery.toLowerCase();

        return email.contains(searchLower) ||
            fname.contains(searchLower) ||
            lname.contains(searchLower) ||
            displayName.contains(searchLower);
      }).toList();
    });
  }

  Future<void> _banUser(String userId, String userName) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Ban User',
      message: 'Are you sure you want to ban "$userName"?\n\nThey will not be able to access the app.',
      confirmText: 'Ban',
      cancelText: 'Cancel',
      confirmColor: Colors.red[600],
    );

    if (confirmed != true) return;

    try {
      await _adminService.banUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'User banned successfully',
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error banning user: $e',
          ),
        );
      }
    }
  }

  Future<void> _unbanUser(String userId, String userName) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Unban User',
      message: 'Are you sure you want to unban "$userName"?',
      confirmText: 'Unban',
      cancelText: 'Cancel',
    );

    if (confirmed != true) return;

    try {
      await _adminService.unbanUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'User unbanned successfully',
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error unbanning user: $e',
          ),
        );
      }
    }
  }

  Future<void> _verifyUser(String userId) async {
    try {
      await _adminService.verifyUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'User verified successfully',
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error verifying user: $e',
          ),
        );
      }
    }
  }

  Future<void> _unverifyUser(String userId) async {
    try {
      await _adminService.unverifyUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'User unverified successfully',
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error unverifying user: $e',
          ),
        );
      }
    }
  }

  String _getUserName(Map<String, dynamic> user) {
    final fname = user['fname'] as String? ?? '';
    final lname = user['lname'] as String? ?? '';
    final displayName = user['displayName'] as String?;
    
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    if (fname.isNotEmpty || lname.isNotEmpty) {
      return '$fname $lname'.trim();
    }
    return user['email'] as String? ?? 'Unknown User';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Unknown';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: _themeColorDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
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
                hintText: 'Search by name or email...',
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
                              Icons.people_outline,
                              size: 64,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No users found'
                                  : 'No users found',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                            final userId = user['id'] as String;
                            final userName = _getUserName(user);
                            final email = user['email'] as String? ?? 'No email';
                            final isBanned = user['isBanned'] as bool? ?? false;
                            final isVerified = user['isVerified'] as bool? ?? false;
                            final role = user['role'] as String?;
                            final createdAt = user['createdAt'];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: cardColor,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: isBanned
                                      ? Colors.red[300]
                                      : _themeColorDark,
                                  child: Text(
                                    userName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        userName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (isVerified)
                                      Icon(
                                        Icons.verified,
                                        color: _themeColorDark,
                                        size: 20,
                                      ),
                                    if (role == 'admin')
                                      Container(
                                        margin: const EdgeInsets.only(left: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _themeColorDark,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'ADMIN',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (isBanned)
                                      Container(
                                        margin: const EdgeInsets.only(left: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'BANNED',
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
                                      email,
                                      style: TextStyle(
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Joined: ${_formatDate(createdAt)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    switch (value) {
                                      case 'view':
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AdminUserDetailPage(userId: userId),
                                          ),
                                        );
                                        break;
                                      case 'verify':
                                        await _verifyUser(userId);
                                        break;
                                      case 'unverify':
                                        await _unverifyUser(userId);
                                        break;
                                      case 'ban':
                                        await _banUser(userId, userName);
                                        break;
                                      case 'unban':
                                        await _unbanUser(userId, userName);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(Icons.person, size: 20),
                                          SizedBox(width: 8),
                                          Text('View Details'),
                                        ],
                                      ),
                                    ),
                                    if (!isVerified)
                                      const PopupMenuItem(
                                        value: 'verify',
                                        child: Row(
                                          children: [
                                            Icon(Icons.verified, size: 20),
                                            SizedBox(width: 8),
                                            Text('Verify User'),
                                          ],
                                        ),
                                      ),
                                    if (isVerified)
                                      const PopupMenuItem(
                                        value: 'unverify',
                                        child: Row(
                                          children: [
                                            Icon(Icons.cancel_outlined, size: 20),
                                            SizedBox(width: 8),
                                            Text('Unverify User'),
                                          ],
                                        ),
                                      ),
                                    if (!isBanned)
                                      const PopupMenuItem(
                                        value: 'ban',
                                        child: Row(
                                          children: [
                                            Icon(Icons.block, size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Ban User', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    if (isBanned)
                                      const PopupMenuItem(
                                        value: 'unban',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, size: 20),
                                            SizedBox(width: 8),
                                            Text('Unban User'),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminUserDetailPage(userId: userId),
                                    ),
                                  );
                                },
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

