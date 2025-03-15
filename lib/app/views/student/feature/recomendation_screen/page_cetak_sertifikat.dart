import 'dart:io';
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
            color: const Color(0xFF1A5F7A),
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

class _CertificateFrontState extends State<CertificateFront>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize date formatting for Indonesian locale
    initializeDateFormatting('id_ID', null);

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animations
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    try {
      final now = DateTime.now();
      final formatter = DateFormat('d MMMM yyyy', 'id_ID');
      return formatter.format(now);
    } catch (e) {
      // Fallback if locale formatting fails
      final now = DateTime.now();
      return "${now.day}/${now.month}/${now.year}";
    }
  }

  // Helper function to find a student in all schools
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

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Fancy background
          Positioned.fill(
            child: CustomPaint(
              painter: EnhancedCertificateBackgroundPainter(),
            ),
          ),

          // Animated shine effect
          _buildShineEffect(),

          // Decorative edges
          Positioned.fill(
            child: CustomPaint(
              painter: DecorativeEdgesPainter(),
            ),
          ),

          // Elegant border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 5,
                  color: const Color(0xFF1A5F7A),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1.5,
                    color: const Color(0xFF57C5B6),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Certificate ID
          Positioned(
            top: 35,
            right: 40,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A5F7A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF1A5F7A).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'ID: ${widget.certificateId}',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 12,
                    color: const Color(0xFF1A5F7A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Header
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Logo/Header Image
                    Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png', // Replace with your logo
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.school,
                              size: 60,
                              color: const Color(0xFF1A5F7A),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'SERTIFIKAT',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A5F7A),
                        letterSpacing: 6,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'HASIL ANALISIS MINAT DAN BAKAT',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF159895),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      child: Stack(
                        children: [
                          Divider(
                            color: const Color(0xFF57C5B6),
                            thickness: 2,
                          ),
                          Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1A5F7A),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            top: 290,
            left: 60,
            right: 60,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    Text(
                      'Diberikan Kepada:',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.crimsonText(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

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
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                if (userClass.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      userClass,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        color: const Color(0xFF1A5F7A),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                    Text(
                      'telah menyelesaikan analisis minat dan bakat\ndengan hasil bidang minat terbaik:',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF159895),
                            Color(0xFF1A5F7A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.recommendation.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer with date
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A5F7A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF1A5F7A).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Diterbitkan Pada',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1A5F7A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getFormattedDate(),
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 150,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1A5F7A),
                                Color(0xFF57C5B6),
                                Color(0xFF1A5F7A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Decorative corner elements
          Positioned(
            top: 24,
            left: 24,
            child: _buildCornerElement(),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: Transform.rotate(
              angle: 1.57,
              child: _buildCornerElement(),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: Transform.rotate(
              angle: 3.14,
              child: _buildCornerElement(),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            child: Transform.rotate(
              angle: 4.71,
              child: _buildCornerElement(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShineEffect() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: -1.0, end: 2.0),
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      onEnd: () {
        // Rebuild the widget to restart animation
        if (mounted) setState(() {});
      },
      builder: (context, value, child) {
        return Positioned.fill(
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(value - 0.2, value - 0.2),
                end: Alignment(value, value),
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.4),
                  Colors.white.withOpacity(0.0),
                ],
                stops: const [0.35, 0.50, 0.65],
              ).createShader(bounds);
            },
            child: Container(
              color: Colors.transparent,
            ),
            blendMode: BlendMode.srcATop,
          ),
        );
      },
    );
  }

  Widget _buildCornerElement() {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(
        painter: CornerElementPainter(),
      ),
    );
  }
}

