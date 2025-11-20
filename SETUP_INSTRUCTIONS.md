# Setup Instructions for Student ID Verification

This document provides step-by-step instructions to configure camera and storage permissions for Android and iOS platforms.

## Prerequisites

1. Flutter SDK installed (version 3.9.2 or higher)
2. Android Studio / Xcode installed
3. Physical device or emulator for testing

## Step 1: Install Dependencies

Run the following command in your project root directory:

```bash
cd RentEase
flutter pub get
```

## Step 2: Android Configuration

### 2.1 Update AndroidManifest.xml

Open `RentEase/android/app/src/main/AndroidManifest.xml` and add the following permissions inside the `<manifest>` tag (before the `<application>` tag):

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Camera permission -->
    <uses-permission android:name="android.permission.CAMERA" />
    
    <!-- Storage permissions for Android 12 and below -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="32" 
                     android:requestLegacyExternalStorage="true" />
    
    <!-- Photos permission for Android 13+ -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    
    <!-- Camera feature (optional, but recommended) -->
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />

    <application
        android:label="rent_ease"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- ... rest of your application config ... -->
    </application>
</manifest>
```

### 2.2 Update build.gradle (if needed)

Ensure your `minSdkVersion` is at least 21. Check `RentEase/android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // or higher
        targetSdkVersion 33  // or higher
        // ... other config
    }
}
```

### 2.3 Test on Android

1. Connect an Android device or start an emulator
2. Run the app: `flutter run`
3. Navigate to Student Sign Up → Next → Try capturing an ID photo
4. Grant permissions when prompted

## Step 3: iOS Configuration

### 3.1 Update Info.plist

Open `RentEase/ios/Runner/Info.plist` and add the following keys inside the `<dict>` tag:

```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to capture photos of your student ID for verification.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select ID photos for verification.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save ID photos to your photo library.</string>
```

**Important Notes:**
- The description strings will be shown to users when requesting permissions
- Make sure these descriptions are clear and explain why you need the permissions
- These keys are **required** - the app will crash if they're missing

### 3.2 Update Podfile (if needed)

The `image_picker` and `permission_handler` packages should automatically handle pod dependencies. However, if you encounter issues, you may need to update your `RentEase/ios/Podfile`:

```ruby
platform :ios, '12.0'  # Ensure minimum iOS version is 12.0 or higher
```

Then run:
```bash
cd RentEase/ios
pod install
cd ..
```

### 3.3 Test on iOS

1. Connect an iOS device or start a simulator
2. Run the app: `flutter run`
3. Navigate to Student Sign Up → Next → Try capturing an ID photo
4. Grant permissions when prompted

## Step 4: Testing Permissions

### Test Scenarios:

1. **First-time permission request:**
   - Open the Student ID Verification page
   - Tap the camera icon
   - Verify that permission dialog appears
   - Grant permissions and verify camera opens

2. **Permission denied:**
   - Deny permissions when prompted
   - Verify that error message is shown
   - Verify that app doesn't crash

3. **Permission permanently denied:**
   - Go to device settings → Apps → RentEase → Permissions
   - Deny camera/storage permissions
   - Try to capture image again
   - Verify that dialog appears to open app settings

4. **Image capture:**
   - Capture front ID photo
   - Verify preview appears
   - Confirm or retake image
   - Repeat for back ID photo
   - Verify both images are stored in state

5. **Gallery selection:**
   - Choose "Gallery" option when capturing
   - Select an image from gallery
   - Verify preview appears
   - Confirm or retake

## Troubleshooting

### Android Issues:

1. **Permission not requested:**
   - Check AndroidManifest.xml has all required permissions
   - Ensure targetSdkVersion is 33 or higher
   - Try uninstalling and reinstalling the app

2. **Camera doesn't open:**
   - Check if device has a camera
   - Verify camera permission is granted in device settings
   - Check logcat for error messages: `flutter logs`

3. **Storage permission issues on Android 13+:**
   - Ensure `READ_MEDIA_IMAGES` permission is in manifest
   - For Android 12 and below, ensure `READ_EXTERNAL_STORAGE` is present

### iOS Issues:

1. **App crashes on permission request:**
   - Verify Info.plist has all required usage descriptions
   - Check that descriptions are not empty
   - Clean and rebuild: `flutter clean && flutter pub get`

2. **Permission dialog doesn't appear:**
   - Check Info.plist keys are spelled correctly
   - Verify pod dependencies are installed: `cd ios && pod install`
   - Try resetting simulator permissions

3. **Camera doesn't open:**
   - iOS Simulator doesn't have a real camera - use a physical device
   - Check device settings → Privacy → Camera → RentEase is enabled

## Additional Notes

- **Image Quality:** Images are compressed to 85% quality and limited to 1920x1920 pixels to reduce file size
- **Storage:** Images are stored temporarily in app state. You may want to implement permanent storage (e.g., Firebase Storage, local database) for production
- **Error Handling:** All permission and camera errors are caught and displayed to the user via SnackBar messages
- **Platform Differences:** Android 13+ uses different storage permissions than older versions - the code handles this automatically

## Next Steps

After setting up permissions:

1. Test the complete flow: Sign Up → Student Sign Up → Next → Capture Front ID → Capture Back ID → Upload
2. Implement backend integration to upload images to your server
3. Add image validation (e.g., check if ID is readable, verify format)
4. Add progress indicators for upload process
5. Implement image compression/optimization before upload

## Support

If you encounter issues:
1. Check Flutter logs: `flutter logs`
2. Check device logs (Android: logcat, iOS: Console app)
3. Verify all dependencies are up to date: `flutter pub outdated`
4. Try clean build: `flutter clean && flutter pub get && flutter run`

