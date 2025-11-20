import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Student ID Verification Page with camera functionality
/// This page allows users to capture front and back photos of their student ID
class StudentIDVerificationPage extends StatefulWidget {
  const StudentIDVerificationPage({super.key});

  @override
  State<StudentIDVerificationPage> createState() => _StudentIDVerificationPageState();
}

class _StudentIDVerificationPageState extends State<StudentIDVerificationPage> {
  // Image picker instance
  final ImagePicker _imagePicker = ImagePicker();
  
  // Store captured images
  XFile? _frontIdImage;
  XFile? _backIdImage;
  
  // Track which image is being captured
  String? _capturingImageType; // 'front' or 'back'
  
  // Loading state
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image Widget at the top
          _BackgroundImageWidget(),
          // White Card Background Widget
          _WhiteCardBackgroundWidget(
            child: _StudentIDVerificationContentWidget(
              frontIdImage: _frontIdImage,
              backIdImage: _backIdImage,
              isLoading: _isLoading,
              onCaptureFront: () => _captureImage('front'),
              onCaptureBack: () => _captureImage('back'),
              onRetakeFront: () => _captureImage('front'),
              onRetakeBack: () => _captureImage('back'),
            ),
          ),
        ],
      ),
    );
  }

  /// Request camera and storage permissions
  /// Returns true if permissions are granted, false otherwise
  Future<bool> _requestPermissions() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      
      // Request photos permission (for gallery access)
      // On Android 13+, we need photos permission
      // On iOS, we need photos permission
      PermissionStatus photosStatus;
      if (Platform.isAndroid) {
        // For Android 13+, use photos permission
        photosStatus = await Permission.photos.request();
        // If photos permission is not available (older Android), try storage
        if (photosStatus.isDenied) {
          photosStatus = await Permission.storage.request();
        }
      } else {
        // For iOS, use photos permission
        photosStatus = await Permission.photos.request();
      }

      // Check if both permissions are granted
      if (cameraStatus.isGranted && photosStatus.isGranted) {
        return true;
      } else if (cameraStatus.isPermanentlyDenied || photosStatus.isPermanentlyDenied) {
        // Show dialog to open app settings
        if (mounted) {
          _showPermissionDeniedDialog();
        }
        return false;
      } else {
        // Permissions denied but not permanently
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera and storage permissions are required to capture ID photos.'),
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

  /// Show dialog when permissions are permanently denied
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

  /// Capture image from camera or gallery
  /// imageType: 'front' or 'back'
  Future<void> _captureImage(String imageType) async {
    setState(() {
      _capturingImageType = imageType;
      _isLoading = true;
    });

    try {
      // Request permissions first
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        setState(() {
          _isLoading = false;
          _capturingImageType = null;
        });
        return;
      }

      // Show dialog to choose camera or gallery
      if (mounted) {
        final source = await showDialog<ImageSource>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Capture ${imageType == 'front' ? 'Front' : 'Back'} ID'),
              content: const Text('Choose an option:'),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );

        if (source == null) {
          setState(() {
            _isLoading = false;
            _capturingImageType = null;
          });
          return;
        }

        // Pick image based on selected source
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          imageQuality: 85, // Compress image to reduce file size
          maxWidth: 1920, // Limit image width
          maxHeight: 1920, // Limit image height
        );

        if (image != null) {
          // Show preview and confirmation dialog
          if (mounted) {
            final confirmed = await _showImagePreview(image, imageType);
            if (confirmed) {
              setState(() {
                if (imageType == 'front') {
                  _frontIdImage = image;
                } else {
                  _backIdImage = image;
                }
                _isLoading = false;
                _capturingImageType = null;
              });
            } else {
              setState(() {
                _isLoading = false;
                _capturingImageType = null;
              });
            }
          }
        } else {
          setState(() {
            _isLoading = false;
            _capturingImageType = null;
          });
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
        setState(() {
          _isLoading = false;
          _capturingImageType = null;
        });
      }
    }
  }

  /// Show image preview and ask for confirmation
  /// Returns true if user confirms, false if they want to retake
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
                // Title
                Text(
                  'Verify your image for upload.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                // Image preview
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
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Reject button
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
                    // Accept button
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
    ) ?? false;
  }
}

