import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rentease_app/services/user_service.dart';
import 'package:rentease_app/services/auth_service.dart';
import 'package:rentease_app/main_app.dart';

class StudentIDVerificationPage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String birthday;
  final String phone;
  final String countryCode;
  final User? googleUser; // Firebase User from Google sign-in

  const StudentIDVerificationPage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.birthday,
    required this.phone,
    required this.countryCode,
    this.googleUser,
  });

  @override
  State<StudentIDVerificationPage> createState() =>
      _StudentIDVerificationPageState();
}

class _StudentIDVerificationPageState extends State<StudentIDVerificationPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  XFile? _frontIdImage;
  XFile? _backIdImage;
  XFile? _faceWithIdImage;

  bool _isLoading = false;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _BackgroundImageWidget(),
          _WhiteCardBackgroundWidget(
            child: _StudentIDVerificationContentWidget(
              frontIdImage: _frontIdImage,
              backIdImage: _backIdImage,
              faceWithIdImage: _faceWithIdImage,
              isLoading: _isLoading,
              isUploading: _isUploading,
              onCaptureFront: () => _captureImage('front'),
              onCaptureBack: () => _captureImage('back'),
              onCaptureFaceWithId: () => _captureImage('faceWithId'),
              onRetakeFront: () => _captureImage('front'),
              onRetakeBack: () => _captureImage('back'),
              onRetakeFaceWithId: () => _captureImage('faceWithId'),
              onUpload: _handleUpload,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _requestPermissions() async {
    try {
      final cameraStatus = await Permission.camera.request();

      PermissionStatus photosStatus;
      if (Platform.isAndroid) {
        photosStatus = await Permission.photos.request();
        if (photosStatus.isDenied) {
          photosStatus = await Permission.storage.request();
        }
      } else {
        photosStatus = await Permission.photos.request();
      }

      if (cameraStatus.isGranted && photosStatus.isGranted) {
        return true;
      } else if (cameraStatus.isPermanentlyDenied ||
          photosStatus.isPermanentlyDenied) {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
        return false;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Camera and storage permissions are required to capture ID photos.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'Camera and storage permissions are required to capture ID photos. '
            'Please enable them in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _captureImage(String imageType) async {
    if (mounted) {
    setState(() {
      _isLoading = true;
    });
    }

    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        if (mounted) {
        setState(() {
          _isLoading = false;
        });
        }
        return;
      }

      if (mounted) {
        final source = await showDialog<ImageSource>(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Title
                    Text(
                      imageType == 'faceWithId' 
                          ? 'Capture Face with ID'
                          : 'Capture ${imageType == 'front' ? 'Front' : 'Back'} ID',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose an option',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Camera Option
                    _ModernDialogOption(
                      icon: Icons.camera_alt,
                      iconColor: Colors.cyan[700]!,
                      backgroundColor: Colors.cyan[50]!,
                      title: 'Camera',
                      subtitle: 'Take a new photo',
                      onTap: () => Navigator.of(context).pop(ImageSource.camera),
                    ),
                    const SizedBox(height: 12),
                    // Gallery Option
                    _ModernDialogOption(
                      icon: Icons.photo_library,
                      iconColor: Colors.blue[600]!,
                      backgroundColor: Colors.blue[50]!,
                      title: 'Gallery',
                      subtitle: 'Choose from photos',
                      onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                        ),
                    const SizedBox(height: 20),
                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                    ),
                  ),
                ],
                ),
              ),
            );
          },
        );

        if (source == null) {
          if (mounted) {
          setState(() {
            _isLoading = false;
          });
          }
          return;
        }

        final XFile? image = await _imagePicker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );

        if (image != null) {
          if (mounted) {
            final confirmed = await _showImagePreview(image, imageType);
            if (confirmed) {
              if (mounted) {
              setState(() {
                if (imageType == 'front') {
                  _frontIdImage = image;
                } else if (imageType == 'back') {
                  _backIdImage = image;
                } else if (imageType == 'faceWithId') {
                  _faceWithIdImage = image;
                }
                _isLoading = false;
              });
              }
            } else {
              if (mounted) {
              setState(() {
                _isLoading = false;
              });
              }
            }
          }
        } else {
          if (mounted) {
          setState(() {
            _isLoading = false;
          });
          }
        }
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
        if (mounted) {
        setState(() {
          _isLoading = false;
        });
        }
      }
    }
  }

  Future<bool> _showImagePreview(XFile image, String imageType) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Verify your image for upload.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(image.path),
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 300,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.error_outline,
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(false),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.red, width: 2),
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(true),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.green, width: 2),
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  Future<void> _handleUpload() async {
    if (_frontIdImage == null || _backIdImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture both front and back ID images'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      User? user = widget.googleUser;

      // If no Google user, try to create email/password account
      if (user == null) {
        try {
          const password = 'Pass123'; // Default password
          final email = widget.email.trim().toLowerCase();
          
          debugPrint('=== EMAIL/PASSWORD SIGN UP ===');
          debugPrint('Email: "$email"');
          debugPrint('Password length: ${password.length}');

          // Check if email is already in use FIRST
          try {
            final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
            if (signInMethods.isNotEmpty) {
              debugPrint('Email already exists. Signing in instead...');
              // Try to sign in with the default password
              try {
                final userCredential = await _authService.signInWithEmailAndPassword(
                  email,
                  password,
                );
                user = userCredential.user;
                debugPrint('Signed in existing user: ${user?.uid}');
              } catch (signInError) {
                debugPrint('Failed to sign in: $signInError');
                // Email exists but password is wrong - ask user to reset
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account already exists. Please use "Forgot Password" or sign in.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 4),
                    ),
                  );
                  setState(() { _isUploading = false; });
                  return;
                }
              }
            } else {
              // Create new account
              debugPrint('Creating new account...');
              final userCredential = await _authService.signUpWithEmailAndPassword(
                email,
                password,
              );
              user = userCredential.user;
              debugPrint('Account created: ${user?.uid}');
              
              // Verify the account was actually created
              await user?.reload();
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null && currentUser.uid == user?.uid) {
                debugPrint('✅ Account verified in Firebase Auth');
              } else {
                debugPrint('⚠️ Account created but not current user');
              }
            }
          } catch (fetchError) {
            debugPrint('Error checking email: $fetchError');
            // Proceed with account creation anyway
            final userCredential = await _authService.signUpWithEmailAndPassword(
              email,
              password,
            );
            user = userCredential.user;
          }
        } catch (e) {
          debugPrint('ERROR creating account: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error creating account: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
            setState(() { _isUploading = false; });
          }
          return;
        }
      }

      if (user == null) {
        throw Exception('Failed to authenticate user');
      }

      final uid = user.uid;
      debugPrint('✅ User authenticated with UID: $uid');

      // Save user data to Firestore
      await _userService.createOrUpdateUser(
        uid: uid,
        email: widget.email.trim().toLowerCase(),
        fname: widget.firstName.trim(),
        lname: widget.lastName.trim(),
        birthday: widget.birthday,
        phone: widget.phone.trim(),
        countryCode: widget.countryCode,
        idImageFrontUrl: 'PENDING', // Mark as pending until images uploaded
        idImageBackUrl: 'PENDING',
        faceWithIdUrl: _faceWithIdImage != null ? 'PENDING' : null,
        userType: 'student',
        password: widget.googleUser == null ? 'Pass123' : null,
      );

      debugPrint('✅ User data saved to Firestore');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to main app
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainApp(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Final error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}

