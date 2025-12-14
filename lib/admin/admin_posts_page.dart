import 'package:flutter/material.dart';
import 'package:rentease_app/admin/utils/admin_auth_utils.dart';
import 'package:rentease_app/backend/BAdminService.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';
import 'package:rentease_app/dialogs/confirmation_dialog.dart';
import 'package:rentease_app/admin/admin_user_detail_page.dart';

// Theme color constants
const Color _themeColorDark = Color(0xFF00B8E6);

/// Admin Posts Management Page
/// 
/// Allows admin to view all posts/listings and remove them
class AdminPostsPage extends StatefulWidget {
  const AdminPostsPage({super.key});

  @override
  State<AdminPostsPage> createState() => _AdminPostsPageState();
}

class _AdminPostsPageState extends State<AdminPostsPage> {
  final BAdminService _adminService = BAdminService();
  final BUserService _userService = BUserService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allListings = [];
  List<Map<String, dynamic>> _filteredListings = [];
  final Map<String, Map<String, dynamic>> _userCache = {}; // Cache user data
  final Set<String> _selectedListingIds = {};
  bool _isLoading = true;
  String _searchQuery = '';
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadListings();
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
    _applySearch();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredListings = _allListings;
      });
      return;
    }

    setState(() {
      _filteredListings = _allListings.where((listing) {
        final title = (listing['title'] as String? ?? '').toLowerCase();
        final location = (listing['location'] as String? ?? '').toLowerCase();
        final description = (listing['description'] as String? ?? '').toLowerCase();
        final searchLower = _searchQuery.toLowerCase();

        return title.contains(searchLower) ||
            location.contains(searchLower) ||
            description.contains(searchLower);
      }).toList();
    });
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

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final listings = await _adminService.getAllListings();
      
      // Load user data for all listings
      final userIds = listings
          .map((l) => l['userId'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      
      // Fetch user data for all unique user IDs
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
          _allListings = listings;
          _filteredListings = listings;
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
            'Error loading listings: $e',
          ),
        );
      }
    }
  }

  Future<void> _deleteListing(String listingId, String title) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Listing',
      message: 'Are you sure you want to delete "$title"?\n\nThis action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmColor: Colors.red[600],
    );

    if (confirmed != true) return;

    try {
      await _adminService.deleteListing(listingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Listing deleted successfully',
          ),
        );
        _loadListings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error deleting listing: $e',
          ),
        );
      }
    }
  }

  Future<void> _flagListing(String listingId) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Listing'),
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
      await _adminService.flagListing(listingId, reasonController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Listing flagged successfully',
          ),
        );
        _loadListings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error flagging listing: $e',
          ),
        );
      }
    }
  }

  Future<void> _unflagListing(String listingId) async {
    try {
      await _adminService.unflagListing(listingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Listing unflagged successfully',
          ),
        );
        _loadListings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error unflagging listing: $e',
          ),
        );
      }
    }
  }

  Future<void> _bulkDeleteListings() async {
    if (_selectedListingIds.isEmpty) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Bulk Delete Listings',
      message: 'Are you sure you want to delete ${_selectedListingIds.length} listing(s)?\n\nThis action cannot be undone.',
      confirmText: 'Delete All',
      cancelText: 'Cancel',
      confirmColor: Colors.red[600],
    );

    if (confirmed != true) return;

    try {
      await _adminService.bulkDeleteListings(_selectedListingIds.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            '${_selectedListingIds.length} listing(s) deleted successfully',
          ),
        );
        setState(() {
          _selectedListingIds.clear();
          _selectionMode = false;
        });
        _loadListings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error deleting listings: $e',
          ),
        );
      }
    }
  }

  Future<void> _bulkFlagListings() async {
    if (_selectedListingIds.isEmpty) return;

    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Flag Listings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Flag ${_selectedListingIds.length} listing(s)?'),
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
            child: const Text('Flag All'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) return;

    try {
      await _adminService.bulkFlagListings(_selectedListingIds.toList(), reasonController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            '${_selectedListingIds.length} listing(s) flagged successfully',
          ),
        );
        setState(() {
          _selectedListingIds.clear();
          _selectionMode = false;
        });
        _loadListings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error flagging listings: $e',
          ),
        );
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedListingIds.clear();
      }
    });
  }

  void _toggleListingSelection(String listingId) {
    setState(() {
      if (_selectedListingIds.contains(listingId)) {
        _selectedListingIds.remove(listingId);
      } else {
        _selectedListingIds.add(listingId);
      }
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
        // Reload user data
        final userData = await _userService.getUserData(userId);
        if (userData != null) {
          setState(() {
            _userCache[userId] = userData;
          });
        }
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

  bool _isUserBanned(String? userId) {
    if (userId == null) return false;
    final userData = _userCache[userId];
    return userData?['isBanned'] as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode 
          ? '${_selectedListingIds.length} selected' 
          : 'Manage Posts'),
        backgroundColor: _themeColorDark,
        foregroundColor: Colors.white,
        actions: [
          if (_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              onPressed: _selectedListingIds.isEmpty ? null : _bulkFlagListings,
              tooltip: 'Flag Selected',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _selectedListingIds.isEmpty ? null : _bulkDeleteListings,
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
              onPressed: _loadListings,
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
                hintText: 'Search by title, location...',
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

          // Listings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredListings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 64,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No listings found'
                                  : 'No listings found',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadListings,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredListings.length,
                          itemBuilder: (context, index) {
                            final listing = _filteredListings[index];
                      final listingModel = ListingModel.fromMap(listing);
                      final listingId = listing['id'] as String;
                      final isFlagged = listing['isFlagged'] as bool? ?? false;
                      final isSelected = _selectedListingIds.contains(listingId);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isSelected 
                          ? _themeColorDark.withValues(alpha: 0.2)
                          : (isFlagged ? Colors.orange.withValues(alpha: 0.1) : cardColor),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: _selectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _toggleListingSelection(listingId),
                                )
                              : (listingModel.imagePaths.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        listingModel.imagePaths.first,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.home),
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.home),
                                    )),
                          title: Text(
                            listingModel.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                listingModel.location,
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₱${listingModel.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: _themeColorDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Show who posted it
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Posted by: ${_getUserName(listing['userId'] as String?)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_isUserBanned(listing['userId'] as String?))
                                    Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
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
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (isFlagged)
                                    Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
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
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                listingModel.timeAgo,
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
                                    final userId = listing['userId'] as String?;
                                    final userName = _getUserName(userId);
                                    
                                    switch (value) {
                                      case 'delete':
                                        await _deleteListing(
                                          listingModel.id,
                                          listingModel.title,
                                        );
                                        break;
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
                                      case 'ban_user':
                                        if (userId != null) {
                                          await _banUser(userId, userName);
                                        }
                                        break;
                                      case 'flag':
                                        await _flagListing(listingId);
                                        break;
                                      case 'unflag':
                                        await _unflagListing(listingId);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) {
                                    final userId = listing['userId'] as String?;
                                    final isBanned = _isUserBanned(userId);
                                    
                                    return [
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
                                      if (!isBanned && userId != null)
                                        const PopupMenuItem(
                                          value: 'ban_user',
                                          child: Row(
                                            children: [
                                              Icon(Icons.block, size: 20, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Ban User', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      const PopupMenuDivider(),
                                      if (!isFlagged)
                                        const PopupMenuItem(
                                          value: 'flag',
                                          child: Row(
                                            children: [
                                              Icon(Icons.flag, size: 20, color: Colors.orange),
                                              SizedBox(width: 8),
                                              Text('Flag Listing', style: TextStyle(color: Colors.orange)),
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
                                              Text('Unflag Listing'),
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
                                            Text('Delete Listing', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ];
                                  },
                                  child: const Icon(Icons.more_vert),
                                ),
                          onTap: _selectionMode
                              ? () => _toggleListingSelection(listingId)
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

