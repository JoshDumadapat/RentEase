# Code Organization Guide

This document describes the new code organization structure for the RentEase project.

## Backend Services (lib/backend/)

All backend/Firestore operations are now organized in the `lib/backend/` folder with services prefixed with `B` for easy identification:

### Backend Services

- **BUserService.dart** - User data operations (create, update, get, delete users)
- **BListingService.dart** - Property listing operations (create, update, get, delete, search listings)
- **BCommentService.dart** - Comment operations (create, update, get, delete comments)
- **BLookingForPostService.dart** - "Looking For" post operations (create, update, get, delete posts)
- **BNotificationService.dart** - Notification operations (create, update, get, delete notifications)

### Key Principles

1. **All backend services are callable only** - They contain pure business logic and Firestore operations
2. **No UI dependencies** - Backend services don't import Flutter UI packages
3. **Consistent naming** - All backend services start with `B` prefix
4. **Collection names** - All Firestore collection names are defined as constants in each service

## Dialogs (lib/dialogs/)

All reusable dialog/modal components are organized in the `lib/dialogs/` folder:

### Dialog Components

- **confirmation_dialog.dart** - Reusable confirmation dialogs:
  - `ConfirmationDialog` - Generic confirmation dialog widget
  - `showDiscardChangesDialog()` - Discard changes confirmation
  - `showLogoutDialog()` - Logout confirmation
  - `showDeleteDialog()` - Delete confirmation

- **image_source_dialog.dart** - Image source selection (Camera/Gallery)

- **image_verification_dialog.dart** - Image verification before upload

### Usage

```dart
// Import dialogs
import 'package:rentease_app/dialogs/confirmation_dialog.dart';

// Use in code
final confirmed = await showLogoutDialog(context);
if (confirmed) {
  // User confirmed logout
}
```

## Services (lib/services/)

Service layer that wraps backend services and provides state management:

- **auth_service.dart** - Authentication operations (sign in, sign up, sign out)
- **user_service.dart** - Wrapper around BUserService (for backward compatibility)
- **notification_service.dart** - Notification state management using BNotificationService

## Models (lib/models/)

Data models for Firestore collections:

- **user_model.dart** - User data model
- **listing_model.dart** - Property listing model
- **comment_model.dart** - Comment model
- **looking_for_post_model.dart** - Looking for post model
- **notification_model.dart** - Notification model
- **category_model.dart** - Category model
- **filter_model.dart** - Filter model

## Utils (lib/utils/)

Utility functions:

- **confirmation_dialog_utils.dart** - Exports dialogs for backward compatibility
- **time_ago.dart** - Time formatting utilities

## Migration Guide

### Using Backend Services

**Before:**
```dart
// Direct Firestore calls in UI
final doc = await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .get();
```

**After:**
```dart
// Use backend service
import 'package:rentease_app/backend/BUserService.dart';

final userService = BUserService();
final userData = await userService.getUserData(uid);
```

### Using Dialogs

**Before:**
```dart
// Inline dialog code
showDialog(
  context: context,
  builder: (context) => AlertDialog(...),
);
```

**After:**
```dart
// Use organized dialogs
import 'package:rentease_app/dialogs/confirmation_dialog.dart';

final confirmed = await showLogoutDialog(context);
```

## Best Practices

1. **Always use backend services** for Firestore operations - never call Firestore directly from UI
2. **Use organized dialogs** instead of creating inline dialogs
3. **Keep UI logic separate** from backend logic
4. **Backend services are stateless** - they only contain callable methods
5. **State management** should be in service layer (like NotificationService)

## File Naming Conventions

- Backend services: `B[Entity]Service.dart` (e.g., `BUserService.dart`)
- Dialogs: `[purpose]_dialog.dart` (e.g., `confirmation_dialog.dart`)
- Models: `[entity]_model.dart` (e.g., `user_model.dart`)
- Services: `[entity]_service.dart` (e.g., `auth_service.dart`)



