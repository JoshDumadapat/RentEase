/// Time Ago Utility
/// 
/// Converts DateTime to human-readable "time ago" format
/// (e.g., "5m", "2h", "3d" - matching social media style)
class TimeAgo {
  static String format(DateTime dateTime, {bool includeAgo = false}) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final suffix = includeAgo ? ' ago' : '';

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y$suffix';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo$suffix';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d$suffix';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h$suffix';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m$suffix';
    } else {
      return includeAgo ? 'Just now' : 'now';
    }
  }
}

