import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'package:flutter/services.dart';
import 'package:forward_chaining_man_app/app/views/about/page_about.dart';
import 'package:forward_chaining_man_app/app/views/page_intro.dart';
import 'package:forward_chaining_man_app/app/views/page_login.dart';
import 'package:forward_chaining_man_app/app/views/page_profile.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/quiz/controller/question_controller.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/quiz/page_feedback_evaluation.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/quiz/view/page_select_economy.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/quiz/view/widget/shimmer.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:intl/intl.dart' as intl;

import 'package:url_launcher/url_launcher.dart';

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final random = math.Random(42); // Fixed seed for consistent pattern

    // Draw simple patterns
    for (int i = 0; i < 10; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      if (i % 3 == 0) {
        // Draw circles
        canvas.drawCircle(
          Offset(x, y),
          10 + random.nextDouble() * 20,
          paint,
        );
      } else if (i % 3 == 1) {
        // Draw squares
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: 20 + random.nextDouble() * 20,
            height: 20 + random.nextDouble() * 20,
          ),
          paint,
        );
      } else {
        // Draw stars
        _drawStar(canvas, Offset(x, y), 5 + random.nextDouble() * 10, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const int numPoints = 5;
    final path = Path();

    for (int i = 0; i < numPoints * 2; i++) {
      final angle = i * math.pi / numPoints;
      final r = i.isEven ? radius : radius * 0.4;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated science icons that float around
// Simple animated icon for background
class AnimatedBackgroundIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final Offset position;

  const AnimatedBackgroundIcon({
    Key? key,
    required this.icon,
    required this.size,
    required this.color,
    required this.position,
  }) : super(key: key);

  @override
  State<AnimatedBackgroundIcon> createState() => _AnimatedBackgroundIconState();
}

class _AnimatedBackgroundIconState extends State<AnimatedBackgroundIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();

    final random = math.Random();

    _controller = AnimationController(
      duration: Duration(milliseconds: 2000 + random.nextInt(2000)),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: Offset(
        (random.nextDouble() - 0.5) * 0.4,
        (random.nextDouble() - 0.5) * 0.4,
      ),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: SlideTransition(
        position: _animation,
        child: Icon(
          widget.icon,
          size: widget.size,
          color: widget.color,
        ),
      ),
    );
  }
}

// Background with multiple animated icons
class FloatingIconsBackground extends StatelessWidget {
  const FloatingIconsBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final random = math.Random();
    final icons = [
      Icons.science,
      Icons.psychology,
      Icons.sports_soccer,
      Icons.computer,
      Icons.brush,
      Icons.business,
      Icons.music_note,
      Icons.health_and_safety,
    ];

    // Generate backgrounds icons with random positions, sizes and colors
    final backgroundIcons = List.generate(
      8,
      (i) => AnimatedBackgroundIcon(
        icon: icons[i % icons.length],
        size: 12.0 + random.nextDouble() * 12,
        color: Color.fromRGBO(
          50 + random.nextInt(150),
          50 + random.nextInt(150),
          150 + random.nextInt(100),
          0.3,
        ),
        position: Offset(
          random.nextDouble() * 300,
          random.nextDouble() * 300,
        ),
      ),
    );

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: backgroundIcons,
      ),
    );
  }
}

class PulsingWarningIcon extends StatefulWidget {
  const PulsingWarningIcon({Key? key}) : super(key: key);

  @override
  State<PulsingWarningIcon> createState() => _PulsingWarningIconState();
}

class _PulsingWarningIconState extends State<PulsingWarningIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.warning_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}

