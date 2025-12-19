import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/backend/BFollowService.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/screens/profile/profile_page.dart';

/// Widget to display a list of followers in a modal
class FollowersListModal extends StatefulWidget {
  final String userId;
  
  const FollowersListModal({
    super.key,
    required this.userId,
  });

  @override
  State<FollowersListModal> createState() => _FollowersListModalState();
}

class _FollowersListModalState extends State<FollowersListModal> {
  final BFollowService _followService = BFollowService();
  final BUserService _userService = BUserService();
  List<UserModel> _followers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Load followers asynchronously after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFollowers();
    });
  }

  Future<void> _loadFollowers() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get list of follower IDs
      final followerIds = await _followService.getFollowers(widget.userId);
      
      if (!mounted) return;
      
      // If no followers, update state immediately
      if (followerIds.isEmpty) {
        setState(() {
          _followers = [];
          _isLoading = false;
        });
        return;
      }
      
      // Load user data in batches to avoid blocking UI
      final followers = <UserModel>[];
      
      // Process in smaller batches with delays to keep UI responsive
      const batchSize = 10;
      for (int i = 0; i < followerIds.length; i += batchSize) {
        if (!mounted) return;
        
        final batch = followerIds.skip(i).take(batchSize).toList();
        
        // Load batch in parallel
        final batchResults = await Future.wait(
          batch.map((followerId) async {
            try {
              final userData = await _userService.getUserData(followerId);
              if (userData != null) {
                return UserModel.fromFirestore(userData, followerId);
              }
              return null;
            } catch (e) {
              debugPrint('Error loading follower $followerId: $e');
              return null;
            }
          }),
        );
        
        // Add valid results
        followers.addAll(batchResults.whereType<UserModel>());
        
        // Update UI after each batch
        if (mounted) {
          setState(() {
            _followers = List.from(followers);
            // Keep loading until all batches are done
            _isLoading = i + batchSize < followerIds.length;
          });
        }
        
        // Small delay to keep UI responsive
        if (i + batchSize < followerIds.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      if (mounted) {
        setState(() {
          _followers = followers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading followers: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load followers';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToProfile(String userId) {
    Navigator.pop(context); // Close modal first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardColor = isDark ? Colors.grey[800] : Colors.grey[50];

    if (_isLoading && _followers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading followers...',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null && _followers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFollowers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_followers.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: subtextColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No followers yet',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When someone follows you, they\'ll appear here',
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _followers.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the end if still loading
          if (index == _followers.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final follower = _followers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: cardColor,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                backgroundImage: follower.profileImageUrl != null &&
                        follower.profileImageUrl!.isNotEmpty
                    ? NetworkImage(follower.profileImageUrl!)
                    : null,
                child: follower.profileImageUrl == null ||
                        follower.profileImageUrl!.isEmpty
                    ? Text(
                        follower.displayName.isNotEmpty
                            ? follower.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      )
                    : null,
              ),
              title: Text(
                follower.displayName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: follower.username != null && follower.username!.isNotEmpty
                  ? Text(
                      '@${follower.username}',
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 14,
                      ),
                    )
                  : null,
              trailing: Icon(
                Icons.chevron_right,
                color: subtextColor,
              ),
              onTap: () => _navigateToProfile(follower.id),
            ),
          );
        },
      ),
    );
  }
}

/// Widget to display a list of followers (legacy - for tab view)
class FollowersListSection extends StatefulWidget {
  final String userId;
  
  const FollowersListSection({
    super.key,
    required this.userId,
  });

  @override
  State<FollowersListSection> createState() => _FollowersListSectionState();
}

class _FollowersListSectionState extends State<FollowersListSection> {
  @override
  Widget build(BuildContext context) {
    return FollowersListModal(userId: widget.userId);
  }
}
