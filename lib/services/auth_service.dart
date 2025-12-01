import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Temporary container for Google account selection data without creating a Firebase user yet.
///
/// This allows you to:
/// - Let the user pick a Google account
/// - Collect the ID / access tokens
/// - Postpone creating the Firebase Auth user until after registration is complete.
class GoogleSignInTempData {
  final String email;
  final String idToken;
  final String accessToken;
  final String? displayName;

  GoogleSignInTempData({
    required this.email,
    required this.idToken,
    required this.accessToken,
    this.displayName,
  });
}

/// Service class for handling authentication operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Configure GoogleSignIn
  // For Android: Don't use serverClientId - it will use the Android client ID automatically
  // serverClientId is only needed for web/server-side authentication
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Remove serverClientId for Android - let it use the default Android client ID from google-services.json
    // serverClientId: '948370771334-k9o21p423l6mq4aq0o5cuf2v3jnmeaqe.apps.googleusercontent.com', // Only for web
  );

  /// Get the current user
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Start Google Sign-In but **do NOT** create a Firebase Auth user yet.
  ///
  /// This:
  /// - Shows the Google account picker
  /// - Returns Google tokens + basic profile info
  /// - Leaves Firebase Auth untouched (no user created)
  Future<GoogleSignInTempData?> signInWithGoogleAccountOnly() async {
    try {
      debugPrint('=== GOOGLE ACCOUNT SELECTION (NO FIREBASE USER) START ===');

      // Always clear any previously selected Google account so the account picker shows.
      // This prevents Google from silently reusing the last account.
      try {
        debugPrint('Step 0 (account-only): Signing out any existing Google session...');
        await _googleSignIn.signOut();
        debugPrint('Step 0 Result: Google session cleared');
      } catch (e) {
        debugPrint('Step 0 Warning: Failed to sign out previous Google session: $e');
      }

      // Trigger Google Sign-In UI
      debugPrint('Step 1 (account-only): Triggering Google Sign-In UI...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      debugPrint('Step 1 Result: ${googleUser != null ? "User selected account" : "User canceled"}');

      if (googleUser == null) {
        // User canceled the sign-in
        debugPrint('User canceled Google account selection');
        return null;
      }

      debugPrint('Step 2 (account-only): Getting Google authentication tokens...');
      debugPrint('User email: ${googleUser.email}');
      debugPrint('User ID: ${googleUser.id}');

      GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
        debugPrint('Step 2 Result: Authentication tokens obtained (account-only)');
        debugPrint('Has access token: ${googleAuth.accessToken != null}');
        debugPrint('Has ID token: ${googleAuth.idToken != null}');
      } catch (e) {
        debugPrint('❌ ERROR in Step 2 (account-only): Failed to get Google authentication');
        debugPrint('Error: $e');
        await _googleSignIn.signOut();
        throw Exception('Failed to get Google authentication: $e');
      }

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ ERROR (account-only): Missing authentication tokens');
        await _googleSignIn.signOut();
        throw Exception('Google Sign-In failed: Missing authentication tokens');
      }

      debugPrint('=== GOOGLE ACCOUNT SELECTION (NO FIREBASE USER) SUCCESS ===');

      return GoogleSignInTempData(
        email: googleUser.email,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
        displayName: googleUser.displayName,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ === GOOGLE ACCOUNT SELECTION ERROR (NO FIREBASE USER) ===');
      debugPrint('❌ Error details: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: $stackTrace');

      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      throw Exception('Google account selection failed: $e');
    }
  }

  /// Check if email/password authentication is enabled (by attempting a test)
  /// This will help diagnose if Email/Password is not enabled in Firebase
  Future<bool> checkEmailPasswordEnabled() async {
    try {
      // Try to create a test user to check if Email/Password is enabled
      // We'll immediately delete it if creation succeeds
      // This will fail with 'operation-not-allowed' if Email/Password is not enabled
      final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final testPassword = 'Test123!@#';
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        // Delete the test user immediately
        await credential.user?.delete();
        return true; // If we get here, Email/Password is enabled
      } on FirebaseAuthException catch (e) {
        if (e.code == 'operation-not-allowed') {
          return false;
        }
        // Other errors might indicate it's enabled but something else went wrong
        return true;
      }
    } catch (e) {
      debugPrint('Error checking Email/Password status: $e');
      return false;
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('=== GOOGLE SIGN-IN START ===');
      debugPrint('Server Client ID: 948370771334-k9o21p423l6mq4aq0o5cuf2v3jnmeaqe.apps.googleusercontent.com');

      // Always clear any previously selected Google account so the account picker shows.
      try {
        debugPrint('Step 0: Signing out any existing Google session...');
        await _googleSignIn.signOut();
        debugPrint('Step 0 Result: Google session cleared');
      } catch (e) {
        debugPrint('Step 0 Warning: Failed to sign out previous Google session: $e');
      }

      // Trigger the Google Sign In flow (will now show account chooser)
      debugPrint('Step 1: Triggering Google Sign-In UI...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      debugPrint('Step 1 Result: ${googleUser != null ? "User selected account" : "User canceled"}');

      if (googleUser == null) {
        // User canceled the sign-in
        debugPrint('User canceled Google Sign-In');
        return null;
      }

      debugPrint('Step 2: Getting Google authentication tokens...');
      debugPrint('User email: ${googleUser.email}');
      debugPrint('User ID: ${googleUser.id}');
      
      // Obtain the auth details from the request
      GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
        debugPrint('Step 2 Result: Authentication tokens obtained');
        debugPrint('Has access token: ${googleAuth.accessToken != null}');
        debugPrint('Has ID token: ${googleAuth.idToken != null}');
      } catch (e) {
        debugPrint('❌ ERROR in Step 2: Failed to get Google authentication');
        debugPrint('Error: $e');
        // If authentication access fails, sign out and throw
        await _googleSignIn.signOut();
        throw Exception('Failed to get Google authentication: $e');
      }

      // Validate that we have the required tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ ERROR: Missing authentication tokens');
        debugPrint('Access token: ${googleAuth.accessToken != null}');
        debugPrint('ID token: ${googleAuth.idToken != null}');
        await _googleSignIn.signOut();
        throw Exception('Google Sign-In failed: Missing authentication tokens');
      }

      debugPrint('Step 3: Creating Firebase credential...');
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      debugPrint('Step 3 Result: Credential created');

      debugPrint('Step 4: Signing in to Firebase with Google credential...');
      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('Step 4 Result: Firebase sign-in successful');
      debugPrint('Firebase UID: ${userCredential.user?.uid}');
      debugPrint('=== GOOGLE SIGN-IN SUCCESS ===');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth exceptions specifically
      debugPrint('❌ FirebaseAuthException: ${e.code}');
      debugPrint('❌ Error message: ${e.message}');
      debugPrint('❌ Full error: $e');
      await _googleSignIn.signOut();
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception('An account already exists with a different sign-in method.');
      } else if (e.code == 'invalid-credential') {
        throw Exception('The credential is invalid or has expired. This usually means:\n1. OAuth client ID mismatch\n2. SHA-1 fingerprint not properly configured\n3. Google Sign-In not properly enabled in Firebase');
      } else if (e.code == 'operation-not-allowed') {
        throw Exception('Google Sign-In is not enabled. Please enable it in Firebase Console → Authentication → Sign-in method.');
      } else if (e.code == 'user-disabled') {
        throw Exception('This user account has been disabled.');
      }
      throw Exception('Google Sign-In failed (${e.code}): ${e.message}');
    } catch (e, stackTrace) {
      // Log the actual error for debugging
      debugPrint('❌ === GOOGLE SIGN-IN ERROR ===');
      debugPrint('❌ Error details: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Ensure we sign out on any error to prevent state issues
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore sign out errors
      }
      
      // Check for specific error patterns that indicate configuration issues
      final errorString = e.toString().toLowerCase();
      final errorMessage = e.toString();
      
      debugPrint('❌ Error string (lowercase): $errorString');
      
      // Only show configuration error for actual Google Sign-In configuration issues
      if (errorString.contains('pigeonuserdetails') || 
          errorString.contains('list<object>') ||
          (errorString.contains('developer_error') && errorString.contains('10:')) ||
          (errorString.contains('sign_in_failed') && errorString.contains('configuration')) ||
          errorString.contains('12500') || // API_NOT_CONNECTED
          errorString.contains('12501') || // SIGN_IN_CANCELLED
          errorString.contains('12502') || // SIGN_IN_CURRENTLY_IN_PROGRESS
          errorString.contains('12503') || // SIGN_IN_FAILED
          errorString.contains('10:') || // Common Google Sign-In error prefix
          errorString.contains('com.google.android.gms.common.api.resolvableexception')) {
        throw Exception(
          'Google Sign-In configuration error. Please check:\n\n'
          '1. ✅ SHA-1 fingerprint is in Firebase Console (e6:8b:cb:3a:4d:64:e5:7d:80:48:05:47:fb:12:18:9a:30:67:cc:a9)\n'
          '2. ✅ Google Sign-In is enabled in Firebase Console\n'
          '3. ⚠️ Download NEW google-services.json from Firebase Console\n'
          '4. ⚠️ Clean and rebuild: flutter clean && flutter pub get && flutter run\n'
          '5. ⚠️ Wait 5-10 minutes after adding SHA-1 for changes to propagate\n'
          '6. ⚠️ Check Google Cloud Console → APIs & Services → Credentials\n\n'
          'Error: $errorMessage'
        );
      }
      
      // For other errors, provide more specific error messages
      if (errorString.contains('firestore') || errorString.contains('permission')) {
        throw Exception('Database error: Please check Firestore security rules. $errorMessage');
      }
      
      // Re-throw the original error with context
      throw Exception('Google Sign-In failed: $errorMessage\n\nPlease check the debug console for detailed error information.');
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email,
      String password,
    ) async {
      try {
        final trimmedEmail = email.trim().toLowerCase();
        final trimmedPassword = password.trim();
        
        debugPrint('=== DEBUG SIGN IN ATTEMPT ===');
        debugPrint('Email: "$trimmedEmail"');
        debugPrint('Password entered: "${maskPassword(trimmedPassword)}" (length: ${trimmedPassword.length})');
        debugPrint('Firebase Auth instance hash: ${_auth.hashCode}');
        debugPrint('Firebase Auth app name: ${_auth.app.name}');

        try {
          debugPrint('Checking Firebase Auth state before sign-in...');
          final currentUser = _auth.currentUser;
          debugPrint('Current user before sign-in: ${currentUser?.uid}');
          debugPrint('Current user email: ${currentUser?.email}');
        } catch (e) {
          debugPrint('Error checking current user: $e');
        }
        
        debugPrint('Calling Firebase Auth signInWithEmailAndPassword...');
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: trimmedEmail,
          password: trimmedPassword,
        );
        
        debugPrint('✅ SIGN IN SUCCESSFUL');
        debugPrint('✅ User UID: ${userCredential.user?.uid}');
        debugPrint('✅ User email: ${userCredential.user?.email}');
        debugPrint('✅ Email verified: ${userCredential.user?.emailVerified}');
        debugPrint('✅ Provider data: ${userCredential.user?.providerData}');
        
        return userCredential;
      } on FirebaseAuthException catch (e) {
        debugPrint('❌ FIREBASE AUTH EXCEPTION');
        debugPrint('❌ Code: ${e.code}');
        debugPrint('❌ Message: ${e.message}');
        debugPrint('❌ Details: $e');
        
        try {
          final trimmedEmail = email.trim().toLowerCase();
          debugPrint('=== POST-ERROR DIAGNOSTICS ===');
          debugPrint('Attempting to check if account exists for: $trimmedEmail');
          // Try to create a user with the email to check if it exists
          // We'll catch the email-already-in-use error
          try {
            final testPassword = 'Test123!@#${DateTime.now().millisecondsSinceEpoch}';
            await _auth.createUserWithEmailAndPassword(
              email: trimmedEmail,
              password: testPassword,
            );
            // If we get here, the account was created (shouldn't happen in normal flow)
            debugPrint('🔍 Account was created (unexpected)');
          } on FirebaseAuthException catch (createError) {
            if (createError.code == 'email-already-in-use') {
              debugPrint('🔍 ACCOUNT EXISTS - Email is already in use');
              debugPrint('🔍 The error is likely password-related');
            } else if (createError.code == 'operation-not-allowed') {
              debugPrint('🔍 Email/Password authentication is not enabled');
            } else {
              debugPrint('🔍 Account may not exist or other error: ${createError.code}');
            }
          }
        } catch (fetchError) {
          debugPrint('Could not check account status: $fetchError');
        }
        
        switch (e.code) {
          case 'user-not-found':
            throw Exception('No account found with this email. Please check the email or sign up.');
          case 'wrong-password':
          case 'invalid-credential':
            throw Exception('Incorrect password. Please try again or use "Forgot Password".');
          case 'invalid-email':
            throw Exception('Invalid email format.');
          case 'user-disabled':
            throw Exception('This account has been disabled.');
          case 'too-many-requests':
            throw Exception('Too many attempts. Try again later.');
          case 'operation-not-allowed':
            throw Exception('Email/password sign-in is not enabled. Contact support.');
          default:
            throw Exception('Sign-in failed: ${e.message}');
        }
      } catch (e) {
        debugPrint('❌ GENERAL SIGN-IN ERROR: $e');
        debugPrint('❌ Error type: ${e.runtimeType}');
        debugPrint('❌ Stack trace: ${e.toString()}');
        
        throw Exception('Sign-in error: $e');
      }
    }

    String maskPassword(String password) {
      if (password.isEmpty) return '[empty]';
      return password.replaceAll(RegExp(r'.'), '*');
    }

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Trim email to avoid whitespace issues
      final trimmedEmail = email.trim().toLowerCase();
      // Trim password to remove any whitespace
      final trimmedPassword = password.trim();
      
      debugPrint('AuthService: Creating account with email: "$trimmedEmail"');
      debugPrint('AuthService: Password length: ${trimmedPassword.length}');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );
      
      debugPrint('AuthService: Firebase Auth account created successfully');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Sign up error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/Password authentication is not enabled. Please enable it in Firebase Console.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      default:
        return 'An error occurred: ${e.message ?? e.code}';
    }
  }
}