// Dialog entrance animation
class FadeScaleTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const FadeScaleTransition({
    Key? key,
    required this.child,
    required this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(animation.value),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// Custom painter for science-themed background
class SciencePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw atoms and molecules in background
    _drawAtom(canvas, Offset(size.width * 0.2, size.height * 0.2), 15, paint);
    _drawAtom(canvas, Offset(size.width * 0.8, size.height * 0.7), 10, paint);
    _drawMolecule(canvas, Offset(size.width * 0.7, size.height * 0.3), paint);

    // Draw some math/science symbols
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "E=mc²",
        style: TextStyle(
          color: Colors.indigo,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.1, size.height * 0.8));

    // Draw DNA helix pattern along one side
    _drawDnaHelix(canvas, Offset(size.width * 0.05, size.height * 0.3),
        size.height * 0.4, paint);
  }

  void _drawAtom(Canvas canvas, Offset center, double radius, Paint paint) {
    // Nucleus
    canvas.drawCircle(
        center,
        radius * 0.3,
        Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..style = PaintingStyle.fill);

    // Electron orbits
    for (int i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2 * (0.7 + i * 0.3),
          height: radius * 2 * (0.5 + i * 0.3),
        ),
        paint,
      );
    }

    // Electrons
    final electronPaint = Paint()
      ..color = Colors.indigo
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(center.dx + radius * 0.9, center.dy + radius * 0.3),
        radius * 0.1,
        electronPaint);

    canvas.drawCircle(
        Offset(center.dx - radius * 0.8, center.dy - radius * 0.4),
        radius * 0.1,
        electronPaint);
  }

  void _drawMolecule(Canvas canvas, Offset center, Paint paint) {
    final molPaint = Paint()
      ..color = Colors.purple.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw H2O-like molecule
    final o = center;
    final h1 = Offset(center.dx - 15, center.dy + 10);
    final h2 = Offset(center.dx + 15, center.dy + 10);

    // Oxygen
    canvas.drawCircle(
        o,
        8,
        Paint()
          ..color = Colors.red.withOpacity(0.3)
          ..style = PaintingStyle.fill);

    // Hydrogens
    canvas.drawCircle(
        h1,
        5,
        Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        h2,
        5,
        Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..style = PaintingStyle.fill);

    // Bonds
    canvas.drawLine(o, h1, molPaint);
    canvas.drawLine(o, h2, molPaint);
  }

  void _drawDnaHelix(Canvas canvas, Offset start, double height, Paint paint) {
    final dnaStrandPaint1 = Paint()
      ..color = Colors.purple.withOpacity(0.2)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final dnaStrandPaint2 = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const amplitude = 10.0;
    const period = 40.0;
    const stepSize = 4.0;

    Path path1 = Path();
    Path path2 = Path();

    path1.moveTo(start.dx, start.dy);
    path2.moveTo(start.dx, start.dy + period / 2);

    for (double i = 0; i <= height; i += stepSize) {
      final y = start.dy + i;
      final x1 = start.dx + amplitude * math.sin((i / period) * 2 * math.pi);
      final x2 = start.dx +
          amplitude * math.sin(((i + period / 2) / period) * 2 * math.pi);

      path1.lineTo(x1, y);
      path2.lineTo(x2, y);

      // Draw connecting "rungs" of the DNA ladder
      if (i % 20 < 1) {
        canvas.drawLine(
            Offset(x1, y),
            Offset(x2, y),
            Paint()
              ..color = Colors.grey.withOpacity(0.2)
              ..strokeWidth = 1.0);
      }
    }

    canvas.drawPath(path1, dnaStrandPaint1);
    canvas.drawPath(path2, dnaStrandPaint2);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class QuestionPage extends StatefulWidget {
  final bool isKerja; // true=Kerja, false=Kuliah
  QuestionPage({Key? key, required this.isKerja}) : super(key: key);

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

// Tambahkan class ini untuk animasi item
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final bool isHighlighted;

  const AnimatedListItem({
    Key? key,
    required this.child,
    required this.index,
    this.isHighlighted = false,
  }) : super(key: key);

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Buat controller dengan durasi yang lebih lama untuk efek yang lebih halus
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
    );

    // Buat animasi scale yang dimulai dari 0.8 hingga 1.0
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Buat animasi opacity dari 0 hingga 1
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Buat animasi slide dari bawah
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Mulai animasi dengan sedikit delay berdasarkan index
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedListItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Jika item baru di-highlight, mainkan animasi perhatian
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _playAttentionAnimation();
    }
  }

  void _playAttentionAnimation() {
    // Animasi perhatian: scale sedikit lebih besar kemudian kembali normal
    _controller.reset();
    _controller.forward();
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
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _QuestionPageState extends State<QuestionPage>
    with TickerProviderStateMixin {
// Modifikasi metode _showAutoFillOptions
  void _showAutoFillOptions(
      BuildContext context, QuestionController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Auto Fill Options (Testing)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 20),
              // Opsi untuk mengisi & lanjut ke halaman berikutnya
              _buildAutoFillOption(
                context,
                icon: Icons.fast_forward,
                label: 'Lanjut ke Halaman Berikutnya',
                color: Colors.blue.shade600,
                onTap: () {
                  controller.autoFillAnswers(true);
                  Navigator.pop(context);
                  // Langsung lanjut ke halaman berikutnya
                  if (controller.currentPage.value <
                      controller.totalPages - 1) {
                    controller.nextPage();
                  } else {
                    // Jika halaman terakhir, tampilkan hasil
                    final results = controller.runForwardChaining();
                    controller.saveResultsToFirestore(results).then((_) {
                      showRecommendationResultsGetx(results);
                    });
                  }
                },
              ),
              const Divider(height: 1),
              // Opsi untuk mengisi & menyelesaikan semua halaman
              _buildAutoFillOption(
                context,
                icon: Icons.done_all,
                label: 'Selesaikan Semua & Lihat Hasil',
                color: Colors.green.shade600,
                onTap: () {
                  Navigator.pop(context);
                  // Isi semua pertanyaan di semua halaman
                  controller.autoFillAllPages(true).then((_) {
                    // Kemudian jalankan forward chaining
                    final results = controller.runForwardChaining();
                    controller.saveResultsToFirestore(results).then((_) {
                      showRecommendationResultsGetx(results);
                    });
                  });
                },
              ),
              const Divider(height: 1),
              // Opsi mengisi secara acak & menyelesaikan semua
              _buildAutoFillOption(
                context,
                icon: Icons.shuffle,
                label: 'Isi Acak & Lihat Hasil',
                color: Colors.purple.shade600,
                onTap: () {
                  Navigator.pop(context);
                  // Isi semua pertanyaan secara acak
                  controller.autoFillAllPages(null).then((_) {
                    // Kemudian jalankan forward chaining
                    final results = controller.runForwardChaining();
                    controller.saveResultsToFirestore(results).then((_) {
                      showRecommendationResultsGetx(results);
                    });
                  });
                },
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              // Opsi mengisi secara acak & menyelesaikan semua
              _buildAutoFillOption(
                context,
                icon: Icons.shuffle,
                label: 'Isi Salah',
                color: Colors.purple.shade600,
                onTap: () {
                  Navigator.pop(context);
                  // Isi semua pertanyaan secara acak
                  controller.autoFillAllPages(false).then((_) {
                    // Kemudian jalankan forward chaining
                    final results = controller.runForwardChaining();
                    controller.saveResultsToFirestore(results).then((_) {
                      showRecommendationResultsGetx(results);
                    });
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper untuk item menu auto fill
  Widget _buildAutoFillOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Dialog konfirmasi yang ditampilkan ketika pengguna ingin kembali

  // Handler untuk tombol kembali dengan logika berdasarkan halaman
  Future<bool> _handleBackPress(BuildContext context) async {
    // Jika berada di halaman selain halaman pertama, cukup decrement controller
    if (controller.currentPage.value > 0) {
      controller.prevPage();
      return false; // Jangan keluar dari aplikasi/halaman
    }
    // Jika di halaman pertama, tampilkan dialog konfirmasi
    else {
      return await _showExitConfirmationDialog(context);
    }
  }

  // Dialog konfirmasi saat di halaman pertama
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    bool? exitPage = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 8,
          content: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: BoxConstraints(
              maxWidth: 400, // Memastikan dialog tidak terlalu lebar
              maxHeight: MediaQuery.of(context).size.height *
                  0.6, // Memastikan dialog tidak terlalu tinggi
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background dengan pattern ringan
                Positioned.fill(
                  child: CustomPaint(
                    painter: PatternPainter(),
                  ),
                ),

                // Main content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Peringatan!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        'Semua jawaban pada kuesioner minat akan ',
                                  ),
                                  TextSpan(
                                    text: 'HILANG ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'jika Anda kembali ke halaman pemilihan minat.\n\n',
                                  ),
                                  TextSpan(
                                    text:
                                        'Anda harus mengisi ulang semua pertanyaan jika melanjutkan.',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Yakin ingin kembali?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Menggunakan spaceBetween alih-alih spaceEvenly
                        children: [
                          // Tombol Kembali (kiri)
                          OutlinedButton(
                            onPressed: () {
                              // Tampilkan dialog konfirmasi kedua
                              _showSecondConfirmation(dialogContext);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10), // Mengurangi padding
                              side: BorderSide(color: Colors.red.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Kembali',
                              style: TextStyle(
                                fontSize: 14, // Mengurangi ukuran font
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Tombol Lanjutkan Mengisi (kanan)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(false);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10), // Mengurangi padding
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Lanjutkan Mengisi',
                              style: TextStyle(
                                fontSize: 14, // Mengurangi ukuran font
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Top warning icon
                const Positioned(
                  top: -30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: PulsingWarningIcon(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return exitPage ?? false;
  }

  // Konfirmasi kedua sebelum kembali
  void _showSecondConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext secondDialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Konfirmasi Terakhir',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Anda yakin ingin kembali? Semua jawaban Anda akan hilang dan tidak dapat dikembalikan.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(secondDialogContext).pop();
              },
              child: const Text(
                'BATAL',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Tutup dialog kedua
                Navigator.of(secondDialogContext).pop();
                // Tutup dialog pertama dengan hasil true (kembali)
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'YA, KEMBALI',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  final List<AnimationController> _controllers = [];

  final List<Animation<Offset>> _animations = [];

  final List<IconData> _icons = [
    Icons.science,
    Icons.psychology,
    Icons.sports_soccer,
    Icons.computer,
    Icons.brush,
    Icons.business,
    Icons.music_note,
    Icons.health_and_safety,
  ];

  final List<double> _sizes = [];

  final List<Color> _colors = [];

  final List<Offset> _positions = [];
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Generate random positions, sizes and colors for icons
    final random = math.Random();
    for (int i = 0; i < 8; i++) {
      // Create controller and add to list
      final controller = AnimationController(
        duration: Duration(milliseconds: 2000 + (500 * i % 2000)),
        vsync: this,
      )..repeat(reverse: true);
      _controllers.add(controller);

      _sizes.add(12.0 + random.nextDouble() * 12);
      _colors.add(
        Color.fromRGBO(
          50 + random.nextInt(150),
          50 + random.nextInt(150),
          150 + random.nextInt(100),
          0.3,
        ),
      );
      _positions.add(
        Offset(
          random.nextDouble() * 250,
          random.nextDouble() * 300,
        ),
      );

      // Create animation and add to list
      final animation = Tween<Offset>(
        begin: Offset(random.nextDouble() * 0.3, random.nextDouble() * 0.3),
        end: Offset(-random.nextDouble() * 0.3, -random.nextDouble() * 0.3),
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
      _animations.add(animation);
    }
  }

  final controller = Get.find<QuestionController>();
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent automatic pop
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldExit = await _handleBackPress(context);
          if (shouldExit && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },

      child: Scaffold(
        body: Container(
          color: Colors.blue.shade700,
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 60, color: Colors.white70),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${controller.errorMessage.value}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (controller.programList.value.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 60, color: Colors.white70),
                    SizedBox(height: 16),
                    Text(
                      'Data Kosong',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final questionsThisPage = controller.questionsThisPage;
            final startIndex =
                controller.currentPage.value * QuestionController.pageSize;

            // Jika flag scroll ke atas aktif, lakukan scrolling
            if (controller.shouldScrollToTop) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (scrollController.hasClients) {
                  scrollController.animateTo(0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut);
                  // Reset flag
                  controller.shouldScrollToTop = false;
                }
              });
            }

            return Column(
              children: [
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress Indicator Section - Kept as requested
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade600,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                '${controller.answeredCount}/${controller.totalCount} Pertanyaan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Halaman ${controller.currentPage.value + 1} dari ${controller.totalPages}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                                textAlign: TextAlign.right,
                              ),
                            )
                          ],
                        ),

                        SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: controller.answeredCount /
                                controller.totalCount,
                            backgroundColor: Colors.white24,
                            color: Colors.amber.shade500,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ShimmerEffect(
                          baseColor: Colors.white,
                          highlightColor: Colors.yellow,
                          duration: const Duration(seconds: 3),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Jawab dengan jujur pertanyaan di bawah ini.',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Questions Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Title
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Text(
                            widget.isKerja ? 'Pertanyaan' : 'Pertanyaan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),

                        // List of Questions
                        Expanded(
                          child: ListView.builder(
                            controller:
                                scrollController, // Tambahkan controller
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            itemCount: questionsThisPage.length,
                            itemBuilder: (context, index) {
                              final qItem = questionsThisPage[index];
                              final globalIndex = startIndex + index;

                              return Obx(() {
                                // Cek apakah pertanyaan ini perlu di-highlight
                                final isHighlighted = controller
                                    .highlightedQuestionIds
                                    .contains(qItem.id);

                                // Cek status jawaban dari pertanyaan ini
                                final isAnswered = controller.allQuestions
                                        .firstWhere((q) => q.id == qItem.id)
                                        .userAnswer !=
                                    null;

                                return Card(
                                  key: ValueKey(
                                      'question_${qItem.id}'), // Key untuk identifikasi
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 2,
                                  shadowColor: Colors.black.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  // Wrap dengan Container biasa agar tidak memicu animasi saat jawaban dipilih
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isHighlighted
                                            ? Colors.amber.shade500
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                      boxShadow: isHighlighted
                                          ? [
                                              BoxShadow(
                                                color: Colors.amber.shade200
                                                    .withOpacity(0.5),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Question header
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isHighlighted
                                                ? Colors.amber.shade50
                                                : Colors.blue.shade50,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              topRight: Radius.circular(16),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: isHighlighted
                                                      ? Colors.amber.shade600
                                                      : Colors.blue.shade600,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  '${globalIndex + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  qItem.questionText,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                              // Badge untuk pertanyaan yang di-highlight
                                              if (isHighlighted && !isAnswered)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.amber.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                        color: Colors
                                                            .amber.shade600),
                                                  ),
                                                  child: Text(
                                                    'Belum Diisi',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.amber.shade900,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),

                                        // Answer options
                                        Column(
                                          children: [
                                            _buildAnswerOption(
                                              icon: Icons.check_circle_outline,
                                              label: 'Ya',
                                              isSelected: controller
                                                      .allQuestions
                                                      .firstWhere((q) =>
                                                          q.id == qItem.id)
                                                      .userAnswer ==
                                                  true,
                                              onTap: () {
                                                controller.setAnswer(
                                                    qItem, true);
                                                // Hapus highlight saat jawaban dipilih
                                                if (controller
                                                    .highlightedQuestionIds
                                                    .contains(qItem.id)) {
                                                  controller
                                                      .highlightedQuestionIds
                                                      .remove(qItem.id);
                                                }
                                              },
                                              activeColor:
                                                  Colors.green.shade600,
                                            ),
                                            Divider(
                                              height: 1,
                                              color: Colors.grey.shade200,
                                            ),
                                            _buildAnswerOption(
                                              icon: Icons.cancel_outlined,
                                              label: 'Tidak',
                                              isSelected: controller
                                                      .allQuestions
                                                      .firstWhere((q) =>
                                                          q.id == qItem.id)
                                                      .userAnswer ==
                                                  false,
                                              onTap: () {
                                                controller.setAnswer(
                                                    qItem, false);
                                                // Hapus highlight saat jawaban dipilih
                                                if (controller
                                                    .highlightedQuestionIds
                                                    .contains(qItem.id)) {
                                                  controller
                                                      .highlightedQuestionIds
                                                      .remove(qItem.id);
                                                }
                                              },
                                              activeColor: Colors.red.shade600,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              });
                            },
                          ),
                        ),

                        // Navigation Buttons
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Back Button
                              Expanded(
                                flex: 1,
                                child: ElevatedButton.icon(
                                  onPressed: controller.currentPage.value > 0
                                      ? () {
                                          // Hapus semua highlight sebelum pindah halaman
                                          controller.highlightedQuestionIds
                                              .clear();
                                          controller.prevPage();
                                          // Set flag untuk scroll ke atas
                                          controller.shouldScrollToTop = true;
                                        }
                                      : null,
                                  icon: const Icon(Icons.arrow_back, size: 18),
                                  label: const Text('Kembali'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.grey.shade700,
                                    backgroundColor: Colors.grey.shade200,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Next/Submit Button
                              Expanded(
                                flex: 2,
                                child: Obx(() {
                                  bool allAnswered =
                                      controller.allAnsweredThisPage;
                                  final isLastPage =
                                      controller.currentPage.value ==
                                          controller.totalPages - 1;

                                  return ElevatedButton.icon(
                                    onPressed: () {
                                      if (allAnswered) {
                                        // Hapus semua highlight sebelum pindah halaman
                                        controller.highlightedQuestionIds
                                            .clear();

                                        if (!isLastPage) {
                                          controller.nextPage();
                                          // Set flag untuk scroll ke atas
                                          controller.shouldScrollToTop = true;
                                        } else {
                                          final results =
                                              controller.runForwardChaining();
                                          controller
                                              .saveResultsToFirestore(results)
                                              .then((_) {
                                            // Then show results to user
                                            showFeedbackEvaluationPage(
                                                results,
                                                controller.isKerja,
                                                controller.majorType);
                                          });
                                        }
                                      } else {
                                        // Highlight pertanyaan yang belum dijawab
                                        controller.highlightUnansweredQuestions(
                                            scrollController);
                                      }
                                    },
                                    icon: Icon(
                                        isLastPage
                                            ? Icons.check_circle
                                            : Icons.arrow_forward,
                                        size: 18),
                                    label: Text(
                                      isLastPage ? 'Cek Rekomendasi' : 'Lanjut',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.blue.shade600,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                      disabledBackgroundColor:
                                          null, // Hapus ini agar tombol selalu aktif
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // Fungsi helper yang sama seperti sebelumnya
  Widget _buildAnswerOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : Colors.grey.shade400,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? activeColor : Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? activeColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? activeColor : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
