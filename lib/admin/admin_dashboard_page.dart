import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    // Monetary statistics
    'verifiedUserListings': 0,
    'verifiedUserAvailableListings': 0,
    'verifiedUserActiveListings': 0,
    'totalVerifiedRevenue': 0.0,
    'averageVerifiedPrice': 0.0,
    'estimatedMonthlyRevenue': 0.0,
    'estimatedAnnualRevenue': 0.0,
    'potentialMonthlyRevenue': 0.0,
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
      debugPrint('📊 [AdminDashboard] Loading dashboard data...');
      final stats = await _adminService.getEnhancedDashboardStats();
      debugPrint('✅ [AdminDashboard] Dashboard data loaded: $stats');
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
        debugPrint('✅ [AdminDashboard] Stats updated in UI');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [AdminDashboard] Error loading dashboard data: $e');
      debugPrint('❌ [AdminDashboard] Stack trace: $stackTrace');
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

  /// Format currency value
  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '₱${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '₱${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '₱${value.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBgColor = isDark ? Colors.grey[900] : Colors.white;
    final appBarTextColor = isDark ? Colors.white : Colors.black87;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: appBarBgColor,
          foregroundColor: appBarTextColor,
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: appBarBgColor,
        foregroundColor: appBarTextColor,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: appBarTextColor),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark 
                        ? _themeColorDark.withValues(alpha: 0.3)
                        : _themeColorDark.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark 
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            _themeColorDark,
                            _themeColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _themeColorDark.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.transparent,
                        child: Text(
                          _currentUser?.displayName.substring(0, 1).toUpperCase() ?? 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${_currentUser?.displayName ?? 'Admin'}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                size: 16,
                                color: _themeColorDark,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Admin Dashboard',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Stats Section
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Users',
                      value: _stats['totalUsers']?.toString() ?? '0',
                      icon: Icons.people_rounded,
                      color: _themeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Total Listings',
                      value: _stats['totalListings']?.toString() ?? '0',
                      isHomeIcon: true,
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
                      icon: Icons.comment_rounded,
                      color: _themeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Looking For',
                      value: _stats['totalLookingForPosts']?.toString() ?? '0',
                      icon: Icons.search_rounded,
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
                      icon: Icons.report_problem_rounded,
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 0.5,
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
                      icon: Icons.person_add_rounded,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TrendCard(
                      title: 'New Listings',
                      value: _stats['newListingsLast30Days']?.toString() ?? '0',
                      last7Days: _stats['newListingsLast7Days']?.toString() ?? '0',
                      isHomeIcon: true,
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
                      icon: Icons.people_outline_rounded,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Banned Users',
                      value: _stats['bannedUsers']?.toString() ?? '0',
                      icon: Icons.block_rounded,
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
                      icon: Icons.verified_rounded,
                      color: _themeColorDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Verified User Statistics Section (Simplified)
              Text(
                'Verified User Statistics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Simple line graph showing revenue trend
              _SimpleLineGraph(
                monthlyRevenue: _stats['estimatedMonthlyRevenue'] as double? ?? 0.0,
                annualRevenue: _stats['estimatedAnnualRevenue'] as double? ?? 0.0,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MonetaryCard(
                      title: 'Monthly Revenue',
                      value: _formatCurrency(_stats['estimatedMonthlyRevenue'] as double? ?? 0.0),
                      icon: Icons.attach_money_rounded,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MonetaryCard(
                      title: 'Available Listings',
                      value: _stats['verifiedUserAvailableListings']?.toString() ?? '0',
                      icon: Icons.home_rounded,
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              _ActionCard(
                title: 'Manage Users',
                subtitle: 'View, ban, and verify users',
                icon: Icons.people_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminUsersPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _ActionCard(
                title: 'Manage Posts',
                subtitle: 'View and remove listings',
                isHomeIcon: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminPostsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _ActionCard(
                title: 'Manage Notifications',
                subtitle: 'View and remove notifications',
                icon: Icons.notifications_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminNotificationsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _ActionCard(
                title: 'Manage Comments',
                subtitle: 'View, delete, and flag comments',
                icon: Icons.comment_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminCommentsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _ActionCard(
                title: 'Manage Looking For Posts',
                subtitle: 'View, delete, and flag posts',
                icon: Icons.search_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminLookingForPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _ActionCard(
                title: 'Manage Reports',
                subtitle: 'Review and resolve reports',
                icon: Icons.report_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminReportsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _ActionCard(
                title: 'My Profile',
                subtitle: 'Manage admin profile',
                icon: Icons.person_rounded,
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
  final IconData? icon;
  final bool isHomeIcon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    this.icon,
    this.isHomeIcon = false,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark 
              ? Colors.grey[800]!
              : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              isHomeIcon
                  ? SvgPicture.asset(
                      'assets/icons/navbar/home_filled.svg',
                      width: 26,
                      height: 26,
                      colorFilter: ColorFilter.mode(
                        color,
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(icon!, color: color, size: 26),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
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
  final IconData? icon;
  final bool isHomeIcon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    this.icon,
    this.isHomeIcon = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: _themeColorDark.withValues(alpha: 0.1),
        highlightColor: _themeColorDark.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? _themeColorDark.withValues(alpha: 0.4)
                  : _themeColorDark.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: isDark ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                spreadRadius: 0,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                spreadRadius: 0,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                spreadRadius: 0,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            _themeColorDark.withValues(alpha: 0.3),
                            _themeColorDark.withValues(alpha: 0.2),
                          ]
                        : [
                            _themeColorLight,
                            _themeColorLight.withValues(alpha: 0.8),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? _themeColorDark.withValues(alpha: 0.5)
                        : _themeColorDark.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _themeColorDark.withValues(alpha: isDark ? 0.2 : 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isHomeIcon
                    ? SvgPicture.asset(
                        'assets/icons/navbar/home_filled.svg',
                        width: 28,
                        height: 28,
                        colorFilter: ColorFilter.mode(
                          _themeColorDark,
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(icon!, color: _themeColorDark, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[800]!.withValues(alpha: 0.5)
                      : Colors.grey[100]!,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String title;
  final String value;
  final String last7Days;
  final IconData? icon;
  final bool isHomeIcon;
  final Color color;

  const _TrendCard({
    required this.title,
    required this.value,
    required this.last7Days,
    this.icon,
    this.isHomeIcon = false,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark 
              ? Colors.grey[800]!
              : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              isHomeIcon
                  ? SvgPicture.asset(
                      'assets/icons/navbar/home_filled.svg',
                      width: 26,
                      height: 26,
                      colorFilter: ColorFilter.mode(
                        color,
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(icon!, color: color, size: 26),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.grey[800]!
                  : Colors.grey[100]!,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Last 7 days: $last7Days',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleLineGraph extends StatelessWidget {
  final double monthlyRevenue;
  final double annualRevenue;
  final bool isDark;

  const _SimpleLineGraph({
    required this.monthlyRevenue,
    required this.annualRevenue,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    
    // Create simple data points for the line (12 months)
    final maxValue = annualRevenue > 0 ? annualRevenue : monthlyRevenue * 12;
    final monthlyData = List.generate(12, (index) {
      // Simple linear progression for visualization
      return (monthlyRevenue * (index + 1)).clamp(0.0, maxValue);
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Trend (12 Months)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _LineGraphPainter(
                data: monthlyData,
                maxValue: maxValue,
                color: _themeColorDark,
                isDark: isDark,
              ),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineGraphPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;
  final Color color;
  final bool isDark;

  _LineGraphPainter({
    required this.data,
    required this.maxValue,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final stepX = width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = data[i] / maxValue;
      final y = height - (normalizedValue * height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LineGraphPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.maxValue != maxValue;
}

class _MonetaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MonetaryCard({
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark 
              ? Colors.grey[800]!
              : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 26),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

