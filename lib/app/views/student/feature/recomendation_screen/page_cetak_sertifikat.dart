import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:forward_chaining_man_app/app/views/student/model/data_student.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class MagicRevealAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onAnimationComplete;

  const MagicRevealAnimation({
    Key? key,
    required this.child,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<MagicRevealAnimation> createState() => _MagicRevealAnimationState();
}

class _MagicRevealAnimationState extends State<MagicRevealAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _revealAnimation;
  late Animation<double> _sparkleAnimation;

  // Generate random positions for sparkles
  final List<Offset> _sparklePositions = List.generate(
    20,
    (_) => Offset(
      math.Random().nextDouble(),
      math.Random().nextDouble(),
    ),
  );

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Animation for the reveal effect (0.0 to 1.0)
    _revealAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );

    // Animation for the sparkle effect (0.0 to 1.0 and back to 0.0)
    _sparkleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInExpo)),
        weight: 60,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0),
      ),
    );

    // Start the animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _controller.forward().then((_) {
        if (widget.onAnimationComplete != null) {
          widget.onAnimationComplete!();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // The certificate with reveal effect
            ClipPath(
              clipper: RevealClipper(_revealAnimation.value),
              child: widget.child,
            ),

            // Sparkle effect
            ..._buildSparkles(),
          ],
        );
      },
    );
  }

  List<Widget> _buildSparkles() {
    return _sparklePositions.map((position) {
      // Calculate a delay factor based on position (0.0 to 0.5)
      final delay = position.dx * 0.5;

      // Apply the delay to the animation
      final delayedAnimation = _sparkleAnimation.value - delay;
      final opacity = math.max(0.0, math.min(1.0, delayedAnimation));

      if (opacity <= 0) {
        return const SizedBox.shrink();
      }

      // Calculate size based on animation progress (larger at peak)
      final sizeFactor = 1.0 + math.sin(delayedAnimation * math.pi) * 1.5;
      final size = 10.0 * sizeFactor;

      return Positioned(
        left: position.dx * MediaQuery.of(context).size.width,
        top: position.dy * MediaQuery.of(context).size.height,
        child: Opacity(
          opacity: opacity,
          child: SparkleWidget(
            size: size,
            color: const Color(0xFFd9dbe6),
          ),
        ),
      );
    }).toList();
  }
}

// Custom clipper for the reveal effect
class RevealClipper extends CustomClipper<Path> {
  final double progress;

  RevealClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();

    if (progress <= 0.0) {
      // At the start, clip everything
      return path;
    } else if (progress >= 1.0) {
      // At the end, don't clip anything
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    // Create a radial reveal effect
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final radius = maxRadius * progress;

    path.addOval(Rect.fromCircle(center: center, radius: radius));
    return path;
  }

  @override
  bool shouldReclip(RevealClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

// Custom widget for sparkles
class SparkleWidget extends StatelessWidget {
  final double size;
  final Color color;

  const SparkleWidget({
    Key? key,
    required this.size,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SparklePainter(color: color),
      ),
    );
  }
}

// Custom painter for sparkle shape
class SparklePainter extends CustomPainter {
  final Color color;

  SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw a star shape
    final path = Path();
    const spikes = 4;
    final outerRadius = size.width / 2;
    final innerRadius = size.width / 5;

    for (var i = 0; i < spikes * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = math.pi * i / spikes;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);

    // Draw a subtle glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(SparklePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class CertificateFront extends StatefulWidget {
  final RecommendationItem recommendation;
  final String certificateId;

  const CertificateFront({
    Key? key,
    required this.recommendation,
    required this.certificateId,
  }) : super(key: key);

  @override
  State<CertificateFront> createState() => _CertificateFrontState();
}

class _CertificateFrontState extends State<CertificateFront> {
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final DateFormat dateFormatter = DateFormat('dd MMMM yyyy');
    final String currentDate = dateFormatter.format(DateTime.now());
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double certificateWidth = constraints.maxWidth;
        // Menyesuaikan rasio aspek untuk mengurangi tinggi keseluruhan
        final double certificateHeight =
            certificateWidth * 0.6; // Rasio 10:6 lebih pendek dari 10:7

        return Container(
          width: certificateWidth,
          height: certificateHeight,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.4),
              radius: 1.5,
              colors: [
                Colors.blue.shade700,
                Colors.blue.shade800,
                Colors.indigo.shade900,
              ],
              stops: [0.0, 0.4, 0.9],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background pattern elements
              Positioned.fill(
                child: CustomPaint(
                  painter: CertificateBackgroundPainter(),
                ),
              ),

