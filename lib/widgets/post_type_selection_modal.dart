import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rentease_app/screens/add_property/add_property_page.dart';
import 'package:rentease_app/screens/add_looking_for_post/add_looking_for_post_screen.dart';

// Theme color constants
const Color _themeColor = Color(0xFF00D1FF);
const Color _themeColorDark = Color(0xFF00B8E6);
const Color _lookingForColor = Color(0xFF6C63FF);

void showPostTypeSelectionModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext context) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final backgroundColor = isDark ? Colors.grey[900]! : Colors.white;
      final textColor = isDark ? Colors.white : Colors.black87;
      final subtextColor = isDark ? Colors.grey[300]! : Colors.grey[600]!;
      
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 28),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Text(
                  'Create a Post',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose what you want to share',
                  style: TextStyle(
                    fontSize: 15,
                    color: subtextColor,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Options
                _PostTypeOption(
                  iconPath: 'assets/icons/navbar/home_filled.svg',
                  title: 'List a Property',
                  description: 'Post a property listing for rent',
                  gradientColors: const [
                    Color(0xFF00D1FF),
                    Color(0xFF00B8E6),
                  ],
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddPropertyPage(),
                      ),
                    );
                    
                    // If a listing was published, the home page should refresh
                    // The home page will refresh on next visibility or pull-to-refresh
                    if (result != null) {
                      debugPrint('🔄 [PostTypeModal] Listing published (ID: $result), home page should refresh');
                    }
                  },
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
                const SizedBox(height: 16),
                _PostTypeOption(
                  iconPath: 'assets/icons/navbar/search_filled.svg',
                  title: 'Looking For a Place',
                  description: 'Post what you\'re looking for',
                  gradientColors: const [
                    Color(0xFF6C63FF),
                    Color(0xFF5A52E6),
                  ],
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddLookingForPostScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _PostTypeOption extends StatelessWidget {
  final String iconPath;
  final String title;
  final String description;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final bool isDark;
  final Color textColor;
  final Color subtextColor;

  const _PostTypeOption({
    required this.iconPath,
    required this.title,
    required this.description,
    required this.gradientColors,
    required this.onTap,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradientColors[0].withValues(alpha: isDark ? 0.2 : 0.08),
                gradientColors[1].withValues(alpha: isDark ? 0.15 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: gradientColors[0].withValues(alpha: isDark ? 0.3 : 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon with gradient background
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    width: 28,
                    height: 28,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: subtextColor,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: gradientColors[0].withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: gradientColors[0],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
