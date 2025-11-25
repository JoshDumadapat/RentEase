class LookingForPostModel {
  final String id;
  final String username;
  final String description;
  final String location;
  final String budget;
  final String date;
  final String propertyType;
  final DateTime? moveInDate;

  LookingForPostModel({
    required this.id,
    required this.username,
    required this.description,
    required this.location,
    required this.budget,
    required this.date,
    required this.propertyType,
    this.moveInDate,
  });

  static List<LookingForPostModel> getMockLookingForPosts() {
    return [
      LookingForPostModel(
        id: '1',
        username: 'Rica',
        description: 'Looking for a 2-bedroom apartment near SM Seaside',
        location: 'Cebu City',
        budget: '₱10,000-₱12,000',
        date: 'Nov 25',
        propertyType: 'Apartment',
        moveInDate: DateTime(2024, 11, 25),
      ),
      LookingForPostModel(
        id: '2',
        username: 'Mark',
        description: 'Looking for a studio condo in IT Park',
        location: 'Cebu City',
        budget: '₱7,000-₱9,000',
        date: 'Nov 24',
        propertyType: 'Condo',
        moveInDate: DateTime(2024, 11, 24),
      ),
      LookingForPostModel(
        id: '3',
        username: 'Sarah',
        description: 'Need a room near university campus, preferably with WiFi and study area',
        location: 'Manila',
        budget: '₱3,000-₱5,000',
        date: 'Nov 23',
        propertyType: 'Rooms',
        moveInDate: DateTime(2024, 12, 1),
      ),
      LookingForPostModel(
        id: '4',
        username: 'James',
        description: 'Looking for a 3-bedroom house with parking space for family',
        location: 'Quezon City',
        budget: '₱15,000-₱20,000',
        date: 'Nov 22',
        propertyType: 'House Rentals',
        moveInDate: DateTime(2024, 12, 15),
      ),
    ];
  }
}

