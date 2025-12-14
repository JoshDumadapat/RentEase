import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/screens/profile/profile_page.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

const Color _themeColorDark = Color(0xFF00B8E6);
const Color _themeColor = Color(0xFF00D1FF);

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  CameraController? _cameraController;
  BarcodeScanner? _barcodeScanner;
  bool _isInitialized = false;
  bool _isProcessing = false;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    // Lock orientation to portrait for QR scanner
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _initializeCamera();
    _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
  }

  @override
  void dispose() {
    // Unlock orientation when leaving QR scanner
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _cameraController?.dispose();
    _barcodeScanner?.close();
    super.dispose();
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

      // Use back camera for QR scanning
      CameraDescription? selectedCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }
      selectedCamera ??= _cameras!.first;

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.nv21 
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startScanning();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error initializing camera: $e'),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _startScanning() {
    if (!_isInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessing) return;

      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage == null) return;

        final barcodes = await _barcodeScanner!.processImage(inputImage);
        
        if (barcodes.isNotEmpty && mounted && !_isProcessing) {
          _isProcessing = true;
          final barcode = barcodes.first;
          if (barcode.rawValue != null) {
            await _handleScannedQR(barcode.rawValue!);
          }
        }
      } catch (e) {
        // Ignore processing errors
      }
    });
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    try {
      // Convert CameraImage to InputImage for ML Kit
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // Determine rotation based on camera sensor orientation
      InputImageRotation rotation = InputImageRotation.rotation0deg;
      if (_cameraController != null) {
        final sensorOrientation = _cameraController!.description.sensorOrientation;
        switch (sensorOrientation) {
          case 90:
            rotation = InputImageRotation.rotation90deg;
            break;
          case 180:
            rotation = InputImageRotation.rotation180deg;
            break;
          case 270:
            rotation = InputImageRotation.rotation270deg;
            break;
          default:
            rotation = InputImageRotation.rotation0deg;
        }
      }
      
      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleScannedQR(String qrData) async {
    try {
      // Stop scanning
      await _cameraController?.stopImageStream();
      
      // Extract user ID from URL
      // Expected format: https://rentease.app/profile/{userId}
      String? userId;
      if (qrData.contains('rentease.app/profile/')) {
        final parts = qrData.split('rentease.app/profile/');
        if (parts.length > 1) {
          userId = parts[1].split('/').first.split('?').first;
        }
      } else if (qrData.startsWith('profile/')) {
        userId = qrData.split('profile/')[1].split('/').first.split('?').first;
      } else {
        // Assume it's a direct user ID
        userId = qrData.trim();
      }

      if (userId == null || userId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(context, 'Invalid QR code format'),
          );
          _resumeScanning();
        }
        return;
      }

      // Fetch user data
      final userService = BUserService();
      final userData = await userService.getUserData(userId);

      if (userData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(context, 'User profile not found'),
          );
          _resumeScanning();
        }
        return;
      }

      // Build UserModel
      final user = UserModel.fromFirestore(userData, userId);

      if (mounted) {
        // Navigate to profile page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ProfilePage(userId: userId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error processing QR code: $e'),
        );
        _resumeScanning();
      }
    }
  }

  void _resumeScanning() {
    setState(() {
      _isProcessing = false;
    });
    _startScanning();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const scanBoxSize = 250.0; // Size of the scanning box
    const cornerRadius = 24.0; // Rounded corners like Instagram
    final scanBoxTop = (screenSize.height - scanBoxSize) / 2;

    return Scaffold(
      body: _isInitialized && _cameraController != null
          ? Stack(
              children: [
                // Full-screen camera preview
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),

                // Dimmed overlay with transparent cutout for scanning box
                CustomPaint(
                  painter: _ScanOverlayPainter(
                    scanBoxSize: scanBoxSize,
                    scanBoxTop: scanBoxTop,
                  ),
                  child: Container(),
                ),

                // App Bar (transparent background)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        const Text(
                          'Scan QR Code',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48), // Balance the close button
                      ],
                    ),
                  ),
                ),

                // 4 Corner markers (L-shaped brackets) with rounded corners
                Positioned(
                  top: scanBoxTop,
                  left: (screenSize.width - scanBoxSize) / 2,
                  child: SizedBox(
                    width: scanBoxSize,
                    height: scanBoxSize,
                    child: Stack(
                      children: [
                        // Top-left corner (L-shape with rounded edges)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(cornerRadius),
                              ),
                              border: const Border(
                                top: BorderSide(color: Colors.white, width: 4),
                                left: BorderSide(color: Colors.white, width: 4),
                              ),
                            ),
                          ),
                        ),
                        // Top-right corner (L-shape with rounded edges)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(cornerRadius),
                              ),
                              border: const Border(
                                top: BorderSide(color: Colors.white, width: 4),
                                right: BorderSide(color: Colors.white, width: 4),
                              ),
                            ),
                          ),
                        ),
                        // Bottom-left corner (L-shape with rounded edges)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(cornerRadius),
                              ),
                              border: const Border(
                                bottom: BorderSide(color: Colors.white, width: 4),
                                left: BorderSide(color: Colors.white, width: 4),
                              ),
                            ),
                          ),
                        ),
                        // Bottom-right corner (L-shape with rounded edges)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(cornerRadius),
                              ),
                              border: const Border(
                                bottom: BorderSide(color: Colors.white, width: 4),
                                right: BorderSide(color: Colors.white, width: 4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Instructions at the bottom
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Position the QR code within the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          : Scaffold(
              backgroundColor: Colors.black,
              body: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
    );
  }
}

/// Custom painter for dimmed overlay with transparent cutout and gradient
class _ScanOverlayPainter extends CustomPainter {
  final double scanBoxSize;
  final double scanBoxTop;

  _ScanOverlayPainter({
    required this.scanBoxSize,
    required this.scanBoxTop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Cutout for scanning box (center) with rounded corners like Instagram
    final scanBoxLeft = (size.width - scanBoxSize) / 2;
    const cornerRadius = 24.0; // Rounded corners like Instagram
    
    final cutoutRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        scanBoxLeft,
        scanBoxTop,
        scanBoxSize,
        scanBoxSize,
      ),
      const Radius.circular(cornerRadius),
    );

    // Create gradient for the overlay background
    // Using theme colors from share profile page with lower opacity
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _themeColor.withOpacity(0.3), // Light blue with lower opacity
        _themeColorDark.withOpacity(0.4), // Darker blue with lower opacity
        Colors.black.withOpacity(0.5), // Dark at edges with lower opacity
      ],
    );

    // Create a rectangular clip for the entire screen
    final overlayRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Draw gradient overlay covering entire screen
    final overlayPaint = Paint()
      ..shader = gradient.createShader(overlayRect)
      ..style = PaintingStyle.fill;

    // Create path for the entire screen
    final path = Path()
      ..addRect(overlayRect);

    // Create cutout path with rounded corners
    final cutoutPath = Path()
      ..addRRect(cutoutRect);

    // Combine paths to create hole (cutout) with rounded corners
    final combinedPath = Path.combine(
      PathOperation.difference,
      path,
      cutoutPath,
    );

    canvas.drawPath(combinedPath, overlayPaint);
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter oldDelegate) {
    return oldDelegate.scanBoxSize != scanBoxSize ||
        oldDelegate.scanBoxTop != scanBoxTop;
  }
}
