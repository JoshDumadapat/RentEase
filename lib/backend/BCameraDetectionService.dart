// ignore_for_file: file_names
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Detection state for ID/face in camera
enum DetectionState {
  none,        // No ID detected
  far,         // ID detected but too far
  ready,       // ID detected, clear, and steady
}

/// Result from camera detection analysis
class DetectionResult {
  final DetectionState state;
  final String instruction;
  final bool shouldCapture;

  DetectionResult({
    required this.state,
    required this.instruction,
    this.shouldCapture = false,
  });
}

/// Backend service for camera detection and analysis
class BCameraDetectionService {
  StreamController<DetectionResult>? _streamController;
  img.Image? _previousFrame;
  int _steadyFrameCount = 0;
  int _frameCounter = 0; // Frame skipping counter
  bool _isProcessing = false; // Prevent concurrent processing
  final bool isFaceDetection; // true for face, false for ID
  static const int _steadyFrameThreshold = 6; // Reduced for faster detection
  static const double _fillThreshold = 0.25; // 25% of frame should be filled (more lenient for detection)
  static const int _frameSkipRate = 5; // Process every 5th frame to reduce lag significantly
  static const int _detectionScaleFactor = 2; // Downscale by 2x for faster processing while preserving features

  BCameraDetectionService({this.isFaceDetection = false});

  /// Start detecting ID/face in camera stream (optimized for performance)
  Stream<DetectionResult> startDetection(CameraController controller) {
    _streamController = StreamController<DetectionResult>();
    _frameCounter = 0;
    _isProcessing = false;

    // Start the image stream - process frames asynchronously with aggressive frame skipping
    controller.startImageStream((CameraImage cameraImage) async {
      _frameCounter++;
      
      // Skip frames for performance (process every Nth frame)
      if (_frameCounter % _frameSkipRate != 0) {
        return;
      }
      
      // Prevent concurrent processing
      if (_isProcessing) {
        return;
      }
      
      _isProcessing = true;
      
      // Process frame asynchronously to avoid blocking
      Future.microtask(() async {
        try {
          final result = await _analyzeFrame(cameraImage);
          if (_streamController != null && !_streamController!.isClosed) {
            _streamController!.add(result);
          }
        } catch (e) {
          // Silently handle errors - don't break the stream
        } finally {
          _isProcessing = false;
        }
      });
    });

    return _streamController!.stream;
  }

  /// Stop detecting and clean up
  void stopDetection(CameraController? controller) {
    _streamController?.close();
    _streamController = null;
    _previousFrame = null;
    _steadyFrameCount = 0;
    _frameCounter = 0;
    _isProcessing = false;
    
    try {
      controller?.stopImageStream();
    } catch (e) {
      // Ignore errors when stopping stream
    }
  }

  /// Analyze camera frame for ID detection
  Future<DetectionResult> _analyzeFrame(CameraImage cameraImage) async {
    try {
      // Convert CameraImage to Image
      final image = _convertCameraImageToImage(cameraImage);
      final noneInstruction = isFaceDetection 
          ? 'Place your face in the camera box'
          : 'Place your ID in the camera box';
      
      if (image == null) {
        return DetectionResult(
          state: DetectionState.none,
          instruction: noneInstruction,
        );
      }

      // Detect if ID/face is present (basic edge detection and contrast analysis)
      final hasID = _detectID(image);
      
      if (!hasID) {
        _steadyFrameCount = 0;
        return DetectionResult(
          state: DetectionState.none,
          instruction: noneInstruction,
        );
      }

      // Check if ID fills the frame enough (distance detection)
      final fillRatio = _calculateFillRatio(image);
      
      // Check if frame is steady (compare with previous frame)
      final isSteady = _checkSteady(image);
      
      // If ID is detected but too far (low fill ratio)
      if (fillRatio < _fillThreshold) {
        _steadyFrameCount = 0;
        return DetectionResult(
          state: DetectionState.far,
          instruction: 'Move the camera closer',
        );
      }
      
      // ID fills frame enough - check if steady
      if (isSteady) {
        _steadyFrameCount++;
        
        if (_steadyFrameCount >= _steadyFrameThreshold) {
          // Ready to capture - ID is clear, fills frame, and is steady
          return DetectionResult(
            state: DetectionState.ready,
            instruction: 'Hold it steady',
            shouldCapture: true,
          );
        } else {
          // Getting steady but not quite there yet
          return DetectionResult(
            state: DetectionState.ready,
            instruction: 'Hold it steady',
          );
        }
      } else {
        // ID is close enough but moving - reset steady count
        _steadyFrameCount = 0;
        return DetectionResult(
          state: DetectionState.far,
          instruction: 'Hold still',
        );
      }
    } catch (e) {
      return DetectionResult(
        state: DetectionState.none,
        instruction: 'Place your ID in the camera box',
      );
    }
  }

