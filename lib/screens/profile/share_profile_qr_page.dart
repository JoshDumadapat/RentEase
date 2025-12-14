import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/screens/profile/qr_scanner_page.dart';

const Color _themeColorDark = Color(0xFF00B8E6);
const Color _themeColor = Color(0xFF00D1FF);

class ShareProfileQRPage extends StatefulWidget {
  final UserModel user;

  const ShareProfileQRPage({
    super.key,
    required this.user,
  });

  @override
  State<ShareProfileQRPage> createState() => _ShareProfileQRPageState();
}

class _ShareProfileQRPageState extends State<ShareProfileQRPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey _qrKey = GlobalKey();
  final GlobalKey _cardKey = GlobalKey();
  bool _includeBackground = true;
  int _colorIndex = 0;
  final List<List<Color>> _colorThemes = [
    // Theme colors matching app
    [const Color(0xFF00B8E6), const Color(0xFF0099CC)], // Blue theme
    [const Color(0xFF00D1FF), const Color(0xFF00B8E6)], // Light blue
    [Colors.green, Colors.teal], // Green
    [Colors.orange, Colors.deepOrange], // Orange
    [Colors.purple, Colors.deepPurple], // Purple
    [Colors.pink, Colors.red], // Pink/Red
  ];

  late final String _profileUrl = 'https://rentease.app/profile/${widget.user.id}';
  
  late final String _qrData = _profileUrl;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Slide up animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Scale animation for a subtle zoom effect
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Start animation when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Helper method to get theme-aware SnackBar styling
  SnackBar _buildThemedSnackBar(String message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isDark ? Colors.black87 : Colors.white,
        ),
      ),
      backgroundColor: isDark ? Colors.white : Colors.black87,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentColors = _colorThemes[_colorIndex];
    final qrColor = Colors.black;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [currentColors[0], currentColors[1], currentColors[1].withOpacity(0.8)]
                : [currentColors[0].withOpacity(0.9), currentColors[1].withOpacity(0.9), currentColors[1].withOpacity(0.7)],
          ),
        ),
        child: CustomPaint(
          painter: _TexturePainter(),
          child: SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      // Color Button - Text button with capsule shape
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (mounted) {
                                setState(() {
                                  _colorIndex = (_colorIndex + 1) % _colorThemes.length;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                'COLOR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Scan Icon - First QR icon
                      IconButton(
                        icon: Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                        onPressed: () => _showQRScanner(),
                      ),
                    ],
                  ),
                ),

                // Content Cards - Centered
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Transform.translate(
                              offset: const Offset(0, -30), // Move cards up by 30 pixels
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // QR Code and Name Card - Increased vertical padding for proportional spacing
                                  RepaintBoundary(
                                    key: _cardKey,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 30,
                                            offset: const Offset(0, 15),
                                            spreadRadius: 5,
                                          ),
                                          BoxShadow(
                                            color: currentColors[0].withOpacity(0.2),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // QR Code
                                          RepaintBoundary(
                                            key: _qrKey,
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.grey.shade200,
                                                  width: 1,
                                                ),
                                              ),
                                              child: QrImageView(
                                                data: _qrData,
                                                version: QrVersions.auto,
                                                size: 200,
                                                backgroundColor: Colors.white,
                                                foregroundColor: qrColor,
                                                errorCorrectionLevel: QrErrorCorrectLevel.H,
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // Username
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '@${widget.user.displayName.replaceAll(' ', '').toLowerCase()}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              if (widget.user.isVerified) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: _themeColorDark.withOpacity(0.2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.verified,
                                                    size: 18,
                                                    color: _themeColorDark,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Action Buttons Card - Reduced height
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 30,
                                          offset: const Offset(0, 15),
                                          spreadRadius: 5,
                                        ),
                                        BoxShadow(
                                          color: currentColors[0].withOpacity(0.2),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _ActionButton(
                                          icon: Icons.share_outlined,
                                          label: 'Share',
                                          onTap: () => _shareProfile(),
                                          textColor: Colors.black87,
                                        ),
                                        _ActionButton(
                                          icon: Icons.copy_rounded,
                                          label: 'Copy',
                                          onTap: () => _copyLink(),
                                          textColor: Colors.black87,
                                        ),
                                        _ActionButton(
                                          icon: Icons.file_download_outlined,
                                          label: 'Download',
                                          onTap: () => _showDownloadOptions(),
                                          textColor: Colors.black87,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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

  Future<void> _shareProfile() async {
    try {
      final shareText = 'Check out ${widget.user.displayName}\'s profile on RentEase!\n'
          '${widget.user.bio != null && widget.user.bio!.isNotEmpty ? widget.user.bio! + '\n' : ''}'
          'View profile: $_profileUrl';
      
      await Share.share(shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildThemedSnackBar('Error sharing: $e'),
        );
      }
    }
  }

  Future<void> _copyLink() async {
    try {
      await Clipboard.setData(ClipboardData(text: _profileUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildThemedSnackBar('Copied to clipboard'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildThemedSnackBar('Error copying link: $e'),
        );
      }
    }
  }

  void _showQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerPage(),
      ),
    );
  }

  void _showDownloadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Download Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Include Background Toggle
            StatefulBuilder(
              builder: (context, setModalState) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Include Background',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Switch(
                    value: _includeBackground,
                    onChanged: (value) {
                      setModalState(() {
                        _includeBackground = value;
                      });
                      setState(() {
                        _includeBackground = value;
                      });
                    },
                    activeColor: _themeColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Save Image Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _saveImage();
              },
              icon: const Icon(Icons.image_outlined),
              label: const Text('Save Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Download as PDF Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _downloadAsPDF();
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Download as PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeColorDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _saveImage() async {
    try {
      // Request storage permission
      PermissionStatus status;
      if (Platform.isAndroid) {
        status = await Permission.photos.request();
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      } else {
        status = await Permission.photos.request();
      }
      
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildThemedSnackBar('Permission is required to save image'),
          );
        }
        return;
      }

      // Capture image
      final RenderRepaintBoundary boundary = _includeBackground
          ? (_cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary)
          : (_qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary);
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to gallery with user name
      final userName = widget.user.displayName.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\s-]'), '');
      
      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/RentEase_Profile_QR_${userName}_${widget.user.id}.png');
      await file.writeAsBytes(pngBytes);
      
      // Save to gallery using gallery_saver_plus
      final result = await GallerySaver.saveImage(file.path);

      if (mounted && result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildThemedSnackBar('Image saved to gallery'),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildThemedSnackBar('Failed to save image'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildThemedSnackBar('Error saving image: $e'),
        );
      }
    }
  }

  Future<void> _downloadAsPDF() async {
    try {
      // Capture image based on include background setting
      final RenderRepaintBoundary boundary = _includeBackground
          ? (_cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary)
          : (_qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary);
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Create PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Image(
                    pw.MemoryImage(pngBytes),
                    fit: pw.BoxFit.contain,
                  ),
                  if (!_includeBackground) ...[
                    pw.SizedBox(height: 24),
                    pw.Text(
                      '@${widget.user.displayName.replaceAll(' ', '').toLowerCase()}',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'RentEase Profile QR Code',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Save PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildThemedSnackBar('Error generating PDF: $e'),
        );
      }
    }
  }
}

// Texture painter for background
class _TexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Create a subtle dot pattern texture
    for (double x = 0; x < size.width; x += 20) {
      for (double y = 0; y < size.height; y += 20) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color textColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
