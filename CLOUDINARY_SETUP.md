# Cloudinary Setup Guide

## Step 1: Get Your Cloudinary Credentials

1. Go to https://cloudinary.com/ and sign in to your account
2. From the Dashboard, copy these values:
   - **Cloud Name** (e.g., `dqymvfmbi`)
   - **API Key** (e.g., `123456789012345`)
   - **API Secret** (e.g., `abcdefghijklmnopqrstuvwxyz123456`)

## Step 2: Create Upload Preset (Recommended)

1. In Cloudinary Dashboard, go to **Settings** → **Upload**
2. Scroll down to **Upload presets**
3. Click **"Add Upload Preset"**
4. Configure:
   - **Preset name**: `rentease_properties` (or any name you prefer)
   - **Signing Mode**: Select **"Unsigned"** (for easier client-side uploads)
   - **Folder**: `properties` (optional, for organization)
   - **Format**: `Auto` (or specific formats like `jpg, png, webp`)
   - **Quality**: `Auto:good` (for automatic optimization)
5. Click **"Save"**

## Step 3: Update Cloudinary Service

Open `lib/services/cloudinary_service.dart` and replace the placeholder values:

```dart
static const String _cloudName = 'YOUR_CLOUD_NAME';  // Replace with your cloud name
static const String _apiKey = 'YOUR_API_KEY';        // Replace with your API key
static const String _apiSecret = 'YOUR_API_SECRET';  // Replace with your API secret
static const String _uploadPreset = 'YOUR_UPLOAD_PRESET'; // Replace with your preset name (e.g., 'rentease_properties')
```

**Example:**
```dart
static const String _cloudName = 'dqymvfmbi';
static const String _apiKey = '123456789012345';
static const String _apiSecret = 'abcdefghijklmnopqrstuvwxyz123456';
static const String _uploadPreset = 'rentease_properties';
```

## Step 4: Security Note

⚠️ **IMPORTANT**: The API Secret should never be exposed in client-side code for production apps.

For production, consider:
- Using a backend server to handle uploads
- Using environment variables
- Using Flutter's secure storage for credentials

For development/testing, the current setup is fine.

## Step 5: Test the Integration

After updating the credentials:
1. Run `flutter pub get` to install dependencies
2. Try uploading an image in the app
3. Check your Cloudinary Media Library to verify the upload

## Usage

The Cloudinary service is now ready to use. When users upload images:
- Images will be automatically uploaded to Cloudinary
- You'll receive secure URLs that can be stored in Firestore
- Images are optimized automatically by Cloudinary

## Next Steps

The service is integrated and ready. The `add_property_page.dart` will be updated to use Cloudinary for image uploads automatically.