  /// Convert CameraImage to Image format (optimized with downscaling for performance)
  img.Image? _convertCameraImageToImage(CameraImage cameraImage) {
    try {
      img.Image? fullImage;
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        fullImage = _yuv420ToImage(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        fullImage = _bgra8888ToImage(cameraImage);
      } else {
        return null;
      }
      
      // Downscale image for faster processing (reduce resolution by scale factor)
      if (_detectionScaleFactor > 1) {
        final scaledWidth = fullImage.width ~/ _detectionScaleFactor;
        final scaledHeight = fullImage.height ~/ _detectionScaleFactor;
        return img.copyResize(fullImage, width: scaledWidth, height: scaledHeight);
      }
      
      return fullImage;
    } catch (e) {
      return null;
    }
  }

  /// Convert YUV420 format to Image
  img.Image _yuv420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final yBuffer = cameraImage.planes[0].bytes;
    final uBuffer = cameraImage.planes[1].bytes;
    final vBuffer = cameraImage.planes[2].bytes;

    final yStride = cameraImage.planes[0].bytesPerRow;
    final uStride = cameraImage.planes[1].bytesPerRow;
    final vStride = cameraImage.planes[2].bytesPerRow;

    final image = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yIndex = y * yStride + x;
        final uvY = y ~/ 2;
        final uvX = x ~/ 2;
        final uIndex = uvY * uStride + uvX;
        final vIndex = uvY * vStride + uvX;

        final yValue = yBuffer[yIndex];
        final uValue = uBuffer[uIndex];
        final vValue = vBuffer[vIndex];

        final r = _yuvToR(yValue, uValue, vValue);
        final g = _yuvToG(yValue, uValue, vValue);
        final b = _yuvToB(yValue, uValue, vValue);

