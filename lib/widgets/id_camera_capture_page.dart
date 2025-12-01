import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Camera page for capturing ID photos with rectangular guide overlay
class IDCameraCapturePage extends StatefulWidget {
  final String title; // e.g., "Front ID", "Back ID", "Face with ID"

  const IDCameraCapturePage({
    super.key,
    required this.title,
  });

  // ID field dimensions (matching the capture section - increased for better visibility)
  static const double idFieldHeight = 220.0; // Increased from 150 to 220 for better visibility
  static const double horizontalPadding = 24.0; // Default padding
  static const double horizontalPaddingNarrow = 20.0; // Narrow screen padding

  @override
  State<IDCameraCapturePage> createState() => _IDCameraCapturePageState();
}

class _IDCameraCapturePageState extends State<IDCameraCapturePage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  XFile? _capturedImage;

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

      // Use back camera by default, fallback to first available
      CameraDescription? selectedCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.back) {
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
    } catch (e, stackTrace) {
      debugPrint('Error initializing camera: $e');
      debugPrint('Stack trace: $stackTrace');
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

  Future<XFile?> _cropImageToRectangle(XFile originalImage) async {
    try {
      // Check if widget is still mounted and controller is available
      if (!mounted || _controller == null || !_controller!.value.isInitialized) {
        return originalImage;
      }

      // Store values before async operations to avoid context issues
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final isNarrowScreen = screenWidth < 360;
      final padding = isNarrowScreen ? IDCameraCapturePage.horizontalPaddingNarrow : IDCameraCapturePage.horizontalPadding;
      
      // Get preview size safely
      Size? previewSize;
      try {
        if (_controller!.value.previewSize != null) {
          previewSize = _controller!.value.previewSize;
        }
      } catch (e) {
        debugPrint('Error getting preview size: $e');
        return originalImage;
      }
      
      if (previewSize == null) {
        return originalImage;
      }

      // Read the original image
      final imageBytes = await originalImage.readAsBytes();
      final originalImg = img.decodeImage(imageBytes);
      
      if (originalImg == null) {
        return originalImage; // Return original if decode fails
      }
      
      // Calculate rectangle dimensions on screen
      final guideWidth = screenWidth - (2 * padding);
      final guideHeight = IDCameraCapturePage.idFieldHeight;
      
      // Calculate rectangle position (centered vertically, with horizontal padding)
      final rectLeft = padding;
      final rectTop = (screenHeight - guideHeight) / 2;
      
      // Camera preview aspect ratio
      final previewAspectRatio = previewSize.height / previewSize.width;
      
      // Calculate how the preview is displayed on screen (may be letterboxed/pillarboxed)
      double displayWidth = screenWidth;
      double displayHeight = screenWidth * previewAspectRatio;
      double offsetX = 0;
      double offsetY = 0;
      
      if (displayHeight > screenHeight) {
        // Preview is taller than screen - letterboxed horizontally
        displayHeight = screenHeight;
        displayWidth = screenHeight / previewAspectRatio;
        offsetX = (screenWidth - displayWidth) / 2;
      } else {
        // Preview is wider than screen - pillarboxed vertically
        offsetY = (screenHeight - displayHeight) / 2;
      }
      
      // Calculate the crop area in the original image coordinates
      // Map screen coordinates to image coordinates
      final relativeLeft = (rectLeft - offsetX) / displayWidth;
      final relativeTop = (rectTop - offsetY) / displayHeight;
      final relativeWidth = guideWidth / displayWidth;
      final relativeHeight = guideHeight / displayHeight;
      
      // Ensure values are within bounds
      final imageWidth = originalImg.width;
      final imageHeight = originalImg.height;
      final cropX = (relativeLeft.clamp(0.0, 1.0) * imageWidth).round();
      final cropY = (relativeTop.clamp(0.0, 1.0) * imageHeight).round();
      final cropWidth = ((relativeWidth.clamp(0.0, 1.0 - relativeLeft.clamp(0.0, 1.0)) * imageWidth).round()).clamp(1, imageWidth - cropX);
      final cropHeight = ((relativeHeight.clamp(0.0, 1.0 - relativeTop.clamp(0.0, 1.0)) * imageHeight).round()).clamp(1, imageHeight - cropY);
      
      // Crop the image
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
      final croppedPath = path.join(tempDir.path, 'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(croppedBytes);
      
      // Delete original temporary file
      try {
        final originalFile = File(originalImage.path);
        if (await originalFile.exists()) {
          await originalFile.delete();
        }
      } catch (e) {
        debugPrint('Error deleting original image: $e');
      }
      
      return XFile(croppedPath);
    } catch (e, stackTrace) {
      debugPrint('Error cropping image: $e');
      debugPrint('Stack trace: $stackTrace');
      return originalImage; // Return original if cropping fails
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
        // Widget was disposed, clean up
        try {
          final file = File(originalImage.path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error deleting image after dispose: $e');
        }
        return;
      }
      
      // Crop image to rectangle area
      final XFile? croppedImage = await _cropImageToRectangle(originalImage);
      
      if (!mounted) {
        // Widget was disposed during cropping
        if (croppedImage != null) {
          try {
            final file = File(croppedImage.path);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            debugPrint('Error deleting cropped image after dispose: $e');
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
          debugPrint('Error deleting image after dispose: $e');
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
          debugPrint('Error deleting rejected image: $e');
        }
        if (mounted) {
          setState(() {
            _isCapturing = false;
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error capturing photo: $e');
      debugPrint('Stack trace: $stackTrace');
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
                // Image preview with rectangle frame matching ID field size
                _ImagePreviewWithFrame(image: image),
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
    final isNarrowScreen = screenWidth < 360;
    final padding = isNarrowScreen ? IDCameraCapturePage.horizontalPaddingNarrow : IDCameraCapturePage.horizontalPadding;
    final guideWidth = screenWidth - (2 * padding);

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
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
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
            child: Text(
              'Point your camera on your ${widget.title} and capture it.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),

          // Rectangular guide overlay (centered)
          Center(
            child: Container(
              width: guideWidth,
              height: IDCameraCapturePage.idFieldHeight,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.orange,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(4),
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

/// Widget for displaying image preview with rectangle frame in confirmation dialog
class _ImagePreviewWithFrame extends StatelessWidget {
  final XFile image;

  const _ImagePreviewWithFrame({required this.image});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 360;
    final padding = isNarrowScreen 
        ? IDCameraCapturePage.horizontalPaddingNarrow 
        : IDCameraCapturePage.horizontalPadding;
    final frameWidth = screenWidth - (2 * padding) - 32; // 32 for dialog padding
    final frameHeight = IDCameraCapturePage.idFieldHeight;

    return Container(
      width: frameWidth,
      height: frameHeight,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.orange,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1), // Slightly smaller to show border
        child: Image.file(
          File(image.path),
          width: frameWidth,
          height: frameHeight,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: frameWidth,
              height: frameHeight,
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
    );
  }
}

