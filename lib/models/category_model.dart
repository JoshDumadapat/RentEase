class CategoryModel {
  final String id;
  final String name;
  final String imagePath;
  final String description;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.description,
  });

  static List<CategoryModel> getMockCategories() {
    return [
      CategoryModel(
        id: '1',
        name: 'House Rentals',
        imagePath: 'assets/category_imgs/house.jpg',
        description: 'Find your perfect house',
      ),
      CategoryModel(
        id: '2',
        name: 'Apartments',
        imagePath: 'assets/category_imgs/apartment2.jpg',
        description: 'Modern apartment living',
      ),
      CategoryModel(
        id: '3',
        name: 'Rooms',
        imagePath: 'assets/category_imgs/room.jpg',
        description: 'Private rooms for rent',
      ),
      CategoryModel(
        id: '4',
        name: 'Boarding House',
        imagePath: 'assets/category_imgs/boardinghouse.jpg',
        description: 'Affordable boarding options',
      ),
      CategoryModel(
        id: '5',
        name: 'Condo Rentals',
        imagePath: 'assets/category_imgs/condo.jpg',
        description: 'Luxury condo living',
      ),
      CategoryModel(
        id: '6',
        name: 'Student Dorms',
        imagePath: 'assets/category_imgs/dorms.jpg',
        description: 'Student-friendly accommodations',
      ),
    ];
  }
}