class _BackgroundImageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.30;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: imageHeight,
      child: Image.asset(
        'assets/sign_in_up/signGen.png',
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.blue[100],
            child: const Center(
              child: Icon(Icons.image, size: 100, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}

class _WhiteCardBackgroundWidget extends StatelessWidget {
  final Widget child;

  const _WhiteCardBackgroundWidget({required this.child});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.30;

    return Positioned(
      left: 0,
      right: 0,
      top: imageHeight - 55,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _StudentIDVerificationContentWidget extends StatelessWidget {
  final XFile? frontIdImage;
  final XFile? backIdImage;
  final XFile? faceWithIdImage;
  final bool isLoading;
  final bool isUploading;
  final VoidCallback onCaptureFront;
  final VoidCallback onCaptureBack;
  final VoidCallback onCaptureFaceWithId;
  final VoidCallback onRetakeFront;
  final VoidCallback onRetakeBack;
  final VoidCallback onRetakeFaceWithId;
  final VoidCallback onUpload;

  const _StudentIDVerificationContentWidget({
    required this.frontIdImage,
    required this.backIdImage,
    this.faceWithIdImage,
    required this.isLoading,
    required this.isUploading,
    required this.onCaptureFront,
    required this.onCaptureBack,
    required this.onCaptureFaceWithId,
    required this.onRetakeFront,
    required this.onRetakeBack,
    required this.onRetakeFaceWithId,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isNarrowScreen = screenWidth < 360;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isNarrowScreen ? 20.0 : 24.0,
          vertical: isSmallScreen ? 0.0 : 2.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: isSmallScreen ? 8 : 12),
            // Back button and Logo aligned in same row
            Stack(
              alignment: Alignment.center,
              children: [
                // Back button aligned to start (left) with negative margin
                Positioned(
                  left: -12,
                  child: _BackButtonWidget(),
                ),
                // Logo centered horizontally
                _LogoWidget(),
              ],
            ),
            SizedBox(height: isSmallScreen ? 14 : 16),
            _TitleWidget(),
            SizedBox(height: isSmallScreen ? 4 : 6),
            _DescriptionWidget(),
            SizedBox(height: isSmallScreen ? 16 : 18),
            _IDCaptureSectionWidget(
              title: 'Front ID',
              image: frontIdImage,
              isLoading: isLoading,
              onCapture: onCaptureFront,
              onRetake: onRetakeFront,
            ),
            SizedBox(height: isSmallScreen ? 14 : 16),
            _IDCaptureSectionWidget(
              title: 'Back ID',
              image: backIdImage,
              isLoading: isLoading,
              onCapture: onCaptureBack,
              onRetake: onRetakeBack,
            ),
            SizedBox(height: isSmallScreen ? 14 : 16),
            _IDCaptureSectionWidget(
              title: 'Face with ID (Optional)',
              image: faceWithIdImage,
              isLoading: isLoading,
              onCapture: onCaptureFaceWithId,
              onRetake: onRetakeFaceWithId,
            ),
            SizedBox(height: isSmallScreen ? 16 : 18),
            _UploadIDButtonWidget(
              isEnabled: frontIdImage != null && backIdImage != null,
              isLoading: isLoading || isUploading,
              onUpload: onUpload,
            ),
            SizedBox(height: isSmallScreen ? 8 : 16),
          ],
        ),
      ),
    );
  }
}

