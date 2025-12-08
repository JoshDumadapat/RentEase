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
  final String? photoUrl;

  GoogleSignInTempData({
    required this.email,
    required this.idToken,
    required this.accessToken,
    this.displayName,
    this.photoUrl,
  });
}

/// Service class for handling authentication operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache GoogleSignIn instance for better performance
  GoogleSignIn? _cachedGoogleSignIn;
  
  // Configure GoogleSignIn - cached for performance
  // For Web: serverClientId is NOT supported - use meta tag in web/index.html instead
  // For Web: Using only 'email' scope to avoid People API requirement
  // For Android/iOS: Can use serverClientId (Android will prefer google-services.json)
  GoogleSignIn get _googleSignIn {
    if (_cachedGoogleSignIn == null) {
      if (kIsWeb) {
        // Web: Don't use serverClientId - it's not supported, meta tag handles it
        // Using only 'email' scope to avoid People API requirement
        _cachedGoogleSignIn = GoogleSignIn(
          scopes: ['email'],
        );
      } else {
        // Android/iOS: Can use serverClientId (Android will prefer google-services.json)
        _cachedGoogleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId: '948370771334-k9o21p423l6mq4aq0o5cuf2v3jnmeaqe.apps.googleusercontent.com',
        );
      }
    }
    return _cachedGoogleSignIn!;
  }

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
    GoogleSignInAccount? googleUser;
    GoogleSignInAuthentication? googleAuth;
    
    try {
      // Force account picker to always show by clearing cached instance and signing out/disconnecting
      try {
        // Clear cached instance to reset state
        _cachedGoogleSignIn = null;
        
        // Get fresh instance
        final googleSignIn = _googleSignIn;
        
        // Disconnect and sign out to force account selection
        await googleSignIn.disconnect();
        await googleSignIn.signOut();
      } catch (_) {
        // Ignore errors - just ensure we have a fresh instance
        _cachedGoogleSignIn = null;
      }
      
      // Get fresh GoogleSignIn instance and trigger account picker
      final googleSignIn = _googleSignIn;
      googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      // On web, the authentication getter triggers People API calls internally
      // The google_sign_in_web package requires People API to be enabled
      // We'll catch the error and provide clear instructions
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        final errorString = e.toString().toLowerCase();
        final isPeopleApiError = errorString.contains('people api') || 
            errorString.contains('people.googleapis.com') ||
            errorString.contains('service_disabled') ||
            (errorString.contains('permission_denied') && errorString.contains('403'));
        
        if (isPeopleApiError && kIsWeb) {
          // Workaround: Extract OAuth tokens from browser's OAuth response
          final tokens = _extractOAuthTokensFromBrowser();
          
          if (tokens != null && tokens['accessToken'] != null) {
            String? idToken = tokens['idToken'];
            String? accessToken = tokens['accessToken'];
            
            if (idToken == null && accessToken != null) {
              idToken = _extractIdTokenFromOAuthResponse();
            }
            
            if (accessToken != null) {
              googleAuth = _GoogleSignInAuthenticationFromTokens(
                accessToken: accessToken,
                idToken: idToken ?? '',
              );
            } else {
              await _googleSignIn.signOut();
              throw Exception(
                'Google Sign-In on web requires the People API to be enabled.\n\n'
                'To enable People API:\n'
                '1. Go to: https://console.cloud.google.com/apis/api/people.googleapis.com/overview?project=948370771334\n'
                '2. Click "Enable"\n'
                '3. Wait 2-3 minutes for changes to propagate\n'
                '4. Try signing in again'
              );
            }
          } else {
            await _googleSignIn.signOut();
            throw Exception(
              'Google Sign-In on web requires the People API to be enabled.\n\n'
              'To enable People API:\n'
              '1. Go to: https://console.cloud.google.com/apis/api/people.googleapis.com/overview?project=948370771334\n'
              '2. Click "Enable"\n'
              '3. Wait 2-3 minutes for changes to propagate\n'
              '4. Try signing in again'
            );
          }
        } else {
          await _googleSignIn.signOut();
          throw Exception('Failed to get Google authentication: $e');
        }
      }

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        await _googleSignIn.signOut();
        throw Exception('Google Sign-In failed: Missing authentication tokens');
      }

      // Get displayName and photoUrl, but handle People API errors gracefully
      String? displayName;
      String? photoUrl;
      if (!kIsWeb) {
        try {
          displayName = googleUser.displayName;
        } catch (_) {
          displayName = null;
        }
        try {
          photoUrl = googleUser.photoUrl;
        } catch (_) {
          photoUrl = null;
        }
      }

      return GoogleSignInTempData(
        email: googleUser.email,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
        displayName: displayName,
        photoUrl: photoUrl,
      );
    } catch (e) {
      // Check if it's a People API error - if so, we can still proceed with just email
      final errorString = e.toString().toLowerCase();
      if ((errorString.contains('people api') || 
          errorString.contains('people.googleapis.com') ||
          errorString.contains('service_disabled')) &&
          googleUser != null && 
          googleAuth != null &&
          googleAuth.accessToken != null &&
          googleAuth.idToken != null) {
        try {
          return GoogleSignInTempData(
            email: googleUser.email,
            idToken: googleAuth.idToken!,
            accessToken: googleAuth.accessToken!,
            displayName: null,
            photoUrl: null,
          );
        } catch (_) {}
      }

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
    } catch (_) {
      return false;
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Force account picker to always show by clearing cached instance and signing out/disconnecting
      try {
        // Clear cached instance to reset state
        _cachedGoogleSignIn = null;
        
        // Get fresh instance
        final googleSignIn = _googleSignIn;
        
        // Disconnect and sign out to force account selection
        await googleSignIn.disconnect();
        await googleSignIn.signOut();
      } catch (_) {
        // Ignore errors - just ensure we have a fresh instance
        _cachedGoogleSignIn = null;
      }
      
      // Get fresh GoogleSignIn instance and trigger account picker
      final googleSignIn = _googleSignIn;
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }
      
      // Obtain the auth details from the request
      GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        await _googleSignIn.signOut();
        throw Exception('Failed to get Google authentication: $e');
      }

      // Validate that we have the required tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        await _googleSignIn.signOut();
        throw Exception('Google Sign-In failed: Missing authentication tokens');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      await _googleSignIn.signOut();
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception('An account already exists with a different sign-in method.');
      } else if (e.code == 'invalid-credential') {
        throw Exception('The credential is invalid or has expired.');
      } else if (e.code == 'operation-not-allowed') {
        throw Exception('Google Sign-In is not enabled. Please enable it in Firebase Console.');
      } else if (e.code == 'user-disabled') {
        throw Exception('This user account has been disabled.');
      }
      throw Exception('Google Sign-In failed (${e.code}): ${e.message}');
    } catch (e) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      
      final errorString = e.toString().toLowerCase();
      final errorMessage = e.toString();
      
      if (errorString.contains('pigeonuserdetails') || 
          errorString.contains('list<object>') ||
          (errorString.contains('developer_error') && errorString.contains('10:')) ||
          (errorString.contains('sign_in_failed') && errorString.contains('configuration')) ||
          errorString.contains('12500') ||
          errorString.contains('12501') ||
          errorString.contains('12502') ||
          errorString.contains('12503') ||
          errorString.contains('10:') ||
          errorString.contains('com.google.android.gms.common.api.resolvableexception')) {
        throw Exception(
          'Google Sign-In configuration error. Please check:\n\n'
          '1. SHA-1 fingerprint is in Firebase Console\n'
          '2. Google Sign-In is enabled in Firebase Console\n'
          '3. Download NEW google-services.json from Firebase Console\n'
          '4. Clean and rebuild: flutter clean && flutter pub get && flutter run\n\n'
          'Error: $errorMessage'
        );
      }
      
      if (errorString.contains('firestore') || errorString.contains('permission')) {
        throw Exception('Database error: Please check Firestore security rules.');
      }
      
      throw Exception('Google Sign-In failed: $errorMessage');
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
        
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: trimmedEmail,
          password: trimmedPassword,
        );
        
        return userCredential;
      } on FirebaseAuthException catch (e) {
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
        throw Exception('Sign-in error: $e');
      }
    }

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final trimmedEmail = email.trim().toLowerCase();
      final trimmedPassword = password.trim();
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );
      
      return credential;
    } on FirebaseAuthException catch (e) {
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

  /// Extract OAuth tokens from browser's OAuth response (web only)
  Map<String, String?>? _extractOAuthTokensFromBrowser() {
    if (!kIsWeb) return null;
    return null;
  }

  /// Extract ID token from OAuth response (web only)
  String? _extractIdTokenFromOAuthResponse() {
    if (!kIsWeb) return null;
    return null;
  }
}

/// Mock GoogleSignInAuthentication for web when People API fails
/// This allows us to use tokens extracted from browser OAuth response
class _GoogleSignInAuthenticationFromTokens implements GoogleSignInAuthentication {
  @override
  final String? accessToken;
  
  @override
  final String? idToken;
  
  @override
  String? get serverAuthCode => null; // Not available without People API

  _GoogleSignInAuthenticationFromTokens({
    required this.accessToken,
    required this.idToken,
  });
}