/// Widget for displaying the background image at the top
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

/// Widget for the white card background with rounded top corners
class _WhiteCardBackgroundWidget extends StatelessWidget {
  final Widget child;

  const _WhiteCardBackgroundWidget({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.30;
    
    return Positioned(
      left: 0,
      right: 0,
      top: imageHeight - 25,
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

/// Widget for the student ID verification content
class _StudentIDVerificationContentWidget extends StatelessWidget {
  final XFile? frontIdImage;
  final XFile? backIdImage;
  final bool isLoading;
  final VoidCallback onCaptureFront;
  final VoidCallback onCaptureBack;
  final VoidCallback onRetakeFront;
  final VoidCallback onRetakeBack;

  const _StudentIDVerificationContentWidget({
    required this.frontIdImage,
    required this.backIdImage,
    required this.isLoading,
    required this.onCaptureFront,
    required this.onCaptureBack,
    required this.onRetakeFront,
    required this.onRetakeBack,
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
          vertical: isSmallScreen ? 12.0 : 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: isSmallScreen ? 4 : 8),
            // Back button
            _BackButtonWidget(),
            SizedBox(height: isSmallScreen ? 12 : 16),
            // Logo Widget
            _LogoWidget(),
            SizedBox(height: isSmallScreen ? 16 : 20),
            // Title Widget
            _TitleWidget(),
            SizedBox(height: isSmallScreen ? 4 : 8),
            // Description Widget
            _DescriptionWidget(),
            SizedBox(height: isSmallScreen ? 20 : 24),
            // Front ID Capture Section
            _IDCaptureSectionWidget(
              title: 'Front ID',
              image: frontIdImage,
              isLoading: isLoading,
              onCapture: onCaptureFront,
              onRetake: onRetakeFront,
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            // Back ID Capture Section
            _IDCaptureSectionWidget(
              title: 'Back ID',
              image: backIdImage,
              isLoading: isLoading,
              onCapture: onCaptureBack,
              onRetake: onRetakeBack,
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            // Upload ID Photo Button (only enabled when both images are captured)
            _UploadIDButtonWidget(
              isEnabled: frontIdImage != null && backIdImage != null,
              isLoading: isLoading,
            ),
            SizedBox(height: isSmallScreen ? 8 : 16),
          ],
        ),
      ),
    );
  }
}

/// Widget for back button
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

/// Widget for the RentEase logo
class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final logoHeight = isSmallScreen ? 40.0 : 45.0;
    
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

/// Widget for the Sign Up as Student title
class _TitleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Text(
      'Sign Up as Student',
      style: TextStyle(
        fontSize: isSmallScreen ? 24 : 28,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

/// Widget for the description text
class _DescriptionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Provide Your ID Information for Verification.',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Colors.grey[700],
        height: 1.4,
      ),
    );
  }
}

/// Widget for ID capture section (Front or Back)
class _IDCaptureSectionWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          '$title:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        // Capture area or preview
        GestureDetector(
          onTap: image == null ? onCapture : null,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: image != null ? Colors.green : Colors.grey[300]!,
                width: 2,
                style: image != null ? BorderStyle.solid : BorderStyle.solid,
              ),
            ),
            child: image == null
                ? _EmptyCaptureAreaWidget(
                    onTap: isLoading ? null : onCapture,
                  )
                : _ImagePreviewWidget(
                    imagePath: image!.path,
                    onRetake: onRetake,
                  ),
          ),
        ),
      ],
    );
  }
}

/// Widget for empty capture area (shows camera icon)
class _EmptyCaptureAreaWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const _EmptyCaptureAreaWidget({
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: 50,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to capture',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for image preview
class _ImagePreviewWidget extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRetake;

  const _ImagePreviewWidget({
    required this.imagePath,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(imagePath),
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
        // Retake button overlay
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRetake,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget for Upload ID Photo button
class _UploadIDButtonWidget extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;

  const _UploadIDButtonWidget({
    required this.isEnabled,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 44 : 48,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading
            ? () {
                // TODO: Handle upload logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ID photos uploaded successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? Colors.grey[850] : Colors.grey[400],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

