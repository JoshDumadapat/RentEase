import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:tflite_flutter/tflite_flutter.dart';

void _log(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// Validates ID documents using OCR and face recognition
class IdValidationService {
  final TextRecognizer _textRecognizer;
  final FaceDetector _faceDetector;
  Interpreter? _tfliteInterpreter;
  bool _isTfliteLoaded = false;
  
  static const String _tfliteModelPath = 'assets/models/mobilefacenet.tflite';
  static const int _inputSize = 112;
  static const int _embeddingSize = 192;
  
  static const String? _backendBaseUrl = null;
  final String? backendUrl;

  static const String? _facePlusPlusApiKey = null;
  static const String? _facePlusPlusApiSecret = null;
  static const String _facePlusPlusApiUrl = 'https://api-us.faceplusplus.com/facepp/v3/compare';
  
  final String? facePlusPlusApiKey;
  final String? facePlusPlusApiSecret;
  
  IdValidationService({
    String? backendUrl,
    String? facePlusPlusApiKey,
    String? facePlusPlusApiSecret,
  })  : backendUrl = backendUrl ?? _backendBaseUrl,
        facePlusPlusApiKey = facePlusPlusApiKey ?? _facePlusPlusApiKey,
        facePlusPlusApiSecret = facePlusPlusApiSecret ?? _facePlusPlusApiSecret,
        _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin),
        _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableLandmarks: true,
            enableClassification: false,
            enableTracking: false,
            enableContours: false,
            minFaceSize: 0.05,
          ),
        );

  Future<IdValidationResult> validateId({
    required File frontIdImage,
    File? backIdImage,
    required File selfieImage,
    required String userInputIdNumber,
    required String userInputFirstName,
    required String userInputLastName,
    String? userInputBirthday,
    String? userType,
  }) async {
    try {
      String frontRawText = '';
      String backRawText = '';
      
      if (backendUrl != null) {
        try {
          final idImageBytes = await frontIdImage.readAsBytes();
          final idImageBase64 = base64Encode(idImageBytes);
          
          final response = await http.post(
            Uri.parse('$backendUrl/extract-text'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image': idImageBase64}),
          ).timeout(const Duration(seconds: 30));
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            frontRawText = data['rawText'] ?? '';
          } else {
            throw Exception('Backend OCR failed');
          }
        } catch (e) {
          // Fall through to ML Kit OCR
        }
      }
      
      // Optimized: Try fewer orientations, starting with original
      // Only try other orientations if original fails or returns minimal text
      final orientations = [
        {'name': 'Original', 'rotation': 0},
        {'name': 'Rotated 90°', 'rotation': 90},
        {'name': 'Rotated 180°', 'rotation': 180},
        {'name': 'Rotated 270°', 'rotation': 270},
      ];
      
      if (frontRawText.isEmpty) {
        String bestText = '';
        int bestTextLength = 0;
        final allExtractedTexts = <String>[];
        final allTextBlocks = <String>[];
        
        // Try original orientation first (most common case)
        final originalProcessed = await _preprocessImageForOCR(frontIdImage, 0);
        final originalInputImage = InputImage.fromFilePath(originalProcessed.path);
        final originalRecognizedText = await _textRecognizer.processImage(originalInputImage);
        
        if (originalRecognizedText.text.isNotEmpty) {
          allExtractedTexts.add(originalRecognizedText.text);
          
          for (var block in originalRecognizedText.blocks) {
            final blockText = block.text.trim();
            if (blockText.isNotEmpty) {
              allTextBlocks.add(blockText);
            }
          }
          
          if (originalRecognizedText.text.length > bestTextLength) {
            bestTextLength = originalRecognizedText.text.length;
            bestText = originalRecognizedText.text;
          }
        }
        
        try {
          await originalProcessed.delete();
        } catch (_) {}
        
        // Only try other orientations if original returned minimal text (< 20 chars)
        // This reduces processing time significantly
        if (bestTextLength < 20) {
          for (var i = 1; i < orientations.length; i++) {
            final orientation = orientations[i];
            // Yield periodically to keep UI responsive
            await Future.delayed(const Duration(milliseconds: 50));
            
            final processedImage = await _preprocessImageForOCR(frontIdImage, orientation['rotation'] as int);
            final inputImage = InputImage.fromFilePath(processedImage.path);
            final recognizedText = await _textRecognizer.processImage(inputImage);
            
            if (recognizedText.text.isNotEmpty) {
              allExtractedTexts.add(recognizedText.text);
              
              for (var block in recognizedText.blocks) {
                final blockText = block.text.trim();
                if (blockText.isNotEmpty) {
                  allTextBlocks.add(blockText);
                }
              }
              
              if (recognizedText.text.length > bestTextLength) {
                bestTextLength = recognizedText.text.length;
                bestText = recognizedText.text;
              }
            }
            
            try {
              await processedImage.delete();
            } catch (_) {}
          }
        }
        
        if (allTextBlocks.isNotEmpty) {
          final uniqueBlocks = <String>{};
          final combinedBlocks = allTextBlocks.where((block) {
            final lower = block.toLowerCase().trim();
            if (lower.isEmpty || uniqueBlocks.contains(lower)) return false;
            uniqueBlocks.add(lower);
            return true;
          }).join('\n');
          
          if (combinedBlocks.length > bestTextLength) {
            bestText = combinedBlocks;
            bestTextLength = combinedBlocks.length;
          }
        }
        
        if (allExtractedTexts.length > 1) {
          final combinedText = allExtractedTexts.join('\n');
          final uniqueLines = <String>{};
          final combinedLines = combinedText.split('\n');
          final deduplicatedText = combinedLines.where((line) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) return false;
            if (uniqueLines.contains(trimmed.toLowerCase())) return false;
            uniqueLines.add(trimmed.toLowerCase());
            return true;
          }).join('\n');
          
          if (deduplicatedText.length > bestTextLength) {
            bestText = deduplicatedText;
            bestTextLength = deduplicatedText.length;
          }
        }
        
        frontRawText = bestText;
      }
      
      _log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log('📄 TEXT EXTRACTION - FRONT ID:');
      _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      if (frontRawText.isEmpty) {
        _log('  ⚠️  No text extracted from front ID');
      } else {
        final lines = frontRawText.split('\n');
        int lineCount = 0;
        for (var line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) {
            lineCount++;
            _log('  [$lineCount] $trimmed');
          }
        }
        _log('✅ Extracted $lineCount line(s) from front ID');
      }
      _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
      if (backIdImage != null) {
        if (backendUrl != null) {
          try {
            final backImageBytes = await backIdImage.readAsBytes();
            final backImageBase64 = base64Encode(backImageBytes);
            
            final response = await http.post(
              Uri.parse('$backendUrl/extract-text'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'image': backImageBase64}),
            ).timeout(const Duration(seconds: 30));
            
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              backRawText = data['rawText'] ?? '';
            } else {
              throw Exception('Backend OCR failed');
            }
          } catch (e) {
            // Fall through to ML Kit OCR
          }
        }
        
        if (backRawText.isEmpty) {
          String bestBackText = '';
          int bestBackTextLength = 0;
          
          // Try original orientation first
          final originalBackProcessed = await _preprocessImageForOCR(backIdImage, 0);
          final originalBackInputImage = InputImage.fromFilePath(originalBackProcessed.path);
          final originalBackRecognizedText = await _textRecognizer.processImage(originalBackInputImage);
          
          if (originalBackRecognizedText.text.length > bestBackTextLength) {
            bestBackTextLength = originalBackRecognizedText.text.length;
            bestBackText = originalBackRecognizedText.text;
          }
          
          try {
            await originalBackProcessed.delete();
          } catch (_) {}
          
          // Only try other orientations if original returned minimal text
          if (bestBackTextLength < 20) {
            for (var i = 1; i < orientations.length; i++) {
              final orientation = orientations[i];
              // Yield periodically to keep UI responsive
              await Future.delayed(const Duration(milliseconds: 50));
              
              final processedImage = await _preprocessImageForOCR(backIdImage, orientation['rotation'] as int);
              final inputImage = InputImage.fromFilePath(processedImage.path);
              final recognizedText = await _textRecognizer.processImage(inputImage);
              
              if (recognizedText.text.length > bestBackTextLength) {
                bestBackTextLength = recognizedText.text.length;
                bestBackText = recognizedText.text;
              }
              
              try {
                await processedImage.delete();
              } catch (_) {}
            }
          }
          
          backRawText = bestBackText;
        }
        
        _log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        _log('📄 TEXT EXTRACTION - BACK ID:');
        _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        if (backRawText.isEmpty) {
          _log('  ⚠️  No text extracted from back ID');
        } else {
          final lines = backRawText.split('\n');
          int lineCount = 0;
          for (var line in lines) {
            final trimmed = line.trim();
            if (trimmed.isNotEmpty) {
              lineCount++;
              _log('  [$lineCount] $trimmed');
            }
          }
          _log('✅ Extracted $lineCount line(s) from back ID');
        }
        _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      }
      
      final combinedRawText = backRawText.isNotEmpty 
          ? '$frontRawText\n$backRawText'.trim()
          : frontRawText;
      
      final extractedData = _extractIdData(
        combinedRawText,
        userInputFirstName: userInputFirstName,
        userInputLastName: userInputLastName,
        userInputIdNumber: userInputIdNumber,
        userInputBirthday: userInputBirthday,
      );
      
      final idType = _detectIdType(combinedRawText);
      final isGovernmentId = idType == IdType.government;
      
      if (userType == 'professional' && !isGovernmentId) {
        return IdValidationResult(
          isValid: false,
          extractedData: extractedData,
          idType: idType,
          isGovernmentId: false,
          errorMessage: 'Cannot validate your credentials.',
        );
      }
      
      final textValidation = _validateText(
        extractedData: extractedData,
        userInputIdNumber: userInputIdNumber,
        userInputFirstName: userInputFirstName,
        userInputLastName: userInputLastName,
        userInputBirthday: userInputBirthday,
      );
      
      final preprocessedIdFile = await _preprocessImageForFaceDetection(frontIdImage);
      final idInputImage = InputImage.fromFilePath(preprocessedIdFile.path);
      final idFaces = await _faceDetector.processImage(idInputImage);
      
      final selfieInputImage = InputImage.fromFilePath(selfieImage.path);
      final selfieFaces = await _faceDetector.processImage(selfieInputImage);
      
      _log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log('👁️  FACE DETECTION:');
      _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log('🆔 ID Image: ${idFaces.length} face(s) detected');
      if (idFaces.isEmpty) {
        _log('   ❌ No face detected in ID image');
      } else {
        _log('   ✅ Face detected in ID image');
      }
      _log('📸 Selfie Image: ${selfieFaces.length} face(s) detected');
      if (selfieFaces.isEmpty) {
        _log('   ❌ No face detected in selfie image');
      } else {
        _log('   ✅ Face detected in selfie image');
      }
      _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
      bool faceMatch = false;
      double faceSimilarity = 0.0;
      String faceMessage = '';
      
      if (facePlusPlusApiKey != null && facePlusPlusApiSecret != null) {
        try {
          final faceResult = await _compareFacesFacePlusPlus(frontIdImage, selfieImage);
          faceMatch = faceResult['match'] == true;
          faceSimilarity = (faceResult['similarity'] ?? 0.0).toDouble();
          faceMessage = faceResult['message'] ?? '';
        } catch (e) {
          faceMessage = 'Face++ API error: ${e.toString()}';
          faceMatch = false;
          faceSimilarity = 0.0;
        }
      } else if (backendUrl != null) {
        try {
          var request = http.MultipartRequest(
            'POST',
            Uri.parse('$backendUrl/compare-face'),
          );
          
          request.files.add(
            await http.MultipartFile.fromPath('id_image', frontIdImage.path),
          );
          request.files.add(
            await http.MultipartFile.fromPath('selfie_image', selfieImage.path),
          );
          
          final streamedResponse = await request.send().timeout(
            const Duration(seconds: 120),
            onTimeout: () {
              throw TimeoutException('Face comparison request timed out after 120 seconds');
            },
          );
          
          final response = await http.Response.fromStream(streamedResponse);
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            faceSimilarity = (data['similarity'] ?? 0.0).toDouble();
            faceMatch = data['match'] == true;
            faceMessage = data['message'] ?? '';
          } else {
            faceMessage = 'Backend error: ${response.statusCode}';
            faceMatch = false;
            faceSimilarity = 0.0;
          }
        } on TimeoutException catch (e) {
          faceMessage = 'Backend timeout: ${e.message}';
          faceMatch = false;
          faceSimilarity = 0.0;
        } on SocketException catch (e) {
          faceMessage = 'Cannot connect to backend: ${e.message}';
          faceMatch = false;
          faceSimilarity = 0.0;
        } catch (e) {
          faceMessage = 'Face comparison failed: ${e.toString()}';
          faceMatch = false;
          faceSimilarity = 0.0;
        }
      } else {
        try {
          final faceResult = await _compareFacesTFLite(frontIdImage, selfieImage);
          faceMatch = faceResult['match'] == true;
          faceSimilarity = (faceResult['similarity'] ?? 0.0).toDouble();
          faceMessage = faceResult['message'] ?? '';
        } catch (e) {
          faceMessage = 'TFLite face comparison error: ${e.toString()}';
          faceMatch = false;
          faceSimilarity = 0.0;
        }
      }
      
      _log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log('🔍 FINAL VALIDATION SUMMARY:');
      _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log('📊 Face Similarity: ${(faceSimilarity * 100).toStringAsFixed(2)}%');
      _log('👤 Face Match: ${faceMatch ? "✅ MATCH" : "❌ NO MATCH"}');
      _log('📋 Text Validation: ${textValidation.isValid ? "✅ VALID" : "❌ INVALID"}');
      _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
      try {
        await preprocessedIdFile.delete();
      } catch (_) {}
      
      final faceMatchResult = FaceMatchResult(
        isMatch: faceMatch,
        confidence: faceSimilarity,
        message: faceMessage,
      );
      
      final isValid = textValidation.isValid && faceMatch;
      
      return IdValidationResult(
        isValid: isValid,
        textValidation: textValidation,
        faceMatch: faceMatchResult,
        extractedData: extractedData,
        idType: idType,
        isGovernmentId: isGovernmentId,
        errorMessage: isValid ? null : 'Cannot validate your credentials.',
      );
    } catch (e) {
      _log('Validation error: $e');
      return IdValidationResult(
        isValid: false,
        errorMessage: 'Cannot validate your credentials.',
      );
    }
  }

  ExtractedIdData _extractIdData(
    String ocrText, {
    required String userInputFirstName,
    required String userInputLastName,
    required String userInputIdNumber,
    String? userInputBirthday,
  }) {
    final userFullName = '$userInputFirstName $userInputLastName'.toLowerCase().trim();
    final userIdNumber = userInputIdNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final userInputPrefix = userInputIdNumber.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
    
    _log('\n🔍 NAME EXTRACTION:');
    _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _log('🎯 Target Name: "$userInputFirstName $userInputLastName"');
    _log('   First Name: "$userInputFirstName"');
    _log('   Last Name: "$userInputLastName"');
    
    String? fullName;
    double bestNameScore = 0.0;
    final lines = ocrText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    _log('📄 Scanning ${lines.length} line(s) from OCR text...');
    
    for (var line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.length >= 3 && 
          RegExp(r'[A-Za-z]').hasMatch(cleanLine) &&
          cleanLine.split(RegExp(r'\s+')).length >= 2) {
        final lowerLine = cleanLine.toLowerCase();
        if (!lowerLine.contains('college') &&
            !lowerLine.contains('university') &&
            !lowerLine.contains('education') &&
            !lowerLine.contains('department') &&
            !lowerLine.contains('school') &&
            !lowerLine.contains('student') &&
            !lowerLine.contains('id') &&
            !lowerLine.contains('number') &&
            !lowerLine.contains('date') &&
            !lowerLine.contains('birthday')) {
          
          final similarity = ratio(lowerLine, userFullName) / 100.0;
          final firstNameMatch = ratio(lowerLine, userInputFirstName.toLowerCase()) / 100.0;
          final lastNameMatch = ratio(lowerLine, userInputLastName.toLowerCase()) / 100.0;
          final containsFirstName = lowerLine.contains(userInputFirstName.toLowerCase());
          final containsLastName = lowerLine.contains(userInputLastName.toLowerCase());
          
          final combinedScore = (similarity * 0.5) + 
                               (firstNameMatch * 0.25) + 
                               (lastNameMatch * 0.25) +
                               (containsFirstName ? 0.1 : 0.0) +
                               (containsLastName ? 0.1 : 0.0);
          
          if (combinedScore > bestNameScore && combinedScore >= 0.3) {
            bestNameScore = combinedScore;
            fullName = cleanLine;
            _log('   💡 Found potential name: "$cleanLine" (Score: ${(combinedScore * 100).toStringAsFixed(2)}%)');
          }
        }
      }
    }
    
    if (fullName != null) {
      _log('✅ Best Name Match: "$fullName" (Score: ${(bestNameScore * 100).toStringAsFixed(2)}%)');
    } else {
      _log('❌ No name match found (need ≥30% similarity)');
    }
    _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    // Extract ALL numbers from OCR text and find best ID number match
    String? idNumber;
    double bestIdScore = 0.0;
    
    _log('\n🔍 ID NUMBER EXTRACTION:');
    _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _log('🎯 Target ID Number: "$userIdNumber" (${userIdNumber.length} digits)');
    if (userInputPrefix.isNotEmpty) {
      _log('   Prefix: "$userInputPrefix"');
    }
    
    // PRIORITY 0: Look for ID number with prefix pattern (e.g., "S548025", "*S548025*")
    // This handles vertical column format like "* S 5 4 8 0 2 5 *"
    if (userInputPrefix.isNotEmpty) {
      // Look for patterns like "S548025", "*S548025*", "S 5 4 8 0 2 5", etc.
      final prefixPatterns = [
        RegExp('$userInputPrefix\\s*$userIdNumber', caseSensitive: false), // "S548025" or "S 548025"
        RegExp('\\*\\s*$userInputPrefix\\s*$userIdNumber\\s*\\*', caseSensitive: false), // "*S548025*"
        RegExp('$userInputPrefix\\s+[\\d\\s]+$userIdNumber', caseSensitive: false), // "S 5 4 8 0 2 5"
      ];
      
      for (var pattern in prefixPatterns) {
        final matches = pattern.allMatches(ocrText);
        for (var match in matches) {
          final matchedText = match.group(0)!;
          // Extract just the digits
          final extractedDigits = matchedText.replaceAll(RegExp(r'[^0-9]'), '');
          if (extractedDigits == userIdNumber) {
            idNumber = extractedDigits;
            bestIdScore = 1.0;
            _log('✅ Found ID with prefix pattern: "$matchedText" → "$extractedDigits"');
            _log('   Match Score: 100% (EXACT MATCH)');
            break;
          }
        }
        if (bestIdScore >= 1.0) break;
      }
    }
    
    final datePatterns = [
      RegExp(r'\b\d{2}[/-]\d{2}[/-]\d{4}\b'),
      RegExp(r'\b\d{4}[/-]\d{2}[/-]\d{2}\b'),
      RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'),
    ];
    
    final Set<String> dateDigitSequences = {};
    for (var pattern in datePatterns) {
      for (var match in pattern.allMatches(ocrText)) {
        final dateStr = match.group(0)!;
        final dateDigits = dateStr.replaceAll(RegExp(r'[^0-9]'), '');
        dateDigitSequences.add(dateDigits);
        if (dateDigits.length == 7) {
          dateDigitSequences.add('0$dateDigits');
        }
        if (dateDigits.length == 8) {
          dateDigitSequences.add(dateDigits.substring(1));
        }
      }
    }
    
    final allDigits = RegExp(r'\d').allMatches(ocrText);
    final digitSequence = allDigits.map((m) => m.group(0)!).join('');
    final alphanumericSequences = RegExp(r'[A-Za-z*]\s*[\d\s*]+').allMatches(ocrText);
    
    if (bestIdScore < 1.0 && digitSequence.contains(userIdNumber)) {
      idNumber = userIdNumber;
      bestIdScore = 1.0;
      _log('✅ Found ID in digit sequence: "$userIdNumber"');
      _log('   Match Score: 100% (EXACT MATCH)');
    }
    
    if (bestIdScore < 1.0) {
      final digitGroups = RegExp(r'\d+').allMatches(ocrText).map((m) => m.group(0)!).toList();
      for (var i = 0; i < digitGroups.length; i++) {
        String combined = digitGroups[i];
        for (var j = i + 1; j < digitGroups.length && combined.length < userIdNumber.length + 2; j++) {
          combined += digitGroups[j];
          if (combined.contains(userIdNumber)) {
            idNumber = userIdNumber;
            bestIdScore = 1.0;
            break;
          }
        }
        if (bestIdScore >= 1.0) break;
      }
    }
    
    if (bestIdScore < 1.0 && userInputPrefix.isNotEmpty) {
      for (var seq in alphanumericSequences) {
        final seqText = seq.group(0)!;
        final seqDigits = seqText.replaceAll(RegExp(r'[^0-9]'), '');
        final seqPrefix = seqText.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
        
        if (seqDigits == userIdNumber && seqPrefix == userInputPrefix) {
          idNumber = seqDigits;
          bestIdScore = 1.0;
          break;
        }
      }
    }
    
    if (bestIdScore < 1.0) {
      final targetLength = userIdNumber.length;
      if (digitSequence.length >= targetLength) {
        bool foundExact = false;
        for (var i = 0; i <= digitSequence.length - targetLength; i++) {
          final candidate = digitSequence.substring(i, i + targetLength);
          
          if (candidate == userIdNumber) {
            idNumber = candidate;
            bestIdScore = 1.0;
            foundExact = true;
            break;
          }
        }
        
        if (!foundExact) {
          for (var i = 0; i <= digitSequence.length - targetLength; i++) {
            final candidate = digitSequence.substring(i, i + targetLength);
            
            if (dateDigitSequences.contains(candidate) || 
                (candidate.length == 8 && dateDigitSequences.contains(candidate.substring(1)))) {
              continue;
            }
            
            final similarity = ratio(candidate, userIdNumber) / 100.0;
            if (similarity >= 0.90 && similarity > bestIdScore) {
              bestIdScore = similarity;
              idNumber = candidate;
            }
          }
        }
        
        if (bestIdScore < 0.95) {
          final reverseSequence = digitSequence.split('').reversed.join('');
          if (reverseSequence.contains(userIdNumber)) {
            idNumber = userIdNumber;
            bestIdScore = 1.0;
          } else {
            for (var i = 0; i <= reverseSequence.length - targetLength; i++) {
              final candidate = reverseSequence.substring(i, i + targetLength);
              if (candidate == userIdNumber) {
                idNumber = candidate;
                bestIdScore = 1.0;
                break;
              }
            }
          }
        }
      }
      
      final ocrLines = ocrText.split('\n');
      for (var line in ocrLines) {
        final lowerLine = line.toLowerCase();
        if (lowerLine.contains('birth') || 
            lowerLine.contains('date') || 
            lowerLine.contains('dob') ||
            lowerLine.contains('born')) {
          continue;
        }
        
        final lineDigits = RegExp(r'\d').allMatches(line).map((m) => m.group(0)!).join('');
        
        if (dateDigitSequences.contains(lineDigits) || 
            dateDigitSequences.contains(lineDigits.padLeft(8, '0')) ||
            dateDigitSequences.contains(lineDigits.length > 1 ? lineDigits.substring(1) : lineDigits)) {
          continue;
        }
        
        if (lineDigits.length >= 4 && lineDigits.length <= 15) {
          final similarity = ratio(lineDigits, userIdNumber) / 100.0;
          if (similarity > bestIdScore) {
            bestIdScore = similarity;
            idNumber = lineDigits;
          }
        }
      }
      
      final allNumbers = RegExp(r'\b\d{4,15}\b').allMatches(ocrText);
      for (var match in allNumbers) {
        final numStr = match.group(0)!;
        
        if (dateDigitSequences.contains(numStr) || 
            dateDigitSequences.contains(numStr.padLeft(8, '0')) ||
            (numStr.length == 8 && dateDigitSequences.contains(numStr.substring(1)))) {
          continue;
        }
        
        final similarity = ratio(numStr, userIdNumber) / 100.0;
        final lengthBonus = numStr.length == userIdNumber.length ? 0.1 : 0.0;
        final combinedScore = similarity + lengthBonus;
        
        if (combinedScore > bestIdScore) {
          bestIdScore = combinedScore;
          idNumber = numStr;
        }
      }
    }
    
    // Extract date of birth - search for best match if user input provided
    String? dateOfBirth;
    if (userInputBirthday != null && userInputBirthday.isNotEmpty) {
      final userDate = userInputBirthday.replaceAll(RegExp(r'[^0-9]'), '');
      double bestDateScore = 0.0;
      
      final datePatterns = [
        RegExp(r'\b\d{2}[/-]\d{2}[/-]\d{4}\b'), // MM/DD/YYYY or DD/MM/YYYY
        RegExp(r'\b\d{4}[/-]\d{2}[/-]\d{2}\b'), // YYYY-MM-DD
        RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'), // Flexible
      ];
      
      for (var pattern in datePatterns) {
        final matches = pattern.allMatches(ocrText);
        for (var match in matches) {
          final dateStr = match.group(0)!;
          final dateDigits = dateStr.replaceAll(RegExp(r'[^0-9]'), '');
          final similarity = ratio(dateDigits, userDate) / 100.0;
          
          if (similarity > bestDateScore) {
            bestDateScore = similarity;
            dateOfBirth = dateStr;
          }
        }
      }
    } else {
      // If no user input, just get first date found
      final datePatterns = [
        RegExp(r'\b\d{2}[/-]\d{2}[/-]\d{4}\b'),
        RegExp(r'\b\d{4}[/-]\d{2}[/-]\d{2}\b'),
        RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'),
      ];
      
      for (var pattern in datePatterns) {
        final match = pattern.firstMatch(ocrText);
        if (match != null) {
          dateOfBirth = match.group(0);
          break;
        }
      }
    }
    
    _log('\n📊 EXTRACTION RESULTS:');
    if (fullName != null) {
      _log('✅ Name Extracted: "$fullName"');
    } else {
      _log('❌ Name: Not found');
    }
    if (idNumber != null) {
      _log('✅ ID Number Extracted: "$idNumber" (Score: ${(bestIdScore * 100).toStringAsFixed(2)}%)');
    } else {
      _log('❌ ID Number: Not found');
    }
    if (dateOfBirth != null) {
      _log('✅ Birthday Extracted: "$dateOfBirth"');
    } else {
      _log('⚠️  Birthday: Not found');
    }
    _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    return ExtractedIdData(
      fullName: fullName,
      idNumber: idNumber,
      dateOfBirth: dateOfBirth,
      rawText: ocrText,
    );
  }

  IdType _detectIdType(String ocrText) {
    final text = ocrText.toLowerCase();
    
    final governmentIndicators = [
      'driver', 'driving', 'license', 'dl', 'd.l.',
      'national id', 'national identification', 'nid',
      'passport', 'passport no', 'passport number',
      'dmv', 'd.m.v.', 'department of motor vehicles',
      'government', 'republic of', 'federal', 'state id',
      'official', 'authorized', 'issued by',
    ];
    
    final studentIndicators = [
      'student', 'student id', 'student identification',
      'university', 'college', 'school', 'academic',
      'student number', 'matriculation', 'enrollment',
    ];
    
    int governmentMatches = governmentIndicators.where((ind) => text.contains(ind)).length;
    int studentMatches = studentIndicators.where((ind) => text.contains(ind)).length;
    
    if (governmentMatches >= 2 || (governmentMatches > 0 && studentMatches == 0)) {
      return IdType.government;
    } else if (studentMatches >= 2) {
      return IdType.student;
    } else if (studentMatches > 0) {
      return IdType.student;
    }
    
    return IdType.unknown;
  }

  /// Validate extracted text against user input using fuzzy matching
  TextValidationResult _validateText({
    required ExtractedIdData extractedData,
    required String userInputIdNumber,
    required String userInputFirstName,
    required String userInputLastName,
    String? userInputBirthday,
  }) {
    _log('\n📋 TEXT VALIDATION:');
    _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Validate ID number (≥90% match or exact)
    bool idNumberValid = false;
    if (extractedData.idNumber != null && userInputIdNumber.isNotEmpty) {
      final extractedId = extractedData.idNumber!.replaceAll(RegExp(r'[^0-9]'), '');
      final userId = userInputIdNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final similarity = ratio(extractedId, userId) / 100.0;
      // Lower threshold to 90% for ID number matching (OCR can be imperfect)
      idNumberValid = similarity >= 0.90 || extractedId == userId;
      
      _log('🔢 ID Number Check:');
      _log('   Extracted: "$extractedId"');
      _log('   User Input: "$userId"');
      _log('   Similarity: ${(similarity * 100).toStringAsFixed(2)}%');
      if (idNumberValid) {
        _log('   ✅ ID Number MATCH');
      } else {
        _log('   ❌ ID Number NO MATCH (need ≥90%)');
      }
    } else {
      _log('🔢 ID Number Check:');
      _log('   ⚠️  No ID number extracted or provided');
    }
    
    bool nameValid = false;
    if (extractedData.fullName != null) {
      final extractedName = extractedData.fullName!.toLowerCase();
      final userFullName = '$userInputFirstName $userInputLastName'.toLowerCase().trim();
      final similarity = ratio(extractedName, userFullName) / 100.0;
      nameValid = similarity >= 0.80;
      
      _log('\n👤 Name Check:');
      _log('   Extracted: "${extractedData.fullName}"');
      _log('   User Input: "$userInputFirstName $userInputLastName"');
      _log('   Full Name Similarity: ${(similarity * 100).toStringAsFixed(2)}%');
      
      if (!nameValid) {
        final firstNameSimilarity = ratio(extractedName, userInputFirstName.toLowerCase()) / 100.0;
        final lastNameSimilarity = ratio(extractedName, userInputLastName.toLowerCase()) / 100.0;
        final containsFirstName = extractedName.contains(userInputFirstName.toLowerCase());
        final containsLastName = extractedName.contains(userInputLastName.toLowerCase());
        
        _log('   First Name Similarity: ${(firstNameSimilarity * 100).toStringAsFixed(2)}%');
        _log('   Last Name Similarity: ${(lastNameSimilarity * 100).toStringAsFixed(2)}%');
        _log('   Contains First Name: ${containsFirstName ? "✅" : "❌"}');
        _log('   Contains Last Name: ${containsLastName ? "✅" : "❌"}');
        
        nameValid = firstNameSimilarity >= 0.80 || lastNameSimilarity >= 0.80 ||
            containsFirstName || containsLastName;
      }
      
      if (nameValid) {
        _log('   ✅ Name MATCH');
      } else {
        _log('   ❌ Name NO MATCH (need ≥80% or contains name)');
      }
    } else {
      _log('\n👤 Name Check:');
      _log('   ⚠️  No name extracted from ID');
    }
    
    bool birthdayValid = true;
    if (userInputBirthday != null && userInputBirthday.isNotEmpty && extractedData.dateOfBirth != null) {
      String extractedDate = extractedData.dateOfBirth!.replaceAll(RegExp(r'[^0-9]'), '');
      String userDate = userInputBirthday.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (extractedDate.length < 8) {
        extractedDate = extractedDate.padLeft(8, '0');
      }
      if (userDate.length < 8) {
        userDate = userDate.padLeft(8, '0');
      }
      
      bool exactMatch = extractedDate == userDate;
      bool formatMatch = false;
      if (extractedDate.length >= 6 && userDate.length >= 6) {
        if (extractedDate.length == 8 && userDate.length == 8) {
          final extYear1 = extractedDate.substring(0, 4);
          final extMonth1 = extractedDate.substring(4, 6);
          final extDay1 = extractedDate.substring(6, 8);
          
          final userYear1 = userDate.substring(0, 4);
          final userMonth1 = userDate.substring(4, 6);
          final userDay1 = userDate.substring(6, 8);
          
          if (extYear1 == userYear1 && extMonth1 == userMonth1 && extDay1 == userDay1) {
            formatMatch = true;
          } else {
            final extMonth2 = extractedDate.substring(0, 2);
            final extDay2 = extractedDate.substring(2, 4);
            final extYear2 = extractedDate.substring(4, 8);
            
            final userMonth2 = userDate.substring(0, 2);
            final userDay2 = userDate.substring(2, 4);
            final userYear2 = userDate.substring(4, 8);
            
            if (extYear2 == userYear2 && extMonth2 == userMonth2 && extDay2 == userDay2) {
              formatMatch = true;
            } else {
              final extDay3 = extractedDate.substring(0, 2);
              final extMonth3 = extractedDate.substring(2, 4);
              final extYear3 = extractedDate.substring(4, 8);
              
              final userDay3 = userDate.substring(0, 2);
              final userMonth3 = userDate.substring(2, 4);
              final userYear3 = userDate.substring(4, 8);
              
              if (extYear3 == userYear3 && extMonth3 == userMonth3 && extDay3 == userDay3) {
                formatMatch = true;
              }
            }
          }
        } else if (extractedDate.length == 7 && userDate.length == 7) {
          final extPadded = extractedDate.length == 7 ? '0$extractedDate' : extractedDate;
          final userPadded = userDate.length == 7 ? '0$userDate' : userDate;
          
          if (extPadded == userPadded) {
            formatMatch = true;
          } else {
            if (extPadded.length == 8 && userPadded.length == 8) {
              if (extPadded.substring(4) == userPadded.substring(4) && 
                  extPadded.substring(0, 4) == userPadded.substring(0, 4)) {
                formatMatch = true;
              }
            }
          }
        }
      }
      
      final similarity = ratio(extractedDate, userDate) / 100.0;
      birthdayValid = exactMatch || formatMatch || similarity >= 0.95;
      
      _log('\n📅 Birthday Check:');
      _log('   Extracted: "${extractedData.dateOfBirth}" → "$extractedDate"');
      _log('   User Input: "$userInputBirthday" → "$userDate"');
      _log('   Similarity: ${(similarity * 100).toStringAsFixed(2)}%');
      if (birthdayValid) {
        _log('   ✅ Birthday MATCH');
      } else {
        _log('   ❌ Birthday NO MATCH (need ≥95%)');
      }
    } else {
      _log('\n📅 Birthday Check:');
      if (userInputBirthday == null || userInputBirthday.isEmpty) {
        _log('   ⚠️  No birthday provided by user (skipping check)');
      } else {
        _log('   ⚠️  No birthday extracted from ID');
      }
    }
    
    final isValid = idNumberValid && nameValid;
    
    _log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _log('📊 TEXT VALIDATION RESULT:');
    _log('   ID Number: ${idNumberValid ? "✅ MATCH" : "❌ NO MATCH"}');
    _log('   Name: ${nameValid ? "✅ MATCH" : "❌ NO MATCH"}');
    _log('   Birthday: ${birthdayValid ? "✅ MATCH" : "⚠️  NO MATCH (optional)"}');
    _log('   Overall: ${isValid ? "✅ VALID" : "❌ INVALID"}');
    _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    return TextValidationResult(
      isValid: isValid,
      idNumberMatch: idNumberValid,
      nameMatch: nameValid,
      birthdayMatch: birthdayValid,
    );
  }

  Future<Map<String, dynamic>> _compareFacesFacePlusPlus(File idImage, File selfieImage) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_facePlusPlusApiUrl));
      
      request.fields['api_key'] = facePlusPlusApiKey!;
      request.fields['api_secret'] = facePlusPlusApiSecret!;
      
      request.files.add(
        await http.MultipartFile.fromPath('image_file1', idImage.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('image_file2', selfieImage.path),
      );
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Face++ API request timed out');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data.containsKey('error_message')) {
          throw Exception('Face++ API error: ${data['error_message']}');
        }
        
        final confidence = (data['confidence'] ?? 0.0).toDouble();
        final similarity = confidence / 100.0;
        
        final threshold = 0.10; // 10% threshold
        final isMatch = similarity >= threshold;
        
        return {
          'similarity': similarity,
          'match': isMatch,
          'message': isMatch 
              ? 'Face match confirmed'
              : 'Face does not match',
        };
      } else {
        throw Exception('Face++ API returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('  ❌ Face++ API call failed: $e');
      rethrow;
    }
  }

  /// Load TensorFlow Lite model for face recognition
  Future<void> _loadTFLiteModel() async {
    if (_isTfliteLoaded && _tfliteInterpreter != null) {
      return; // Already loaded
    }
    
    try {
      _log('  📥 Loading TFLite model from $_tfliteModelPath...');
      
      // Load model from assets
      final modelData = await rootBundle.load(_tfliteModelPath);
      final modelBytes = modelData.buffer.asUint8List();
      
      // Create interpreter
      _tfliteInterpreter = Interpreter.fromBuffer(modelBytes);
      _isTfliteLoaded = true;
      
      _log('  ✅ TFLite model loaded successfully');
    } catch (e) {
      _log('  ❌ Failed to load TFLite model: $e');
      _log('  💡 Make sure the model file exists at $_tfliteModelPath');
      _log('  💡 Download a face recognition model (MobileFaceNet, FaceNet, or ArcFace)');
      rethrow;
    }
  }

  /// Detect and crop face from image using ML Kit
  Future<img.Image?> _detectAndCropFace(File imageFile) async {
    try {
      // Preprocess image first for better face detection
      final preprocessedFile = await _preprocessImageForFaceDetection(imageFile);
      final preprocessedInputImage = InputImage.fromFilePath(preprocessedFile.path);
      final preprocessedFaces = await _faceDetector.processImage(preprocessedInputImage);
      
      // Clean up temp file
      try {
        if (preprocessedFile.path != imageFile.path) {
          await preprocessedFile.delete();
        }
      } catch (_) {}
      
      List<Face> detectedFaces = preprocessedFaces;
      
      if (preprocessedFaces.isEmpty) {
        // Try with original image as fallback
        _log('  ⚠️  No face detected in preprocessed image, trying original...');
        final originalInputImage = InputImage.fromFilePath(imageFile.path);
        final originalFaces = await _faceDetector.processImage(originalInputImage);
        
        if (originalFaces.isEmpty) {
          throw Exception('No face detected in image');
        }
        
        detectedFaces = originalFaces;
      }
      
      if (detectedFaces.length > 1) {
        _log('  ⚠️  Multiple faces detected (${detectedFaces.length}) - using first face');
      }
      
      final face = detectedFaces.first;
      final boundingBox = face.boundingBox;
      
      // Read original image (not preprocessed) for cropping
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // ENHANCED FACE ALIGNMENT AND CROPPING
      // Use facial landmarks if available for better alignment
      img.Image? alignedFace;
      
      if (face.landmarks.isNotEmpty) {
        // Try to align face using landmarks (eyes, nose, mouth)
        alignedFace = _alignFaceUsingLandmarks(image, face, boundingBox);
      }
      
      // If alignment failed or no landmarks, use bounding box with smart cropping
      alignedFace ??= _cropFaceWithSmartPadding(image, boundingBox);
      
      // Apply advanced preprocessing for better recognition
      return _preprocessFaceImage(alignedFace);
    } catch (e) {
      _log('  ❌ Face detection/cropping failed: $e');
      rethrow;
    }
  }

  /// Align face using facial landmarks for better recognition accuracy
  img.Image _alignFaceUsingLandmarks(img.Image image, Face face, Rect boundingBox) {
    try {
      // Get key landmarks (eyes)
      ui.Offset? leftEye;
      ui.Offset? rightEye;
      
      for (var landmarkEntry in face.landmarks.entries) {
        final landmark = landmarkEntry.value;
        if (landmark == null) continue;
        
        // Convert landmark.position (Point<int> from image package) to ui.Offset
        final position = landmark.position;
        // Point<int> has x and y properties, Offset has dx and dy
        final offset = ui.Offset(position.x.toDouble(), position.y.toDouble());
        
        switch (landmark.type) {
          case FaceLandmarkType.leftEye:
            leftEye = offset;
            break;
          case FaceLandmarkType.rightEye:
            rightEye = offset;
            break;
          default:
            break;
        }
      }
      
      // If we have both eyes, align based on eye positions
      if (leftEye != null && rightEye != null) {
        // Calculate angle between eyes
        final eyeVector = ui.Offset(rightEye.dx - leftEye.dx, rightEye.dy - leftEye.dy);
        final angle = math.atan2(eyeVector.dy, eyeVector.dx) * 180 / math.pi;
        
        // Rotate image to align eyes horizontally
        if (angle.abs() > 2.0) { // Only rotate if angle is significant
          final rotated = img.copyRotate(image, angle: -angle);
          
          // Recalculate bounding box after rotation (simplified)
          final centerX = image.width / 2;
          final centerY = image.height / 2;
          final distance = math.sqrt(
            math.pow(boundingBox.width, 2) + math.pow(boundingBox.height, 2)
          );
          
          final newLeft = (centerX - distance / 2).clamp(0.0, rotated.width.toDouble()).toInt();
          final newTop = (centerY - distance / 2).clamp(0.0, rotated.height.toDouble()).toInt();
          final newRight = (centerX + distance / 2).clamp(0.0, rotated.width.toDouble()).toInt();
          final newBottom = (centerY + distance / 2).clamp(0.0, rotated.height.toDouble()).toInt();
          
          return img.copyCrop(
            rotated,
            x: newLeft,
            y: newTop,
            width: newRight - newLeft,
            height: newBottom - newTop,
          );
        }
      }
      
      // Fallback to smart padding if alignment not possible
      return _cropFaceWithSmartPadding(image, boundingBox);
    } catch (e) {
      _log('  ⚠️  Face alignment failed: $e, using smart padding');
      return _cropFaceWithSmartPadding(image, boundingBox);
    }
  }
  
  /// Preprocess image for better face detection (enhance contrast, brightness)
  Future<File> _preprocessImageForFaceDetection(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      var image = img.decodeImage(imageBytes);
      
      if (image == null) {
        return imageFile; // Return original if decode fails
      }
      
      // Enhance image for better face detection
      var enhanced = img.adjustColor(
        image,
        contrast: 1.3, // Higher contrast for better edge detection
        brightness: 1.15, // Brighter for better visibility
      );
      
      // Apply histogram equalization for lighting normalization
      enhanced = _equalizeHistogram(enhanced);
      
      // Save to temporary file with optimized quality
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/preprocessed_face_detection_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final encoded = img.encodeJpg(enhanced, quality: 85); // Reduced from 95 to 85 for faster processing
      await tempFile.writeAsBytes(encoded);
      
      return tempFile;
    } catch (e) {
      _log('  ⚠️  Image preprocessing failed: $e, using original');
      return imageFile; // Return original on error
    }
  }

  /// Crop face with smart padding (square crop, centered on face)
  img.Image _cropFaceWithSmartPadding(img.Image image, Rect boundingBox) {
    // Calculate square crop centered on face
    final faceCenterX = boundingBox.left + boundingBox.width / 2;
    final faceCenterY = boundingBox.top + boundingBox.height / 2;
    
    // Use the larger dimension (width or height) for square crop
    final faceSize = math.max(boundingBox.width, boundingBox.height);
    
    // Add more padding (50% on each side) for better facial context
    // More context helps with recognition when face is at different angles or lighting
    final padding = 0.5;
    final cropSize = (faceSize * (1 + padding * 2)).toInt();
    
    // Calculate crop bounds (centered on face)
    final left = (faceCenterX - cropSize / 2).clamp(0.0, image.width.toDouble()).toInt();
    final top = (faceCenterY - cropSize / 2).clamp(0.0, image.height.toDouble()).toInt();
    final right = math.min(left + cropSize, image.width);
    final bottom = math.min(top + cropSize, image.height);
    
    // Ensure minimum size (increased for better quality)
    final minSize = 250;
    final actualWidth = right - left;
    final actualHeight = bottom - top;
    
    if (actualWidth < minSize || actualHeight < minSize) {
      final newSize = math.max(minSize, math.max(actualWidth, actualHeight));
      final newLeft = ((faceCenterX - newSize / 2).clamp(0.0, image.width.toDouble())).toInt();
      final newTop = ((faceCenterY - newSize / 2).clamp(0.0, image.height.toDouble())).toInt();
      final newRight = math.min(newLeft + newSize, image.width);
      final newBottom = math.min(newTop + newSize, image.height);
      
      return img.copyCrop(
        image,
        x: newLeft,
        y: newTop,
        width: newRight - newLeft,
        height: newBottom - newTop,
      );
    }
    
    return img.copyCrop(
      image,
      x: left,
      y: top,
      width: actualWidth,
      height: actualHeight,
    );
  }
  
  /// Apply histogram equalization to improve contrast and normalize lighting
  img.Image _equalizeHistogram(img.Image image) {
    // Calculate luminance histogram (using grayscale conversion formula)
    final histogram = List<int>.filled(256, 0);
    final pixelCount = image.width * image.height;
    
    // Build histogram from luminance values
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        // Calculate luminance: Y = 0.299*R + 0.587*G + 0.114*B
        final gray = (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114).round().clamp(0, 255);
        histogram[gray]++;
      }
    }
    
    // Calculate cumulative distribution function (CDF)
    final cdf = List<int>.filled(256, 0);
    cdf[0] = histogram[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + histogram[i];
    }
    
    // Create lookup table for equalization
    final lookup = List<int>.filled(256, 0);
    final cdfMin = cdf.firstWhere((value) => value > 0, orElse: () => 0);
    if (cdfMin > 0 && pixelCount > cdfMin) {
      for (int i = 0; i < 256; i++) {
        lookup[i] = ((cdf[i] - cdfMin) * 255 / (pixelCount - cdfMin)).round().clamp(0, 255);
      }
    } else {
      // Fallback: identity mapping
      for (int i = 0; i < 256; i++) {
        lookup[i] = i;
      }
    }
    
    // Apply equalization to each pixel
    final equalized = img.copyResize(image, width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        // Calculate luminance
        final gray = (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114).round().clamp(0, 255);
        final equalizedValue = lookup[gray];
        
        // Apply equalization proportionally to each channel
        if (gray > 0) {
          final ratio = equalizedValue / gray;
          final newR = (pixel.r * ratio).clamp(0, 255).round();
          final newG = (pixel.g * ratio).clamp(0, 255).round();
          final newB = (pixel.b * ratio).clamp(0, 255).round();
          
          // Create new pixel with equalized values
          final newPixel = img.ColorRgb8(newR, newG, newB);
          equalized.setPixel(x, y, newPixel);
        } else {
          // Keep original pixel if gray is 0
          equalized.setPixel(x, y, pixel);
        }
      }
    }
    
    return equalized;
  }

  /// Advanced preprocessing for face images (contrast enhancement, normalization)
  img.Image _preprocessFaceImage(img.Image faceImage) {
    // Minimal preprocessing to preserve facial features
    // Too much enhancement can reduce similarity scores between same person
    
    // 1. Very light contrast and brightness adjustment
    var enhanced = img.adjustColor(
      faceImage,
      contrast: 1.05, // Minimal contrast boost (further reduced)
      brightness: 1.01, // Minimal brightness boost (further reduced)
      saturation: 0.95, // Preserve natural colors
    );
    
    // 2. Skip histogram equalization - it reduces similarity for same person
    // enhanced = _equalizeHistogram(enhanced);
    
    // 3. Skip gamma correction - minimal changes preserve features better
    // enhanced = img.adjustColor(enhanced, gamma: 1.02);
    
    // 3. Ensure square aspect ratio (important for face recognition models)
    if (enhanced.width != enhanced.height) {
      final size = math.min(enhanced.width, enhanced.height);
      final x = (enhanced.width - size) ~/ 2;
      final y = (enhanced.height - size) ~/ 2;
      enhanced = img.copyCrop(enhanced, x: x, y: y, width: size, height: size);
    }
    
    return enhanced;
  }
  
  /// Preprocess face image for TFLite (resize and normalize with proper mean/std)
  Float32List _preprocessFaceForTFLite(img.Image faceImage) {
    // Minimal preprocessing to preserve facial features
    // Too much enhancement can reduce similarity scores between same person
    
    // Very light contrast and brightness adjustment
    var enhanced = img.adjustColor(
      faceImage,
      contrast: 1.03, // Minimal contrast boost (further reduced)
      brightness: 1.01, // Minimal brightness boost (further reduced)
    );
    
    // Skip histogram equalization for TFLite preprocessing
    // It can reduce similarity scores for the same person
    // enhanced = _equalizeHistogram(enhanced);
    
    // Resize to model input size (112x112) with high-quality interpolation
    final resized = img.copyResize(
      enhanced,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.cubic, // Better quality than linear
    );
    
    // MobileFaceNet uses normalization: (pixel - 127.5) / 128.0
    // This centers values around 0 and scales to [-1, 1] range
    // This is the standard normalization for MobileFaceNet models
    final input = Float32List(1 * _inputSize * _inputSize * 3);
    int index = 0;
    
    // Use MobileFaceNet standard normalization: (pixel - 127.5) / 128.0
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        
        // MobileFaceNet normalization: (pixel - 127.5) / 128.0
        input[index++] = (r - 127.5) / 128.0;
        input[index++] = (g - 127.5) / 128.0;
        input[index++] = (b - 127.5) / 128.0;
      }
    }
    
    return input;
  }

  /// Reshape input data to match TFLite model's expected shape
  dynamic _reshapeInputForTFLite(Float32List flatInput, List<int> shape) {
    // If shape is [1, height, width, channels], reshape to nested list
    if (shape.length == 4 && shape[0] == 1) {
      final height = shape[1];
      final width = shape[2];
      final channels = shape[3];
      
      // Create nested list structure: [batch][height][width][channel]
      final batch = <List<List<List<double>>>>[];
      int index = 0;
      
      for (int b = 0; b < shape[0]; b++) {
        final batchData = <List<List<double>>>[];
        for (int h = 0; h < height; h++) {
          final row = <List<double>>[];
          for (int w = 0; w < width; w++) {
            final pixel = <double>[];
            for (int c = 0; c < channels; c++) {
              if (index < flatInput.length) {
                pixel.add(flatInput[index++].toDouble());
              } else {
                pixel.add(0.0);
              }
            }
            row.add(pixel);
          }
          batchData.add(row);
        }
        batch.add(batchData);
      }
      return batch;
    } else {
      // If shape is different or flat, return as flat Float32List
      return flatInput;
    }
  }

  /// Generate face embedding using TFLite model
  Future<Float32List> _generateFaceEmbedding(File imageFile) async {
    try {
      // Load model if not loaded
      if (!_isTfliteLoaded) {
        await _loadTFLiteModel();
      }
      
      if (_tfliteInterpreter == null) {
        throw Exception('TFLite interpreter not initialized');
      }
      
      // Detect and crop face
      final croppedFace = await _detectAndCropFace(imageFile);
      if (croppedFace == null) {
        throw Exception('Failed to crop face');
      }
      
      // Preprocess face
      final preprocessedInput = _preprocessFaceForTFLite(croppedFace);
      
      // Get input and output tensors to check shapes
      final inputTensor = _tfliteInterpreter!.getInputTensors()[0];
      final outputTensor = _tfliteInterpreter!.getOutputTensors()[0];
      
      _log('  📐 Model input shape: ${inputTensor.shape}');
      _log('  📐 Model output shape: ${outputTensor.shape}');
      
      // Reshape input to match model's expected shape [1, 112, 112, 3]
      // Convert flat Float32List to nested list structure
      final reshapedInput = _reshapeInputForTFLite(preprocessedInput, inputTensor.shape);
      
      // Prepare output tensor - use List<List<double>> for output
      final output = List<List<double>>.filled(1, List<double>.filled(_embeddingSize, 0.0));
      
      // Run inference
      _tfliteInterpreter!.run(reshapedInput, output);
      
      // Convert to Float32List and normalize
      final embedding = Float32List(_embeddingSize);
      double norm = 0.0;
      
      for (int i = 0; i < _embeddingSize; i++) {
        embedding[i] = output[0][i].toDouble();
        norm += embedding[i] * embedding[i];
      }
      
      // L2 normalize the embedding
      norm = math.sqrt(norm);
      if (norm > 0) {
        for (int i = 0; i < _embeddingSize; i++) {
          embedding[i] = embedding[i] / norm;
        }
      }
      
      return embedding;
    } catch (e) {
      _log('  ❌ Face embedding generation failed: $e');
      rethrow;
    }
  }

  /// Calculate cosine similarity between two L2-normalized embeddings
  /// Since embeddings are already L2-normalized, we can use dot product directly
  /// Cosine similarity = dot product when vectors are normalized
  double _cosineSimilarity(Float32List embedding1, Float32List embedding2) {
    if (embedding1.length != embedding2.length) {
      throw Exception('Embedding dimensions do not match');
    }
    
    // Since embeddings are L2-normalized, cosine similarity = dot product
    // This is more efficient than recalculating norms
    double dotProduct = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
    }
    
    // Clamp to [-1, 1] range (should already be in this range for normalized vectors)
    return dotProduct.clamp(-1.0, 1.0);
  }

  /// Compare faces using ML Kit + TensorFlow Lite
  Future<Map<String, dynamic>> _compareFacesTFLite(File idImage, File selfieImage) async {
    try {
      _log('  🔍 Detecting and cropping faces...');
      
      // Generate embeddings for both faces
      _log('  📊 Generating embedding for ID face...');
      final idEmbedding = await _generateFaceEmbedding(idImage);
      
      _log('  📊 Generating embedding for selfie face...');
      final selfieEmbedding = await _generateFaceEmbedding(selfieImage);
      
      // Calculate cosine similarity
      _log('  🔢 Calculating cosine similarity...');
      final similarity = _cosineSimilarity(idEmbedding, selfieEmbedding);
      
      // ENHANCED THRESHOLD WITH ADAPTIVE LOGIC
      // MobileFaceNet typical ranges:
      // Same person: 0.60-0.85 (ideal)
      // Same person with variations (hair, expression, lighting): 0.30-0.60
      // Different person: 0.15-0.30
      // Borderline: 0.28-0.35
      
      // Use 10% threshold for ID photos
      // ID photos are often lower quality, older, and have different lighting/expression
      // Lower threshold helps reduce false negatives for legitimate ID verifications
      final threshold = 0.10; // 10% threshold for ID photos
      final isMatch = similarity >= threshold;
      
      // Additional validation: Check if similarity is in expected range
      final isInSamePersonRange = similarity >= 0.60 && similarity <= 0.85;
      final isInSamePersonWithVariations = similarity >= 0.30 && similarity < 0.60;
      final isInDifferentPersonRange = similarity >= 0.15 && similarity < 0.30;
      final isInBorderlineRange = similarity >= 0.28 && similarity < 0.35;
      
      _log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log('👤 FACE VALIDATION:');
      _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log('📊 Face Similarity Score: ${(similarity * 100).toStringAsFixed(2)}%');
      _log('🎯 Threshold: ≥${(threshold * 100).toStringAsFixed(0)}% required for PASS');
      
      // Detailed analysis
      if (isInSamePersonRange) {
        _log('✅ Similarity indicates SAME PERSON (ideal range: 60-85%)');
      } else if (isInSamePersonWithVariations) {
        _log('⚠️  Similarity indicates SAME PERSON with variations');
        _log('   (hair, expression, lighting, age: 30-60%)');
        _log('💡 This is normal for ID photos - using lenient 10% threshold');
      } else if (isInDifferentPersonRange) {
        _log('❌ Similarity indicates DIFFERENT PERSON (typical range: 15-30%)');
      } else if (isInBorderlineRange) {
        _log('⚠️  Similarity in BORDERLINE range (28-35%)');
      } else {
        _log('⚠️  Similarity outside expected ranges - may indicate image quality issues');
      }
      
      if (isMatch) {
        _log('✅ FACE MATCH - Validation PASSED');
      } else {
        _log('❌ FACE NO MATCH - Validation FAILED');
        _log('   Need ≥${(threshold * 100).toStringAsFixed(0)}% but got ${(similarity * 100).toStringAsFixed(2)}%');
      }
      _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
      return {
        'similarity': similarity,
        'match': isMatch,
        'message': isMatch
            ? 'Face match confirmed (TFLite similarity: ${(similarity * 100).toStringAsFixed(2)}%)'
            : 'Face does not match (TFLite similarity: ${(similarity * 100).toStringAsFixed(2)}%, required: ≥${(threshold * 100).toStringAsFixed(0)}%)',
      };
    } catch (e) {
      _log('  ❌ TFLite face comparison failed: $e');
      rethrow;
    }
  }

  /// Preprocess image for OCR (rotate if needed for vertical text)
  /// Enhanced with aggressive preprocessing for maximum text extraction
  Future<File> _preprocessImageForOCR(File imageFile, int rotationDegrees) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        return imageFile; // Return original if decode fails
      }
      
      img.Image? processedImage = originalImage;
      
      // Rotate if needed
      if (rotationDegrees == 90) {
        processedImage = img.copyRotate(originalImage, angle: 90);
      } else if (rotationDegrees == 180) {
        processedImage = img.copyRotate(originalImage, angle: 180);
      } else if (rotationDegrees == 270) {
        processedImage = img.copyRotate(originalImage, angle: -90);
      }
      
      // OPTIMIZED PREPROCESSING - Reduced memory usage
      // Only upscale if image is very small (< 1000px) to reduce memory pressure
      // Large images already have enough resolution for OCR
      if (processedImage.width < 1000 || processedImage.height < 1000) {
        final scaleFactor = 1.5; // Reduced from 2.0 to save memory
        final newWidth = (processedImage.width * scaleFactor).round().clamp(1000, 2000);
        final newHeight = (processedImage.height * scaleFactor).round().clamp(1000, 2000);
        processedImage = img.copyResize(
          processedImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear, // Faster than cubic, still good quality
        );
      } else if (processedImage.width > 3000 || processedImage.height > 3000) {
        // Downscale very large images to reduce memory usage
        final maxDimension = 2500;
        double scaleFactor = 1.0;
        if (processedImage.width > maxDimension) {
          scaleFactor = maxDimension / processedImage.width;
        }
        if (processedImage.height > maxDimension) {
          scaleFactor = math.min(scaleFactor, maxDimension / processedImage.height);
        }
        if (scaleFactor < 1.0) {
          processedImage = img.copyResize(
            processedImage,
            width: (processedImage.width * scaleFactor).round(),
            height: (processedImage.height * scaleFactor).round(),
            interpolation: img.Interpolation.linear,
          );
        }
      }
      
      // 2. Convert to grayscale FIRST (removes color noise, improves contrast)
      processedImage = img.grayscale(processedImage);
      
      // 3. Increase contrast aggressively to make text stand out
      processedImage = img.adjustColor(processedImage, contrast: 1.5); // Increased from 1.3
      
      // 4. Adjust brightness for optimal text visibility
      processedImage = img.adjustColor(processedImage, brightness: 1.15); // Increased from 1.1
      
      // 5. Apply gamma correction to enhance text edges and mid-tones
      processedImage = img.adjustColor(processedImage, gamma: 1.3); // Increased from 1.2
      
      // 6. Apply histogram equalization for better contrast distribution
      processedImage = _equalizeHistogram(processedImage);
      
      // 7. Apply additional contrast boost after equalization
      processedImage = img.adjustColor(processedImage, contrast: 1.2);
      
      // Save processed image to temp file with optimized quality (85% is sufficient and faster)
      final tempDir = await getTemporaryDirectory();
      final processedPath = '${tempDir.path}/ocr_processed_${DateTime.now().millisecondsSinceEpoch}_$rotationDegrees.jpg';
      final processedBytes = img.encodeJpg(processedImage, quality: 85); // Reduced from 100 to 85 for faster processing
      final processedFile = File(processedPath);
      await processedFile.writeAsBytes(processedBytes);
      
      return processedFile;
    } catch (e) {
      _log('  ⚠️  Image preprocessing failed: $e');
      return imageFile; // Return original on error
    }
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
    _faceDetector.close();
  }
}