              // Certificate content
              Padding(
                padding: EdgeInsets.all(certificateWidth * 0.03),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            "EG",
                            style: TextStyle(
                              fontSize: certificateWidth * 0.035,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "EduGuide",
                          style: TextStyle(
                            fontSize: certificateWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: certificateHeight * 0.01),

                    // Certificate title
                    Text(
                      "SERTIFIKAT TES MINAT BAKAT",
                      style: TextStyle(
                        fontSize: certificateWidth * 0.033,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),

                    Divider(
                      color: Colors.white.withOpacity(0.5),
                      thickness: 1,
                      indent: certificateWidth * 0.2,
                      endIndent: certificateWidth * 0.2,
                      height: certificateHeight * 0.04,
                    ),

                    // Student name placeholder
                    Text(
                      "Dengan ini menyatakan bahwa",
                      style: TextStyle(
                        fontSize: certificateWidth * 0.03,
                        color: Colors.white.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    SizedBox(height: certificateHeight * 0.02),

                    // Student name will be added dynamically

                    // Student name - Firebase integration
                    FutureBuilder<String>(
                      // First, get the school ID from SharedPreferences
                      future: () async {
                        final prefs = await SharedPreferences.getInstance();
                        return prefs.getString('school_id') ?? '';
                      }(),
                      builder: (context, schoolSnapshot) {
                        if (schoolSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            width: 320,
                            height: 65,
                            decoration: BoxDecoration(
                              color: const Color(0xFF159895).withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF1A5F7A)),
                                ),
                              ),
                            ),
                          );
                        }

                        // Once we have the school ID (or not), proceed
                        String schoolId = schoolSnapshot.data ?? '';

                        return FutureBuilder<DocumentSnapshot?>(
                          future: schoolId.isNotEmpty
                              // If we have a school ID, try to get the student directly
                              ? FirebaseFirestore.instance
                                  .collection('schools')
                                  .doc(schoolId)
                                  .collection('students')
                                  .doc(currentUser?.uid)
                                  .get()
                              // If no school ID, find the student in all schools
                              : _findStudentInAllSchools(currentUser?.uid),
                          builder: (context, snapshot) {
                            String userName = "Siswa";
                            String userClass = "";

                            if (snapshot.hasData &&
                                snapshot.data != null &&
                                snapshot.data!.exists) {
                              final userData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              userName = userData['name'] ?? "Siswa";
                              userClass = userData['class'] ?? "";
                            }

                            return Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 320,
                                      height: 65,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF159895)
                                            .withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    Text(
                                      userName,
                                      style: TextStyle(
                                        fontSize: certificateWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                if (userClass.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      userClass,
                                      style: TextStyle(
                                        fontSize: certificateWidth * 0.03,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),

                    SizedBox(height: certificateHeight * 0.02),

                    // Award information
                    Text(
                      "telah berhasil menyelesaikan Tes Minat Bakat",
                      style: TextStyle(
                        fontSize: certificateWidth * 0.03,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),

                    SizedBox(height: certificateHeight * 0.02),

                    // Recommendation title with accent
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: certificateWidth * 0.03,
                        vertical: certificateHeight * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        widget.recommendation.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: certificateWidth * 0.03,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    SizedBox(height: certificateHeight * 0.01),

                    // Recommended majors section - Lebih compact

                    SizedBox(height: certificateHeight * 0.02),

                    // Date and signature row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              currentDate,
                              style: TextStyle(
                                fontSize: certificateWidth * 0.02,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              width: certificateWidth * 0.15,
                              height: 1,
                              color: Colors.white.withOpacity(0.5),
                              margin: EdgeInsets.only(top: 3),
                            ),
                            Text(
                              "Tanggal",
                              style: TextStyle(
                                fontSize: certificateWidth * 0.018,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),

                        // Certificate ID
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "ID: ${widget.certificateId}",
                              style: TextStyle(
                                fontSize: certificateWidth * 0.018,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),

                        // Signature
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "EduGuide Team",
                              style: TextStyle(
                                fontSize: certificateWidth * 0.02,
                                fontFamily: 'Signature',
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              width: certificateWidth * 0.15,
                              height: 1,
                              color: Colors.white.withOpacity(0.5),
                              margin: EdgeInsets.only(top: 3),
                            ),
                            Text(
                              "Tanda Tangan",
                              style: TextStyle(
                                fontSize: certificateWidth * 0.018,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Border decoration
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<DocumentSnapshot?> _findStudentInAllSchools(String? studentId) async {
    if (studentId == null) return null;

    try {
      // Get all schools
      final schoolsCollection =
          await FirebaseFirestore.instance.collection('schools').get();

      // For each school, check if this student exists
      for (var school in schoolsCollection.docs) {
        final studentDoc = await FirebaseFirestore.instance
            .collection('schools')
            .doc(school.id)
            .collection('students')
            .doc(studentId)
            .get();

        if (studentDoc.exists) {
          return studentDoc;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error finding student: $e');
      return null;
    }
  }
}

// CustomPainter untuk membuat background pattern yang estetik
class CertificateBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient overlay
    final Rect fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.07),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(fullRect);

    canvas.drawRect(fullRect, gradientPaint);

    // Wavy pattern in the middle
    final Path wavyPath = Path();
    final double amplitude = size.height * 0.02;
    final double frequency = 0.1;
    final double startY = size.height * 0.5;

    wavyPath.moveTo(0, startY);
    for (double x = 0; x <= size.width; x += 1) {
      double y = startY + amplitude * math.sin(frequency * x);
      wavyPath.lineTo(x, y);
    }

    canvas.drawPath(
        wavyPath,
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Pattern 1: Abstract geometric shapes
    // Diamond pattern
    final double diamondSize = size.width * 0.04;
    final double spacing = size.width * 0.15;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        // Only draw diamonds in certain areas to create a pattern
        if ((x / spacing).round() % 3 == (y / spacing).round() % 3) {
          final Path diamondPath = Path();
          diamondPath.moveTo(x, y - diamondSize);
          diamondPath.lineTo(x + diamondSize, y);
          diamondPath.lineTo(x, y + diamondSize);
          diamondPath.lineTo(x - diamondSize, y);
          diamondPath.close();

          canvas.drawPath(
              diamondPath,
              Paint()
                ..color = Colors.white.withOpacity(0.04)
                ..style = PaintingStyle.fill);

          canvas.drawPath(
              diamondPath,
              Paint()
                ..color = Colors.white.withOpacity(0.08)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.5);
        }
      }
    }

    // Pattern 2: Light rays emanating from center
    final Paint rayPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    for (int i = 0; i < 24; i++) {
      final double angle = (i * math.pi / 12);
      final double length = math.max(size.width, size.height) * 0.6;

      canvas.drawLine(
          Offset(centerX, centerY),
          Offset(centerX + math.cos(angle) * length,
              centerY + math.sin(angle) * length),
          rayPaint);
    }

    // Pattern 3: Subtle circle patterns
    for (int i = 0; i < 30; i++) {
      double radius =
          math.Random().nextDouble() * size.width * 0.025 + size.width * 0.005;
      double x = math.Random().nextDouble() * size.width;
      double y = math.Random().nextDouble() * size.height;

      // Create glowing effect with multiple circles
      for (int j = 0; j < 3; j++) {
        double glowRadius = radius * (1 + j * 0.5);
        double opacity = 0.02 / (j + 1);

        canvas.drawCircle(
            Offset(x, y),
            glowRadius,
            Paint()
              ..color = Colors.white.withOpacity(opacity)
              ..style = PaintingStyle.fill);
      }

      canvas.drawCircle(
          Offset(x, y),
          radius,
          Paint()
            ..color = Colors.white.withOpacity(0.05)
            ..style = PaintingStyle.fill);
    }

    // Decorative border with ornate corners
    final double cornerSize = size.width * 0.12;
    final double borderWidth = 2.0;

    // Create a fancy corner design
    void drawOrnateCorner(double startX, double startY, double endX,
        double endY, double controlX, double controlY) {
      final Path cornerPath = Path();
      cornerPath.moveTo(startX, startY);
      cornerPath.quadraticBezierTo(controlX, controlY, endX, endY);

      canvas.drawPath(
          cornerPath,
          Paint()
            ..color = Colors.white.withOpacity(0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = borderWidth);

      // Add small circle decoration at corner point
      canvas.drawCircle(
          Offset(controlX, controlY),
          borderWidth * 1.5,
          Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..style = PaintingStyle.fill);
    }

    // Top left corner
    drawOrnateCorner(
        0, cornerSize, cornerSize, 0, cornerSize * 0.3, cornerSize * 0.3);

    // Top right corner
    drawOrnateCorner(size.width - cornerSize, 0, size.width, cornerSize,
        size.width - cornerSize * 0.3, cornerSize * 0.3);

    // Bottom right corner
    drawOrnateCorner(
        size.width,
        size.height - cornerSize,
        size.width - cornerSize,
        size.height,
        size.width - cornerSize * 0.3,
        size.height - cornerSize * 0.3);

    // Bottom left corner
    drawOrnateCorner(cornerSize, size.height, 0, size.height - cornerSize,
        cornerSize * 0.3, size.height - cornerSize * 0.3);

    // Add decorative elements at each corner
    void drawCornerDecoration(
        double x, double y, double size, double rotation) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final Path decorPath = Path();
      decorPath.moveTo(0, -size);
      decorPath.lineTo(size * 0.5, 0);
      decorPath.lineTo(0, size);
      decorPath.lineTo(-size * 0.5, 0);
      decorPath.close();

      canvas.drawPath(
          decorPath,
          Paint()
            ..color = Colors.white.withOpacity(0.2)
            ..style = PaintingStyle.fill);

      canvas.drawPath(
          decorPath,
          Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8);

      canvas.restore();
    }

    final double decorSize = cornerSize * 0.3;

    // Corner decorations
    drawCornerDecoration(cornerSize * 0.5, cornerSize * 0.5, decorSize, 0);
    drawCornerDecoration(size.width - cornerSize * 0.5, cornerSize * 0.5,
        decorSize, math.pi * 0.5);
    drawCornerDecoration(size.width - cornerSize * 0.5,
        size.height - cornerSize * 0.5, decorSize, math.pi);
    drawCornerDecoration(cornerSize * 0.5, size.height - cornerSize * 0.5,
        decorSize, math.pi * 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Enhanced background painter for front certificate
class EnhancedCertificateBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  EnhancedCertificateBackgroundPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Base background color
    final Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Create a soft gradient background
    final Rect rect = Rect.fromLTRB(0, 0, size.width, size.height);
    final Gradient gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        Colors.blue.shade50,
        Colors.indigo.shade50,
        Colors.white,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final Paint gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, gradientPaint);

    // Draw elegant dot pattern
    final dotPaint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Small dots pattern - create a grid of dots
    for (int i = 0; i < size.width; i += 20) {
      for (int j = 0; j < size.height; j += 20) {
        // Draw tiny circles
        canvas.drawCircle(
          Offset(i.toDouble(), j.toDouble()),
          0.8,
          dotPaint,
        );
      }
    }

    // Add decorative ribbons at the top
    final ribbonPaint = Paint()
      ..color = primaryColor.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final topRibbonPath = Path();
    topRibbonPath.moveTo(0, 0);
    topRibbonPath.lineTo(size.width, 0);
    topRibbonPath.lineTo(size.width, 60);
    topRibbonPath.quadraticBezierTo(
        size.width * 0.75, 50, size.width * 0.5, 60);
    topRibbonPath.quadraticBezierTo(size.width * 0.25, 70, 0, 60);
    topRibbonPath.close();
    canvas.drawPath(topRibbonPath, ribbonPaint);

    // Add decorative ribbons at the bottom
    final bottomRibbonPath = Path();
    bottomRibbonPath.moveTo(0, size.height);
    bottomRibbonPath.lineTo(size.width, size.height);
    bottomRibbonPath.lineTo(size.width, size.height - 60);
    bottomRibbonPath.quadraticBezierTo(size.width * 0.75, size.height - 50,
        size.width * 0.5, size.height - 60);
    bottomRibbonPath.quadraticBezierTo(
        size.width * 0.25, size.height - 70, 0, size.height - 60);
    bottomRibbonPath.close();
    canvas.drawPath(bottomRibbonPath, ribbonPaint);

    // Draw decorative wave patterns
    final wavePaint = Paint()
      ..color = secondaryColor.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Multiple wave lines for richer effect
    // Top waves
    for (int offset = 0; offset < 3; offset++) {
      final topWavePath = Path();
      topWavePath.moveTo(0, 100 + (offset * 15));

      for (int i = 0; i < size.width / 40; i++) {
        topWavePath.quadraticBezierTo(
          (i * 40) + 20,
          90 + (offset * 15) + (i % 2 == 0 ? 5 : 0),
          (i * 40) + 40,
          100 + (offset * 15),
        );
      }
      canvas.drawPath(topWavePath, wavePaint);
    }

    // Bottom waves
    for (int offset = 0; offset < 3; offset++) {
      final bottomWavePath = Path();
      bottomWavePath.moveTo(0, size.height - 100 - (offset * 15));

      for (int i = 0; i < size.width / 40; i++) {
        bottomWavePath.quadraticBezierTo(
          (i * 40) + 20,
          size.height - 90 - (offset * 15) - (i % 2 == 0 ? 5 : 0),
          (i * 40) + 40,
          size.height - 100 - (offset * 15),
        );
      }
      canvas.drawPath(bottomWavePath, wavePaint);
    }

    // Add decorative accent lines
    final accentPaint = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Add diagonal accent lines in corners
    // Top left
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width * 0.2, size.height * 0.2),
      accentPaint,
    );

    // Top right
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width * 0.8, size.height * 0.2),
      accentPaint,
    );

    // Bottom left
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width * 0.2, size.height * 0.8),
      accentPaint,
    );

    // Bottom right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width * 0.8, size.height * 0.8),
      accentPaint,
    );

    // Add decorative circular elements
    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = primaryColor.withOpacity(0.15)
      ..strokeWidth = 1.5;

    // Draw circles in the corners
    canvas.drawCircle(Offset(0, 0), 100, circlePaint);
    canvas.drawCircle(Offset(size.width, 0), 100, circlePaint);
    canvas.drawCircle(Offset(0, size.height), 100, circlePaint);
    canvas.drawCircle(Offset(size.width, size.height), 100, circlePaint);

    // Create radial gradient effect in corners for added depth
    final cornerGradient = RadialGradient(
      colors: [
        primaryColor.withOpacity(0.1),
        Colors.white.withOpacity(0.0),
      ],
    );

    final cornerPaint1 = Paint()
      ..shader = cornerGradient
          .createShader(Rect.fromCircle(center: Offset(0, 0), radius: 200));
    canvas.drawCircle(Offset(0, 0), 200, cornerPaint1);

    final cornerPaint2 = Paint()
      ..shader = cornerGradient.createShader(
          Rect.fromCircle(center: Offset(size.width, 0), radius: 200));
    canvas.drawCircle(Offset(size.width, 0), 200, cornerPaint2);

    final cornerPaint3 = Paint()
      ..shader = cornerGradient.createShader(
          Rect.fromCircle(center: Offset(0, size.height), radius: 200));
    canvas.drawCircle(Offset(0, size.height), 200, cornerPaint3);

    final cornerPaint4 = Paint()
      ..shader = cornerGradient.createShader(Rect.fromCircle(
          center: Offset(size.width, size.height), radius: 200));
    canvas.drawCircle(Offset(size.width, size.height), 200, cornerPaint4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Corner Element Painter
class CornerElementPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  CornerElementPainter({
    required this.primaryColor,
    this.secondaryColor = Colors.transparent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Main outline
    final outlinePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Draw decorative corner element with more details
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.lineTo(0, 0);
    path.lineTo(size.width * 0.8, 0);

    // Add fancy corner flourish
    path.moveTo(0, size.height * 0.4);
    path.quadraticBezierTo(
      size.width * 0.05,
      size.height * 0.35,
      size.width * 0.2,
      size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.15,
      size.width * 0.4,
      0,
    );

    // Add another decorative curve
    path.moveTo(size.width * 0.2, 0);
    path.quadraticBezierTo(
      size.width * 0.15,
      size.height * 0.15,
      0,
      size.height * 0.3,
    );

    canvas.drawPath(path, outlinePaint);

    // Add decorative circles
    final fillPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Add main decorative circle
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.05,
      fillPaint,
    );

    // Add smaller decorative circles
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.3),
      size.width * 0.02,
      fillPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.3),
      size.width * 0.02,
      fillPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.7),
      size.width * 0.02,
      fillPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.7),
      size.width * 0.02,
      fillPaint,
    );

