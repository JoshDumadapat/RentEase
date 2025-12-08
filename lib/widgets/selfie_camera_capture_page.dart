import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Selfie camera page for capturing face photos with oval guide overlay
class SelfieCameraCapturePage extends StatefulWidget {
  const SelfieCameraCapturePage({super.key});

  @override
  State<SelfieCameraCapturePage> createState() => _SelfieCameraCapturePageState();
}

class _SelfieCameraCapturePageState extends State<SelfieCameraCapturePage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No cameras available'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      if (!mounted) return;

      // Use front camera for selfie
      CameraDescription? selectedCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }
      selectedCamera ??= _cameras!.first;

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  Future<XFile?> _cropImageToOval(XFile originalImage) async {
    try {
      if (!mounted || _controller == null || !_controller!.value.isInitialized) {
        return originalImage;
      }

      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      
      // Get preview size safely
      Size? previewSize;
      try {
        if (_controller!.value.previewSize != null) {
          previewSize = _controller!.value.previewSize;
        }
      } catch (e) {
        return originalImage;
      }
      
      if (previewSize == null) {
        return originalImage;
      }

      // Read the original image
      final imageBytes = await originalImage.readAsBytes();
      final originalImg = img.decodeImage(imageBytes);
      
      if (originalImg == null) {
        return originalImage;
      }
      
      // Calculate face shape dimensions on screen (oval, taller than wide)
      final faceWidth = screenWidth * 0.65; // 65% of screen width
      final faceHeight = faceWidth * 1.2; // 20% taller than wide (face shape)
      final faceCenterX = screenWidth / 2;
      final faceCenterY = screenHeight / 2;
      
      // Calculate rectangle position (centered)
      final rectLeft = faceCenterX - (faceWidth / 2);
      final rectTop = faceCenterY - (faceHeight / 2);
      
      // Camera preview aspect ratio
      final previewAspectRatio = previewSize.height / previewSize.width;
      
      // Calculate how the preview is displayed on screen
      double displayWidth = screenWidth;
      double displayHeight = screenWidth * previewAspectRatio;
      double offsetX = 0;
      double offsetY = 0;
      
      if (displayHeight > screenHeight) {
        displayHeight = screenHeight;
        displayWidth = screenHeight / previewAspectRatio;
        offsetX = (screenWidth - displayWidth) / 2;
      } else {
        offsetY = (screenHeight - displayHeight) / 2;
      }
      
      // Calculate the crop area in the original image coordinates
      final relativeLeft = (rectLeft - offsetX) / displayWidth;
      final relativeTop = (rectTop - offsetY) / displayHeight;
      final relativeWidth = faceWidth / displayWidth;
      final relativeHeight = faceHeight / displayHeight;
      
      // Ensure values are within bounds
      final imageWidth = originalImg.width;
      final imageHeight = originalImg.height;
      final cropX = (relativeLeft.clamp(0.0, 1.0) * imageWidth).round();
      final cropY = (relativeTop.clamp(0.0, 1.0) * imageHeight).round();
      final cropWidth = ((relativeWidth.clamp(0.0, 1.0 - relativeLeft.clamp(0.0, 1.0)) * imageWidth).round()).clamp(1, imageWidth - cropX);
      final cropHeight = ((relativeHeight.clamp(0.0, 1.0 - relativeTop.clamp(0.0, 1.0)) * imageHeight).round()).clamp(1, imageHeight - cropY);
      
      // Crop the image to face shape (oval proportions)
      final croppedImg = img.copyCrop(
        originalImg,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );
      
      // Save cropped image
      final croppedBytes = img.encodeJpg(croppedImg, quality: 85);
      final tempDir = await getTemporaryDirectory();
      final croppedPath = '${tempDir.path}/selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(croppedBytes);
      
      // Delete original temporary file
      try {
        final originalFile = File(originalImage.path);
        if (await originalFile.exists()) {
          await originalFile.delete();
        }
      } catch (e) {
        // Error deleting original
      }
      
      return XFile(croppedPath);
    } catch (e) {
      return originalImage;
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || !mounted) {
      return;
    }

    if (_isCapturing) return;

    if (!mounted) return;
    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile originalImage = await _controller!.takePicture();
      
      if (!mounted) {
        try {
          final file = File(originalImage.path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Error deleting
        }
        return;
      }
      
      // Crop image to oval area
      final XFile? croppedImage = await _cropImageToOval(originalImage);
      
      if (!mounted) {
        if (croppedImage != null) {
          try {
            final file = File(croppedImage.path);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            // Error deleting
          }
        }
        return;
      }
      
      if (croppedImage == null) {
        if (mounted) {
          setState(() {
            _isCapturing = false;
          });
        }
        return;
      }
      
      // Show confirmation dialog with cropped image
      final confirmed = await _showImageConfirmation(croppedImage);
      
      if (!mounted) {
        // Widget was disposed during confirmation
        try {
          final file = File(croppedImage.path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Error deleting
        }
        return;
      }
      
      if (confirmed) {
        Navigator.of(context).pop(croppedImage);
      } else {
        // User rejected, delete the cropped file
        try {
          final file = File(croppedImage.path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Error deleting rejected image
        }
        if (mounted) {
          setState(() {
            _isCapturing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<bool> _showImageConfirmation(XFile image) async {
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
                // Centered logo
                Center(
                  child: Image.asset(
                    'assets/sign_in_up/signlogo.png',
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verify your image for upload.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                // Image preview with oval frame matching face shape
                _FaceImagePreviewWithFrame(image: image),
                const SizedBox(height: 16),
                // Action buttons (smaller size)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 2),
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(true),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green, width: 2),
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.green,
                          size: 22,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // Face shape: oval (wider than tall, but more face-like proportions)
    final faceWidth = screenWidth * 0.65; // 65% of screen width
    final faceHeight = faceWidth * 1.2; // 20% taller than wide (face shape)

    // Camera preview
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            SizedBox.expand(
              child: CameraPreview(_controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),

          // Top section with title and close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Selfie',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),

          // Instructions text
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            right: 16,
            child: const Text(
              'Position your face within the oval guide',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Prompt to fit face in the guide
          Positioned(
            top: (screenHeight / 2) - (faceHeight / 2) - 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Fit your face within the face guide',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Full white overlay outside face area (100% opacity)
          CustomPaint(
            size: Size(screenWidth, screenHeight),
            painter: _SelfieOverlayPainter(
              faceRect: Rect.fromCenter(
                center: Offset(screenWidth / 2, screenHeight / 2),
                width: faceWidth,
                height: faceHeight,
              ),
            ),
          ),

          // Face-shaped guide overlay (oval, taller than wide) with dashed border
          Center(
            child: SizedBox(
              width: faceWidth,
              height: faceHeight,
              child: CustomPaint(
                painter: _DashedOvalBorderPainter(
                  color: Colors.orange,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),

          // Bottom section with capture button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Center(
                child: GestureDetector(
                  onTap: _isCapturing ? null : _capturePhoto,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: _isCapturing
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for white overlay outside face capture area
class _SelfieOverlayPainter extends CustomPainter {
  final Rect faceRect;

  _SelfieOverlayPainter({required this.faceRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white // 100% opacity white
      ..style = PaintingStyle.fill;

    // Create path that covers entire screen except face area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Subtract the face oval (make it transparent)
    final facePath = Path()
      ..addOval(faceRect);

    final combinedPath = Path.combine(
      PathOperation.difference,
      path,
      facePath,
    );

    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for dashed oval border
class _DashedOvalBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DashedOvalBorderPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final oval = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()..addOval(oval);

    // Draw dashed border
    final dashWidth = 8.0;
    final dashSpace = 4.0;
    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      var distance = 0.0;
      while (distance < pathMetric.length) {
        final extractPath = pathMetric.extractPath(
          distance,
          distance + dashWidth,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget for displaying face image preview with oval frame in confirmation dialog
class _FaceImagePreviewWithFrame extends StatelessWidget {
  final XFile image;

  const _FaceImagePreviewWithFrame({required this.image});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final faceWidth = screenWidth * 0.65 * 0.8; // Slightly smaller for dialog
    final faceHeight = faceWidth * 1.2; // Face shape proportions

    return Container(
      width: faceWidth,
      height: faceHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(faceHeight / 2), // Oval shape
      ),
      child: ClipOval(
        child: Stack(
          children: [
            Image.file(
              File(image.path),
              width: faceWidth,
              height: faceHeight,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: faceWidth,
                  height: faceHeight,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.error_outline,
                    size: 50,
                    color: Colors.grey,
                  ),
                );
              },
            ),
            // Dashed border overlay
            CustomPaint(
              size: Size(faceWidth, faceHeight),
              painter: _DashedOvalBorderPainter(
                color: Colors.orange,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

