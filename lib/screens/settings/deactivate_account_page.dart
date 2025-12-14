import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/landing/landing_page.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

const Color _themeColorDark = Color(0xFF00B8E6);
const Color _themeColor = Color(0xFF00D1FF);

class DeactivateAccountPage extends StatefulWidget {
  const DeactivateAccountPage({super.key});

  @override
  State<DeactivateAccountPage> createState() => _DeactivateAccountPageState();
}

class _DeactivateAccountPageState extends State<DeactivateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _reasonController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _selectedReason;
  bool _confirmDeactivate = false;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BUserService _userService = BUserService();

  final List<String> _deactivateReasons = [
    'I need a break from social media',
    'I\'m getting too many notifications',
    'I\'m concerned about my privacy',
    'I don\'t find this app useful anymore',
    'I have a technical issue',
    'I\'m creating a new account',
    'Other',
  ];

  @override
  void dispose() {
    _passwordController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // Check if user has password provider
  bool _hasPasswordProvider() {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    return user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
  }

  Future<void> _deactivateAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_confirmDeactivate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Please confirm that you understand'),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user (only if they have password provider)
      if (_hasPasswordProvider()) {
        try {
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: _passwordController.text,
          );
          
          await user.reauthenticateWithCredential(credential);
          debugPrint('✅ [DeactivateAccount] User re-authenticated successfully');
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(
              context,
              'Re-authentication failed. Please verify your password.',
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }
      // For Google-only users, skip password re-auth (they're already authenticated)

      // Deactivate user account using BUserService
      await _userService.deactivateUser(
        uid: user.uid,
        reason: _selectedReason ?? 'Other',
        customReason: _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : null,
      );
      debugPrint('✅ [DeactivateAccount] Account deactivated successfully');

      // Sign out the user
      await _auth.signOut();

      if (!mounted) return;

      // Navigate to login/signup screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(
          context,
          'Your account has been deactivated. You can reactivate by logging in again.',
          duration: const Duration(seconds: 4),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to deactivate account';
      if (e.code == 'wrong-password') {
        message = 'Password is incorrect';
      } else if (e.code == 'requires-recent-login') {
        message = 'Security verification expired. Please verify your credentials again.';
        // Reset confirmation so user can try again
        setState(() {
          _confirmDeactivate = false;
          _passwordController.clear();
        });
      } else if (e.code == 'user-not-found') {
        message = 'User account not found';
      } else {
        message = 'Error: ${e.message ?? e.code}';
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, message),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [DeactivateAccount] Error: $e');
      debugPrint('❌ [DeactivateAccount] Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(
          context,
          'Error deactivating account: ${e.toString()}',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Deactivate Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pause_circle_outline, color: Colors.orange, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Temporary Deactivation',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You can reactivate anytime by logging in',
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Help us understand why you\'re taking a break.',
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Reason Selection
                Text(
                  'Why are you deactivating your account?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                ..._deactivateReasons.map((reason) => RadioListTile<String>(
                  title: Text(reason, style: TextStyle(color: textColor)),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() => _selectedReason = value);
                  },
                  activeColor: Colors.orange,
                )),
                const SizedBox(height: 16),

                // Additional Comments (if Other is selected)
                if (_selectedReason == 'Other') ...[
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 4,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Please tell us more...',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.orange, width: 2),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
                    ),
                    validator: (value) {
                      if (_selectedReason == 'Other' && (value == null || value.trim().isEmpty)) {
                        return 'Please provide a reason';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // What happens when deactivated
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: isDark ? Colors.blue[300] : Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'What happens when you deactivate:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.blue[300] : Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDeactivateInfo('Your profile will be hidden', Icons.visibility_off),
                      _buildDeactivateInfo('Your listings will be hidden', Icons.home_outlined),
                      _buildDeactivateInfo('You won\'t receive notifications', Icons.notifications_off),
                      _buildDeactivateInfo('You can reactivate anytime by logging in', Icons.restore),
                      _buildDeactivateInfo('Your data will be preserved', Icons.backup_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Password Confirmation (only if user has password provider)
                if (_hasPasswordProvider()) ...[
                Text(
                  'Enter your password to confirm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: textColor.withOpacity(0.6),
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.orange, width: 2),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                ] else ...[
                  // Info for Google users
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You signed in with Google. No password required to deactivate.',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Confirmation Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _confirmDeactivate,
                      onChanged: (value) {
                        setState(() => _confirmDeactivate = value ?? false);
                      },
                      activeColor: Colors.orange,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _confirmDeactivate = !_confirmDeactivate);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'I understand that my account will be hidden and I can reactivate it anytime by logging in.',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Deactivate Button
                FilledButton(
                  onPressed: _isLoading ? null : _deactivateAccount,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Deactivate My Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeactivateInfo(String text, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? Colors.blue[300] : Colors.blue[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.blue[200] : Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
