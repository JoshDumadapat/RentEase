import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../backend/BCameraDetectionService.dart';
import '../utils/snackbar_utils.dart';

/// Camera page for capturing ID photos with rectangular guide overlay
class IDCameraCapturePage extends StatefulWidget {
  final String title; // e.g., "Front ID", "Back ID", "Face with ID"

  const IDCameraCapturePage({
    super.key,
    required this.title,
  });

  // ID field dimensions (matching the portrait rectangle in ID validation)
  // Portrait orientation: taller than wide
  static const double idFieldWidthRatio = 0.7; // 70% of screen width
  static const double idFieldHeightRatio = 0.45; // 45% of screen height
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
  BCameraDetectionService? _detectionService;
  StreamSubscription<DetectionResult>? _detectionSubscription;
  DetectionState _currentDetectionState = DetectionState.none;
  String _currentInstruction = 'Place your ID in the camera box';
  bool _autoCaptureTriggered = false;

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
            SnackBarUtils.buildThemedSnackBar(context, 'No cameras available'),
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
        // Start detection after camera is initialized
        _startDetection();
      }
    } catch (e) {
      // Error initializing camera
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error initializing camera: $e'),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _startDetection() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    _detectionService = BCameraDetectionService();
    _detectionSubscription = _detectionService!.startDetection(_controller!).listen(
      (result) {
        if (!mounted) return;
        
        setState(() {
          _currentDetectionState = result.state;
          _currentInstruction = result.instruction;
        });
        
        // Auto-capture when ready and not already triggered
        if (result.shouldCapture && !_autoCaptureTriggered && !_isCapturing) {
          _autoCaptureTriggered = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_isCapturing) {
              _capturePhoto();
            }
          });
        }
      },
      onError: (error) {
        // Silently handle errors - don't show to user
      },
    );
  }

  @override
  void dispose() {
    _detectionSubscription?.cancel();
    _detectionService?.stopDetection(_controller);
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
      
      // Get preview size safely
      Size? previewSize;
      try {
        if (_controller!.value.previewSize != null) {
          previewSize = _controller!.value.previewSize;
        }
      } catch (e) {
        // Error:'Error getting preview size: $e');
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
      
      // Calculate portrait rectangle dimensions on screen (matching ID validation cards)
      final guideWidth = screenWidth * IDCameraCapturePage.idFieldWidthRatio;
      final guideHeight = screenHeight * IDCameraCapturePage.idFieldHeightRatio;
      
      // Calculate rectangle position (centered both horizontally and vertically)
      final rectLeft = (screenWidth - guideWidth) / 2;
      final rectTop = (screenHeight - guideHeight) / 2;
      
      // Since we use FittedBox with BoxFit.cover, the preview fills the entire screen
      // So display dimensions are exactly screen dimensions with no offsets
      final displayWidth = screenWidth;
      final displayHeight = screenHeight;
      
      // Calculate the crop area in the original image coordinates
      // Map screen coordinates (0 to screenWidth/Height) to image coordinates (0 to imageWidth/Height)
      final relativeLeft = rectLeft / displayWidth;
      final relativeTop = rectTop / displayHeight;
      final relativeWidth = guideWidth / displayWidth;
      final relativeHeight = guideHeight / displayHeight;
      
      // Account for BoxFit.cover: the image may be scaled and cropped
      // We need to find what part of the original image is visible on screen
      final previewAspectRatio = previewSize.height / previewSize.width;
      final screenAspectRatio = screenHeight / screenWidth;
      
      // Determine if image is cropped horizontally or vertically
      double visibleImageWidth = originalImg.width.toDouble();
      double visibleImageHeight = originalImg.height.toDouble();
      double imageOffsetX = 0;
      double imageOffsetY = 0;
      
      if (previewAspectRatio > screenAspectRatio) {
        // Image is taller, cropped on sides
        visibleImageHeight = originalImg.height.toDouble();
        visibleImageWidth = visibleImageHeight / screenAspectRatio;
        imageOffsetX = (originalImg.width - visibleImageWidth) / 2;
      } else {
        // Image is wider, cropped on top/bottom
        visibleImageWidth = originalImg.width.toDouble();
        visibleImageHeight = visibleImageWidth * screenAspectRatio;
        imageOffsetY = (originalImg.height - visibleImageHeight) / 2;
      }
      
      // Map relative coordinates to actual image coordinates
      final cropX = (imageOffsetX + relativeLeft * visibleImageWidth).round();
      final cropY = (imageOffsetY + relativeTop * visibleImageHeight).round();
      final cropWidth = (relativeWidth * visibleImageWidth).round();
      final cropHeight = (relativeHeight * visibleImageHeight).round();
      
      // Ensure values are within bounds
      final finalCropX = cropX.clamp(0, originalImg.width - 1);
      final finalCropY = cropY.clamp(0, originalImg.height - 1);
      final finalCropWidth = cropWidth.clamp(1, originalImg.width - finalCropX);
      final finalCropHeight = cropHeight.clamp(1, originalImg.height - finalCropY);
      
      // Crop the image
      final croppedImg = img.copyCrop(
        originalImg,
        x: finalCropX,
        y: finalCropY,
        width: finalCropWidth,
        height: finalCropHeight,
      );
      
      // Save cropped image
      final croppedBytes = img.encodeJpg(croppedImg, quality: 85);
      final tempDir = await getTemporaryDirectory();
      final croppedPath = '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(croppedBytes);
      
      // Delete original temporary file
      try {
        final originalFile = File(originalImage.path);
        if (await originalFile.exists()) {
          await originalFile.delete();
        }
      } catch (e) {
        // Error:'Error deleting original image: $e');
      }
      
      return XFile(croppedPath);
    } catch (e) {
      // Error cropping image
      return originalImage; // Return original if cropping fails
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || !mounted) {
      return;
    }

    if (_isCapturing) return;

    if (!mounted) return;
    
    // Stop detection before capturing
    _detectionSubscription?.cancel();
    _detectionService?.stopDetection(_controller);
    
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
          // Error:'Error deleting image after dispose: $e');
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
            // Error:'Error deleting cropped image after dispose: $e');
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
          // Error:'Error deleting image after dispose: $e');
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
          // Error:'Error deleting rejected image: $e');
        }
        if (mounted) {
          setState(() {
            _isCapturing = false;
          });
          // Restart detection after user rejection
          _autoCaptureTriggered = false;
          _startDetection();
        }
      }
    } catch (e) {
      // Error capturing photo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error capturing photo: $e'),
        );
        setState(() {
          _isCapturing = false;
        });
        // Restart detection after error
        _autoCaptureTriggered = false;
        _startDetection();
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
    final screenHeight = MediaQuery.of(context).size.height;
    // Portrait rectangle dimensions matching ID validation cards
    final guideWidth = screenWidth * IDCameraCapturePage.idFieldWidthRatio;
    final guideHeight = screenHeight * IDCameraCapturePage.idFieldHeightRatio;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
        child: Stack(
          children: [
            // Camera preview - normal display, fill screen
            if (_isInitialized && _controller != null)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.previewSize?.height ?? 1,
                    height: _controller!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_controller!),
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),


          // Full white overlay outside capture area (100% opacity)
          CustomPaint(
            size: Size(screenWidth, screenHeight),
            painter: _OverlayPainter(
              captureRect: Rect.fromCenter(
                center: Offset(screenWidth / 2, screenHeight / 2),
                width: guideWidth,
                height: guideHeight,
              ),
            ),
          ),

          // Top section with white container, black text and black button - ON TOP OF WHITE OVERLAY
          // Extended to top with some spacing
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 12,
              left: 16,
              right: 16,
            ),
            color: Colors.white,
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header - Black text
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Subheader - Black text
                        Text(
                          widget.title.toLowerCase().contains('front')
                              ? 'Position the front side of your ID'
                              : 'Position the back side of your ID',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button - Black icon, aligned with header
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    alignment: Alignment.center,
                  ),
                ],
              ),
          ),

          // Portrait rectangular guide overlay (centered) with dashed border and curved edges
          Center(
            child: SizedBox(
              width: guideWidth,
              height: guideHeight,
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  borderRadius: 16,
                  color: _currentDetectionState == DetectionState.ready 
                      ? Colors.green 
                      : Colors.orange,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),

          // Instructions below the camera guide box (width aligned with camera bbox)
          Positioned(
            top: (screenHeight / 2) + (guideHeight / 2) + 20,
            left: (screenWidth - guideWidth) / 2,
            child: Container(
              width: guideWidth,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5), // Lighter opacity
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _currentInstruction,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentDetectionState == DetectionState.ready
                        ? 'Keep holding steady...'
                        : 'Ensure all edges are visible and text is clear',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[300],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
    ));
  }
}

