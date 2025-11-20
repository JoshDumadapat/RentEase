# Home Page Implementation Guide

## Overview

This document describes the complete implementation of the HomePage and related screens for the RentEase Flutter application.

## Folder Structure

```
RentEase/lib/
├── models/
│   ├── category_model.dart          # Category data model
│   └── listing_model.dart            # Listing data model
├── screens/
│   ├── home/
│   │   └── home_page.dart           # Main home screen
│   ├── posts/
│   │   └── posts_page.dart           # Category listings page
│   └── listing_details/
│       └── listing_details_page.dart # Listing details page
├── widgets/
│   └── bottom_navigation_bar.dart   # Reusable bottom nav bar
└── sign_in/
    └── sign_in_page.dart             # Updated to navigate to HomePage
```

## Implementation Details

### 1. Models

#### CategoryModel (`models/category_model.dart`)
- Represents property rental categories
- Contains: id, name, imagePath, description
- Includes `getMockCategories()` method with 6 categories:
  - House Rentals
  - Apartments
  - Rooms
  - Boarding House
  - Condo Rentals
  - Student Dorms

#### ListingModel (`models/listing_model.dart`)
- Represents property listings
- Contains: id, title, category, location, price, ownerName, images, description, bedrooms, bathrooms, area, postedDate
- Includes `getMockListings()` with 6 sample listings
- Includes `getListingsByCategory()` for filtering

### 2. HomePage (`screens/home/home_page.dart`)

**Features:**
- Welcome section with "Welcome to RentEase!" message
- Featured Categories section (horizontal scrollable)
- Visit Listings section (vertical scrollable)
- Bottom navigation bar
- App bar with logo and menu icon

**Navigation:**
- Category tap → Navigates to `PostsPage` with selected category
- Listing tap → Navigates to `ListingDetailsPage` with selected listing

**Components:**
- `_WelcomeSection`: Welcome message widget
- `_FeaturedCategoriesSection`: Horizontal scrollable categories
- `_CategoryCard`: Individual category card with image
- `_VisitListingsSection`: Vertical listings list
- `_ListingCard`: Individual listing card with details
- `_ActionIcon`: Like, comment, share icons

### 3. PostsPage (`screens/posts/posts_page.dart`)

**Features:**
- Displays listings filtered by category
- Empty state when no listings found
- Back navigation
- Bottom navigation bar

**Components:**
- `_ListingCard`: Reusable listing card
- `_EmptyStateWidget`: Shown when no listings available

### 4. ListingDetailsPage (`screens/listing_details/listing_details_page.dart`)

**Features:**
- Image carousel with multiple photos
- Property details (bedrooms, bathrooms, area)
- Full description
- Owner information with verification badge
- Contact owner button
- Save and Schedule Viewing buttons
- Bottom navigation bar

**Components:**
- `_ImageCarousel`: PageView with image indicators
- `_PropertyDetailsSection`: Bedrooms, bathrooms, area display
- `_DetailItem`: Individual detail item widget
- `_DescriptionSection`: Full property description
- `_OwnerSection`: Owner info with contact button
- `_ActionButtons`: Save and Schedule Viewing buttons

### 5. CustomBottomNavigationBar (`widgets/bottom_navigation_bar.dart`)

**Features:**
- Reusable bottom navigation bar
- 5 tabs: Home, Search, Add, Notifications, Profile
- Consistent styling across all screens

### 6. Sign In Navigation Update

**File:** `sign_in/sign_in_page.dart`

**Changes:**
- Added import for `HomePage`
- Updated Sign In button to navigate to `HomePage` after login
- Uses `pushReplacement` to replace sign-in screen

## Navigation Flow

```
Sign In Page
    ↓ (Successful Login)
HomePage
    ↓ (Tap Category)
PostsPage (Filtered by Category)
    ↓ (Tap Listing)
ListingDetailsPage
```

## Mock Data

### Categories
- 6 categories with images and descriptions
- Images expected in: `assets/categories/`

### Listings
- 6 sample listings across different categories
- Images expected in: `assets/listings/`
- Includes verified and unverified owners
- Various price ranges and locations

## Asset Requirements

### Category Images
Place category images in `assets/categories/`:
- `house_rentals.png`
- `apartments.png`
- `rooms.png`
- `boarding_house.png`
- `condo_rentals.png`
- `student_dorms.png`

### Listing Images
Place listing images in `assets/listings/`:
- `apartment_1_1.png`, `apartment_1_2.png`, etc.
- `house_1_1.png`, `house_1_2.png`, etc.
- `room_1_1.png`, `room_1_2.png`, etc.
- `condo_1_1.png`, `condo_1_2.png`, etc.
- `boarding_1_1.png`
- `dorm_1_1.png`, `dorm_1_2.png`

### Logo
- `assets/logo.png` (used in app bar)

**Note:** The code includes error builders that display placeholder icons if images are not found, so the app will work even without actual images.

## Usage

### Running the App

1. Ensure all dependencies are installed:
   ```bash
   flutter pub get
   ```

2. Add placeholder images (optional):
   - Create the asset directories
   - Add placeholder images or use the error builders

3. Run the app:
   ```bash
   flutter run
   ```

4. Test the flow:
   - Sign in → HomePage appears
   - Tap a category → PostsPage shows filtered listings
   - Tap a listing → ListingDetailsPage shows full details

## Customization

### Adding Real Data

To replace mock data with real data:

1. **Update CategoryModel:**
   - Replace `getMockCategories()` with API call
   - Use `FutureBuilder` in HomePage

2. **Update ListingModel:**
   - Replace `getMockListings()` with API call
   - Use `FutureBuilder` in HomePage and PostsPage
   - Implement pagination for large lists

3. **Add State Management:**
   - Consider using Provider, Riverpod, or Bloc
   - Manage loading states
   - Handle errors

### Styling

All colors and styles can be customized:
- Primary color: `Colors.blue[700]`
- Text colors: `Colors.black87`, `Colors.grey[600]`
- Card shadows and borders
- Button styles

### Adding Features

**TODO items in code:**
- Favorite/like functionality
- Comments system
- Share functionality
- Contact owner (messaging)
- Schedule viewing
- Search functionality
- Filter and sort options

## Testing Checklist

- [ ] Sign in navigates to HomePage
- [ ] Categories display correctly
- [ ] Category tap navigates to PostsPage
- [ ] Listings display in HomePage
- [ ] Listing tap navigates to ListingDetailsPage
- [ ] Image carousel works in ListingDetailsPage
- [ ] Empty state shows when no listings
- [ ] Bottom navigation bar works
- [ ] Back navigation works correctly
- [ ] Responsive design on different screen sizes

## Future Enhancements

1. **State Management:**
   - Implement Provider/Riverpod/Bloc
   - Centralized state for listings and categories

2. **API Integration:**
   - Replace mock data with real API calls
   - Implement caching
   - Add pagination

3. **Features:**
   - Search functionality
   - Filters (price, location, etc.)
   - Favorites/bookmarks
   - User reviews and ratings
   - Map view for listings
   - Image zoom functionality

4. **Performance:**
   - Image caching
   - Lazy loading
   - Optimize list rendering

## Support

For issues or questions:
- Check Flutter documentation
- Review code comments
- Test with mock data first
- Verify asset paths are correct