        image.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }

    return image;
  }

  /// Convert BGRA8888 format to Image
  img.Image _bgra8888ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final buffer = cameraImage.planes[0].bytes;
    final stride = cameraImage.planes[0].bytesPerRow;

    final image = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = y * stride + x * 4;
        final b = buffer[index];
        final g = buffer[index + 1];
        final r = buffer[index + 2];
        final a = buffer[index + 3];

        image.setPixel(x, y, img.ColorRgba8(r, g, b, a));
      }
    }

    return image;
  }

  int _yuvToR(int y, int u, int v) {
    final r = (y + 1.402 * (v - 128)).clamp(0, 255).round();
    return r;
  }

  int _yuvToG(int y, int u, int v) {
    final g = (y - 0.344 * (u - 128) - 0.714 * (v - 128)).clamp(0, 255).round();
    return g;
  }

  int _yuvToB(int y, int u, int v) {
    final b = (y + 1.772 * (u - 128)).clamp(0, 255).round();
    return b;
  }

  /// Detect if ID is present in frame - STRICT detection for actual ID cards only
  /// This method identifies ID cards using multiple checks to avoid false positives
  bool _detectID(img.Image image) {
    // Skip ID detection for face mode - use simpler detection
    if (isFaceDetection) {
      return _detectFace(image);
    }
    
    try {
      final centerX = image.width ~/ 2;
      final centerY = image.height ~/ 2;
      final regionWidth = (image.width * 0.75).round();
      final regionHeight = (image.height * 0.75).round();
      final startX = (centerX - regionWidth / 2).round();
      final startY = (centerY - regionHeight / 2).round();

      // STRICT DETECTION: Require multiple strong indicators for actual ID cards
      
      // 1. Rectangular border (ID cards have clear edges)
      final borderScore = _detectRectangularBorder(image, startX, startY, regionWidth, regionHeight);
      
      // 2. Text patterns (IDs have text - this is REQUIRED)
      final textScore = _detectTextPatterns(image, startX, startY, regionWidth, regionHeight);
      final idTextScore = _detectIDTextPatterns(image, startX, startY, regionWidth, regionHeight);
      
      // 3. Aspect ratio (ID cards have specific proportions - REQUIRED)
      final aspectRatioScore = _detectIDAspectRatio(image, startX, startY, regionWidth, regionHeight);
      
      // PRODUCTION-SAFE THRESHOLDS - optimized for real-world mobile camera conditions
      final hasBorder = borderScore > 0.04; // Low threshold for border (accounts for glare/motion)
      final hasText = textScore > 0.05 || idTextScore > 0.06; // Low threshold for text (accounts for lighting/angle)
      final hasAspectRatio = aspectRatioScore > 0.10; // Low threshold for aspect ratio
      
      // RELAXED ACCEPTANCE: Accept if we have border OR text (not both required)
      // Real IDs often lose either border or text depending on angle/lighting/motion
      // Distance + steadiness checks later protect against false positives
      
      // Primary check: Accept if we have border OR text (either one is enough)
      if (hasBorder || hasText) {
        // If we have border OR text, it's likely an ID
        // This handles cases where glare kills border or lighting kills text
        return true; // Border OR text = ID card indicator
      }
      
      // Fallback: Accept if we have aspect ratio with any border/text signal
      // This allows plain IDs, IDs with glare, IDs with low print contrast
      if (hasAspectRatio && (borderScore > 0.04 || textScore > 0.04 || idTextScore > 0.04)) {
        return true; // Aspect ratio + any border/text signal = likely ID
      }
      
      // Fallback: Accept if we have strong border alone (IDs have clear edges)
      if (borderScore > 0.10 && hasAspectRatio) {
        return true; // Strong border + aspect ratio = likely ID
      }
      
      // Fallback: Accept if we have strong text alone (IDs have text)
      if ((textScore > 0.12 || idTextScore > 0.15) && hasAspectRatio) {
        return true; // Strong text + aspect ratio = likely ID
      }
      
      return false; // Not enough evidence = not an ID
    } catch (e) {
      return false;
    }
  }
  
  /// Detect ID card aspect ratio (standard IDs are ~1.4:1 to 1.7:1 ratio)
  double _detectIDAspectRatio(img.Image image, int startX, int startY, int width, int height) {
    try {
      // Find the actual card boundaries by detecting edges
      // Look for the most prominent rectangular region
      int topEdge = startY;
      int bottomEdge = startY + height;
      int leftEdge = startX;
      int rightEdge = startX + width;
      
      const edgeThreshold = 25;
      const sampleStep = 3;
      
      // Find top edge
      for (var y = startY; y < startY + height ~/ 3 && y < image.height - 1; y += sampleStep) {
        int edgeCount = 0;
        for (var x = startX; x < startX + width - 1 && x < image.width - 1; x += sampleStep) {
          final pixel = image.getPixel(x, y);
          final belowPixel = image.getPixel(x, (y + sampleStep).clamp(0, image.height - 1));
          if ((_getBrightness(pixel) - _getBrightness(belowPixel)).abs() > edgeThreshold) {
            edgeCount++;
          }
        }
        if (edgeCount > width ~/ (sampleStep * 4)) {
          topEdge = y;
          break;
        }
      }
      
      // Find bottom edge
      for (var y = startY + height - height ~/ 3; y >= startY && y < image.height - 1; y -= sampleStep) {
        int edgeCount = 0;
        for (var x = startX; x < startX + width - 1 && x < image.width - 1; x += sampleStep) {
          final pixel = image.getPixel(x, y);
          final abovePixel = image.getPixel(x, (y - sampleStep).clamp(0, image.height - 1));
          if ((_getBrightness(pixel) - _getBrightness(abovePixel)).abs() > edgeThreshold) {
            edgeCount++;
          }
        }
        if (edgeCount > width ~/ (sampleStep * 4)) {
          bottomEdge = y;
          break;
        }
      }
      
      // Find left edge
      for (var x = startX; x < startX + width ~/ 3 && x < image.width - 1; x += sampleStep) {
        int edgeCount = 0;
        for (var y = startY; y < startY + height - 1 && y < image.height - 1; y += sampleStep) {
          final pixel = image.getPixel(x, y);
          final rightPixel = image.getPixel((x + sampleStep).clamp(0, image.width - 1), y);
          if ((_getBrightness(pixel) - _getBrightness(rightPixel)).abs() > edgeThreshold) {
            edgeCount++;
          }
        }
        if (edgeCount > height ~/ (sampleStep * 4)) {
          leftEdge = x;
          break;
        }
      }
      
      // Find right edge
      for (var x = startX + width - width ~/ 3; x >= startX && x < image.width - 1; x -= sampleStep) {
        int edgeCount = 0;
        for (var y = startY; y < startY + height - 1 && y < image.height - 1; y += sampleStep) {
          final pixel = image.getPixel(x, y);
          final leftPixel = image.getPixel((x - sampleStep).clamp(0, image.width - 1), y);
          if ((_getBrightness(pixel) - _getBrightness(leftPixel)).abs() > edgeThreshold) {
            edgeCount++;
          }
        }
        if (edgeCount > height ~/ (sampleStep * 4)) {
          rightEdge = x;
          break;
        }
      }
      
      final cardWidth = (rightEdge - leftEdge).abs();
      final cardHeight = (bottomEdge - topEdge).abs();
      
      if (cardWidth < 20 || cardHeight < 20) return 0.0; // Too small to be a card
      
      final aspectRatio = cardWidth / cardHeight;
      
      // Standard ID cards have aspect ratio between 1.4:1 and 1.7:1
      // Credit card: ~1.59:1, Driver's license: ~1.55:1
      // More lenient range to catch IDs at different angles
      if (aspectRatio >= 1.2 && aspectRatio <= 2.0) {
        // Score based on how close to ideal ratio (1.55)
        const idealRatio = 1.55;
        final distance = (aspectRatio - idealRatio).abs();
        // More generous scoring - give points even if not perfect
        if (distance < 0.5) {
          return (1.0 - (distance / 0.5)).clamp(0.0, 1.0);
        } else if (distance < 0.8) {
          return 0.3; // Still acceptable
        }
        return 0.1; // Edge cases
      }
      
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }


  /// Detect ID-specific text patterns (dates, ID numbers, structured format)
  /// Works for both front and back of ID cards
  double _detectIDTextPatterns(img.Image image, int startX, int startY, int width, int height) {
    try {
      // ID cards (front and back) have specific text patterns:
      // 1. Multiple lines of text (names, addresses, instructions, etc.)
      // 2. Date patterns (MM/DD/YYYY, DD/MM/YYYY, or similar) - front ID
      // 3. Number sequences (ID numbers, barcodes) - both sides
      // 4. Label:Value format (e.g., "Name:", "Date of Birth:") - front ID
      // 5. Instructions, terms, or machine-readable zones - back ID
      
      const rowStep = 3;
      const pixelStep = 2;
      const lineThreshold = 26; // Slightly lower for back ID text detection
      
      // Check multiple regions for text (front ID: right side, back ID: can be anywhere)
      // Check right region (typical for front ID)
      final rightTextRegionX = startX + (width ~/ 3);
      final rightTextRegionY = startY + (height ~/ 5);
      final rightTextRegionWidth = width - (width ~/ 3);
      final rightTextRegionHeight = height - (height ~/ 5);
      
      // Check full center region (typical for back ID)
      final centerTextRegionX = startX + (width ~/ 5);
      final centerTextRegionY = startY + (height ~/ 6);
      final centerTextRegionWidth = width - (2 * (width ~/ 5));
      final centerTextRegionHeight = height - (2 * (height ~/ 6));
      
      // Scan right region (front ID text area)
      final rightTextLines = _countTextLinesInRegion(
        image, 
        rightTextRegionX, 
        rightTextRegionY, 
        rightTextRegionWidth, 
        rightTextRegionHeight,
        rowStep,
        pixelStep,
        lineThreshold,
      );
      
      // Scan center region (back ID text area - covers more area)
      final centerTextLines = _countTextLinesInRegion(
        image, 
        centerTextRegionX, 
        centerTextRegionY, 
        centerTextRegionWidth, 
        centerTextRegionHeight,
        rowStep,
        pixelStep,
        lineThreshold,
      );
      
      // Take the maximum (either region has text, it's an ID)
      // IDs should have at least 2-3 lines of structured text (even more lenient)
      final maxTextLines = rightTextLines > centerTextLines ? rightTextLines : centerTextLines;
      
      // More lenient - accept 2+ lines, give partial score
      if (maxTextLines >= 2) {
        return (maxTextLines / 5.0).clamp(0.2, 1.0); // Minimum 0.2 score if 2+ lines found
      }
      
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Helper: Count text lines in a specific region
  int _countTextLinesInRegion(
    img.Image image, 
    int regionX, 
    int regionY, 
    int regionWidth, 
    int regionHeight,
    int rowStep,
    int pixelStep,
    int lineThreshold,
  ) {
    int textLines = 0;
    
    for (var y = regionY; y < regionY + regionHeight - 5 && y < image.height - 1; y += rowStep) {
      int consecutiveContrast = 0;
      int maxConsecutive = 0;
      int contrastChanges = 0;
      
      for (var x = regionX; x < regionX + regionWidth - pixelStep && x < image.width - pixelStep; x += pixelStep) {
        final pixel = image.getPixel(x, y);
        final nextPixel = image.getPixel((x + pixelStep).clamp(0, image.width - 1), y);
        final brightness = _getBrightness(pixel);
        final nextBrightness = _getBrightness(nextPixel);
        
        if ((brightness - nextBrightness).abs() > lineThreshold) {
          consecutiveContrast += pixelStep;
          contrastChanges++;
          if (consecutiveContrast > maxConsecutive) {
            maxConsecutive = consecutiveContrast;
          }
        } else {
          consecutiveContrast = 0;
        }
      }
      
      final minLineLength = regionWidth ~/ 5; // More lenient minimum length
      if (maxConsecutive > minLineLength && contrastChanges > 6) {
        textLines++;
      }
    }
    
    return textLines;
  }

  
  /// Detect face using simpler pattern (for face detection mode) - optimized
  bool _detectFace(img.Image image) {
    try {
      final centerX = image.width ~/ 2;
      final centerY = image.height ~/ 2;
      final regionWidth = (image.width * 0.6).round();
      final regionHeight = (image.height * 0.6).round();
      final startX = (centerX - regionWidth / 2).round();
      final startY = (centerY - regionHeight / 2).round();

      int contrastPixels = 0;
      const threshold = 25;
      const sampleStep = 5; // Sample every 5th pixel for much faster processing

      for (var y = startY; y < startY + regionHeight && y < image.height - 1; y += sampleStep) {
        for (var x = startX; x < startX + regionWidth && x < image.width - 1; x += sampleStep) {
          final pixel = image.getPixel(x, y);
          final nextPixel = image.getPixel((x + sampleStep).clamp(0, image.width - 1), y);
          final brightness = _getBrightness(pixel);
          final nextBrightness = _getBrightness(nextPixel);
          
          if ((brightness - nextBrightness).abs() > threshold) {
            contrastPixels++;
          }
        }
      }

      final sampledPixels = (regionWidth / sampleStep) * (regionHeight / sampleStep);
      final contrastRatio = contrastPixels / sampledPixels;
      
      return contrastRatio > 0.08 && contrastRatio < 0.25;
    } catch (e) {
      return false;
    }
  }
  
  /// Detect rectangular border pattern typical of ID cards (optimized)
  double _detectRectangularBorder(img.Image image, int startX, int startY, int width, int height) {
    try {
      int borderEdgeCount = 0;
      const edgeThreshold = 28; // Lower threshold for better edge detection
      final borderMargin = (10 / _detectionScaleFactor).round().clamp(2, 8); // Scale margin
      const sampleStep = 2; // Sample every 2nd pixel for better accuracy
      
      // Check top and bottom horizontal borders (sampled)
      for (var y = startY; y < startY + height && y < image.height - 1; y += sampleStep) {
        final isNearBorder = (y - startY) < borderMargin || (startY + height - y) < borderMargin;
        if (!isNearBorder) continue;
        
        for (var x = startX; x < startX + width - 1 && x < image.width - 1; x += sampleStep) {
          final pixel = image.getPixel(x, y);
          final nextPixel = image.getPixel((x + sampleStep).clamp(0, image.width - 1), y);
          final brightness = _getBrightness(pixel);
          final nextBrightness = _getBrightness(nextPixel);
          
          if ((brightness - nextBrightness).abs() > edgeThreshold) {
            borderEdgeCount++;
          }
        }
      }
      
      // Check left and right vertical borders (sampled)
      for (var x = startX; x < startX + width && x < image.width - 1; x += sampleStep) {
        final isNearBorder = (x - startX) < borderMargin || (startX + width - x) < borderMargin;
        if (!isNearBorder) continue;
        
        for (var y = startY; y < startY + height - 1 && y < image.height - 1; y += sampleStep) {
          final pixel = image.getPixel(x, y);
          final belowPixel = image.getPixel(x, (y + sampleStep).clamp(0, image.height - 1));
          final brightness = _getBrightness(pixel);
          final belowBrightness = _getBrightness(belowPixel);
          
          if ((brightness - belowBrightness).abs() > edgeThreshold) {
            borderEdgeCount++;
          }
        }
      }
      
      final sampledBorderPixels = ((width / sampleStep) * borderMargin * 2) + ((height / sampleStep) * borderMargin * 2);
      return (borderEdgeCount / sampledBorderPixels).clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }
  
  /// Detect text-like horizontal patterns (typical of ID cards) - SIMPLIFIED AND MORE RELIABLE
  double _detectTextPatterns(img.Image image, int startX, int startY, int width, int height) {
    try {
      int textLineCount = 0;
      const lineThreshold = 25; // Lower threshold for easier text detection
      final minLineLength = width ~/ 6; // Even shorter lines acceptable
      const rowStep = 3; // Sample more rows for better coverage
      
      // Scan for horizontal lines (text rows) - sampled
      for (var y = startY + 3; y < startY + height - 3 && y < image.height - 1; y += rowStep) {
        int consecutiveContrast = 0;
        int maxConsecutive = 0;
        const pixelStep = 2; // Sample every 2nd pixel for better accuracy
        
        for (var x = startX; x < startX + width - pixelStep && x < image.width - pixelStep; x += pixelStep) {
          final pixel = image.getPixel(x, y);
          final nextPixel = image.getPixel((x + pixelStep).clamp(0, image.width - 1), y);
          final brightness = _getBrightness(pixel);
          final nextBrightness = _getBrightness(nextPixel);
          
          if ((brightness - nextBrightness).abs() > lineThreshold) {
            consecutiveContrast += pixelStep;
            if (consecutiveContrast > maxConsecutive) {
              maxConsecutive = consecutiveContrast;
            }
          } else {
            consecutiveContrast = 0;
          }
        }
        
        // If we found a long horizontal line, likely text
        if (maxConsecutive > minLineLength) {
          textLineCount++;
        }
      }
      
      // Very lenient - require at least 2 text lines
      // IDs can have varying amounts of text, so be very flexible
      final expectedLines = 2; // Lowered from 3
      // Return score based on text lines detected
      if (textLineCount == 0) return 0.0;
      // Give bonus score for detecting text
      return (textLineCount / expectedLines).clamp(0.15, 1.0); // Minimum 0.15 if text found
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate how much of the frame is filled (for distance detection) - optimized
  double _calculateFillRatio(img.Image image) {
    try {
      // Check center region for high contrast areas (where ID should be)
      final centerX = image.width ~/ 2;
      final centerY = image.height ~/ 2;
      final regionWidth = (image.width * 0.6).round(); // Focus on 60% center region
      final regionHeight = (image.height * 0.6).round();
      final startX = (centerX - regionWidth / 2).round();
      final startY = (centerY - regionHeight / 2).round();

      int filledPixels = 0;
      const minBrightness = 30; // Lower threshold - be more inclusive
      const maxBrightness = 220; // Higher max - accept more brightness variations
      const sampleStep = 2;

      for (var y = startY; y < startY + regionHeight && y < image.height; y += sampleStep) {
        for (var x = startX; x < startX + regionWidth && x < image.width; x += sampleStep) {
          final pixel = image.getPixel(x, y);
          final brightness = _getBrightness(pixel);
          
          // Check if pixel is in acceptable brightness range (ID card range)
          if (brightness >= minBrightness && brightness <= maxBrightness) {
            filledPixels++;
          }
        }
      }

      final totalSampledPixels = (regionWidth / sampleStep) * (regionHeight / sampleStep);
      return (filledPixels / totalSampledPixels).clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  /// Check if frame is steady (compare with previous frame) - optimized
  bool _checkSteady(img.Image currentImage) {
    if (_previousFrame == null) {
      _previousFrame = currentImage;
      return false;
    }

    try {
      // Compare key regions between frames
      final centerX = currentImage.width ~/ 2;
      final centerY = currentImage.height ~/ 2;
      const sampleSize = 30; // Reduced for faster processing
      final startX = (centerX - sampleSize / 2).round();
      final startY = (centerY - sampleSize / 2).round();

      int differences = 0;
      const threshold = 20; // Higher threshold for faster processing (fewer comparisons)

      for (var y = startY; y < startY + sampleSize && y < currentImage.height; y++) {
        for (var x = startX; x < startX + sampleSize && x < currentImage.width; x++) {
          final currentPixel = currentImage.getPixel(x, y);
          final previousPixel = _previousFrame!.getPixel(x, y);
          
          final currentBrightness = _getBrightness(currentPixel);
          final previousBrightness = _getBrightness(previousPixel);
          
          if ((currentBrightness - previousBrightness).abs() > threshold) {
            differences++;
          }
        }
      }

      _previousFrame = currentImage;
      
      final totalPixels = sampleSize * sampleSize;
      final differenceRatio = differences / totalPixels;
      
      // Frame is steady if difference is below threshold
      return differenceRatio < 0.20; // Increased threshold for faster steady detection
    } catch (e) {
      return false;
    }
  }

  /// Get brightness value from pixel
  int _getBrightness(img.Pixel pixel) {
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();
    return ((r + g + b) / 3).round();
  }
}