    // Add thin line flourishes
    final thinPaint = Paint()
      ..color = primaryColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Diagonal line
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width, size.height),
      thinPaint,
    );

    // Cross lines
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.5),
      thinPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.7),
      thinPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class DecorativeBorderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double borderWidth;

  DecorativeBorderPainter({
    required this.primaryColor,
    required this.secondaryColor,
    this.borderWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mainBorderPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Outer border with fancy corners
    final outerPath = Path();

    // Top-left corner
    outerPath.moveTo(size.width * 0.05, 0);
    outerPath.lineTo(size.width * 0.95, 0);

    // Top-right corner with flourish
    outerPath.quadraticBezierTo(size.width, 0, size.width, size.height * 0.05);
    outerPath.lineTo(size.width, size.height * 0.95);

    // Bottom-right corner with flourish
    outerPath.quadraticBezierTo(
        size.width, size.height, size.width * 0.95, size.height);
    outerPath.lineTo(size.width * 0.05, size.height);

    // Bottom-left corner with flourish
    outerPath.quadraticBezierTo(0, size.height, 0, size.height * 0.95);
    outerPath.lineTo(0, size.height * 0.05);

    // Back to top-left with flourish
    outerPath.quadraticBezierTo(0, 0, size.width * 0.05, 0);

    canvas.drawPath(outerPath, mainBorderPaint);

    // Inner border
    final innerBorderPaint = Paint()
      ..color = secondaryColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 0.5;

    final padding = borderWidth * 4;
    final innerRect = Rect.fromLTRB(
        padding, padding, size.width - padding, size.height - padding);

    // Draw rounded rect for inner border
    canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect, Radius.circular(padding * 0.5)),
        innerBorderPaint);

    // Add decorative corners
    final cornerSize = padding * 1.5;

    // Draw corner accents
    _drawCornerAccent(
        canvas, Offset(padding, padding), cornerSize, primaryColor);
    _drawCornerAccent(
        canvas, Offset(size.width - padding, padding), cornerSize, primaryColor,
        angle: 1.57);
    _drawCornerAccent(
        canvas,
        Offset(size.width - padding, size.height - padding),
        cornerSize,
        primaryColor,
        angle: 3.14);
    _drawCornerAccent(canvas, Offset(padding, size.height - padding),
        cornerSize, primaryColor,
        angle: 4.71);

    // Add subtle gradient overlay to the borders
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withOpacity(0.1),
          secondaryColor.withOpacity(0.1),
          primaryColor.withOpacity(0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 2;

    // Draw gradient overlay along borders
    canvas.drawPath(outerPath, gradientPaint);
  }

  void _drawCornerAccent(
      Canvas canvas, Offset position, double size, Color color,
      {double angle = 0}) {
    canvas.save();
    canvas.translate(position.dx, position.dy);

    if (angle != 0) {
      canvas.rotate(angle);
    }

    final accentPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 0.3;

    final accentPath = Path();
    accentPath.moveTo(0, size * 0.5);
    accentPath.lineTo(0, 0);
    accentPath.lineTo(size * 0.5, 0);

    // Add flourish
    accentPath.moveTo(size * 0.2, 0);
    accentPath.quadraticBezierTo(size * 0.1, size * 0.1, 0, size * 0.2);

    canvas.drawPath(accentPath, accentPaint);

    // Add small dot decoration
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size * 0.3, size * 0.3), borderWidth * 0.4, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Decorative Edges Painter - not using this anymore to avoid visual clutter
class DecorativeEdgesPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  DecorativeEdgesPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Not implementing to reduce visual elements
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class CertificateBack extends StatefulWidget {
  final RecommendationItem recommendation;

  const CertificateBack({
    Key? key,
    required this.recommendation,
  }) : super(key: key);

  @override
  State<CertificateBack> createState() => _CertificateBackState();
}