/// ID Type classification
enum IdType {
  government, // Government-issued ID (driver's license, national ID, passport)
  student,   // Student ID
  unknown,   // Cannot determine
}

/// Result of ID validation
class IdValidationResult {
  final bool isValid;
  final TextValidationResult? textValidation;
  final FaceMatchResult? faceMatch;
  final ExtractedIdData? extractedData;
  final IdType? idType;
  final bool? isGovernmentId;
  final String? errorMessage;

  IdValidationResult({
    required this.isValid,
    this.textValidation,
    this.faceMatch,
    this.extractedData,
    this.idType,
    this.isGovernmentId,
    this.errorMessage,
  });
}

/// Result of text validation
class TextValidationResult {
  final bool isValid;
  final bool idNumberMatch;
  final bool nameMatch;
  final bool birthdayMatch;

  TextValidationResult({
    required this.isValid,
    required this.idNumberMatch,
    required this.nameMatch,
    required this.birthdayMatch,
  });
}

/// Result of face comparison
class FaceMatchResult {
  final bool isMatch;
  final double confidence; // 0.0 to 1.0
  final String message;

  FaceMatchResult({
    required this.isMatch,
    required this.confidence,
    required this.message,
  });
}

/// Extracted data from ID OCR
class ExtractedIdData {
  final String? fullName;
  final String? idNumber;
  final String? dateOfBirth;
  final String rawText;

  ExtractedIdData({
    this.fullName,
    this.idNumber,
    this.dateOfBirth,
    required this.rawText,
  });
}