class _BackButtonWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black87),
      onPressed: () {
        Navigator.of(context).pop();
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final logoHeight = isSmallScreen ? 50.0 : 55.0;

    return Center(
      child: Image.asset(
        'assets/sign_in_up/signlogo.png',
        height: logoHeight,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.home, size: logoHeight, color: Colors.blue);
        },
      ),
    );
  }
}

class _TitleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Sign Up as Student',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class _DescriptionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Provide Your ID Information for Verification.',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: Colors.grey[700],
        height: 1.4,
      ),
    );
  }
}

class _IDCaptureSectionWidget extends StatefulWidget {
  final String title;
  final XFile? image;
  final bool isLoading;
  final VoidCallback onCapture;
  final VoidCallback onRetake;

  const _IDCaptureSectionWidget({
    required this.title,
    required this.image,
    required this.isLoading,
    required this.onCapture,
    required this.onRetake,
  });

  @override
  State<_IDCaptureSectionWidget> createState() => _IDCaptureSectionWidgetState();
}

class _IDCaptureSectionWidgetState extends State<_IDCaptureSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.title}:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: widget.image == null && !widget.isLoading
              ? () {
                  if (mounted) {
                    widget.onCapture();
                  }
                }
              : null,
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: widget.title.toLowerCase().contains('face') ? Colors.orange[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.image != null 
                    ? Colors.green[400]! 
                    : (widget.title.toLowerCase().contains('face') ? Colors.orange[200]! : Colors.blue[200]!),
                width: 1.5,
                style: BorderStyle.solid,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: widget.image == null
                ? _EmptyCaptureAreaWidget(
                    title: widget.title,
                    onTap: widget.isLoading
                        ? null
                        : () {
                            if (mounted) {
                              widget.onCapture();
                            }
                          },
                  )
                : _ImagePreviewWidget(
                    imagePath: widget.image!.path,
                    onRetake: () {
                      if (mounted) {
                        widget.onRetake();
                      }
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCaptureAreaWidget extends StatelessWidget {
  final String? title;
  final VoidCallback? onTap;

  const _EmptyCaptureAreaWidget({this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFaceWithId = title?.toLowerCase().contains('face') ?? false;
    final iconColor = isFaceWithId ? Colors.orange[700] : Colors.blue[700];
    final backgroundColor = isFaceWithId ? Colors.orange[100] : Colors.blue[100];
    final icon = isFaceWithId ? Icons.face : Icons.camera_alt;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap to capture',
            style: TextStyle(
              fontSize: 13,
              color: iconColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreviewWidget extends StatefulWidget {
  final String imagePath;
  final VoidCallback onRetake;

  const _ImagePreviewWidget({required this.imagePath, required this.onRetake});

  @override
  State<_ImagePreviewWidget> createState() => _ImagePreviewWidgetState();
}

class _ImagePreviewWidgetState extends State<_ImagePreviewWidget> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(widget.imagePath),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(
                    Icons.error_outline,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              if (mounted) {
                widget.onRetake();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

/// Modern dialog option widget
class _ModernDialogOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModernDialogOption({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadIDButtonWidget extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onUpload;

  const _UploadIDButtonWidget({
    required this.isEnabled,
    required this.isLoading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 40 : 42,
      child: IgnorePointer(
        ignoring: !isEnabled || isLoading, // Prevent clicks when disabled or loading but keep visual state
        child: ElevatedButton(
          onPressed: onUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled ? Colors.grey[850] : Colors.grey[400], // Always use same background color
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Upload ID Photo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}