class _CertificateBackState extends State<CertificateBack>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Start animations
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.4),
          radius: 1.5,
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade800,
            Colors.indigo.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background with lighter pattern
          Positioned.fill(
            child: CustomPaint(
              painter: CertificateBackgroundPainter(),
            ),
          ),
          // Border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 3,
                  color: const Color(0xFFd9dbe6),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(50.0, 50.0, 50.0, 30.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'DETAIL REKOMENDASI',
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFd9dbe6),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 150,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFd9dbe6), Color(0xFF57C5B6)],
                        ),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recommendation title
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      widget.recommendation.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Scroll view for content to prevent overflow
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Two columns layout for careers and majors
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Careers
                              Expanded(
                                child: _buildDetailSection(
                                  'Karir yang Cocok:',
                                  widget.recommendation.careers,
                                  const Icon(Icons.work,
                                      color: Color(0xFFd9dbe6)),
                                ),
                              ),
                              const SizedBox(width: 30),
                              // Majors
                              Expanded(
                                child: _buildDetailSection(
                                  'Jurusan yang Cocok:',
                                  widget.recommendation.majors,
                                  const Icon(Icons.school,
                                      color: Color(0xFFd9dbe6)),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Recommended courses and universities if available
                          if (widget.recommendation.recommendedCourses !=
                                  null ||
                              widget.recommendation.recommendedUniversities !=
                                  null)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.recommendation.recommendedCourses !=
                                    null)
                                  Expanded(
                                    child: _buildDetailSection(
                                      'Mata Kuliah yang Cocok:',
                                      widget.recommendation.recommendedCourses!,
                                      const Icon(Icons.menu_book,
                                          color: Color(0xFFd9dbe6)),
                                    ),
                                  ),
                                if (widget.recommendation.recommendedCourses !=
                                        null &&
                                    widget.recommendation
                                            .recommendedUniversities !=
                                        null)
                                  const SizedBox(width: 30),
                                if (widget.recommendation
                                        .recommendedUniversities !=
                                    null)
                                  Expanded(
                                    child: _buildDetailSection(
                                      'Universitas yang Cocok:',
                                      widget.recommendation
                                          .recommendedUniversities!,
                                      const Icon(Icons.account_balance,
                                          color: Color(0xFFd9dbe6)),
                                    ),
                                  ),
                              ],
                            ),

                          const SizedBox(height: 20),

                          // Footer
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFd9dbe6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      const Color(0xFFd9dbe6).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'Hasil analisis ini disusun dari jawaban dan minat yang kamu berikan.\n'
                                'Gunakan info ini untuk membantu merencanakan masa depanmu dengan lebih baik.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Decorative corners
          Positioned(
            top: 35,
            left: 35,
            child: _buildDetailCorner(),
          ),
          Positioned(
            top: 35,
            right: 35,
            child: Transform.rotate(
              angle: 1.57,
              child: _buildDetailCorner(),
            ),
          ),
          Positioned(
            bottom: 35,
            right: 35,
            child: Transform.rotate(
              angle: 3.14,
              child: _buildDetailCorner(),
            ),
          ),
          Positioned(
            bottom: 35,
            left: 35,
            child: Transform.rotate(
              angle: 4.71,
              child: _buildDetailCorner(),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to simplify rules text
  List<String> _simplifyRules(List<String> rules) {
    List<String> simplifiedRules = [];

    for (String rule in rules) {
      // Replace common complex phrases with simpler alternatives
      String simplified = rule
          .replaceAll('direkomendasikan', 'cocok')
          .replaceAll('berdasarkan analisis', 'karena')
          .replaceAll('memiliki ketertarikan yang tinggi', 'tertarik')
          .replaceAll('memiliki kemampuan yang baik', 'kamu mampu')
          .replaceAll('menunjukkan minat yang kuat', 'kamu suka')
          .replaceAll('berdasarkan jawaban anda', 'dari jawabanmu')
          .replaceAll('mempunyai potensi untuk', 'bisa')
          .replaceAll('sangat sesuai dengan', 'cocok dengan');

      // Make first letter uppercase if needed
      if (simplified.isNotEmpty) {
        simplified = simplified[0].toUpperCase() + simplified.substring(1);
      }

      simplifiedRules.add(simplified);
    }

    return simplifiedRules;
  }

  Widget _buildDetailSection(String title, List<String> items, Icon icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon,
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFd9dbe6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          overflow: TextOverflow.visible,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildDetailCorner() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(width: 3, color: const Color(0xFFd9dbe6)),
          top: BorderSide(width: 3, color: const Color(0xFFd9dbe6)),
        ),
      ),
    );
  }
}

