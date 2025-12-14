import 'package:flutter/material.dart';
import 'package:rentease_app/admin/utils/admin_auth_utils.dart';
import 'package:rentease_app/admin/admin_posts_page.dart';
import 'package:rentease_app/admin/admin_notifications_page.dart';
import 'package:rentease_app/admin/admin_profile_page.dart';
import 'package:rentease_app/admin/admin_users_page.dart';
import 'package:rentease_app/admin/admin_comments_page.dart';
import 'package:rentease_app/admin/admin_looking_for_page.dart';
import 'package:rentease_app/admin/admin_reports_page.dart';
import 'package:rentease_app/backend/BAdminService.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

// Theme color constants
const Color _themeColor = Color(0xFF00D1FF);
const Color _themeColorDark = Color(0xFF00B8E6);
const Color _themeColorLight = Color(0xFFE5F9FF);

/// Admin Dashboard Page
/// 
/// Main admin screen with overview stats and quick access to management modules
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final BAdminService _adminService = BAdminService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'totalListings': 0,
    'totalNotifications': 0,
    'totalComments': 0,
    'totalLookingForPosts': 0,
    'pendingReports': 0,
    'newUsersLast7Days': 0,
    'newUsersLast30Days': 0,
    'newListingsLast7Days': 0,
    'newListingsLast30Days': 0,
    'activeUsers': 0,
    'bannedUsers': 0,
    'verifiedUsers': 0,
    'categoryBreakdown': <String, int>{},
  };
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadDashboardData();
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
      return;
    }
    setState(() {
      _currentUser = userModel;
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _adminService.getEnhancedDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error loading dashboard data: $e',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: _themeColorDark,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: _themeColorDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _themeColorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _themeColorDark,
                      child: Text(
                        _currentUser?.displayName.substring(0, 1).toUpperCase() ?? 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${_currentUser?.displayName ?? 'Admin'}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Section
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Users',
                      value: _stats['totalUsers'].toString(),
                      icon: Icons.people,
                      color: _themeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Total Listings',
                      value: _stats['totalListings'].toString(),
                      icon: Icons.home,
                      color: _themeColorDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Comments',
                      value: _stats['totalComments']?.toString() ?? '0',
                      icon: Icons.comment,
                      color: _themeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Looking For',
                      value: _stats['totalLookingForPosts']?.toString() ?? '0',
                      icon: Icons.search,
                      color: _themeColorDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Pending Reports',
                      value: _stats['pendingReports']?.toString() ?? '0',
                      icon: Icons.report_problem,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Trends Section
              Text(
                'Trends (Last 30 Days)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TrendCard(
                      title: 'New Users',
                      value: _stats['newUsersLast30Days']?.toString() ?? '0',
                      last7Days: _stats['newUsersLast7Days']?.toString() ?? '0',
                      icon: Icons.person_add,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TrendCard(
                      title: 'New Listings',
                      value: _stats['newListingsLast30Days']?.toString() ?? '0',
                      last7Days: _stats['newListingsLast7Days']?.toString() ?? '0',
                      icon: Icons.home_work,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Active Users',
                      value: _stats['activeUsers']?.toString() ?? '0',
                      icon: Icons.people_outline,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Banned Users',
                      value: _stats['bannedUsers']?.toString() ?? '0',
                      icon: Icons.block,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Verified Users',
                      value: _stats['verifiedUsers']?.toString() ?? '0',
                      icon: Icons.verified,
                      color: _themeColorDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick Actions
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                title: 'Manage Users',
                subtitle: 'View, ban, and verify users',
                icon: Icons.people,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminUsersPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ActionCard(
                title: 'Manage Posts',
                subtitle: 'View and remove listings',
                icon: Icons.article,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminPostsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ActionCard(
                title: 'Manage Notifications',
                subtitle: 'View and remove notifications',
                icon: Icons.notifications_active,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminNotificationsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ActionCard(
                title: 'Manage Comments',
                subtitle: 'View, delete, and flag comments',
                icon: Icons.comment,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminCommentsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ActionCard(
                title: 'Manage Looking For Posts',
                subtitle: 'View, delete, and flag posts',
                icon: Icons.search,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminLookingForPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ActionCard(
                title: 'Manage Reports',
                subtitle: 'Review and resolve reports',
                icon: Icons.report,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminReportsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ActionCard(
                title: 'My Profile',
                subtitle: 'Manage admin profile',
                icon: Icons.person,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminProfilePage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _themeColorDark.withValues(alpha: 0.2),
          width: 1,
        ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _themeColorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _themeColorDark, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String title;
  final String value;
  final String last7Days;
  final IconData icon;
  final Color color;

  const _TrendCard({
    required this.title,
    required this.value,
    required this.last7Days,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last 7 days: $last7Days',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

