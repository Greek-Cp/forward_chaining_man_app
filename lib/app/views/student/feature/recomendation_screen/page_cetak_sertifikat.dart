import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:forward_chaining_man_app/app/controllers/home_controller.dart';
import 'package:forward_chaining_man_app/app/views/student/model/data_student.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import 'package:url_launcher/url_launcher.dart';

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
