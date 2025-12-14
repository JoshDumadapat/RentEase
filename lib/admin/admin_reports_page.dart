import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/admin/utils/admin_auth_utils.dart';
import 'package:rentease_app/backend/BAdminService.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';
import 'package:rentease_app/dialogs/confirmation_dialog.dart';
import 'package:rentease_app/admin/admin_user_detail_page.dart';

// Theme color constants
const Color _themeColorDark = Color(0xFF00B8E6);

/// Admin Reports Management Page
/// 
/// Allows admin to view, resolve, and dismiss reports
class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final BAdminService _adminService = BAdminService();
  final BUserService _userService = BUserService();
  List<Map<String, dynamic>> _allReports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  Map<String, Map<String, dynamic>> _userCache = {};
  bool _isLoading = true;
  String _filterStatus = 'all'; // 'all', 'pending', 'resolved', 'dismissed'

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadReports();
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

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reports = await _adminService.getAllReports(
        status: _filterStatus == 'all' ? null : _filterStatus,
      );
      
      // Load user data for all reports
      final userIds = reports
          .map((r) => r['reporterId'] as String?)
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
        setState(() {
          _allReports = reports;
          _filteredReports = reports;
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
            'Error loading reports: $e',
          ),
        );
      }
    }
  }

  Future<void> _resolveReport(String reportId, Map<String, dynamic> report) async {
    final actionController = TextEditingController();
    final notesController = TextEditingController();
    
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Report'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Content Type: ${report['contentType']}'),
              const SizedBox(height: 8),
              Text('Reason: ${report['reason']}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Action Taken',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'deleted', child: Text('Content Deleted')),
                  DropdownMenuItem(value: 'warned', child: Text('User Warned')),
                  DropdownMenuItem(value: 'banned', child: Text('User Banned')),
                  DropdownMenuItem(value: 'dismissed', child: Text('Report Dismissed')),
                  DropdownMenuItem(value: 'flagged', child: Text('Content Flagged')),
                ],
                onChanged: (value) {
                  actionController.text = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Admin Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (actionController.text.isNotEmpty) {
                Navigator.pop(context, actionController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeColorDark,
            ),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (action == null) return;

    try {
      await _adminService.resolveReport(
        reportId,
        action,
        notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Report resolved successfully',
          ),
        );
        _loadReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error resolving report: $e',
          ),
        );
      }
    }
  }

  Future<void> _dismissReport(String reportId) async {
    final notesController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismiss Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to dismiss this report?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes (Optional)',
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
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _adminService.dismissReport(
        reportId,
        notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Report dismissed successfully',
          ),
        );
        _loadReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error dismissing report: $e',
          ),
        );
      }
    }
  }

  String _getUserName(String? userId) {
    if (userId == null) return 'Unknown User';
    final userData = _userCache[userId];
    if (userData == null) return 'Loading...';
    
    final fname = userData['fname'] as String? ?? '';
    final lname = userData['lname'] as String? ?? '';
    final displayName = userData['displayName'] as String?;
    
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    if (fname.isNotEmpty || lname.isNotEmpty) {
      return '$fname $lname'.trim();
    }
    return userData['email'] as String? ?? 'Unknown User';
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getContentTypeIcon(String? contentType) {
    switch (contentType) {
      case 'listing':
        return Icons.home;
      case 'comment':
        return Icons.comment;
      case 'lookingForPost':
        return Icons.search;
      case 'user':
        return Icons.person;
      default:
        return Icons.report;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Reports'),
        backgroundColor: _themeColorDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _filterStatus == 'all',
                    onSelected: () {
                      setState(() {
                        _filterStatus = 'all';
                      });
                      _loadReports();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pending',
                    isSelected: _filterStatus == 'pending',
                    onSelected: () {
                      setState(() {
                        _filterStatus = 'pending';
                      });
                      _loadReports();
                    },
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Resolved',
                    isSelected: _filterStatus == 'resolved',
                    onSelected: () {
                      setState(() {
                        _filterStatus = 'resolved';
                      });
                      _loadReports();
                    },
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Dismissed',
                    isSelected: _filterStatus == 'dismissed',
                    onSelected: () {
                      setState(() {
                        _filterStatus = 'dismissed';
                      });
                      _loadReports();
                    },
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Reports List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.report_outlined,
                              size: 64,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No reports found',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadReports,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = _filteredReports[index];
                            final reportId = report['id'] as String;
                            final contentType = report['contentType'] as String? ?? 'unknown';
                            final contentId = report['contentId'] as String? ?? '';
                            final reason = report['reason'] as String? ?? '';
                            final description = report['description'] as String? ?? '';
                            final status = report['status'] as String? ?? 'pending';
                            final reporterId = report['reporterId'] as String?;
                            final action = report['action'] as String?;
                            final adminNotes = report['adminNotes'] as String?;
                            final createdAt = report['createdAt'];
                            final statusColor = _getStatusColor(status);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: cardColor,
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: statusColor.withOpacity(0.2),
                                  child: Icon(
                                    _getContentTypeIcon(contentType),
                                    color: statusColor,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${contentType.toUpperCase()} Report',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: const TextStyle(
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
                                      'Reason: $reason',
                                      style: TextStyle(
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
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
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _InfoRow(
                                          label: 'Content ID',
                                          value: contentId,
                                          icon: Icons.tag,
                                        ),
                                        const SizedBox(height: 8),
                                        if (description.isNotEmpty) ...[
                                          _InfoRow(
                                            label: 'Description',
                                            value: description,
                                            icon: Icons.description,
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        _InfoRow(
                                          label: 'Reporter',
                                          value: _getUserName(reporterId),
                                          icon: Icons.person,
                                        ),
                                        if (status == 'resolved' && action != null) ...[
                                          const SizedBox(height: 8),
                                          _InfoRow(
                                            label: 'Action Taken',
                                            value: action,
                                            icon: Icons.check_circle,
                                          ),
                                        ],
                                        if (adminNotes != null && adminNotes.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          _InfoRow(
                                            label: 'Admin Notes',
                                            value: adminNotes,
                                            icon: Icons.note,
                                          ),
                                        ],
                                        const SizedBox(height: 16),
                                        if (status == 'pending')
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _resolveReport(reportId, report),
                                                  icon: const Icon(Icons.check),
                                                  label: const Text('Resolve'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _dismissReport(reportId),
                                                  icon: const Icon(Icons.close),
                                                  label: const Text('Dismiss'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.grey,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (reporterId != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => AdminUserDetailPage(userId: reporterId),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.person),
                                                label: const Text('View Reporter'),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: color ?? _themeColorDark,
      checkmarkColor: Colors.white,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

