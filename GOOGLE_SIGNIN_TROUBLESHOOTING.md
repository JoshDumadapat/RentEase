# 🔧 Google Sign-In Troubleshooting Guide

## ✅ Current Configuration Status

Based on your Firebase Console:
- ✅ **Email/Password**: Enabled
- ✅ **Google Sign-In**: Enabled  
- ✅ **SHA-1 Fingerprint**: Present (`e6:8b:cb:3a:4d:64:e5:7d:80:48:05:47:fb:12:18:9a:30:67:cc:a9`)

## 🔧 Code Fixes Applied

1. **Removed `serverClientId` for Android**: Android apps should use the default Android client ID from `google-services.json`, not the Web client ID
2. **Enhanced Debug Logging**: Added detailed step-by-step logging to track exactly where the error occurs
3. **Better Error Messages**: More specific error messages to help diagnose the issue

## 📋 Step-by-Step Fix

### Step 1: Clean and Rebuild

**CRITICAL**: After code changes, you MUST clean and rebuild:

```bash
flutter clean
flutter pub get
flutter run
```

### Step 2: Re-download google-services.json

Even though your SHA-1 is correct, re-download the file to ensure it's up to date:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **renteasedb**
3. Click ⚙️ **Project settings**
4. Scroll to **Your apps** → **Android app** (`com.example.rentease_app`)
5. Click **Download google-services.json**
6. Replace `android/app/google-services.json` with the new file
7. **Clean and rebuild** (Step 1)

### Step 3: Check Google Cloud Console OAuth Configuration

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **renteasedb**
3. Go to **APIs & Services** → **Credentials**
4. Look for **OAuth 2.0 Client IDs**:
   - Should have an **Android** client ID
   - Should have a **Web** client ID
5. Click on the **Android** client ID:
   - Verify **Package name**: `com.example.rentease_app`
   - Verify **SHA-1**: `e6:8b:cb:3a:4d:64:e5:7d:80:48:05:47:fb:12:18:9a:30:67:cc:a9`
6. If SHA-1 is missing, add it and **Save**

### Step 4: Check OAuth Consent Screen

1. In Google Cloud Console → **APIs & Services** → **OAuth consent screen**
2. Verify:
   - **User Type**: Internal or External (depending on your setup)
   - **App name**: Should be set
   - **Support email**: Should be set
   - **Scopes**: Should include `email` and `profile`
3. If not configured, configure it and **Save**

### Step 5: Enable Google Sign-In API

1. In Google Cloud Console → **APIs & Services** → **Library**
2. Search for **Google Sign-In API**
3. Make sure it's **ENABLED**
4. If not, click **Enable**

### Step 6: Check Debug Console

When you try Google Sign-In, check the debug console for these messages:

**Expected Success Flow:**
```
=== GOOGLE SIGN-IN START ===
Server Client ID: (should be empty/null for Android)
Step 1: Triggering Google Sign-In UI...
Step 1 Result: User selected account
Step 2: Getting Google authentication tokens...
User email: [email]
User ID: [id]
Step 2 Result: Authentication tokens obtained
Has access token: true
Has ID token: true
Step 3: Creating Firebase credential...
Step 3 Result: Credential created
Step 4: Signing in to Firebase with Google credential...
Step 4 Result: Firebase sign-in successful
Firebase UID: [uid]
=== GOOGLE SIGN-IN SUCCESS ===
```

**If Error Occurs:**
Look for `❌ ERROR` messages and note:
- Which step failed (Step 1, 2, 3, or 4)
- The error code and message
- The error type

## 🚨 Common Error Codes

| Error Code | Meaning | Solution |
|------------|---------|----------|
| `10:` | Developer error / Configuration issue | Check SHA-1, OAuth client, google-services.json |
| `12500` | API_NOT_CONNECTED | Enable Google Sign-In API |
| `12501` | SIGN_IN_CANCELLED | User canceled (not an error) |
| `12502` | SIGN_IN_CURRENTLY_IN_PROGRESS | Wait for current sign-in to complete |
| `12503` | SIGN_IN_FAILED | Check configuration |
| `invalid-credential` | OAuth client mismatch | Re-download google-services.json |
| `operation-not-allowed` | Google Sign-In not enabled | Enable in Firebase Console |

## 🔍 Debugging Checklist

- [ ] Cleaned and rebuilt app (`flutter clean && flutter pub get && flutter run`)
- [ ] Re-downloaded `google-services.json` from Firebase Console
- [ ] Verified SHA-1 in Firebase Console → Project settings
- [ ] Verified SHA-1 in Google Cloud Console → Credentials → Android OAuth client
- [ ] OAuth consent screen is configured
- [ ] Google Sign-In API is enabled in Google Cloud Console
- [ ] Google Sign-In is enabled in Firebase Console → Authentication
- [ ] Checked debug console for specific error messages
- [ ] Waited 5-10 minutes after making changes

## 💡 Important Notes

1. **Android vs Web Client ID**:
   - Android apps use the Android OAuth client ID automatically from `google-services.json`
   - `serverClientId` is only for web/server-side authentication
   - The code now removes `serverClientId` for Android

2. **SHA-1 Propagation**:
   - Changes can take 5-10 minutes to propagate
   - Always wait and rebuild after adding SHA-1

3. **google-services.json**:
   - Must be in `android/app/google-services.json`
   - Must match your package name: `com.example.rentease_app`
   - Should contain your SHA-1 fingerprint

## 🎯 Next Steps

1. **Try the fixes above** (especially clean rebuild and re-download google-services.json)
2. **Check the debug console** for the detailed error messages
3. **Share the error** from the debug console (the `❌ ERROR` messages) if it still doesn't work

The enhanced logging will show exactly where the Google Sign-In process is failing.