class FloatingParticlesPainter extends CustomPainter {
  final List<ParticleModel> particles;
  final double animation; // 0.0 to 1.0

  FloatingParticlesPainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Calculate current position with animation
      // Make particles float upward and wiggle a bit
      final y = (particle.position.dy - (animation * particle.speed)) % 1.0;
      final wiggle =
          math.sin(animation * 2 * math.pi + particle.position.dx * 10) * 0.02;
      final x = (particle.position.dx + wiggle) % 1.0;

      // Draw the particle
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FloatingParticlesPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class CertificateReccomendationPage extends StatefulWidget {
  final RecommendationResult result;
  final String rawMessage;
  const CertificateReccomendationPage({
    required this.result,
    this.rawMessage = '',
    Key? key,
  }) : super(key: key);

  @override
  State<CertificateReccomendationPage> createState() =>
      _CertificateReccomendationPageState();
}

class _CertificateReccomendationPageState
    extends State<CertificateReccomendationPage> with TickerProviderStateMixin {
  final GlobalKey _certificateFrontKey = GlobalKey();
  final GlobalKey _certificateBackKey = GlobalKey();
  final PageController _pageController = PageController();

  bool _isGenerating = false;
  bool _isRevealed = false;
  int _currentPage = 0;
  String _certificateId = '';

  // A4 Landscape dimensions in pixels (assuming 96 DPI)
  // 297mm x 210mm
  final double _a4Width = 1123; // 297mm at 96 DPI
  final double _a4Height = 794; // 210mm at 96 DPI

  late AnimationController _pageIndicatorController;
  late AnimationController _floatingParticlesController;

  // For additional floating particles effect
  final List<ParticleModel> _particles = [];

  @override
  void initState() {
    super.initState();
    _generateCertificateId();

    _pageIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _floatingParticlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    _pageController.addListener(() {
      // Update the page indicator animation
      if (_pageController.page != null) {
        _pageIndicatorController.value = _pageController.page!;
      }

      // Update current page for UI state
      if (_pageController.page != null &&
          _pageController.page!.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });

    // Initialize floating particles
    _initializeParticles();
  }

  void _initializeParticles() {
    // Generate 15 random particles
    for (int i = 0; i < 15; i++) {
      _particles.add(
        ParticleModel(
          position: Offset(
            math.Random().nextDouble(),
            math.Random().nextDouble(),
          ),
          speed: 0.2 + math.Random().nextDouble() * 0.4, // between 0.2 and 0.6
          size: 3 + math.Random().nextDouble() * 7, // between 3 and 10
          color: const Color(0xFF57C5B6).withOpacity(
            0.1 + math.Random().nextDouble() * 0.3, // between 0.1 and 0.4
          ),
        ),
      );
    }
  }

  // Generate a unique certificate ID
  void _generateCertificateId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(6);
    _certificateId = 'CERT-$timestamp';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageIndicatorController.dispose();
    _floatingParticlesController.dispose();
    super.dispose();
  }

  // Capture the certificate using its RenderRepaintBoundary
  Future<Uint8List?> _captureCertificate(GlobalKey key) async {
    try {
      // Ensure the build is complete
      await Future.delayed(const Duration(milliseconds: 500));

      final context = key.currentContext;
      if (context == null) {
        return null;
      }

      final renderObject = context.findRenderObject();
      if (renderObject == null || !renderObject.attached) {
        return null;
      }

      final boundary = renderObject as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      debugPrint('Error capturing certificate: $e');
      return null;
    }
  }

  // Save both certificate front and back to gallery
  Future<void> _saveCertificate() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final title =
          widget.result.recommendations.first.title.replaceAll("|", "_");
      bool frontSuccess = false;
      bool backSuccess = false;

      // First capture front of certificate (go to page 0)
      if (_currentPage != 0) {
        await _pageController.animateToPage(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final frontBytes = await _captureCertificate(_certificateFrontKey);
      if (frontBytes != null) {
        final resultFront = await ImageGallerySaverPlus.saveImage(frontBytes,
            quality: 100, name: "certificate_front_${title}_$timestamp");
        frontSuccess = resultFront['isSuccess'] ?? false;
      }

      // Then capture back of certificate (go to page 1)
      await _pageController.animateToPage(1,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      await Future.delayed(const Duration(milliseconds: 500));

      final backBytes = await _captureCertificate(_certificateBackKey);
      if (backBytes != null) {
        final resultBack = await ImageGallerySaverPlus.saveImage(backBytes,
            quality: 100, name: "certificate_back_${title}_$timestamp");
        backSuccess = resultBack['isSuccess'] ?? false;
      }

      // Show result
      String message;
      Color backgroundColor;

      if (frontSuccess && backSuccess) {
        message = 'Kedua sisi sertifikat berhasil disimpan di galeri';
        backgroundColor = Colors.green;
      } else if (frontSuccess) {
        message = 'Hanya bagian depan sertifikat yang berhasil disimpan';
        backgroundColor = Colors.orange;
      } else if (backSuccess) {
        message = 'Hanya bagian belakang sertifikat yang berhasil disimpan';
        backgroundColor = Colors.orange;
      } else {
        message = 'Gagal menyimpan sertifikat';
        backgroundColor = Colors.red;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error in saving certificate: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat menyimpan sertifikat'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // Share certificate
  Future<void> _shareCertificate() async {
    try {
      setState(() {
        _isGenerating = true;
      });

      final tempDir = await getTemporaryDirectory();
      final List<XFile> filesToShare = [];

      // First capture front of certificate (go to page 0)
      if (_currentPage != 0) {
        await _pageController.animateToPage(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final frontBytes = await _captureCertificate(_certificateFrontKey);
      if (frontBytes != null) {
        final frontPath = '${tempDir.path}/certificate_front.png';
        final frontFile = File(frontPath);
        await frontFile.writeAsBytes(frontBytes);
        filesToShare.add(XFile(frontPath));
      }

      // Then capture back of certificate (go to page 1)
      await _pageController.animateToPage(1,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      await Future.delayed(const Duration(milliseconds: 500));

      final backBytes = await _captureCertificate(_certificateBackKey);
      if (backBytes != null) {
        final backPath = '${tempDir.path}/certificate_back.png';
        final backFile = File(backPath);
        await backFile.writeAsBytes(backBytes);
        filesToShare.add(XFile(backPath));
      }

      if (filesToShare.isNotEmpty) {
        // Share files
        await Share.shareXFiles(filesToShare,
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

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

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
    final recommendation = widget.result.recommendations.first;

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            _currentPage == 0
                ? 'Sertifikat Hasil Analisis'
                : 'Detail Rekomendasi',
            key: ValueKey<int>(_currentPage),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade700,
              Colors.indigo.shade800,
              Colors.blue.shade700,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative elements
            Positioned.fill(
              child: CustomPaint(
                painter: EnhancedBackgroundPainter(),
              ),
            ),

            // Floating particles animation
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _floatingParticlesController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: FloatingParticlesPainter(
                      particles: _particles,
                      animation: _floatingParticlesController.value,
                    ),
                    size: MediaQuery.of(context).size,
                  );
                },
              ),
            ),

            // Content
            Column(
              children: [
                // Page indicator
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPageIndicator(0),
                      const SizedBox(width: 8),
                      _buildPageIndicator(1),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: !_isRevealed
                      ? _buildRevealContainer()
                      : _buildPageView(recommendation),
                ),

                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealContainer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pre-reveal animation
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade100,
                  Colors.white,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade200.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.indigo.shade200.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: Offset(10, 10),
                ),
              ],
            ),
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.5 + (value * 0.5),
                    child: Opacity(
                      opacity: value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow effect behind the certificate
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade400
                                      .withOpacity(0.2 * value),
                                  blurRadius: 30 * value,
                                  spreadRadius: 10 * value,
                                ),
                              ],
                            ),
                          ),

                          // Medal icon with gradient
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade700,
                                Colors.indigo.shade800,
                                Colors.blue.shade700,
                              ],
                            ).createShader(bounds),
                            child: Icon(
                              Icons.workspace_premium,
                              size: 105,
                              color: Colors.white,
                            ),
                          ),

