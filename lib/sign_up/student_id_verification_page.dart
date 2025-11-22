import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class StudentIDVerificationPage extends StatefulWidget {
  const StudentIDVerificationPage({super.key});

  @override
  State<StudentIDVerificationPage> createState() =>
      _StudentIDVerificationPageState();
}

class _StudentIDVerificationPageState extends State<StudentIDVerificationPage> {
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _frontIdImage;
  XFile? _backIdImage;

  String? _capturingImageType;

  bool _isLoading = false;

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
    setState(() {
      _capturingImageType = imageType;
      _isLoading = true;
    });

    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        setState(() {
          _isLoading = false;
          _capturingImageType = null;
        });
        return;
      }

      if (mounted) {
        final source = await showDialog<ImageSource>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Capture ${imageType == 'front' ? 'Front' : 'Back'} ID',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Choose an option:'),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () =>
                              Navigator.of(context).pop(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              Navigator.of(context).pop(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
            _BackButtonWidget(),
            SizedBox(height: isSmallScreen ? 12 : 16),
            _LogoWidget(),
            SizedBox(height: isSmallScreen ? 16 : 20),
            _TitleWidget(),
            SizedBox(height: isSmallScreen ? 4 : 8),
            _DescriptionWidget(),
            SizedBox(height: isSmallScreen ? 20 : 24),
            _IDCaptureSectionWidget(
              title: 'Front ID',
              image: frontIdImage,
              isLoading: isLoading,
              onCapture: onCaptureFront,
              onRetake: onRetakeFront,
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            _IDCaptureSectionWidget(
              title: 'Back ID',
              image: backIdImage,
              isLoading: isLoading,
              onCapture: onCaptureBack,
              onRetake: onRetakeBack,
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
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
        Text(
          '$title:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
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
                ? _EmptyCaptureAreaWidget(onTap: isLoading ? null : onCapture)
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

class _EmptyCaptureAreaWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const _EmptyCaptureAreaWidget({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Tap to capture',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _ImagePreviewWidget extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRetake;

  const _ImagePreviewWidget({required this.imagePath, required this.onRetake});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
