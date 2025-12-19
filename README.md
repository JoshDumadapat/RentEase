# RentEase

A Flutter application for property rental management and user communication. RentEase helps users list properties, search for rentals, verify identities, manage subscriptions, and communicate in real-time with other users.

# Getting Started

## Prerequisites

- Flutter SDK version 3.0 or higher
- Dart SDK
- Android Studio or Xcode for mobile development
- Firebase account with project setup
- Python 3.9 or higher for backend services
- OpenAI API key for AI chat features

## Installation

1. Clone the repository
2. Navigate to the project directory
3. Run flutter pub get to install dependencies
4. Configure Firebase in lib/services/firebase_options.dart
5. Start the backend server from the backend directory
6. Run flutter run to launch the application

## Backend Setup

1. Install Python dependencies with pip install -r requirements.txt
2. Set up environment variables including OPENAI_API_KEY
3. Run the backend server using python app.py

The backend handles ID validation, face detection, OCR processing, and AI chat functionality.

# Application Flow

## User Journey for New Users

1. Launch app and view landing page
2. Choose sign up option
3. Enter email and create password
4. Verify email address
5. Complete student ID verification
6. Take selfie for face verification
7. Access main app after verification
8. Set up profile with photo and details
9. Browse properties or create listings

## User Journey for Existing Users

1. Launch app
2. Sign in with email and password
3. View home page with property listings
4. Navigate using bottom navigation bar
5. Access features through dedicated screens

# Main Features and Navigation

## Home Screen

Browse available property listings with images, prices, and locations. Tap any property to view full details including amenities, contact landlord, or add to favorites.

## Search

Use search screen to find properties by location, price range, and category. Apply filters to narrow results. View property details and contact landlords through chat.

## Add Property

Create new property listings by providing address, price, description, amenities, and photos. Use map picker to set exact location. Submit for publishing to make visible to other users.

## Profile

View and edit user information including name, photo, bio, and contact details. Access favorites list, my properties, and looking for posts. View user ratings and reviews.

## Settings

Manage account settings including email, password, phone number, and privacy. Access verification status, backup settings, terms of service, and privacy policy. Option to deactivate or delete account.

## Messages

Send and receive messages with other users. View list of active conversations. Chat updates in real-time for both users. Delete conversations when finished.

## AI Chat

Access AI assistant for questions about RentEase, property rental advice, or general help. Uses OpenAI integration for intelligent responses.

## Notifications

Receive and view notifications for messages, property inquiries, and system updates. Manage notification preferences in settings.

## Looking For Posts

Create posts about what you are searching for in a property. Browse posts from other users also looking for properties. Contact users directly through chat.

# Verification Process

## ID Verification

1. Go to account settings
2. Start ID verification process
3. Upload photo of government issued ID
4. System extracts text from ID using OCR
5. Verify extracted information is correct
6. Take selfie for face matching
7. System compares face with ID photo
8. Receive verification confirmation

## Student ID Verification

Available for students to get special status. Upload student ID photo and provide verification details. System validates credentials.

## Face Verification

Take clear selfie with good lighting. Face must be centered in oval guide on screen. System detects face and compares with uploaded ID photo. Auto-captures when face detection is optimal.

# Subscription Features

## Verified Badge

Purchase subscription to get verified badge on profile. Shows other users you have passed verification. Increases trust and visibility in listings.

## Subscription Management

View current subscription status. Manage subscription through manage subscription screen. View billing history and payment methods.

# Property Listing Features

## Adding Images

Upload multiple photos of property. Tap to add images from camera or gallery. Organize images in desired order. Delete unwanted photos before publishing.

## Location Setting

Use map picker to set exact property location. Search by landmark or address. Map shows all nearby properties. Location is visible to potential renters.

## Pricing and Details

Set rental price and lease terms. Add description of property features. List amenities like WiFi, parking, utilities. Specify house rules and restrictions.

## Publishing

Review all information before publishing. Submit listing to make visible to other users. Receive confirmation and listing ID. Can edit or delete listing after publishing.

# Chat and Communication

## Starting a Conversation

Find user in search results or through property listing. Tap message button to start conversation. First message creates new chat thread. Other user receives notification.

## Sending Messages

Type message in text field. Tap send button or use keyboard shortcut. Message appears instantly for both users. Timestamps show when each message was sent.

## Managing Conversations

View all active conversations in chat list. Last message and timestamp show recent activity. Swipe to delete conversation. Search for specific conversations.

## Online Status

See if users are currently active. Real-time indicators show message delivery and read status. Notifications alert you to new messages.

# Searching and Filtering

## Basic Search

Enter location, property type, or price range. Tap search to view matching properties. Results update instantly as you type.

## Advanced Filtering

Open filter sheet to access detailed options. Filter by price, location, property type, amenities. Save filter preferences for quick access later.

## Sorting Options

Sort results by newest, price low to high, or distance. Change sorting anytime to view results differently.

## Favorites

Save properties you like by tapping heart icon. View all favorites in profile section. Remove properties from favorites anytime.

# Account Management

## Profile Editing

Edit name, photo, bio, and contact information. Add or remove profile photos. Update preferences and notification settings.

## Password and Security

Change password from settings. Update email address. Add phone number for account recovery. Enable two-factor authentication if available.

## Privacy Settings

Control who can see profile information. Set visibility for listings and looking for posts. Manage who can contact you.

## Account Deletion

Permanently delete account and all associated data. This action cannot be undone. All listings and messages will be removed.

# Technical Details

## Firebase Integration

User authentication and profile management through Firebase Auth. Property listings and data stored in Firestore. Real-time messaging through Firestore. Cloud storage for images and documents.

## File Structure

lib/main.dart - Application entry point and theme setup
lib/screens/ - Main application screens and pages
lib/widgets/ - Reusable UI components
lib/services/ - Firebase and API integration
lib/models/ - Data models for application
lib/utils/ - Helper functions and utilities
lib/backend/ - Backend service integration

## Key Services

auth_service.dart - User authentication
user_service.dart - User profile management
user_chat_service.dart - Chat functionality
ai_chat_service.dart - AI assistant integration
landmark_suggestion_service.dart - Location suggestions
cloudinary_service.dart - Image management

## Important Notes

Chat threads use format userId1_userId2 with alphabetical sorting. Front camera photos are flipped to match preview orientation. Location services require user permissions. Firestore rules enforce privacy. Images are optimized through Cloudinary.

# Troubleshooting

## Camera Not Working

Grant camera permission in app settings. Ensure good lighting for face detection. Close and reopen app if camera freezes.

## Messages Not Sending

Check internet connection. Verify Firebase is initialized. Refresh chat screen to reload messages.

## Images Not Uploading

Verify internet connectivity. Check image file size and format. Clear app cache and retry upload.

## Verification Failing

Ensure good lighting and clear photo. Face must be clearly visible in selfie. Check ID photo quality and readability.

# Support

For issues or questions about RentEase, review relevant service files for implementation details. Check Firebase console for data and authentication issues. Verify backend service is running for ID validation features.
