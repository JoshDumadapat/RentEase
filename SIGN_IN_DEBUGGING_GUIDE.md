# 🔍 Sign-In Debugging Guide

## ⚠️ Important: Firebase Auth vs Firestore

**CRITICAL UNDERSTANDING:**
- **Firestore** stores user data (name, email, password as plain text for reference)
- **Firebase Auth** stores authentication credentials (email + hashed password)
- **Login uses Firebase Auth, NOT Firestore!**

If you see the password "Pass123" in Firestore, that's just for reference. The actual authentication happens in Firebase Auth.

## 🔧 Code Fixes Applied

1. ✅ **Password Trimming**: Added `.trim()` to remove whitespace
2. ✅ **Email Normalization**: Both sign-up and sign-in convert email to lowercase
3. ✅ **Enhanced Debug Logging**: Detailed logs to track authentication flow
4. ✅ **Better Error Messages**: More specific error messages

## 📋 Step-by-Step Debugging

### Step 1: Check Debug Console

When you try to sign in, check your debug console for these messages:

**During Sign-In:**
```
=== SIGN IN ATTEMPT ===
Email: "your@email.com" (length: X)
Password: "*******" (length: 7)
Password should be: "Pass123" (length: 7)
AuthService: Signing in with email: "your@email.com"
AuthService: Password length: 7
```

**If Successful:**
```
AuthService: Firebase Auth sign-in successful
✅ Sign in successful. UID: [uid]
```

**If Failed:**
```
❌ Firebase Auth Error Code: [error-code]
❌ Firebase Auth Error Message: [error-message]
```

### Step 2: Verify Account Exists in Firebase Auth

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **renteasedb**
3. Click **Authentication** (left sidebar)
4. Click **Users** tab
5. **Look for your email address** in the list
6. If the email is NOT there:
   - The account was NOT created in Firebase Auth
   - Only the Firestore document exists
   - You need to create a NEW account

### Step 3: Verify Email/Password is Enabled

1. In Firebase Console → **Authentication**
2. Click **Sign-in method** tab
3. Find **Email/Password**
4. Click on it
5. **Verify it's ENABLED** (toggle should be ON/blue)
6. If it's disabled:
   - Toggle it ON
   - Click **Save**
   - Wait 1-2 minutes
   - Try again

### Step 4: Check Common Error Codes

Look for these error codes in your debug console:

| Error Code | Meaning | Solution |
|------------|---------|----------|
| `operation-not-allowed` | Email/Password not enabled | Enable in Firebase Console |
| `user-not-found` | Account doesn't exist in Firebase Auth | Create new account |
| `wrong-password` | Password is incorrect | Use exactly: `Pass123` |
| `invalid-credential` | Email or password wrong | Check both credentials |
| `invalid-email` | Email format is wrong | Check email format |

## 🧪 Test Procedure

### Test 1: Create a Fresh Account

1. **Use a NEW email** (one you haven't used before)
2. Complete the sign-up process
3. **Check debug console** for:
   ```
   === CREATING ACCOUNT ===
   Email: "new@email.com" (length: X)
   Password: "*******" (length: 7)
   AuthService: Firebase Auth account created successfully
   Account created successfully. UID: [uid]
   Account verified - user is authenticated in Firebase Auth
   ```
4. **Verify in Firebase Console**:
   - Go to Authentication → Users
   - Find the new email
   - Verify it exists

### Test 2: Sign In with Fresh Account

1. **Sign out** (if you're signed in)
2. **Go to Sign In page**
3. Enter:
   - Email: The NEW email you just created
   - Password: `Pass123` (exactly, no spaces)
4. **Check debug console** for the sign-in attempt logs
5. **Check for error codes** if it fails

## 🎯 Most Common Issues

### Issue 1: Account Only in Firestore, Not Firebase Auth

**Symptoms:**
- Account shows in Firestore
- Password "Pass123" visible in Firestore
- But account NOT in Firebase Auth → Users

**Solution:**
- The sign-up process failed to create Firebase Auth account
- Create a NEW account
- Check debug console during sign-up for errors

### Issue 2: Email/Password Not Enabled

**Symptoms:**
- Error: `operation-not-allowed`
- Or: "Email/Password authentication is not enabled"

**Solution:**
- Enable Email/Password in Firebase Console
- Wait 1-2 minutes
- Try again

### Issue 3: Password Mismatch

**Symptoms:**
- Error: `wrong-password` or `invalid-credential`
- Password looks correct

**Solution:**
- Use exactly: `Pass123`
- No spaces before or after
- Case-sensitive (capital P, lowercase ass, numbers 123)
- Check debug console for password length (should be 7)

### Issue 4: Email Case Mismatch

**Symptoms:**
- Email looks correct but login fails

**Solution:**
- Code now converts email to lowercase automatically
- Try with any case, it will be normalized
- Check debug console to see the normalized email

## 📝 What to Check in Debug Console

When signing in, you should see:

```
=== SIGN IN ATTEMPT ===
Email: "your@email.com" (length: 14)
Password: "*******" (length: 7)
Password should be: "Pass123" (length: 7)
AuthService: Signing in with email: "your@email.com"
AuthService: Password length: 7
AuthService: Firebase Auth sign-in successful
✅ Sign in successful. UID: [some-uid]
```

If you see errors instead, note the error code and message.

## 🚨 If Still Not Working

1. **Share the debug console output** (the full error message)
2. **Verify in Firebase Console**:
   - Authentication → Users → Does your email exist?
   - Authentication → Sign-in method → Is Email/Password enabled?
3. **Try creating a completely new account** with a fresh email
4. **Check if the account creation actually succeeded** (look for UID in debug console)

## 💡 Key Points

1. **Firebase Auth is separate from Firestore**
2. **Password in Firestore is just for reference**
3. **Actual authentication uses Firebase Auth**
4. **Email/Password MUST be enabled in Firebase Console**
5. **Password must be exactly: `Pass123` (7 characters, case-sensitive)**

