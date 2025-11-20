# Screens Directory

This directory contains all the main screens of the RentEase application.

## Structure

```
screens/
├── home/
│   └── home_page.dart          # Main home screen after login
├── posts/
│   └── posts_page.dart         # Category-filtered listings page
└── listing_details/
    └── listing_details_page.dart # Individual listing details page
```

## Screen Flow

```
Sign In → HomePage → PostsPage (on category tap) → ListingDetailsPage (on listing tap)
```

## HomePage

- **Location**: `screens/home/home_page.dart`
- **Purpose**: Main landing page after successful login
- **Features**:
  - Welcome message for first-time users
  - Featured categories section (horizontal scrollable)
  - Visit listings section (vertical scrollable list)
  - Bottom navigation bar

## PostsPage

- **Location**: `screens/posts/posts_page.dart`
- **Purpose**: Displays listings filtered by selected category
- **Features**:
  - Shows all listings for a specific category
  - Empty state when no listings found
  - Navigation to listing details

## ListingDetailsPage

- **Location**: `screens/listing_details/listing_details_page.dart`
- **Purpose**: Shows detailed information about a property listing
- **Features**:
  - Image carousel with multiple photos
  - Property details (bedrooms, bathrooms, area)
  - Description
  - Owner information with contact button
  - Action buttons (Save, Schedule Viewing)

## Navigation

All screens use standard Flutter navigation:
- `Navigator.push()` for forward navigation
- `Navigator.pop()` for back navigation
- `Navigator.pushReplacement()` for login flow

## Dependencies

- Models: `models/category_model.dart`, `models/listing_model.dart`
- Widgets: `widgets/bottom_navigation_bar.dart`

