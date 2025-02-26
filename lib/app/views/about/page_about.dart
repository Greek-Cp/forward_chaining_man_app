import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'package:flutter/services.dart';
import 'package:forward_chaining_man_app/app/views/about/widget/diagram_painter.dart';
import 'package:forward_chaining_man_app/app/views/page_intro.dart';
import 'package:forward_chaining_man_app/app/views/page_login.dart';
import 'package:forward_chaining_man_app/app/views/page_profile.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class ForwardChainingLogoPainter extends CustomPainter {
  final double animationValue;

  ForwardChainingLogoPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.32;

    // Create a layered neural network structure with input, hidden, and output nodes

    // Define the layers (3 layers: input, hidden, output)
    final int inputNodes = 4;
    final int hiddenNodes = 6;
    final int outputNodes = 3;

    // Node positions for each layer
    final List<Offset> inputLayer = [];
    final List<Offset> hiddenLayer = [];
    final List<Offset> outputLayer = [];

    // Create a gradient for the background glow
    final Rect rect =
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius * 1.2);
    final gradient = RadialGradient(
      colors: [
        Colors.indigo.shade400.withOpacity(0.2),
        Colors.transparent,
      ],
      stops: const [0.5, 1.0],
    );

    final backgroundPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), radius * 1.2, backgroundPaint);

    // Paints for nodes
    final inputNodePaint = Paint()
      ..color = Colors.blue.shade400
      ..style = PaintingStyle.fill;

    final hiddenNodePaint = Paint()
      ..color = Colors.indigo.shade400
      ..style = PaintingStyle.fill;

    final outputNodePaint = Paint()
      ..color = Colors.purple.shade400
      ..style = PaintingStyle.fill;

    // Paint for node glows
    final glowPaint = Paint()
      ..color = Colors.indigo.shade200.withOpacity(0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Paint for node borders
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Paint for connections with animation
    final connectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Create input layer nodes (left side)
    final inputSpacing = size.height / (inputNodes + 1);
    for (int i = 0; i < inputNodes; i++) {
      final y = (i + 1) * inputSpacing;
      final pulseFactor = math
              .sin((animationValue * 2 * math.pi) + (i * 0.5))
              .clamp(-0.5, 0.5) *
          0.05;
      final offsetX = (math.sin(animationValue * math.pi + i) * 4).clamp(-4, 4);

      // Position slightly to the left of center
      inputLayer.add(Offset(
          centerX - (radius * 0.7) + offsetX, y + (pulseFactor * size.height)));
    }

    // Create hidden layer nodes (center)
    final hiddenSpacing = size.height / (hiddenNodes + 1);
    for (int i = 0; i < hiddenNodes; i++) {
      final y = (i + 1) * hiddenSpacing;
      final pulseFactor = math
              .sin((animationValue * 2 * math.pi) + (i * 0.7))
              .clamp(-0.5, 0.5) *
          0.03;
      final offsetY =
          (math.sin(animationValue * math.pi * 2 + i * 0.5) * 5).clamp(-5, 5);

      // Position at center
      hiddenLayer
          .add(Offset(centerX + (pulseFactor * size.width), y + offsetY));
    }

    // Create output layer nodes (right side)
    final outputSpacing = size.height / (outputNodes + 1);
    for (int i = 0; i < outputNodes; i++) {
      final y = (i + 1) * outputSpacing;
      final pulseFactor = math
              .sin((animationValue * 2 * math.pi) + (i * 0.9))
              .clamp(-0.5, 0.5) *
          0.05;
      final offsetX =
          (math.sin(animationValue * math.pi + i * 1.2) * 4).clamp(-4, 4);

      // Position to the right of center
      outputLayer.add(Offset(
          centerX + (radius * 0.7) + offsetX, y + (pulseFactor * size.height)));
    }

    // Draw connections with animated data flow
    void drawConnections(
        List<Offset> fromLayer, List<Offset> toLayer, Color baseColor) {
      for (int i = 0; i < fromLayer.length; i++) {
        for (int j = 0; j < toLayer.length; j++) {
          // Create a flow effect along the connection
          final path = Path();
          path.moveTo(fromLayer[i].dx, fromLayer[i].dy);
          path.lineTo(toLayer[j].dx, toLayer[j].dy);

          // Create gradient shader for data flow effect
          final pathMetrics = path.computeMetrics().first;
          final length = pathMetrics.length;

          // Animate a dot along the path
          final flowPosition =
              (animationValue * 2 + (i * 0.1) + (j * 0.05)) % 1.0;
          final flowPoint =
              pathMetrics.getTangentForOffset(length * flowPosition)?.position;

          // Basic line
          connectionPaint.color = baseColor.withOpacity(0.3 +
              (0.2 * math.sin(animationValue * math.pi * 2 + i + j))
                  .clamp(0.0, 0.5));
          canvas.drawPath(path, connectionPaint);

          // Draw data flow point
          if (flowPoint != null && (i + j) % 2 == 0) {
            // Only draw on some connections to avoid clutter
            final flowDotPaint = Paint()
              ..color = Colors.white.withOpacity(0.7)
              ..style = PaintingStyle.fill;

            canvas.drawCircle(flowPoint, 1.5, flowDotPaint);
          }
        }
      }
    }

    // Draw connections from input to hidden layer
    drawConnections(inputLayer, hiddenLayer, Colors.blue.shade500);

    // Draw connections from hidden to output layer
    drawConnections(hiddenLayer, outputLayer, Colors.purple.shade500);

    // Draw the nodes with glow effect
    void drawNodesWithEffects(
        List<Offset> nodes, Paint nodePaint, double size) {
      for (int i = 0; i < nodes.length; i++) {
        final node = nodes[i];
        // Size pulsation
        final pulse =
            1.0 + 0.15 * math.sin((animationValue * 2 * math.pi) + (i));
        final nodeSize = size * pulse.clamp(0.9, 1.15);

        // Draw glow
        canvas.drawCircle(node, nodeSize * 1.5, glowPaint);

        // Draw node
        canvas.drawCircle(node, nodeSize, nodePaint);

        // Draw border
        canvas.drawCircle(node, nodeSize, borderPaint);
      }
    }

    // Draw all nodes by layer
    drawNodesWithEffects(inputLayer, inputNodePaint, 5);
    drawNodesWithEffects(hiddenLayer, hiddenNodePaint, 6);
    drawNodesWithEffects(outputLayer, outputNodePaint, 5);

    // Draw central circle highlight
    final centerGlowPaint = Paint()
      ..color = Colors.indigo.withOpacity(
          (0.1 + 0.05 * math.sin(animationValue * math.pi * 2))
              .clamp(0.05, 0.15))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawCircle(Offset(centerX, centerY), radius * 0.4, centerGlowPaint);
  }

  @override
  bool shouldRepaint(ForwardChainingLogoPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _AboutPageState extends State<AboutPage> with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _fadeInAnimation;
  late List<Animation<Offset>> _cardSlideAnimations;

  // For step animation
  int _currentStep = 0;
  final int _totalSteps = 4;

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

// Card animation controller
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

// Logo animations
// Fix: Ensure the end value is <= 1.0 to prevent the assertion error
    _logoRotationAnimation = Tween<double>(begin: 0, end: 0.05).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeInOut,
      ),
    );

