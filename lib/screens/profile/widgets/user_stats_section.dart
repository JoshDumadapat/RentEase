import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rentease_app/models/user_model.dart';

/// User Stats Section Widget
/// 
/// Displays user activity statistics:
/// - Number of properties listed
/// - Number of favorites/saved properties
/// - Number of likes/comments received (optional)
class UserStatsSection extends StatelessWidget {
  final UserModel user;
  final Function(String)? onStatTap;

  const UserStatsSection({
    super.key,
    required this.user,
    this.onStatTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Properties',
                  value: user.propertiesCount.toString(),
                  iconPath: 'assets/icons/navbar/home_outlined.svg',
                  isDark: isDark,
                  onTap: onStatTap != null ? () => onStatTap!('properties') : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Favorites',
                  value: user.favoritesCount.toString(),
                  iconPath: 'assets/icons/navbar/heart_outlined.svg',
                  isDark: isDark,
                  onTap: onStatTap != null ? () => onStatTap!('favorites') : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Rating',
                  value: user.likesReceived.toString(),
                  icon: Icons.star_outline,
                  isDark: isDark,
                  onTap: null, // Rating card is not clickable
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? iconPath;
  final IconData? icon;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatTile({
    required this.label,
    required this.value,
    this.iconPath,
    this.icon,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          iconPath != null
              ? SvgPicture.asset(
                  iconPath!,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF00B8E6),
                    BlendMode.srcIn,
                  ),
                )
              : Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF00B8E6),
                ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: widget,
      );
    }

    return widget;
  }
}

