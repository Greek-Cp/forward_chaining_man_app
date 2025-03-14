import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:forward_chaining_man_app/app/views/student/model/data_student.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:math' as math;

class CertificateGenerator extends StatefulWidget {
  final RecommendationItem recommendation;
  final int index;
  final String userName;
  final String date;

  const CertificateGenerator({
    Key? key,
    required this.recommendation,
    required this.index,
    required this.userName,
    required this.date,
  }) : super(key: key);

  @override
  _CertificateGeneratorState createState() => _CertificateGeneratorState();
}

class _CertificateGeneratorState extends State<CertificateGenerator>
    with SingleTickerProviderStateMixin {
  final GlobalKey _certificateKey = GlobalKey();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isGenerating = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    // Lock the screen to landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    // Reset orientation when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _animationController.dispose();
    super.dispose();
  }

  // Function to capture the certificate as PNG
  Future<Uint8List?> _captureCertificate() async {
    try {
      final RenderRepaintBoundary boundary = _certificateKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // Higher pixel ratio for better quality
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      print('Error capturing certificate: $e');
      return null;
    }
  }

  // Save certificate to gallery
  Future<void> _saveCertificate() async {
    setState(() {
      _isGenerating = true;
    });

    final pngBytes = await _captureCertificate();

    if (pngBytes != null) {
      final result = await ImageGallerySaverPlus.saveImage(pngBytes,
          quality: 100,
          name:
              "certificate_${widget.recommendation.title.replaceAll("|", "_")}_${DateTime.now().millisecondsSinceEpoch}");

      setState(() {
        _isGenerating = false;
        _isSaved = result['isSuccess'] ?? false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSaved
              ? 'Sertifikat berhasil disimpan di galeri'
              : 'Gagal menyimpan sertifikat'),
          backgroundColor: _isSaved ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuat sertifikat'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return Color(0xFFFFD700); // Gold
      case 1:
        return Color(0xFFC0C0C0); // Silver
      case 2:
        return Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey; // Fallback
    }
  }

  // Label yang sesuai dengan medali
  String _getMedalLabel(int index) {
    switch (index) {
      case 0:
        return 'Sangat Direkomendasikan';
      case 1:
        return 'Direkomendasikan';
      case 2:
        return 'Kurang Direkomendasikan';
      default:
        return 'Tidak Direkomendasikan';
    }
  }

  // Emoji yang sesuai dengan medali
  String _getMedalEmoji(int index) {
    switch (index) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '🏅';
    }
  }

  // Share certificate
  Future<void> _shareCertificate() async {
    try {
      setState(() {
        _isGenerating = true;
      });

      final Uint8List? pngBytes = await _captureCertificate();

      if (pngBytes != null) {
        // Dapatkan direktori sementara
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/certificate.png';

        // Buat file dan tulis data gambar ke dalamnya
        final file = File(filePath);
        await file.writeAsBytes(pngBytes);

        // Bagikan file dengan Share Plus
        await Share.shareXFiles([XFile(filePath)],
            text: 'Sertifikat Hasil Analisis Minat dan Bakat');
      } else {
        _showErrorSnackBar('Gagal membuat sertifikat untuk dibagikan');
      }
    } catch (e) {
      _showErrorSnackBar('Terjadi kesalahan: ${e.toString()}');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // Fungsi untuk menampilkan SnackBar error
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get medal info
    final Color medalColor = _getMedalColor(widget.index);
    final Color accentColor = widget.index == 0
        ? Color(0xFFF7D154) // Gold accent
        : widget.index == 1
            ? Color(0xFFB3B6B7) // Silver accent
            : Color(0xFFE59866); // Bronze accent
    final String medalEmoji = _getMedalEmoji(widget.index);
    final String medalLabel = _getMedalLabel(widget.index);

    // Get recommendation data
    final parts = widget.recommendation.title.split('|');
    final programName = parts[0];
    final minatName = parts.length > 1 ? parts[1] : parts[0];

    // Calculate screen size for aspect ratio
    final Size screenSize = MediaQuery.of(context).size;
    final double certificateWidth = screenSize.width * 0.9;
    final double certificateHeight =
        certificateWidth * 0.5625; // 16:9 aspect ratio

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: Text('Sertifikat Hasil'),
        backgroundColor: medalColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              // Show info dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Informasi Sertifikat'),
                  content: Text(
                      'Sertifikat ini berisi hasil analisis minat dan bakat Anda. '
                      'Anda dapat menyimpan sertifikat ini ke galeri atau membagikannya. '
                      'Sertifikat akan disimpan dalam format PNG.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Mengerti'),
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          CustomPaint(
            painter: CertificateBackgroundPainter(
              color: medalColor.withOpacity(0.15),
              accentColor: accentColor.withOpacity(0.15),
            ),
            size: Size(screenSize.width, screenSize.height),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Certificate
                    RepaintBoundary(
                      key: _certificateKey,
                      child: Container(
                        width: certificateWidth,
                        height: certificateHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // Background pattern
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: CertificatePatternPainter(
                                    color: medalColor,
                                    accentColor: accentColor,
                                  ),
                                ),
                              ),

                              // Certificate content
                              Row(
                                children: [
                                  // Left section (medal, name)
                                  Container(
                                    width: certificateWidth * 0.35,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          medalColor.withOpacity(0.9),
                                          accentColor.withOpacity(0.9),
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Medal logo
                                        Container(
                                          padding: EdgeInsets.all(15),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  medalColor,
                                                  accentColor
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                medalEmoji,
                                                style: TextStyle(fontSize: 40),
                                              ),
                                            ),
                                          ),
                                        ),

                                        SizedBox(height: 20),

                                        Text(
                                          'SERTIFIKAT',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 3,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black26,
                                                offset: Offset(0, 2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          'HASIL ANALISIS',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        Text(
                                          'MINAT & BAKAT',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            letterSpacing: 1.5,
                                          ),
                                        ),

                                        SizedBox(height: 30),

                                        // User info
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20),
                                          child: Column(
                                            children: [
                                              Text(
                                                'Diberikan Kepada:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                              SizedBox(height: 5),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  widget.userName,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Right section (details)
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'HASIL ANALISIS',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: medalColor,
                                                  letterSpacing: 1,
                                                ),
                                              ),

                                              // ID dan Tanggal
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    widget.date,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  Text(
                                                    'ID: PSY-${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13)}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          Divider(
                                              color:
                                                  medalColor.withOpacity(0.3),
                                              height: 20),

                                          Expanded(
                                            child: Row(
                                              children: [
                                                // Program & minat info
                                                Expanded(
                                                  flex: 3,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'MEMILIKI KECOCOKAN DENGAN',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors
                                                              .grey.shade600,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                      SizedBox(height: 8),
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 12,
                                                                vertical: 6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: medalColor
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        child: Text(
                                                          programName,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: medalColor,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(height: 8),
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 14,
                                                                vertical: 8),
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            colors: [
                                                              medalColor
                                                                  .withOpacity(
                                                                      0.15),
                                                              accentColor
                                                                  .withOpacity(
                                                                      0.15)
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          border: Border.all(
                                                            color: medalColor
                                                                .withOpacity(
                                                                    0.3),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          minatName,
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: medalColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                SizedBox(width: 20),

                                                // Match percentage
                                                Expanded(
                                                  flex: 2,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      // Score circle
                                                      Container(
                                                        width: 70,
                                                        height: 70,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Colors.white,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: medalColor
                                                                  .withOpacity(
                                                                      0.2),
                                                              blurRadius: 8,
                                                              spreadRadius: 0,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Stack(
                                                          alignment:
                                                              Alignment.center,
                                                          children: [
                                                            CircularProgressIndicator(
                                                              value: widget
                                                                      .recommendation
                                                                      .score /
                                                                  100,
                                                              strokeWidth: 8,
                                                              backgroundColor:
                                                                  Colors.grey
                                                                      .shade200,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                          Color>(
                                                                      medalColor),
                                                            ),
                                                            Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  '${widget.recommendation.score}%',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color:
                                                                        medalColor,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  'MATCH',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize: 9,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: Colors
                                                                        .grey
                                                                        .shade600,
                                                                    letterSpacing:
                                                                        0.5,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      SizedBox(height: 16),

                                                      // Medal label
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 12,
                                                                vertical: 8),
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            colors: [
                                                              medalColor
                                                                  .withOpacity(
                                                                      0.1),
                                                              accentColor
                                                                  .withOpacity(
                                                                      0.1)
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              medalEmoji,
                                                              style: TextStyle(
                                                                  fontSize: 14),
                                                            ),
                                                            SizedBox(width: 6),
                                                            Text(
                                                              medalLabel,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    medalColor,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Footer
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 8),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                  color: medalColor
                                                      .withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'MyApp',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: medalColor,
                                                  ),
                                                ),
                                                Text(
                                                  'Hasil analisis ini berlaku selamanya',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Border overlay for glass effect
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withOpacity(0.3),
                                        Colors.white.withOpacity(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _saveCertificate,
                          icon: Icon(_isSaved ? Icons.check : Icons.save_alt),
                          label: Text(_isSaved ? 'Tersimpan' : 'Simpan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: medalColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 3,
                          ),
                        ),
                        SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _isGenerating ? null : _shareCertificate,
                          icon: Icon(Icons.share),
                          label: Text('Bagikan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading indicator
          if (_isGenerating)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(medalColor),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memproses sertifikat...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Pattern painter for certificate background
class CertificatePatternPainter extends CustomPainter {
  final Color color;
  final Color accentColor;

  CertificatePatternPainter({
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final bgPaint = Paint()..color = Colors.white;

    canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height), bgPaint);

    // Draw subtle geometric patterns
    final random = math.Random(42);

    // Grid lines
    final gridPaint = Paint()
      ..color = color.withOpacity(0.03)
      ..strokeWidth = 0.5;

    final gridSpacing = 20.0;
    for (double x = 0; x < canvasSize.width; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, canvasSize.height),
        gridPaint,
      );
    }

    for (double y = 0; y < canvasSize.height; y += gridSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(canvasSize.width, y),
        gridPaint,
      );
    }

    // Circle decorations
    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Large circles
    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * canvasSize.width;
      final y = random.nextDouble() * canvasSize.height;
      final radius = random.nextDouble() * 50 + 30;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        circlePaint..color = color.withOpacity(0.05),
      );
    }

    // Small decorative elements
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * canvasSize.width;
      final y = random.nextDouble() * canvasSize.height;
      final elementSize = random.nextDouble() * 5 + 2;

      if (random.nextBool()) {
        // Small circle
        canvas.drawCircle(
          Offset(x, y),
          elementSize / 2,
          Paint()..color = accentColor.withOpacity(0.1),
        );
      } else {
        // Small square
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(x, y), width: elementSize, height: elementSize),
          Paint()..color = color.withOpacity(0.1),
        );
      }
    }

    // Decorative corner elements
    final cornerSize = canvasSize.width * 0.1;
    final cornerPaint = Paint()
      ..color = color.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Top-left corner
    canvas.drawArc(
      Rect.fromLTWH(0, 0, cornerSize * 2, cornerSize * 2),
      math.pi / 2,
      math.pi / 2,
      false,
      cornerPaint,
    );

    // Top-right corner
    canvas.drawArc(
      Rect.fromLTWH(
          canvasSize.width - cornerSize * 2, 0, cornerSize * 2, cornerSize * 2),
      0,
      math.pi / 2,
      false,
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawArc(
      Rect.fromLTWH(0, canvasSize.height - cornerSize * 2, cornerSize * 2,
          cornerSize * 2),
      math.pi,
      math.pi / 2,
      false,
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawArc(
      Rect.fromLTWH(canvasSize.width - cornerSize * 2,
          canvasSize.height - cornerSize * 2, cornerSize * 2, cornerSize * 2),
      -math.pi / 2,
      math.pi / 2,
      false,
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(CertificatePatternPainter oldDelegate) =>
      color != oldDelegate.color || accentColor != oldDelegate.accentColor;
}

// Background painter for the screen
class CertificateBackgroundPainter extends CustomPainter {
  final Color color;
  final Color accentColor;

  CertificateBackgroundPainter({
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.black,
          Color(0xFF1E1E2A),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw subtle pattern elements
    final random = math.Random(42);
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Small dots in the background
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2 + 0.5;

      canvas.drawCircle(Offset(x, y), radius,
          dotPaint..color = color.withOpacity(0.1 + random.nextDouble() * 0.1));
    }

    // Diagonal lines
    final linePaint = Paint()
      ..color = accentColor.withOpacity(0.05)
      ..strokeWidth = 1;

    for (int i = 0; i < 10; i++) {
      final y = -size.height + (i * size.height / 2);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