// Fix: Ensure the end value doesn't cause any curves to go beyond 1.0
    _logoScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        // Fix: Ensure the end of the interval is <= 1.0
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Card slide animations (staggered)
    _cardSlideAnimations = [
      for (int i = 0; i < 5; i++)
        Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _cardAnimationController,
            curve: Interval(
              0.2 + (i * 0.12),
              0.7 + (i * 0.08),
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
    ];

    // Start animations
    _cardAnimationController.forward();

    // Start step animation
    Future.delayed(const Duration(seconds: 2), () {
      _startStepAnimation();
    });
  }

  void _startStepAnimation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentStep = (_currentStep + 1) % _totalSteps;
        });
        _startStepAnimation();
      }
    });
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade900,
              Colors.blue.shade800,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Tentang Aplikasi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40), // Balance the layout
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Animated Logo
                      FadeTransition(
                        opacity: _fadeInAnimation,
                        child: ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: RotationTransition(
                            turns: _logoRotationAnimation,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _buildAnimatedLogoContent(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title and Tagline
                      FadeTransition(
                        opacity: _fadeInAnimation,
                        child: Column(
                          children: [
                            const Text(
                              'Forward Chaining',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Text(
                                'Sistem Rekomendasi Karir & Jurusan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // About App Card
                      SlideTransition(
                        position: _cardSlideAnimations[0],
                        child: _buildInfoCard(
                          title: 'Tentang Aplikasi',
                          icon: Icons.info_outline,
                          color: Colors.blue.shade300,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Aplikasi Forward Chaining adalah sistem pakar berbasis aturan (rule-based expert system) yang menggunakan metode inferensi forward chaining untuk memberikan rekomendasi jurusan dan karir yang sesuai dengan minat pengguna.',
                                style: TextStyle(fontSize: 14, height: 1.5),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Aplikasi ini dikembangkan sebagai bagian dari tugas akhir/skripsi untuk menunjukkan implementasi praktis dari metode forward chaining dalam sistem pendukung keputusan.',
                                style: TextStyle(fontSize: 14, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // How It Works Card
                      SlideTransition(
                        position: _cardSlideAnimations[1],
                        child: _buildInfoCard(
                          title: 'Cara Kerja Forward Chaining',
                          icon: Icons.lightbulb_outline,
                          color: Colors.orange.shade300,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Forward Chaining adalah metode penalaran dari fakta-fakta yang diketahui menuju kesimpulan. Dalam aplikasi ini:',
                                style: TextStyle(fontSize: 14, height: 1.5),
                              ),
                              const SizedBox(height: 16),

                              // Animated steps
                              _buildAnimatedStepExplanation(),

                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.amber.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.tips_and_updates,
                                      color: Colors.amber.shade700,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Dengan metode ini, sistem dapat memberikan rekomendasi yang paling sesuai berdasarkan minat kamu!',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
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
                      const SizedBox(height: 16),

                      // Forward Chaining Visual Explanation
                      SlideTransition(
                        position: _cardSlideAnimations[2],
                        child: _buildInfoCard(
                          title: 'Visualisasi Proses',
                          icon: Icons.bar_chart,
                          color: Colors.green.shade300,
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/forward_chaining_diagram.png',
                                fit: BoxFit.contain,
                                height: 180,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback if image not available
                                  return _buildForwardChainingDiagram();
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Forward Chaining bekerja dengan mengevaluasi jawaban kamu dan mencocokkannya dengan aturan (rules) untuk menemukan rekomendasi terbaik. Ini seperti menyelesaikan teka-teki dengan petunjuk yang kamu berikan.',
                                style: TextStyle(fontSize: 14, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tech Stack Card
                      SlideTransition(
                        position: _cardSlideAnimations[3],
                        child: _buildInfoCard(
                          title: 'Teknologi',
                          icon: Icons.code,
                          color: Colors.purple.shade300,
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildTechChip(
                                  label: 'Flutter', icon: Icons.flutter_dash),
                              _buildTechChip(
                                  label: 'Dart', icon: Icons.extension),
                              _buildTechChip(
                                  label: 'Forward Chaining',
                                  icon: Icons.account_tree),
                              _buildTechChip(
                                  label: 'GetX', icon: Icons.auto_awesome),
                              _buildTechChip(
                                  label: 'Rule-Based System', icon: Icons.rule),
                              _buildTechChip(
                                  label: 'Expert System',
                                  icon: Icons.psychology),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Developer Card
                      SlideTransition(
                        position: _cardSlideAnimations[4],
                        child: _buildInfoCard(
                          title: 'Pengembang',
                          icon: Icons.person,
                          color: Colors.amber.shade300,
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  image: const DecorationImage(
                                    image: AssetImage('assets/ic_denis.jpg'),
                                    fit: BoxFit.cover,
                                    // Use a placeholder if no image is available
                                    onError: null,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.person,
                                      size: 40, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Yanuar Tri Laksono',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Mahasiswa Informatika',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildSocialButton(
                                          icon: Icons.email,
                                          onTap: () {
                                            // Launch email
                                            launchUrl(Uri.parse(
                                                'mailto:yanuartrilaksono23@gmail.com'));
                                          },
                                        ),
                                        const SizedBox(width: 12),
                                        _buildSocialButton(
                                          icon: Icons.link,
                                          onTap: () {
                                            // Launch website/portfolio
                                            launchUrl(Uri.parse(
                                                'https://yanuartrilaksono23.com/portfolio'));
                                          },
                                        ),
                                        const SizedBox(width: 12),
                                        _buildSocialButton(
                                          icon: Icons.code,
                                          onTap: () {
                                            // Launch GitHub
                                            launchUrl(Uri.parse(
                                                'https://github.com/Greek-Cp'));
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Footer
                      FadeTransition(
                        opacity: _fadeInAnimation,
                        child: Column(
                          children: [
                            Text(
                              '© ${DateTime.now().year} Forward Chaining App',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Versi 1.0.0',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the animated step explanation
  Widget _buildAnimatedStepExplanation() {
    final List<Map<String, dynamic>> steps = [
      {
        'icon': Icons.question_answer,
        'title': 'Langkah 1: Mengumpulkan Fakta',
        'content':
            'Sistem mengumpulkan jawaban "Ya" atau "Tidak" dari semua pertanyaanmu dan menyimpannya sebagai fakta.',
        'color': Colors.blue.shade700,
      },
      {
        'icon': Icons.rule,
        'title': 'Langkah 2: Mencocokkan Aturan',
        'content':
            'Sistem mencocokkan jawabanmu dengan aturan-aturan minat dan karir. Setiap jawaban "Ya" akan menambah skor pada minat tertentu.',
        'color': Colors.green.shade700,
      },
      {
        'icon': Icons.calculate,
        'title': 'Langkah 3: Menghitung Skor',
        'content':
            'Skor untuk setiap minat dan karir dihitung berdasarkan pertanyaan yang kamu jawab "Ya".',
        'color': Colors.orange.shade700,
      },
      {
        'icon': Icons.star,
        'title': 'Langkah 4: Memberikan Rekomendasi',
        'content':
            'Sistem mengurutkan hasil dan menampilkan 3 minat dengan skor tertinggi sebagai rekomendasi terbaikmu.',
        'color': Colors.purple.shade700,
      },
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = index == _currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isActive ? step['color'].withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? step['color'] : Colors.grey.shade200,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive ? step['color'] : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step['icon'],
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isActive ? step['color'] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step['content'],
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isActive ? Colors.black87 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Fallback Forward Chaining diagram if image is not available
  Widget _buildForwardChainingDiagram() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: ForwardChainingDiagramPainter(),
        size: const Size(double.infinity, 180),
      ),
    );
  }

  // Animated logo content with nodes and connections
  Widget _buildAnimatedLogoContent() {
    return CustomPaint(
      painter: ForwardChainingLogoPainter(
        animationValue: _logoAnimationController.value,
      ),
      child: const Icon(
        Icons.psychology,
        size: 70,
        color: Colors.indigo,
      ),
    );
  }

  // Card widget with consistent styling
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Card Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // Tech stack chip
  Widget _buildTechChip({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.indigo,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // Social media/contact button
  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.indigo,
        ),
      ),
    );
  }
}
