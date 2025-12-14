# How to Deploy Firestore Rules

## ⚠️ IMPORTANT: Rules Must Be Deployed to Firebase

The `firestore.rules` file in your project is just a local file. **You must deploy it to Firebase** for the rules to take effect.

## Method 1: Using Firebase Console (Easiest)

1. **Open Firebase Console**
   - Go to https://console.firebase.google.com/
   - Select your project: `renteasedb`

2. **Navigate to Firestore Rules**
   - Click on "Firestore Database" in the left sidebar
   - Click on the "Rules" tab at the top

3. **Copy and Paste Rules**
   - Open `firestore.rules` file from your project
   - Copy ALL the content (Ctrl+A, Ctrl+C)
   - Paste it into the Firebase Console Rules editor (Ctrl+V)

4. **Publish Rules**
   - Click the "Publish" button
   - Wait for confirmation that rules are deployed

## Method 2: Using Firebase CLI

If you have Firebase CLI installed:

```bash
# Install Firebase CLI (if not installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy rules
firebase deploy --only firestore:rules
```

## Verify Rules Are Deployed

After deploying, check the Firebase Console:
- Rules tab should show your updated rules
- The timestamp should update to show when rules were last published

## Current Rules Status

Your rules allow:
- ✅ Authenticated users can create listings with their own userId
- ✅ Authenticated users can read all listings
- ✅ Only listing owners can update/delete their listings

## Troubleshooting

If you still get permission errors after deploying:
1. Wait 1-2 minutes for rules to propagate
2. Check that `userId` in your data matches `request.auth.uid`
3. Verify user is authenticated (check logs)
4. Try signing out and back in
