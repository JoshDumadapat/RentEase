class CommentModel {
  final String id;
  final String username;
  final String text;
  final DateTime postedDate;
  final bool isVerified;
  final String? propertyListingId; // ID of the property listing being shared

  CommentModel({
    required this.id,
    required this.username,
    required this.text,
    required this.postedDate,
    this.isVerified = false,
    this.propertyListingId,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(postedDate);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  static List<CommentModel> getMockComments() {
    final now = DateTime.now();
    return [
      CommentModel(
        id: '1',
        username: 'Alex',
        text: 'I have a 2-bedroom apartment available near SM Seaside! Check it out:',
        postedDate: now.subtract(const Duration(minutes: 15)),
        isVerified: true,
        propertyListingId: '1', // Links to listing ID '1'
      ),
      CommentModel(
        id: '2',
        username: 'Maria',
        text: 'Check out my listing in IT Park, it might be what you\'re looking for!',
        postedDate: now.subtract(const Duration(hours: 1)),
        isVerified: false,
        propertyListingId: '2', // Links to listing ID '2'
      ),
      CommentModel(
        id: '3',
        username: 'John',
        text: 'I know a great place that matches your budget. Here\'s my property:',
        postedDate: now.subtract(const Duration(hours: 2)),
        isVerified: true,
        propertyListingId: '3', // Links to listing ID '3'
      ),
    ];
  }
}