/// Custom painter for white overlay outside capture area
class _OverlayPainter extends CustomPainter {
  final Rect captureRect;

  _OverlayPainter({required this.captureRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white // 100% opacity white
      ..style = PaintingStyle.fill;

    // Create path that covers entire screen except capture area
    // Leave top safe area clear for header
    final topSafeArea = 80.0; // Approximate safe area for header
    final path = Path()
      ..addRect(Rect.fromLTWH(0, topSafeArea, size.width, size.height - topSafeArea));

    // Subtract the capture rectangle with rounded corners (make it transparent)
    final capturePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          captureRect,
          const Radius.circular(16),
        ),
      );

    final combinedPath = Path.combine(
      PathOperation.difference,
      path,
      capturePath,
    );

    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for solid border with curved edges
class _DashedBorderPainter extends CustomPainter {
  final double borderRadius;
  final Color color;
  final double strokeWidth;

  _DashedBorderPainter({
    required this.borderRadius,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    // Draw solid border
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget for displaying image preview with rectangle frame in confirmation dialog
class _ImagePreviewWithFrame extends StatelessWidget {
  final XFile image;

  const _ImagePreviewWithFrame({required this.image});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final frameWidth = screenWidth * IDCameraCapturePage.idFieldWidthRatio * 0.8; // Slightly smaller for dialog
    final frameHeight = screenHeight * IDCameraCapturePage.idFieldHeightRatio * 0.8;

    return Container(
      width: frameWidth,
      height: frameHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.file(
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
            // Dashed border overlay
            CustomPaint(
              size: Size(frameWidth, frameHeight),
              painter: _DashedBorderPainter(
                borderRadius: 16,
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

