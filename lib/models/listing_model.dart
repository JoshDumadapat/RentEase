class ListingModel {
  final String id;
  final String title;
  final String category;
  final String location;
  final double price;
  final String ownerName;
  final bool isOwnerVerified;
  final List<String> imagePaths;
  final String description;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final DateTime postedDate;

  ListingModel({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.price,
    required this.ownerName,
    this.isOwnerVerified = false,
    required this.imagePaths,
    required this.description,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.postedDate,
  });

  static List<ListingModel> getMockListings() {
    final now = DateTime.now();
    return [
      ListingModel(
        id: '1',
        title: '2 Bedroom Apartment for Rent',
        category: 'Apartment',
        location: 'Metro Manila, 264 St, Philippines',
        price: 3400.00,
        ownerName: 'John Doe',
        isOwnerVerified: true,
        imagePaths: [
          'assets/listings/bedroom1.jpg',
          'assets/listings/bedroom2.jpg',
          'assets/listings/bedroom3.jpg',
          'assets/listings/bedroom4.jpg',
        ],
        description: 'Beautiful 2-bedroom apartment with modern amenities. Located in a prime area with easy access to transportation and shopping centers.',
        bedrooms: 2,
        bathrooms: 1,
        area: 65.0,
        postedDate: now.subtract(const Duration(days: 2)),
      ),
      ListingModel(
        id: '2',
        title: 'Spacious 3BR House with Garden',
        category: 'House Rentals',
        location: 'Quezon City, Philippines',
        price: 8500.00,
        ownerName: 'Jane Smith',
        isOwnerVerified: true,
        imagePaths: [
          'assets/listings/housee2.jpg',
          'assets/listings/gardeen2.jpg',
          'assets/listings/bedroom5.jpg',
        ],
        description: 'Lovely family home with garden and parking space. Perfect for families looking for a comfortable living space.',
        bedrooms: 3,
        bathrooms: 2,
        area: 120.0,
        postedDate: now.subtract(const Duration(days: 5)),
      ),
      ListingModel(
        id: '3',
        title: 'Cozy Studio Room Near University',
        category: 'Rooms',
        location: 'Makati, Philippines',
        price: 2500.00,
        ownerName: 'Maria Garcia',
        isOwnerVerified: false,
        imagePaths: [
          'assets/listings/studioroom.jpg',
          'assets/listings/bedroom1.jpg',
        ],
        description: 'Furnished studio room perfect for students. Walking distance to university and public transport.',
        bedrooms: 1,
        bathrooms: 1,
        area: 25.0,
        postedDate: now.subtract(const Duration(days: 1)),
      ),
      ListingModel(
        id: '4',
        title: 'Modern Condo Unit with City View',
        category: 'Condo Rentals',
        location: 'BGC, Taguig, Philippines',
        price: 12000.00,
        ownerName: 'Robert Johnson',
        isOwnerVerified: true,
        imagePaths: [
          'assets/listings/condo2.jpg',
          'assets/listings/bedroom3.jpg',
          'assets/listings/bedroom4.jpg',
          'assets/listings/bedroom5.jpg',
        ],
        description: 'Luxury condo unit with stunning city views. Includes gym, pool, and 24/7 security.',
        bedrooms: 2,
        bathrooms: 2,
        area: 85.0,
        postedDate: now.subtract(const Duration(days: 3)),
      ),
      ListingModel(
        id: '5',
        title: 'Affordable Boarding House Room',
        category: 'Boarding House',
        location: 'Manila, Philippines',
        price: 1800.00,
        ownerName: 'Luis Rodriguez',
        isOwnerVerified: false,
        imagePaths: [
          'assets/listings/bedroom2.jpg',
        ],
        description: 'Clean and affordable boarding house room. Shared kitchen and bathroom facilities.',
        bedrooms: 1,
        bathrooms: 0,
        area: 15.0,
        postedDate: now.subtract(const Duration(days: 7)),
      ),
      ListingModel(
        id: '6',
        title: 'Student Dormitory - Single Bed',
        category: 'Student Dorms',
        location: 'Diliman, Quezon City, Philippines',
        price: 2000.00,
        ownerName: 'Anna Lee',
        isOwnerVerified: true,
        imagePaths: [
          'assets/listings/singledorm.jpg',
          'assets/listings/bedroom1.jpg',
        ],
        description: 'Student-friendly dormitory with study areas and WiFi. Close to universities.',
        bedrooms: 1,
        bathrooms: 1,
        area: 12.0,
        postedDate: now.subtract(const Duration(hours: 12)),
      ),
    ];
  }

  static List<ListingModel> getListingsByCategory(String category) {
    return getMockListings()
        .where((listing) => listing.category.toLowerCase() == category.toLowerCase())
        .toList();
  }
}