                          // Shine effect
                          AnimatedBuilder(
                            animation: _floatingParticlesController,
                            builder: (context, child) {
                              return Positioned(
                                top: 25 +
                                    (10 *
                                        math.sin(
                                            _floatingParticlesController.value *
                                                math.pi *
                                                2)),
                                right: 25 +
                                    (5 *
                                        math.cos(
                                            _floatingParticlesController.value *
                                                math.pi *
                                                2)),
                                child: Container(
                                  width: 15,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.9),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.5),
                                        blurRadius: 5,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isRevealed = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade900,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
              shadowColor: Colors.indigo.withOpacity(0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.visibility,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Tampilkan Sertifikat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView(RecommendationItem recommendation) {
    return PageView(
      controller: _pageController,
      physics: const PagePhysics(),
      children: [
        // Front certificate
        Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _a4Width,
                  height: _a4Height,
                  child: MagicRevealAnimation(
                    child: RepaintBoundary(
                      key: _certificateFrontKey,
                      child: CertificateFront(
                        recommendation: recommendation,
                        certificateId: _certificateId,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Back certificate
        Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _a4Width,
                  height: _a4Height,
                  child: RepaintBoundary(
                    key: _certificateBackKey,
                    child: CertificateBack(
                      recommendation: recommendation,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(int pageIndex) {
    final isActive = _currentPage == pageIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 24.0 : 12.0,
      height: 8.0,
      decoration: BoxDecoration(
        color: isActive
            ? Colors.blue.shade800
            : Colors.indigo.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4.0),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.blue.shade800.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: !_isRevealed
            ? const SizedBox.shrink() // Hide buttons before reveal
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _saveCertificate,
                      icon: const Icon(Icons.save),
                      label: Text(_isGenerating ? 'Menyimpan...' : 'Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                        shadowColor: Colors.blue.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _shareCertificate,
                      icon: const Icon(Icons.share),
                      label: Text(_isGenerating ? 'Membagikan...' : 'Bagikan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                        shadowColor: Colors.indigo.shade300,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class EnhancedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background subtle elements

    // Soft curves
    final Path curvePath1 = Path();
    curvePath1.moveTo(0, size.height * 0.1);
    curvePath1.quadraticBezierTo(size.width * 0.2, size.height * 0.05,
        size.width * 0.4, size.height * 0.1);

    canvas.drawPath(
        curvePath1,
        Paint()
          ..color = Colors.blue.shade100.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 15);

    final Path curvePath2 = Path();
    curvePath2.moveTo(size.width, size.height * 0.5);
    curvePath2.quadraticBezierTo(size.width * 0.7, size.height * 0.6,
        size.width * 0.5, size.height * 0.5);

    canvas.drawPath(
        curvePath2,
        Paint()
          ..color = Colors.indigo.shade100.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 15);

    // Subtle circles
    final random = math.Random(123); // Fixed seed for consistency
    for (int i = 0; i < 20; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double radius = random.nextDouble() * 30 + 5;

      canvas.drawCircle(
          Offset(x, y),
          radius,
          Paint()
            ..color = (i % 2 == 0 ? Colors.blue : Colors.indigo)
                .withOpacity(0.03 + (random.nextDouble() * 0.02))
            ..style = PaintingStyle.fill);
    }

    // Abstract geometric elements in the corners
    final double cornerSize = 100;

    // Top right
    final Path diamondPath = Path();
    final double diamondX = size.width - cornerSize * 0.5;
    final double diamondY = cornerSize * 0.5;
    final double diamondSize = 30;

    diamondPath.moveTo(diamondX, diamondY - diamondSize);
    diamondPath.lineTo(diamondX + diamondSize, diamondY);
    diamondPath.lineTo(diamondX, diamondY + diamondSize);
    diamondPath.lineTo(diamondX - diamondSize, diamondY);
    diamondPath.close();

    canvas.drawPath(
        diamondPath,
        Paint()
          ..color = Colors.blue.shade300.withOpacity(0.1)
          ..style = PaintingStyle.fill);

    // Bottom left
    final double triangleX = cornerSize * 0.5;
    final double triangleY = size.height - cornerSize * 0.5;
    final double triangleSize = 40;

    final Path trianglePath = Path();
    trianglePath.moveTo(triangleX, triangleY - triangleSize);
    trianglePath.lineTo(triangleX + triangleSize, triangleY + triangleSize);
    trianglePath.lineTo(triangleX - triangleSize, triangleY + triangleSize);
    trianglePath.close();

    canvas.drawPath(
        trianglePath,
        Paint()
          ..color = Colors.indigo.shade300.withOpacity(0.1)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom page physics for better swipe experience
class PagePhysics extends ScrollPhysics {
  const PagePhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  PagePhysics applyTo(ScrollPhysics? ancestor) {
    return PagePhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 80,
        stiffness: 100,
        damping: 1,
      );
}

// Model for floating particles
class ParticleModel {
  Offset position; // Value between 0.0 and 1.0 for screen relative positioning
  final double speed;
  final double size;
  final Color color;

  ParticleModel({
    required this.position,
    required this.speed,
    required this.size,
    required this.color,
  });
}

// Background painter for detail page
class DetailBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base background color
    final Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Create a soft gradient background
    final Rect rect = Rect.fromLTRB(0, 0, size.width, size.height);
    final Gradient gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFF8FDFF),
        const Color(0xFFF0F7F8),
        const Color(0xFFF8FDFF),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final Paint gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, gradientPaint);

    // Draw subtle dot pattern
    final dotPaint = Paint()
      ..color = const Color(0xFFd9dbe6).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Dot pattern
    for (int i = 0; i < size.width; i += 30) {
      for (int j = 0; j < size.height; j += 30) {
        // Draw small dots
        canvas.drawCircle(
          Offset(i.toDouble(), j.toDouble()),
          1,
          dotPaint,
        );
      }
    }

    // Add subtle waves at top and bottom
    final wavePaint = Paint()
      ..color = const Color(0xFF57C5B6).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Top waves
    final topWavePath = Path();
    topWavePath.moveTo(0, 0);
    topWavePath.lineTo(0, 70);

    for (int i = 0; i < (size.width / 80).ceil(); i++) {
      topWavePath.quadraticBezierTo(
        (i * 80) + 40,
        40,
        (i * 80) + 80,
        70,
      );
    }

    topWavePath.lineTo(size.width, 0);
    topWavePath.close();

    // Bottom waves
    final bottomWavePath = Path();
    bottomWavePath.moveTo(0, size.height);
    bottomWavePath.lineTo(0, size.height - 70);

    for (int i = 0; i < (size.width / 80).ceil(); i++) {
      bottomWavePath.quadraticBezierTo(
        (i * 80) + 40,
        size.height - 40,
        (i * 80) + 80,
        size.height - 70,
      );
    }

    bottomWavePath.lineTo(size.width, size.height);
    bottomWavePath.close();

    canvas.drawPath(topWavePath, wavePaint);
    canvas.drawPath(bottomWavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