// Enhanced background painter for front certificate
class EnhancedCertificateBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base background color
    final Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Create a soft gradient background
    final Rect rect = Rect.fromLTRB(0, 0, size.width, size.height);
    final Gradient gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFF8FDFF),
        const Color(0xFFE6F7F5),
        const Color(0xFFF0F8FF),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final Paint gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, gradientPaint);

    // Draw elegant pattern
    final dotPaint = Paint()
      ..color = const Color(0xFF57C5B6).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    // Small dots pattern
    for (int i = 0; i < size.width; i += 40) {
      for (int j = 0; j < size.height; j += 40) {
        // Draw tiny circles
        canvas.drawCircle(
          Offset(i.toDouble(), j.toDouble()),
          1.5,
          dotPaint,
        );
      }
    }

    // Draw decorative wave patterns
    final wavePaint = Paint()
      ..color = const Color(0xFF159895).withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Top wave
    final topWavePath = Path();
    topWavePath.moveTo(0, 120);

    for (int i = 0; i < size.width / 40; i++) {
      topWavePath.quadraticBezierTo(
        (i * 40) + 20,
        100,
        (i * 40) + 40,
        120,
      );
    }

    // Bottom wave
    final bottomWavePath = Path();
    bottomWavePath.moveTo(0, size.height - 120);

    for (int i = 0; i < size.width / 40; i++) {
      bottomWavePath.quadraticBezierTo(
        (i * 40) + 20,
        size.height - 100,
        (i * 40) + 40,
        size.height - 120,
      );
    }

    canvas.drawPath(topWavePath, wavePaint);
    canvas.drawPath(bottomWavePath, wavePaint);

    // Create radial gradient in corners for added depth
    final cornerGradient = RadialGradient(
      colors: [
        const Color(0xFF57C5B6).withOpacity(0.1),
        Colors.white.withOpacity(0.0),
      ],
    );

    final cornerPaint = Paint()
      ..shader = cornerGradient
          .createShader(Rect.fromCircle(center: Offset(0, 0), radius: 200));

    canvas.drawCircle(Offset(0, 0), 200, cornerPaint);

    final cornerPaint2 = Paint()
      ..shader = cornerGradient.createShader(Rect.fromCircle(
          center: Offset(size.width, size.height), radius: 200));

    canvas.drawCircle(Offset(size.width, size.height), 200, cornerPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Decorative edge painter for certificate edges
class DecorativeEdgesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF57C5B6).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Edge decorations - top and bottom
    const edgeSpacing = 15.0;
    for (double i = edgeSpacing * 2;
        i < size.width - (edgeSpacing * 2);
        i += edgeSpacing) {
      // Top edge decorations
      final topPath = Path();
      topPath.moveTo(i, 12);
      topPath.lineTo(i, 20);

      // Bottom edge decorations
      final bottomPath = Path();
      bottomPath.moveTo(i, size.height - 12);
      bottomPath.lineTo(i, size.height - 20);

      canvas.drawPath(topPath, paint);
      canvas.drawPath(bottomPath, paint);
    }

    // Edge decorations - left and right
    for (double i = edgeSpacing * 2;
        i < size.height - (edgeSpacing * 2);
        i += edgeSpacing) {
      // Left edge decorations
      final leftPath = Path();
      leftPath.moveTo(12, i);
      leftPath.lineTo(20, i);

      // Right edge decorations
      final rightPath = Path();
      rightPath.moveTo(size.width - 12, i);
      rightPath.lineTo(size.width - 20, i);

      canvas.drawPath(leftPath, paint);
      canvas.drawPath(rightPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Corner element painter
class CornerElementPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A5F7A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path();
    path.moveTo(0, 15);
    path.lineTo(0, 0);
    path.lineTo(15, 0);

    final lightPaint = Paint()
      ..color = const Color(0xFF57C5B6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final lightPath = Path();
    lightPath.moveTo(3, 22);
    lightPath.lineTo(3, 3);
    lightPath.lineTo(22, 3);

    canvas.drawPath(path, paint);
    canvas.drawPath(lightPath, lightPaint);
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
        color: Colors.white,
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
              painter: DetailBackgroundPainter(),
            ),
          ),

          // Border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 3,
                  color: const Color(0xFF1A5F7A),
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
                        color: const Color(0xFF1A5F7A),
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
                          colors: [Color(0xFF1A5F7A), Color(0xFF57C5B6)],
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
                      color: const Color(0xFF1A5F7A),
                      borderRadius: BorderRadius.circular(8),
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
                                      color: Color(0xFF1A5F7A)),
                                ),
                              ),
                              const SizedBox(width: 30),
                              // Majors
                              Expanded(
                                child: _buildDetailSection(
                                  'Jurusan yang Cocok:',
                                  widget.recommendation.majors,
                                  const Icon(Icons.school,
                                      color: Color(0xFF1A5F7A)),
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
                                          color: Color(0xFF1A5F7A)),
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
                                          color: Color(0xFF1A5F7A)),
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
                                color: const Color(0xFF1A5F7A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      const Color(0xFF1A5F7A).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'Hasil analisis ini disusun dari jawaban dan minat yang kamu berikan.\n'
                                'Gunakan info ini untuk membantu merencanakan masa depanmu dengan lebih baik.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
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
                  color: const Color(0xFF1A5F7A),
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
                          color: const Color(0xFF57C5B6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          overflow: TextOverflow.visible,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.black87,
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
          left: BorderSide(width: 3, color: const Color(0xFF1A5F7A)),
          top: BorderSide(width: 3, color: const Color(0xFF1A5F7A)),
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
          ),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background
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
                padding: const EdgeInsets.symmetric(vertical: 8),
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
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A5F7A).withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 5,
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
                      child: Icon(
                        Icons.workspace_premium,
                        size: 120,
                        color: Color.lerp(
                          const Color(0xFF57C5B6),
                          const Color(0xFF1A5F7A),
                          value,
                        ),
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
              backgroundColor: const Color(0xFF1A5F7A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            child: const Text(
              'Tampilkan Sertifikat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
            ? const Color(0xFF1A5F7A)
            : const Color(0xFF57C5B6).withOpacity(0.3),
        borderRadius: BorderRadius.circular(4.0),
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
                        backgroundColor: const Color(0xFF159895),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                        backgroundColor: const Color(0xFF1A5F7A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
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
      ..color = const Color(0xFF1A5F7A).withOpacity(0.05)
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
