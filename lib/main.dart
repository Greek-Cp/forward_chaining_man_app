import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import 'package:url_launcher/url_launcher.dart';

// Global flag for developer mode
bool developerMode = false;

void main() {
  runApp(const MyApp());
}

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

/// Root widget aplikasi
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Forward Chaining Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DeveloperModePage(),
    );
  }
}

/// Controller untuk DeveloperModePage
class DeveloperModeController extends GetxController {
  final RxBool isDeveloperMode = developerMode.obs;

  void toggleDeveloperMode(bool value) {
    isDeveloperMode.value = value;
    developerMode = value;
  }
}

class HomeController extends GetxController {
  final Rx<bool?> pilihan =
      Rx<bool?>(null); // null=belum pilih; true=Kerja; false=Kuliah
  final RxString selectedKode =
      "".obs; // Menyimpan kode pilihan yang dipilih user

  void setPilihan(String kode) {
    if (selectedKode.value == kode)
      return; // Jika memilih yang sama, tidak berubah
    selectedKode.value = kode;

    // Logika pemilihan: Kuliah atau Kerja
    if (kode == "E01" || kode == "E02" || kode == "E03") {
      pilihan.value = false; // Kuliah
    } else if (kode == "E04" || kode == "E05") {
      pilihan.value = true; // Kerja
    }
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.indigo.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                    const SizedBox(width: 16),
                    const Text(
                      'Pilih Rencana Anda',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.lightbulb_outline,
                                size: 24,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kondisi Ekonomi',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pilih situasi yang paling sesuai',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Options List
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                Obx(() => buildOptionCard(
                                      title:
                                          "Kondisi ekonomi cukup untuk kuliah",
                                      subtitle:
                                          "Memiliki dana untuk pendidikan lanjutan",
                                      kode: "E01",
                                      icon: Icons.school,
                                      controller: controller,
                                    )),

                                Obx(() => buildOptionCard(
                                      title: "Ekonomi terbatas",
                                      subtitle:
                                          "Perlu mempertimbangkan biaya kuliah",
                                      kode: "E02",
                                      icon: Icons.attach_money,
                                      controller: controller,
                                    )),

                                Obx(() => buildOptionCard(
                                      title: "Mencari beasiswa",
                                      subtitle:
                                          "Berminat kuliah dengan bantuan biaya",
                                      kode: "E03",
                                      icon: Icons.card_giftcard,
                                      controller: controller,
                                    )),

                                Obx(() => buildOptionCard(
                                      title: "Memilih bekerja atau usaha",
                                      subtitle:
                                          "Ingin langsung terjun ke dunia kerja",
                                      kode: "E04",
                                      icon: Icons.work,
                                      controller: controller,
                                    )),

                                Obx(() => buildOptionCard(
                                      title: "Bekerja dulu, kuliah nanti",
                                      subtitle: "Menunda kuliah untuk bekerja",
                                      kode: "E05",
                                      icon: Icons.timeline,
                                      controller: controller,
                                    )),

                                // Add some space at the bottom for better scrolling
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Next Button
                        Obx(() => AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: controller.selectedKode.value.isEmpty
                                  ? 0.6
                                  : 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow:
                                      controller.selectedKode.value.isEmpty
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: Colors.blue.shade300
                                                    .withOpacity(0.4),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                ),
                                child: ElevatedButton(
                                  onPressed: controller
                                          .selectedKode.value.isEmpty
                                      ? null
                                      : () {
                                          Get.to(() => QuestionPage(
                                                isKerja:
                                                    controller.pilihan.value!,
                                              ));
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    minimumSize:
                                        const Size(double.infinity, 54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                    disabledBackgroundColor:
                                        Colors.blue.shade200,
                                    disabledForegroundColor: Colors.white70,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        controller.selectedKode.value.isEmpty
                                            ? 'Pilih Salah Satu Opsi'
                                            : 'Lanjutkan',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget untuk membuat tampilan pilihan lebih menarik dan modern
  Widget buildOptionCard({
    required String title,
    required String subtitle,
    required String kode,
    required IconData icon,
    required HomeController controller,
  }) {
    final isSelected = controller.selectedKode.value == kode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.setPilihan(kode),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected ? Colors.blue.shade50 : Colors.white,
              border: Border.all(
                color: isSelected ? Colors.blue.shade400 : Colors.grey.shade200,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade400
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.blue.shade800
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? Colors.blue.shade600
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
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
}

class ForwardChainingDiagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Define colors
    final workingMemoryColor = Colors.blue.shade100;
    final rulesColor = Colors.orange.shade100;
    final resultsColor = Colors.green.shade100;
    final arrowColor = Colors.grey.shade700;

    // Define paint objects
    final boxPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.5;

    final textStyle = TextStyle(
      color: Colors.black87,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    final titleStyle = TextStyle(
      color: Colors.black,
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );

    // Helper function to draw boxes with text
    void drawBox(String title, String content, Rect rect, Color color) {
      // Draw box
      boxPaint.color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(8)),
        boxPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(8)),
        borderPaint,
      );

      // Draw title
      final titleSpan = TextSpan(text: title, style: titleStyle);
      final titlePainter = TextPainter(
        text: titleSpan,
        textDirection: TextDirection.ltr,
      );
      titlePainter.layout(maxWidth: rect.width - 10);
      titlePainter.paint(
        canvas,
        Offset(rect.left + 5, rect.top + 5),
      );

      // Draw content
      final contentSpan = TextSpan(text: content, style: textStyle);
      final contentPainter = TextPainter(
        text: contentSpan,
        textDirection: TextDirection.ltr,
      );
      contentPainter.layout(maxWidth: rect.width - 10);
      contentPainter.paint(
        canvas,
        Offset(rect.left + 5, rect.top + 25),
      );
    }

    // Helper to draw arrows
    void drawArrow(Offset start, Offset end) {
      final paint = Paint()
        ..color = arrowColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Draw line
      canvas.drawLine(start, end, paint);

      // Draw arrowhead
      final delta = end - start;
      final angle = delta.direction;
      final arrowSize = 8.0;

      final arrowPath = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - arrowSize * math.cos(angle - math.pi / 6),
          end.dy - arrowSize * math.sin(angle - math.pi / 6),
        )
        ..lineTo(
          end.dx - arrowSize * math.cos(angle + math.pi / 6),
          end.dy - arrowSize * math.sin(angle + math.pi / 6),
        )
        ..close();

      canvas.drawPath(arrowPath, Paint()..color = arrowColor);
    }

    // Calculate box positions
    final workingMemoryRect = Rect.fromLTWH(20, 20, width * 0.25, height - 40);
    final rulesRect =
        Rect.fromLTWH(width * 0.33, 20, width * 0.25, height - 40);
    final resultsRect =
        Rect.fromLTWH(width * 0.66, 20, width * 0.25, height - 40);

    // Draw the boxes
    drawBox(
      'Working Memory',
      'Facts:\n• Q1=Yes\n• Q2=No\n• Q3=Yes\n...',
      workingMemoryRect,
      workingMemoryColor,
    );

    drawBox(
      'Rules',
      'IF Q1=Yes THEN Skor+3\nIF Q2=Yes THEN Skor+2\nIF Q3=Yes AND Q4=Yes\n THEN Skor+4\n...',
      rulesRect,
      rulesColor,
    );

    drawBox(
      'Results (Top 3)',
      '1. IPA | Kedokteran (24)\n2. IPS | Ekonomi (19)\n3. IPA | Teknik (16)',
      resultsRect,
      resultsColor,
    );

    // Draw arrows
    drawArrow(
      Offset(workingMemoryRect.right, workingMemoryRect.center.dy - 20),
      Offset(rulesRect.left, rulesRect.center.dy - 20),
    );

    drawArrow(
      Offset(rulesRect.right, rulesRect.center.dy),
      Offset(resultsRect.left, resultsRect.center.dy),
    );

    // Draw loop arrow for rule evaluation
    final loopStart = Offset(rulesRect.right - 20, rulesRect.bottom - 25);
    final loopControl1 = Offset(rulesRect.right + 20, rulesRect.bottom + 15);
    final loopControl2 = Offset(rulesRect.left - 20, rulesRect.bottom + 15);
    final loopEnd = Offset(rulesRect.left, rulesRect.bottom - 25);

    final loopPath = Path()
      ..moveTo(loopStart.dx, loopStart.dy)
      ..cubicTo(
        loopControl1.dx,
        loopControl1.dy,
        loopControl2.dx,
        loopControl2.dy,
        loopEnd.dx,
        loopEnd.dy,
      );

    canvas.drawPath(
      loopPath,
      Paint()
        ..color = arrowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Draw arrowhead for loop
    final loopDelta = Offset(0, -5);
    final loopAngle = loopDelta.direction;
    final arrowSize = 7.0;

    final loopArrowPath = Path()
      ..moveTo(loopEnd.dx, loopEnd.dy)
      ..lineTo(
        loopEnd.dx - arrowSize * math.cos(loopAngle - math.pi / 6),
        loopEnd.dy - arrowSize * math.sin(loopAngle - math.pi / 6),
      )
      ..lineTo(
        loopEnd.dx - arrowSize * math.cos(loopAngle + math.pi / 6),
        loopEnd.dy - arrowSize * math.sin(loopAngle + math.pi / 6),
      )
      ..close();

    canvas.drawPath(loopArrowPath, Paint()..color = arrowColor);

    // Add "Rule Evaluation Loop" text
    final loopTextSpan = TextSpan(
      text: "Rule Evaluation Loop",
      style: TextStyle(
        color: Colors.grey.shade800,
        fontSize: 9,
        fontStyle: FontStyle.italic,
      ),
    );

    final loopTextPainter = TextPainter(
      text: loopTextSpan,
      textDirection: TextDirection.ltr,
    );
    loopTextPainter.layout();
    loopTextPainter.paint(
        canvas, Offset(rulesRect.center.dx - 35, rulesRect.bottom + 5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Controller untuk QuestionPage
class QuestionController extends GetxController {
  final bool isKerja;

  QuestionController({required this.isKerja});

  // Akan menampung data ProgramStudi lengkap (untuk lookup karir di akhir)
  final Rx<List<ProgramStudi>> programList = Rx<List<ProgramStudi>>([]);

  // Daftar pertanyaan yang sudah di-flatten
  final RxList<QuestionItem> allQuestions = <QuestionItem>[].obs;

  // Paging
  final RxInt currentPage = 0.obs;
  static const pageSize = 5;

  // Untuk tampilan loading
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProgramData(isKerja);
  }

  /// Computed property: pertanyaan pada halaman saat ini
  List<QuestionItem> get questionsThisPage {
    final totalPages = (allQuestions.length / pageSize).ceil();
    if (currentPage.value >= totalPages) currentPage.value = totalPages - 1;
    if (currentPage.value < 0) currentPage.value = 0;

    final startIndex = currentPage.value * pageSize;
    final endIndex =
        ((currentPage.value + 1) * pageSize).clamp(0, allQuestions.length);
    return allQuestions.sublist(startIndex, endIndex);
  }

  /// Computed property: total halaman
  int get totalPages => (allQuestions.length / pageSize).ceil();

  /// Computed property: jumlah pertanyaan terjawab
  int get answeredCount =>
      allQuestions.where((q) => q.userAnswer != null).length;

  /// Computed property: total pertanyaan
  int get totalCount => allQuestions.length;

  /// Computed property: semua pertanyaan di halaman ini terjawab
  bool get allAnsweredThisPage =>
      questionsThisPage.every((q) => q.userAnswer != null);

  /// Memuat data ProgramStudi dari file JSON (Sains + Teknik) tergantung Kerja/Kuliah
  Future<void> loadProgramData(bool isKerja) async {
    // Implementation unchanged
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Tentukan file sains
      final sainsFile = isKerja
          ? 'assets/ipa_sains_kerja.json'
          : 'assets/ipa_sains_kuliah.json';

      // File teknik
      final teknikFile = isKerja
          ? 'assets/ipa_teknik_kerja.json'
          : 'assets/ipa_teknik_kuliah.json';

      // Baca JSON sains
      final sainsString = await rootBundle.rootBundle.loadString(sainsFile);
      final sainsMap = json.decode(sainsString) as Map<String, dynamic>;

      // Baca JSON teknik
      final teknikString = await rootBundle.rootBundle.loadString(teknikFile);
      final teknikMap = json.decode(teknikString) as Map<String, dynamic>;

      // Ubah ke list ProgramStudi
      final programs = <ProgramStudi>[];
      // Parsing sains
      for (var entry in sainsMap.entries) {
        programs.add(ProgramStudi.fromJson(entry.value));
      }
      // Parsing teknik
      for (var entry in teknikMap.entries) {
        programs.add(ProgramStudi.fromJson(entry.value));
      }

      programList.value = programs;

      // Flatten jadi QuestionItem
      flattenQuestions(programs);

      isLoading.value = false;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false;
    }
  }

  /// Flatten pertanyaan dari programList -> allQuestions (Q1, Q2, dsb)
  void flattenQuestions(List<ProgramStudi> programs) {
    // Implementation unchanged
    final all = <QuestionItem>[];
    int counter = 1;

    for (var prog in programs) {
      // prog.name = "IPA (Sains Murni) - Kerja" atau "IPA (Sains Murni)"
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;
        final minatVal = minatEntry.value; // punya pertanyaan, karir, dsb.

        for (var p in minatVal.pertanyaan) {
          final bobot = extractBobot(p);
          final cleaned = cleanPertanyaan(p);
          final qId = 'Q$counter';
          counter++;

          all.add(
            QuestionItem(
              id: qId,
              programName: prog.name,
              minatKey: minatKey,
              questionText: cleaned,
              rawQuestionText: p,
              bobot: bobot,
            ),
          );
        }
      }
    }

    // Set state
    allQuestions.value = all;
  }

  /// Set jawaban user
  void setAnswer(QuestionItem question, bool? answer) {
    final index = allQuestions.indexWhere((q) => q.id == question.id);
    if (index != -1) {
      allQuestions[index].userAnswer = answer;
      allQuestions.refresh(); // trigger UI refresh
    }
  }

  /// Navigasi ke halaman sebelumnya
  void prevPage() {
    if (currentPage.value > 0) {
      currentPage.value--;
    }
  }

  /// Navigasi ke halaman berikutnya
  void nextPage() {
    if (currentPage.value < totalPages - 1) {
      currentPage.value++;
    }
  }

  /// Modified: Return RecommendationResult object instead of a string
  RecommendationResult runForwardChaining() {
    // 1. Working Memory: "Q1=Yes" atau "Q1=No"
    final workingMemoryList = <String>[];
    final workingMemory = <String>{};

    for (var q in allQuestions) {
      if (q.userAnswer == true) {
        workingMemory.add('${q.id}=Yes'); // misal "Q1=Yes"
        workingMemoryList.add('${q.id}=Yes');
      } else if (q.userAnswer == false) {
        workingMemory.add('${q.id}=No'); // "Q1=No" (opsional)
        workingMemoryList.add('${q.id}=No');
      }
    }

    // 2. Skor per-minat
    final minatScores = <String, int>{};

    // 3. Untuk menampilkan rule, kita simpan "kontribusi" rule di map ini:
    //    Key: nama minat (ex: "IPA (Sains Murni) - Kerja|Kedokteran")
    //    Value: daftar string penjelasan rule
    final minatContrib = <String, List<String>>{};

    // 4. Generate rule: "IF Qx=Yes THEN skor[(prog|minat)] += bobot"
    //    + simpan catatan rule di minatContrib agar kita tahu pertanyaan apa.
    final rules = <Rule>[];
    for (var q in allQuestions) {
      final rule = Rule(
        ifFacts: ['${q.id}=Yes'], // kondisi: Qx=Yes
        thenAction: (wm) {
          final keyMinat = '${q.programName}|${q.minatKey}';
          // Tambah skor
          minatScores[keyMinat] = (minatScores[keyMinat] ?? 0) + q.bobot;

          // Catat rule fired:
          // Kita sertakan penjelasan pertanyaan agar lebih jelas.
          minatContrib[keyMinat] ??= [];
          minatContrib[keyMinat]!
              .add('IF (${q.id}=Yes) THEN +${q.bobot} skor → $keyMinat\n'
                  '   [Pertanyaan: "${q.questionText}"]');
        },
      );
      rules.add(rule);
    }

    // 5. Jalankan Forward Chaining (sederhana: 1 kali loop iteratif)
    bool firedSomething = true;
    final firedRules = <Rule>{};

    while (firedSomething) {
      firedSomething = false;
      for (var r in rules) {
        if (firedRules.contains(r)) continue; // sudah menembak

        // Cek kondisi IF (semua ifFacts ada di workingMemory)
        final allMatch =
            r.ifFacts.every((fact) => workingMemory.contains(fact));
        if (allMatch) {
          r.thenAction(workingMemory);
          firedRules.add(r);
          firedSomething = true;
        }
      }
    }

    // 6. Cek hasil skor
    if (minatScores.isEmpty) {
      // Jika tidak ada hasil, kembalikan objek kosong
      return RecommendationResult(
        workingMemory: workingMemoryList,
        recommendations: [],
      );
    }

    // Urutkan descending
    final sorted = minatScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // Ambil top 3
    final top3 = sorted.take(3).toList();

    // 7. Buat list rekomendasi
    final recommendations = <RecommendationItem>[];

    for (int i = 0; i < top3.length; i++) {
      final minatKey =
          top3[i].key; // ex: "IPA (Sains Murni) - Kerja|Kedokteran"
      final score = top3[i].value;

      // Split "IPA (Sains Murni) - Kerja" | "Kedokteran"
      final parts = minatKey.split('|');
      if (parts.length == 2) {
        final progName = parts[0];
        final mKey = parts[1];

        // Cari programStudi & minat
        final programStudi = programList.value.firstWhere(
          (p) => p.name == progName,
          orElse: () => ProgramStudi.empty(),
        );
        final minatObj = programStudi.minat[mKey];

        if (minatObj != null) {
          // Dapatkan careers dan majors dari minatObj
          final careers = minatObj.karir;
          final majors = minatObj.jurusanTerkait;

          // Dapatkan rules dari minatContrib
          final rules = minatContrib[minatKey] ?? [];

          // Add to recommendations using user's existing RecommendationItem structure
          recommendations.add(
            RecommendationItem(
              title: minatKey,
              score: score,
              careers: careers,
              majors: majors,
              rules: rules,
              index: i,
            ),
          );
        }
      }
    }

    return RecommendationResult(
      workingMemory: workingMemoryList,
      recommendations: recommendations,
    );
  }

  /// Still needed for legacy reasons - converts the RecommendationResult to a string
  String runForwardChainingAsString() {
    final result = runForwardChaining();

    // Convert to string format (legacy format)
    String message = 'HASIL FORWARD CHAINING:\n\n';
    message += 'Working Memory (fakta): ${result.workingMemory.join(', ')}\n\n';

    message += 'Top 3 Rekomendasi:\n';
    for (int i = 0; i < result.recommendations.length; i++) {
      final rec = result.recommendations[i];
      message += '${i + 1}. ${rec.title} (Skor: ${rec.score})\n';

      // Rules
      if (rec.rules.isNotEmpty) {
        message += '  RULES YANG:\n';
        for (var rule in rec.rules) {
          message += '   - $rule\n';
        }
      }

      // Careers
      if (rec.careers.isNotEmpty) {
        message += '  Karir:\n';
        for (var career in rec.careers) {
          message += '   - $career\n';
        }
      } else {
        message += '  Karir: (Tidak ada data)\n';
      }

      // Majors
      if (rec.majors.isNotEmpty) {
        message += '  Jurusan Terkait:\n';
        for (var major in rec.majors) {
          message += '   - $major\n';
        }
      }

      message += '\n';
    }

    return message;
  }
}

class RecommendationResultsScreen extends StatelessWidget {
  final RecommendationResult result;
  final String rawMessage; // Optional: for backward compatibility

  const RecommendationResultsScreen({
    required this.result,
    this.rawMessage = '',
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.indigo.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
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
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Hasil Rekomendasi',
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

              // Header Content with Animation
              Container(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
                child: Column(
                  children: [
                    // Animated Success Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Congratulations Text
                    Text(
                      'Rekomendasi Untuk Kamu!',
                      style: TextStyle(
                        color: Colors.amber.shade300,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Berdasarkan jawaban Anda, berikut adalah rekomendasi minat dan karir yang paling sesuai:',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Recommendation Cards in Material Container
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
                      // Top Handle for Visual Cue
                      Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(top: 16, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      // Results Count
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '${result.recommendations.length} Rekomendasi Terbaik',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),

                      // List of Recommendations
                      Expanded(
                        child: result.recommendations.isEmpty
                            ? _buildEmptyState(context)
                            : ListView.builder(
                                itemCount: result.recommendations.length,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final item = result.recommendations[index];
                                  // Update the index for the item
                                  final updatedItem = RecommendationItem(
                                    title: item.title,
                                    score: item.score,
                                    index: index,
                                    rules: item.rules,
                                    careers: item.careers,
                                    majors: item.majors,
                                  );
                                  return RecommendationCard(item: updatedItem);
                                },
                              ),
                      ),

                      // Action Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade700,
                                Colors.indigo.shade700,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade700.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              _showRawResults(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.auto_awesome, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Lihat Detail Forward Chaining',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 70,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak ada rekomendasi yang cocok',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Coba jawab pertanyaan dengan pola yang berbeda untuk menemukan rekomendasi yang sesuai',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRawResults(BuildContext context) {
    // Use raw message if available, otherwise generate it
    final detailedText =
        rawMessage.isNotEmpty ? rawMessage : _generateDetailedText();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Handle Bar
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(top: 16, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Detail Forward Chaining',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: SelectableText(
                            detailedText,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.grey.shade800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Copy and Share buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: detailedText));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Teks berhasil disalin!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy),
                                label: const Text('Salin Teks'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade200,
                                  foregroundColor: Colors.grey.shade800,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Share functionality would go here
                                  // Using a placeholder for now
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Bagikan hasil'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.share),
                                label: const Text('Bagikan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
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
            ],
          ),
        ),
      ),
    );
  }

  // Helper to generate detailed text from the result object if needed
  String _generateDetailedText() {
    String text = 'HASIL FORWARD CHAINING:\n\n';
    text += 'Working Memory (fakta): ${result.workingMemory.join(', ')}\n\n';

    text += 'Top ${result.recommendations.length} Rekomendasi:\n';
    for (int i = 0; i < result.recommendations.length; i++) {
      final rec = result.recommendations[i];
      text += '${i + 1}. ${rec.title} (Skor: ${rec.score})\n';

      // Rules
      if (rec.rules.isNotEmpty) {
        text += '  RULES YANG:\n';
        for (var rule in rec.rules) {
          text += '   - $rule\n';
        }
      }

      // Careers
      if (rec.careers.isNotEmpty) {
        text += '  Karir:\n';
        for (var career in rec.careers) {
          text += '   - $career\n';
        }
      } else {
        text += '  Karir: (Tidak ada data)\n';
      }

      // Majors
      if (rec.majors.isNotEmpty) {
        text += '  Jurusan Terkait:\n';
        for (var major in rec.majors) {
          text += '   - $major\n';
        }
      }

      text += '\n';
    }

    return text;
  }
}

// Models for the recommendation results
class RecommendationResult {
  final List<String> workingMemory;
  final List<RecommendationItem> recommendations;

  RecommendationResult({
    required this.workingMemory,
    required this.recommendations,
  });
}

// Using your existing RecommendationItem class
class RecommendationItem {
  final String title;
  final int score;
  final List<String> careers;
  final List<String> majors;
  final List<String> rules;
  final int index;

  RecommendationItem({
    required this.title,
    required this.score,
    required this.careers,
    required this.majors,
    required this.rules,
    required this.index,
  });
}

class RecommendationCard extends StatefulWidget {
  final RecommendationItem item;

  const RecommendationCard({
    required this.item,
    Key? key,
  }) : super(key: key);

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Generate medal color based on index
    final medalColors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];

    final medalColor = widget.item.index < medalColors.length
        ? medalColors[widget.item.index]
        : Colors.blue.shade300;

    // Parse the title to split program and concentration
    final parts = widget.item.title.split('|');
    final program = parts[0].trim();
    final concentration = parts.length > 1 ? parts[1].trim() : '';

    // Check if this is the top recommendation
    final isTopRecommendation = widget.item.index == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Card header with medal
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isTopRecommendation
                        ? [Colors.amber.shade300, Colors.amber.shade600]
                        : [Colors.blue.shade100, Colors.blue.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(_expanded ? 0 : 20),
                    bottomRight: Radius.circular(_expanded ? 0 : 20),
                  ),
                ),
                child: Row(
                  children: [
                    // Medal/Ranking indicator
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: medalColor,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: medalColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.item.index + 1}',
                          style: TextStyle(
                            color: medalColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Title and program
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            concentration,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            program,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Score indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isTopRecommendation
                            ? Colors.amber.shade600
                            : Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.item.score}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Card content (expandable)
              AnimatedCrossFade(
                firstChild: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tap untuk melihat detail',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                secondChild: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // New Explanation Section
                      if (isTopRecommendation) ...[
                        _buildExplanationSection(widget.item),
                        const SizedBox(height: 20),
                      ],

                      // Careers section
                      if (widget.item.careers.isNotEmpty) ...[
                        _buildSectionTitle('Karir yang Cocok:', Icons.work),
                        const SizedBox(height: 12),
                        _buildItemsList(widget.item.careers),
                        const SizedBox(height: 20),
                      ],

                      // Majors section
                      if (widget.item.majors.isNotEmpty) ...[
                        _buildSectionTitle('Jurusan Terkait:', Icons.school),
                        const SizedBox(height: 12),
                        _buildItemsList(widget.item.majors),
                        const SizedBox(height: 20),
                      ],

                      // Rules section
                      if (widget.item.rules.isNotEmpty) ...[
                        _buildSectionTitle(
                            'Forward Chaining Rules:', Icons.psychology),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.item.rules.map((rule) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.arrow_right,
                                      color: Colors.blue.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        rule,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      // Collapse button
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _expanded = false;
                              });
                            },
                            icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                            label: const Text('Tutup'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New method to build the explanation section
// New method to build the explanation section with student-friendly language
// Updated method to build the explanation section with all rules
  int totalItem = 0;
  Widget _buildExplanationSection(RecommendationItem item) {
    totalItem++;
    // Use all rules instead of limiting to 3
    final allRules = item.rules;

    // Process rules into friendly explanations
    final friendlyExplanations = allRules.map((rule) {
      // Clean up the rule text first
      String cleanedRule = rule.trim();

      // Try different patterns to extract questions
      String question = "";

      // Pattern 1: Try to find text between quotes with "pertanyaan" nearby
      final pattern1 = RegExp(r'pertanyaan\s*["""]([^"""]+)["""]');
      final match1 = pattern1.firstMatch(cleanedRule);

      // Pattern 2: Look for text after "menjawab Ya untuk"
      final pattern2 = RegExp(r'menjawab Ya untuk\s+["""]([^"""]+)["""]');
      final match2 = pattern2.firstMatch(cleanedRule);

      // Pattern 3: Look for any quoted text as a fallback
      final pattern3 = RegExp(r'["""]([^"""]+)["""]');
      final match3 = pattern3.firstMatch(cleanedRule);

      // Try each pattern in order
      if (match1 != null && match1.group(1) != null) {
        question = match1.group(1)!.trim();
      } else if (match2 != null && match2.group(1) != null) {
        question = match2.group(1)!.trim();
      } else if (match3 != null && match3.group(1) != null) {
        question = match3.group(1)!.trim();
      } else {
        // If no match found, use a generic placeholder
        question = "terkait minat ini";
      }

      // Extract program/minat part using multiple patterns
      String program = "";

      // Pattern for THEN Score("Program|Minat")
      final programPattern1 = RegExp(r'Score\s*\(\s*["""]([^"""]+)["""]');
      // Pattern for any program mention
      final programPattern2 =
          RegExp(r'(IPA|Sains|Teknik|[A-Za-z]+ologi)\s*\|\s*([A-Za-z\s]+)');

      final programMatch1 = programPattern1.firstMatch(cleanedRule);
      final programMatch2 = programPattern2.firstMatch(cleanedRule);

      if (programMatch1 != null && programMatch1.group(1) != null) {
        program = _formatProgramName(programMatch1.group(1)!.trim());
      } else if (programMatch2 != null) {
        // Format as "Concentration in Program"
        final programType = programMatch2.group(1);
        final concentration = programMatch2.group(2);
        if (programType != null && concentration != null) {
          program = "$concentration di bidang $programType";
        } else {
          program = _formatProgramName(item.title);
        }
      } else {
        program = _formatProgramName(item.title);
      }

      // Create a friendly explanation based on the extracted information
      return "Kamu menjawab \"Ya\" untuk pertanyaan \"$question\" yang menunjukkan ketertarikan pada bidang $program";
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Colors.green.shade700,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mengapa Ini Direkomendasikan',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Berdasarkan jawaban-jawabanmu di kuisioner, kami menemukan bahwa "${_formatProgramName(item.title)}" sangat sesuai dengan minat dan bakatmu.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Alasan utama (${friendlyExplanations.length} faktor):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),

          // If there are many rules, put them in a scrollable container with max height
          friendlyExplanations.length > 5
              ? Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _buildExplanationItems(friendlyExplanations),
                    ),
                  ),
                )
              : Column(
                  children: _buildExplanationItems(friendlyExplanations),
                ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.amber.shade800,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rekomendasi ini diambil dari pertanyaan minat yang kamu pilih, rekomendasi ini terkadang tidak akurat',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ingat, ini adalah rekomendasi berdasarkan minatmu saat ini. Kamu tetap berhak menentukan pilihan terbaikmu sendiri.',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build the explanation items
  List<Widget> _buildExplanationItems(List<String> explanations) {
    return explanations.asMap().entries.map((entry) {
      final index = entry.key;
      final explanation = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                explanation,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Helper method to format program names more readably
  String _formatProgramName(String title) {
    final parts = title.split('|');
    if (parts.length > 1) {
      final program = parts[0].trim();
      final concentration = parts[1].trim();
      return "$concentration di bidang $program";
    }
    return title;
  }

  // Helper method to simplify the title for better readability
  String _simplifyTitle(String title) {
    final parts = title.split('|');
    if (parts.length > 1) {
      return '${parts[1].trim()} di bidang ${parts[0].trim()}';
    }
    return title;
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.blue.shade700,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Helper function to replace the simple dialog with our new UI
void showRecommendationResultsGetx(RecommendationResult result,
    {String rawMessage = ''}) {
  Get.to(() => RecommendationResultsScreen(
        result: result,
        rawMessage: rawMessage,
      ));
}
// Helper function to replace the simple dialog with our new UI

class QuestionPage extends StatelessWidget {
  final bool isKerja; // true=Kerja, false=Kuliah
  const QuestionPage({Key? key, required this.isKerja}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(QuestionController(isKerja: isKerja));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isKerja ? 'Kuisioner Karir' : 'Kuisioner Kuliah',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
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

          return Column(
            children: [
              // Progress Indicator Section - Kept as requested
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: controller.answeredCount / controller.totalCount,
                        backgroundColor: Colors.white24,
                        color: Colors.amber.shade500,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
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
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                          isKerja
                              ? 'Pertanyaan Minat Karir'
                              : 'Pertanyaan Minat Kuliah',
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
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          itemCount: questionsThisPage.length,
                          itemBuilder: (context, index) {
                            final qItem = questionsThisPage[index];
                            final globalIndex = startIndex + index;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              shadowColor: Colors.black.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Question header
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade600,
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
                                      ],
                                    ),
                                  ),

                                  // Answer options
                                  Obx(() {
                                    final selectedAnswer = controller
                                        .allQuestions
                                        .firstWhere((q) => q.id == qItem.id)
                                        .userAnswer;

                                    return Column(
                                      children: [
                                        _buildAnswerOption(
                                          icon: Icons.check_circle_outline,
                                          label: 'Ya',
                                          isSelected: selectedAnswer == true,
                                          onTap: () {
                                            controller.setAnswer(qItem, true);
                                          },
                                          activeColor: Colors.green.shade600,
                                        ),
                                        Divider(
                                          height: 1,
                                          color: Colors.grey.shade200,
                                        ),
                                        _buildAnswerOption(
                                          icon: Icons.cancel_outlined,
                                          label: 'Tidak',
                                          isSelected: selectedAnswer == false,
                                          onTap: () {
                                            controller.setAnswer(qItem, false);
                                          },
                                          activeColor: Colors.red.shade600,
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            );
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
                                    ? () => controller.prevPage()
                                    : null,
                                icon: const Icon(Icons.arrow_back, size: 18),
                                label: const Text('Kembali'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  backgroundColor: Colors.grey.shade200,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
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
                                bool canProceed =
                                    controller.allAnsweredThisPage;
                                final isLastPage =
                                    controller.currentPage.value ==
                                        controller.totalPages - 1;

                                return ElevatedButton.icon(
                                  onPressed: canProceed
                                      ? () {
                                          if (!isLastPage) {
                                            controller.nextPage();
                                          } else {
                                            final results =
                                                controller.runForwardChaining();
                                            showRecommendationResultsGetx(
                                                results);
                                          }
                                        }
                                      : null,
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
                                        Colors.blue.shade200,
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
    );
  }

  // Helper method for building answer options
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

  void _showResultDialog(BuildContext context, String msg) {
    Get.dialog(
      AlertDialog(
        title: const Text('Rekomendasi'),
        content: SingleChildScrollView(child: Text(msg)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }
}

/// Halaman untuk memilih/toggle Developer Mode dengan desain yang lebih modern dan menarik
/// Fixed version to prevent overflow
class DeveloperModePage extends StatelessWidget {
  const DeveloperModePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DeveloperModeController());

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade800,
              Colors.indigo.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      Get.to(() => AboutPage());
                    },
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.indigo.shade100,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.indigo.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Tentang",
                            style: TextStyle(
                              color: Colors.indigo.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30), // Reduced height
                // App Logo and Title
                Center(
                  child: Container(
                    width: 100, // Reduced size
                    height: 100, // Reduced size
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.psychology,
                        size: 60, // Reduced size
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Reduced height
                const Text(
                  'Forward Chaining',
                  style: TextStyle(
                    fontSize: 28, // Reduced size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),

                const Text(
                  'Sistem Rekomendasi Karir & Kuliah',
                  style: TextStyle(
                    fontSize: 15, // Reduced size
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 30), // Reduced height

                // Main Content Area - Using Flexible instead of Expanded to prevent overflow
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      // Add scroll to prevent overflow
                      child: Padding(
                        padding: const EdgeInsets.all(20.0), // Reduced padding
                        child: Column(
                          children: [
                            const SizedBox(height: 12), // Reduced height
                            Text(
                              'Selamat Datang!',
                              style: TextStyle(
                                fontSize: 20, // Reduced size
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Aplikasi ini akan membantumu menemukan program studi dan karir yang paling sesuai dengan minatmu.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14, // Reduced size
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20), // Reduced height

                            // Developer Mode Card
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.indigo.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    16.0), // Reduced padding
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(
                                              8), // Reduced padding
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.code,
                                            size: 20, // Reduced size
                                            color: Colors.orange.shade800,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Mode Developer',
                                                style: TextStyle(
                                                  fontSize: 16, // Reduced size
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.indigo.shade800,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                'Akses data & model AI',
                                                style: TextStyle(
                                                  fontSize: 12, // Reduced size
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Aktifkan mode developer untuk melihat data dan validasi model forward chaining yang digunakan dalam sistem rekomendasi.',
                                      style: TextStyle(
                                        fontSize: 13, // Reduced size
                                        color: Colors.black54,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Obx(() => Container(
                                          decoration: BoxDecoration(
                                            color:
                                                controller.isDeveloperMode.value
                                                    ? Colors.indigo.shade50
                                                    : Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: SwitchListTile(
                                            title: Text(
                                              controller.isDeveloperMode.value
                                                  ? 'Developer Mode Aktif'
                                                  : 'Developer Mode Nonaktif',
                                              style: TextStyle(
                                                fontSize: 14, // Reduced size
                                                fontWeight: FontWeight.w500,
                                                color: controller
                                                        .isDeveloperMode.value
                                                    ? Colors.indigo.shade800
                                                    : Colors.black54,
                                              ),
                                            ),
                                            value: controller
                                                .isDeveloperMode.value,
                                            onChanged: (value) => controller
                                                .toggleDeveloperMode(value),
                                            activeColor: Colors.indigo,
                                            activeTrackColor:
                                                Colors.indigo.shade300,
                                            inactiveThumbColor:
                                                Colors.grey.shade400,
                                            inactiveTrackColor:
                                                Colors.grey.shade300,
                                            secondary: Icon(
                                              controller.isDeveloperMode.value
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                              color: controller
                                                      .isDeveloperMode.value
                                                  ? Colors.indigo
                                                  : Colors.grey.shade500,
                                              size: 20, // Reduced size
                                            ),
                                            dense:
                                                true, // Make switch more compact
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Buttons
                            ElevatedButton(
                              onPressed: () => Get.to(() => const HomePage()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade800,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14), // Reduced padding
                                minimumSize: const Size(
                                    double.infinity, 50), // Reduced height
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded,
                                      size: 20), // Reduced size
                                  SizedBox(width: 8),
                                  Text(
                                    'Mulai Aplikasi',
                                    style: TextStyle(
                                      fontSize: 15, // Reduced size
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16), // Reduced height

                            // Developer mode button (only visible when dev mode is active)
                            Obx(() => controller.isDeveloperMode.value
                                ? ElevatedButton(
                                    onPressed: () =>
                                        Get.to(() => const DevDataViewerPage()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14), // Reduced padding
                                      minimumSize: const Size(double.infinity,
                                          50), // Reduced height
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.data_array,
                                            size: 18), // Reduced size
                                        SizedBox(width: 8),
                                        Text(
                                          'Data & Model Viewer',
                                          style: TextStyle(
                                            fontSize: 15, // Reduced size
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink()),

                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Reduced height
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DevDataViewerController extends GetxController {
  final RxList<ProgramStudi> programStudiKerja = <ProgramStudi>[].obs;
  final RxList<ProgramStudi> programStudiKuliah = <ProgramStudi>[].obs;
  final RxString currentView =
      'overview'.obs; // overview, kerja, kuliah, rules, ugm
  final RxBool isLoading = true.obs;
  final RxString loadingError = ''.obs;
  final RxList<Map<String, dynamic>> rulesData = <Map<String, dynamic>>[].obs;

  // Data for UGM tuition fees
  final RxList<Map<String, dynamic>> biayaKuliahD4UGM =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> biayaKuliahS1UGM =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  /// Load all data for analysis
  void loadAllData() async {
    isLoading.value = true;
    loadingError.value = '';

    try {
      // Load Kerja data
      await loadProgramData(true, programStudiKerja);

      // Load Kuliah data
      await loadProgramData(false, programStudiKuliah);

      // Load UGM tuition fee data
      await loadUGMTuitionData();

      // Generate sample rules for analysis
      generateSampleRules();

      isLoading.value = false;
    } catch (e) {
      loadingError.value = e.toString();
      isLoading.value = false;
    }
  }

  void setCurrentView(String view) {
    currentView.value = view;
  }

  /// Memuat data ProgramStudi dari file JSON (Sains + Teknik) tergantung Kerja/Kuliah
  Future<void> loadProgramData(
      bool isKerja, RxList<ProgramStudi> target) async {
    // Tentukan file sains
    final sainsFile = isKerja
        ? 'assets/ipa_sains_kerja.json'
        : 'assets/ipa_sains_kuliah.json';

    // File teknik
    final teknikFile = isKerja
        ? 'assets/ipa_teknik_kerja.json'
        : 'assets/ipa_teknik_kuliah.json';

    // Baca JSON sains
    final sainsString = await rootBundle.rootBundle.loadString(sainsFile);
    final sainsMap = json.decode(sainsString) as Map<String, dynamic>;

    // Baca JSON teknik
    final teknikString = await rootBundle.rootBundle.loadString(teknikFile);
    final teknikMap = json.decode(teknikString) as Map<String, dynamic>;

    // Ubah ke list ProgramStudi
    final programs = <ProgramStudi>[];
    // Parsing sains
    for (var entry in sainsMap.entries) {
      programs.add(ProgramStudi.fromJson(entry.value));
    }
    // Parsing teknik
    for (var entry in teknikMap.entries) {
      programs.add(ProgramStudi.fromJson(entry.value));
    }

    target.value = programs;
  }

  /// Load UGM tuition fee data
  Future<void> loadUGMTuitionData() async {
    try {
      // Load D4 data
      final d4String = await rootBundle.rootBundle
          .loadString('assets/biaya_kuliah_d4_ugm.json');
      final d4List = json.decode(d4String) as List<dynamic>;
      biayaKuliahD4UGM.value = d4List.cast<Map<String, dynamic>>();

      // Load S1 data
      final s1String = await rootBundle.rootBundle
          .loadString('assets/biaya_kuliah_s1_ugm.json');
      final s1List = json.decode(s1String) as List<dynamic>;
      biayaKuliahS1UGM.value = s1List.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error loading UGM data: $e');
      // Continue even if UGM data fails to load
    }
  }

  /// Generate sample rules untuk analisis
  void generateSampleRules() {
    final rules = <Map<String, dynamic>>[];

    // Flatten pertanyaan dari programStudiKerja untuk contoh rules
    int counter = 1;
    for (var prog in programStudiKerja) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;
        final minatVal = minatEntry.value;

        for (var p in minatVal.pertanyaan) {
          final bobot = extractBobot(p);
          final cleaned = cleanPertanyaan(p);
          final qId = 'Q$counter';
          counter++;

          rules.add({
            'id': 'R$counter',
            'type': 'Forward Chaining Rule',
            'condition': 'IF $qId = Yes',
            'action': 'THEN Score("${prog.name}|$minatKey") += $bobot',
            'question': cleaned,
            'weight': bobot,
            'programName': prog.name,
            'minatKey': minatKey,
          });
        }
      }
    }

    rulesData.value = rules;
  }

  /// Get total question count
  int getTotalQuestions() {
    int count = 0;

    // Count questions from kerja
    for (var prog in programStudiKerja) {
      for (var minat in prog.minat.values) {
        count += minat.pertanyaan.length;
      }
    }

    // Count questions from kuliah
    for (var prog in programStudiKuliah) {
      for (var minat in prog.minat.values) {
        count += minat.pertanyaan.length;
      }
    }

    return count;
  }

  /// Count total minat
  int getTotalMinat() {
    int kerjaMinat =
        programStudiKerja.fold(0, (sum, prog) => sum + prog.minat.length);
    int kuliahMinat =
        programStudiKuliah.fold(0, (sum, prog) => sum + prog.minat.length);
    return kerjaMinat + kuliahMinat;
  }

  /// Count total jurusan
  int getTotalJurusan() {
    Set<String> allJurusan = {};

    // Collect unique jurusan from Kerja
    for (var prog in programStudiKerja) {
      for (var minat in prog.minat.values) {
        allJurusan.addAll(minat.jurusanTerkait);
      }
    }

    // Collect unique jurusan from Kuliah
    for (var prog in programStudiKuliah) {
      for (var minat in prog.minat.values) {
        allJurusan.addAll(minat.jurusanTerkait);
      }
    }

    return allJurusan.length;
  }

  /// Count total karir
  int getTotalKarir() {
    Set<String> allKarir = {};

    // Collect unique karir from Kerja
    for (var prog in programStudiKerja) {
      for (var minat in prog.minat.values) {
        allKarir.addAll(minat.karir);
      }
    }

    // Collect unique karir from Kuliah
    for (var prog in programStudiKuliah) {
      for (var minat in prog.minat.values) {
        allKarir.addAll(minat.karir);
      }
    }

    return allKarir.length;
  }
}

/// Halaman untuk melihat data dan analisis forward chaining (developer mode)
class DevDataViewerPage extends StatelessWidget {
  const DevDataViewerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DevDataViewerController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Data Viewer'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.loadingError.value.isNotEmpty) {
          return Center(child: Text('Error: ${controller.loadingError.value}'));
        }

        return Column(
          children: [
            // Tab navigation
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTab(controller, 'overview', 'Overview'),
                    _buildTab(controller, 'kerja', 'Kerja Data'),
                    _buildTab(controller, 'kuliah', 'Kuliah Data'),
                    _buildTab(controller, 'rules', 'Rules'),
                    _buildTab(controller, 'analysis', 'Model Analysis'),
                    _buildTab(controller, 'ugm', 'UGM Data'),
                  ],
                ),
              ),
            ),

            // Content based on selected tab
            Expanded(
              child: buildContent(controller),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTab(
      DevDataViewerController controller, String viewName, String label) {
    return InkWell(
      onTap: () => controller.setCurrentView(viewName),
      splashColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: controller.currentView.value == viewName
              ? Colors.blue
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: controller.currentView.value == viewName
                ? Colors.white
                : Colors.black,
            fontWeight: controller.currentView.value == viewName
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget buildContent(DevDataViewerController controller) {
    switch (controller.currentView.value) {
      case 'overview':
        return buildOverviewTab(controller);
      case 'kerja':
        return buildDataTab(controller, controller.programStudiKerja, 'Kerja');
      case 'kuliah':
        return buildDataTab(
            controller, controller.programStudiKuliah, 'Kuliah');
      case 'rules':
        return buildRulesTab(controller);
      case 'analysis':
        return buildAnalysisTab(controller);
      case 'ugm':
        return buildUGMDataTab(controller);
      default:
        return const Center(child: Text('Unknown view'));
    }
  }

  /// Tab Overview - statistik umum
  Widget buildOverviewTab(DevDataViewerController controller) {
    return Container(
      color: Colors.blueAccent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Data Aplikasi',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Stats Cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  'Total Questions',
                  controller.getTotalQuestions().toString(),
                  Icons.question_answer,
                  onTap: () => _showQuestionsDialog(controller),
                ),
                _buildStatCard(
                  'Total Rules',
                  controller.rulesData.length.toString(),
                  Icons.rule,
                  onTap: () => _showRulesDialog(controller),
                ),
                _buildStatCard(
                  'Total Minat',
                  controller.getTotalMinat().toString(),
                  Icons.category,
                  onTap: () => _showMinatDialog(controller),
                ),
                _buildStatCard(
                  'Total Jurusan',
                  controller.getTotalJurusan().toString(),
                  Icons.school,
                  onTap: () => _showJurusanDialog(controller),
                ),
                _buildStatCard(
                  'Total Karir',
                  controller.getTotalKarir().toString(),
                  Icons.work,
                  onTap: () => _showKarirDialog(controller),
                ),
                _buildStatCard(
                    'Data Sources', '6 JSON Files', Icons.data_array),
              ],
            ),

            const SizedBox(height: 30),

            // Forward Chaining Explanation
            const Text(
              'Implementasi Forward Chaining',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Model ini mengimplementasikan pendekatan Forward Chaining berbasis aturan dengan:'),
                    SizedBox(height: 8),
                    Text(
                        '• Memori Kerja: Menyimpan fakta seperti "Q1=Ya" / "Q1=Tidak"'),
                    Text(
                        '• Basis Aturan: Aturan dalam bentuk "JIKA kondisi MAKA aksi"'),
                    Text(
                        '• Mesin Inferensi: Menerapkan aturan pada memori kerja untuk mendapatkan skor'),
                    Text(
                        '• Pembobotan Skor: Setiap pertanyaan memiliki bobot yang berkontribusi pada skor akhir'),
                    SizedBox(height: 8),
                    Text(
                        'Implementasi ini adalah sistem produksi klasik dengan siklus cocok-selesaikan-bertindak yang berlanjut hingga tidak ada lagi aturan yang dapat dijalankan.'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Visualisasi Flow Forward Chaining
            const Text(
              'Alur Forward Chaining',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '1. Pengguna menjawab pertanyaan (Ya/Tidak) untuk menetapkan fakta awal'),
                    Text(
                        '2. Fakta ditambahkan ke dalam memori kerja (misalnya, "Q1=Ya")'),
                    Text(
                        '3. Aturan yang sesuai dengan fakta dalam memori kerja dijalankan'),
                    Text(
                        '4. Setiap aturan yang dijalankan menambahkan skor ke minat yang sesuai'),
                    Text(
                        '5. Setelah semua aturan dievaluasi, minat diurutkan berdasarkan skor'),
                    Text('6. Tiga minat teratas disajikan sebagai rekomendasi'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 5),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              if (onTap != null) const SizedBox(height: 5),
              if (onTap != null)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lihat Detail',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.touch_app,
                      size: 12,
                      color: Colors.blue,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  } // Add the dialog methods to show detailed information when a card is tapped

  void _showQuestionsDialog(DevDataViewerController controller) {
    final allQuestions = <Map<String, dynamic>>[];

    // Collect questions from Kerja
    for (var prog in controller.programStudiKerja) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;
        final minatVal = minatEntry.value;

        for (var p in minatVal.pertanyaan) {
          final bobot = extractBobot(p);
          final cleaned = cleanPertanyaan(p);

          allQuestions.add({
            'pertanyaan': cleaned,
            'bobot': bobot,
            'program': prog.name,
            'minat': minatKey,
            'type': 'Kerja',
          });
        }
      }
    }

    // Collect questions from Kuliah
    for (var prog in controller.programStudiKuliah) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;
        final minatVal = minatEntry.value;

        for (var p in minatVal.pertanyaan) {
          final bobot = extractBobot(p);
          final cleaned = cleanPertanyaan(p);

          allQuestions.add({
            'pertanyaan': cleaned,
            'bobot': bobot,
            'program': prog.name,
            'minat': minatKey,
            'type': 'Kuliah',
          });
        }
      }
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'All Questions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Total: ${allQuestions.length} questions'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: allQuestions.length,
                  itemBuilder: (context, index) {
                    final q = allQuestions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(q['pertanyaan']),
                        subtitle: Text(
                          '${q['type']} | ${q['program']} | ${q['minat']} | Bobot: ${q['bobot']}',
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              q['type'] == 'Kerja' ? Colors.blue : Colors.green,
                          child: Text('${index + 1}'),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRulesDialog(DevDataViewerController controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'All Rules',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Total: ${controller.rulesData.length} rules'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.rulesData.length,
                  itemBuilder: (context, index) {
                    final rule = controller.rulesData[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${rule['condition']} ${rule['action']}'),
                        subtitle: Text(
                          'Question: ${rule['question']}\nProgram: ${rule['programName']} | Minat: ${rule['minatKey']} | Weight: ${rule['weight']}',
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber,
                          child:
                              Text(rule['id'].toString().replaceAll('R', '')),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMinatDialog(DevDataViewerController controller) {
    final allMinat = <Map<String, dynamic>>[];

    // Collect minat from Kerja
    for (var prog in controller.programStudiKerja) {
      for (var minatEntry in prog.minat.entries) {
        allMinat.add({
          'name': minatEntry.key,
          'program': prog.name,
          'type': 'Kerja',
          'jumlahPertanyaan': minatEntry.value.pertanyaan.length,
          'jumlahKarir': minatEntry.value.karir.length,
          'jumlahJurusan': minatEntry.value.jurusanTerkait.length,
        });
      }
    }

    // Collect minat from Kuliah
    for (var prog in controller.programStudiKuliah) {
      for (var minatEntry in prog.minat.entries) {
        allMinat.add({
          'name': minatEntry.key,
          'program': prog.name,
          'type': 'Kuliah',
          'jumlahPertanyaan': minatEntry.value.pertanyaan.length,
          'jumlahKarir': minatEntry.value.karir.length,
          'jumlahJurusan': minatEntry.value.jurusanTerkait.length,
        });
      }
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'All Minat',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Total: ${allMinat.length} minat'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: allMinat.length,
                  itemBuilder: (context, index) {
                    final minat = allMinat[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(minat['name']),
                        subtitle: Text(
                          '${minat['type']} | ${minat['program']}\nPertanyaan: ${minat['jumlahPertanyaan']} | Karir: ${minat['jumlahKarir']} | Jurusan: ${minat['jumlahJurusan']}',
                        ),
                        leading: CircleAvatar(
                          backgroundColor: minat['type'] == 'Kerja'
                              ? Colors.blue
                              : Colors.green,
                          child: Text('${index + 1}'),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJurusanDialog(DevDataViewerController controller) {
    // Collect all unique jurusan with their associated minat and program
    final Map<String, List<Map<String, dynamic>>> jurusanMap = {};

    // Helper function to add jurusan data
    void addJurusanData(
        String jurusan, String program, String minat, String type) {
      if (!jurusanMap.containsKey(jurusan)) {
        jurusanMap[jurusan] = [];
      }

      jurusanMap[jurusan]!.add({
        'program': program,
        'minat': minat,
        'type': type,
      });
    }

    // Collect from Kerja
    for (var prog in controller.programStudiKerja) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;

        for (var jurusan in minatEntry.value.jurusanTerkait) {
          addJurusanData(jurusan, prog.name, minatKey, 'Kerja');
        }
      }
    }

    // Collect from Kuliah
    for (var prog in controller.programStudiKuliah) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;

        for (var jurusan in minatEntry.value.jurusanTerkait) {
          addJurusanData(jurusan, prog.name, minatKey, 'Kuliah');
        }
      }
    }

    // Convert to list for display
    final jurusanList = jurusanMap.entries.map((entry) {
      return {
        'name': entry.key,
        'count': entry.value.length,
        'references': entry.value,
      };
    }).toList();

    // Sort by frequency
    jurusanList
        .sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'All Jurusan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Total: ${jurusanList.length} jurusan'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: jurusanList.length,
                  itemBuilder: (context, index) {
                    final jurusan = jurusanList[index];
                    final references =
                        jurusan['references'] as List<Map<String, dynamic>>;

                    return ExpansionTile(
                      title: Text(jurusan['name'] as String),
                      subtitle: Text('Referenced ${jurusan['count']} times'),
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Text('${index + 1}'),
                      ),
                      children: [
                        ...references.map((ref) {
                          return ListTile(
                            title: Text('${ref['type']} | ${ref['program']}'),
                            subtitle: Text('Minat: ${ref['minat']}'),
                            leading: Icon(
                              ref['type'] == 'Kerja'
                                  ? Icons.work
                                  : Icons.school,
                              color: ref['type'] == 'Kerja'
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showKarirDialog(DevDataViewerController controller) {
    // Collect all unique karir with their associated minat and program
    final Map<String, List<Map<String, dynamic>>> karirMap = {};

    // Helper function to add karir data
    void addKarirData(String karir, String program, String minat, String type) {
      if (!karirMap.containsKey(karir)) {
        karirMap[karir] = [];
      }

      karirMap[karir]!.add({
        'program': program,
        'minat': minat,
        'type': type,
      });
    }

    // Collect from Kerja
    for (var prog in controller.programStudiKerja) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;

        for (var karir in minatEntry.value.karir) {
          addKarirData(karir, prog.name, minatKey, 'Kerja');
        }
      }
    }

    // Collect from Kuliah
    for (var prog in controller.programStudiKuliah) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;

        for (var karir in minatEntry.value.karir) {
          addKarirData(karir, prog.name, minatKey, 'Kuliah');
        }
      }
    }

    // Convert to list for display
    final karirList = karirMap.entries.map((entry) {
      return {
        'name': entry.key,
        'count': entry.value.length,
        'references': entry.value,
      };
    }).toList();

    // Sort by frequency
    karirList.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'All Karir',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Total: ${karirList.length} karir'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: karirList.length,
                  itemBuilder: (context, index) {
                    final karir = karirList[index];
                    final references =
                        karir['references'] as List<Map<String, dynamic>>;

                    return ExpansionTile(
                      title: Text(karir['name'] as String),
                      subtitle: Text('Referenced ${karir['count']} times'),
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Text('${index + 1}'),
                      ),
                      children: [
                        ...references.map((ref) {
                          return ListTile(
                            title: Text('${ref['type']} | ${ref['program']}'),
                            subtitle: Text('Minat: ${ref['minat']}'),
                            leading: Icon(
                              ref['type'] == 'Kerja'
                                  ? Icons.work
                                  : Icons.school,
                              color: ref['type'] == 'Kerja'
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab untuk menampilkan data ProgramStudi (Kerja atau Kuliah)
  /// Tab untuk menampilkan data ProgramStudi (Kerja atau Kuliah)
  Widget buildDataTab(DevDataViewerController controller,
      List<ProgramStudi> data, String type) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '$type Dataset - ${data.length} Program Studi',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final program = data[index];
              final minatCount = program.minat.length;
              int pertanyaanCount = 0;

              // Count pertanyaan
              for (var minat in program.minat.values) {
                pertanyaanCount += minat.pertanyaan.length;
              }

              return ExpansionTile(
                title: Text(program.name),
                subtitle:
                    Text('$minatCount minat, $pertanyaanCount pertanyaan'),
                children: [
                  // Program description
                  if (program.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text('Description: ${program.description}'),
                    ),

                  // Categories
                  if (program.categories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child:
                          Text('Categories: ${program.categories.join(", ")}'),
                    ),

                  // Minat details
                  ...program.minat.entries.map((minatEntry) {
                    final minatKey = minatEntry.key;
                    final minatValue = minatEntry.value;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ExpansionTile(
                          title: Text('Minat: $minatKey'),
                          subtitle: Text(
                              '${minatValue.pertanyaan.length} pertanyaan'),
                          children: [
                            // Pertanyaan
                            if (minatValue.pertanyaan.isNotEmpty)
                              ListTile(
                                title: const Text('Pertanyaan:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: minatValue.pertanyaan.map((p) {
                                    final bobot = extractBobot(p);
                                    final cleaned = cleanPertanyaan(p);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text('• $cleaned [bobot: $bobot]'),
                                    );
                                  }).toList(),
                                ),
                              ),

                            // Karir
                            if (minatValue.karir.isNotEmpty)
                              ListTile(
                                title: const Text('Karir:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: minatValue.karir
                                      .map((k) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Text('• $k'),
                                          ))
                                      .toList(),
                                ),
                              ),

                            // Jurusan Terkait
                            if (minatValue.jurusanTerkait.isNotEmpty)
                              ListTile(
                                title: const Text('Jurusan Terkait:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: minatValue.jurusanTerkait
                                      .map((j) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Text('• $j'),
                                          ))
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Tab untuk menampilkan rules
  Widget buildRulesTab(DevDataViewerController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Forward Chaining Rules - ${controller.rulesData.length} Rules',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // Search & Filter controls could be added here

        Expanded(
          child: ListView.builder(
            itemCount: controller.rulesData.length,
            itemBuilder: (context, index) {
              final rule = controller.rulesData[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(
                      '${rule['id']}: ${rule['condition']} ${rule['action']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Question: ${rule['question']}'),
                      Text(
                          'Weight: ${rule['weight']} | Program: ${rule['programName']} | Minat: ${rule['minatKey']}'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Tab untuk analisis kesesuaian dengan metode Forward Chaining
  Widget buildAnalysisTab(DevDataViewerController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Forward Chaining Model Analysis',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 16),

          // Analysis of implementation
          _buildAnalysisSection(
            'Implementation Accuracy',
            [
              'The implementation correctly follows forward chaining principles:',
              '• Uses a working memory to store facts',
              '• Has a rule base of IF-THEN rules',
              '• Implements pattern matching to find applicable rules',
              '• Rules fire when their conditions match working memory',
              '• Actions of fired rules can update scores (modify state)',
            ],
            90,
          ),

          _buildAnalysisSection(
            'Rule Structure',
            [
              'Rules follow standard structure but with simplifications:',
              '• Conditions only check for presence of "Qn=Yes"',
              '• More complex conditions (e.g., AND/OR combinations) aren\'t implemented',
              '• Rule actions only increase scores instead of adding new facts',
              '• The system does not support rule chaining (where firing one rule enables another)',
            ],
            75,
          ),

          _buildAnalysisSection(
            'Inference Process',
            [
              'The inference process is partially implemented:',
              '• Rules are checked against working memory',
              '• Matched rules are fired and actions executed',
              '• The process loops until no more rules can fire',
              '• However, since rules don\'t add new facts, the process completes in one iteration',
              '• There\'s no conflict resolution strategy as all applicable rules are fired',
            ],
            80,
          ),

          _buildAnalysisSection(
            'Results Explanation',
            [
              'The system provides good explanation capabilities:',
              '• Shows which rules contributed to each recommendation',
              '• Displays the questions that influenced the result',
              '• Shows the weights/scores that led to the final ranking',
              '• This transparency is a strength of the implementation',
            ],
            95,
          ),

          _buildAnalysisSection(
            'Overall Assessment',
            [
              'This is a simplified but valid forward chaining implementation:',
              '• It follows the core principles of the forward chaining method',
              '• The implementation is well-suited for its specific use case',
              '• The scoring mechanism is an appropriate adaptation for the recommendation context',
              '• Areas for potential enhancement: more complex rule conditions, true fact generation, and multi-stage inference',
            ],
            85,
          ),

          const SizedBox(height: 30),

          // Recommendations for improvement
          const Text(
            'Improvement Suggestions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Implement full fact generation (not just scoring)'),
                  Text('2. Support complex conditions with AND/OR operators'),
                  Text('3. Enable multi-stage inference with rule chaining'),
                  Text(
                      '4. Add conflict resolution strategies for rule prioritization'),
                  Text(
                      '5. Consider implementing backward chaining to complement forward chaining'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUGMDataTab(DevDataViewerController controller) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Program S1'),
              Tab(text: 'Program D4'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // S1 Data Tab
                buildUGMProgramTab(controller.biayaKuliahS1UGM, 'S1'),
                // D4 Data Tab
                buildUGMProgramTab(controller.biayaKuliahD4UGM, 'D4'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget to build UGM program data tab content
  Widget buildUGMProgramTab(
      List<Map<String, dynamic>> data, String programType) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available for this program type'),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biaya Kuliah UGM - Program $programType',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Data Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 15,
                horizontalMargin: 10,
                headingRowColor:
                    MaterialStateProperty.all(Colors.blue.shade100),
                columns: [
                  const DataColumn(label: Text('NO')),
                  const DataColumn(label: Text('PROGRAM')),
                  const DataColumn(label: Text('NAMA PROGRAM STUDI')),
                  const DataColumn(label: Text('BKT')),
                  const DataColumn(label: Text('UKT 1')),
                  const DataColumn(label: Text('UKT 2')),
                  const DataColumn(label: Text('UKT 3')),
                  const DataColumn(label: Text('UKT 4')),
                  const DataColumn(label: Text('UKT 5')),
                  const DataColumn(label: Text('UKT 6')),
                ],
                rows: data
                    .where((row) => row['NO'] != '') // Skip header row
                    .map((row) {
                  return DataRow(
                    cells: [
                      DataCell(Text(row['NO'] ?? '')),
                      DataCell(Text(row['PROGRAM'] ?? '')),
                      DataCell(Text(row['NAMA PROGRAM STUDI'] ?? '')),
                      DataCell(Text(row['BKT PER SEMESTER'] ?? '')),
                      DataCell(Text(row['UKT_KELOMPOK_1'] ?? '')),
                      DataCell(Text(row['UKT_KELOMPOK_2'] ?? '')),
                      DataCell(Text(row['UKT_KELOMPOK_3'] ?? '')),
                      DataCell(Text(row['UKT_KELOMPOK_4'] ?? '')),
                      DataCell(Text(row['UKT_KELOMPOK_5'] ?? '')),
                      DataCell(Text(row['UKT_KELOMPOK_6'] ?? '')),
                    ],
                  );
                }).toList(),
              ),
            ),

            // Semester Fee Summary
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Penjelasan UKT (Uang Kuliah Tunggal)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        '• UKT Kelompok 1: Pendidikan Unggul Bersubsidi 100%'),
                    const Text(
                        '• UKT Kelompok 2: Pendidikan Unggul Bersubsidi 100%'),
                    const Text(
                        '• UKT Kelompok 3: Pendidikan Unggul Bersubsidi 75%'),
                    const Text(
                        '• UKT Kelompok 4: Pendidikan Unggul Bersubsidi 50%'),
                    const Text(
                        '• UKT Kelompok 5: Pendidikan Unggul Bersubsidi 25%'),
                    const Text(
                        '• UKT Kelompok 6: Pendidikan Unggul (Biaya Penuh)'),
                    const SizedBox(height: 8),
                    const Text(
                        'BKT: Biaya Kuliah Tunggal (Biaya operasional per mahasiswa per semester)'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(
      String title, List<String> points, int scorePercent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getScoreColor(scorePercent),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '$scorePercent%',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            ...points.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(point),
                )),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

//////////////////////////////////////////////
// Bagian Model, Fungsi Pendukung, & Rule
//////////////////////////////////////////////

/// Representasi data utama (ProgramStudi) dari JSON
class ProgramStudi {
  final String name;
  final String description;
  final List<String> categories;
  final Map<String, Minat> minat;

  ProgramStudi({
    required this.name,
    required this.description,
    required this.categories,
    required this.minat,
  });

  factory ProgramStudi.fromJson(Map<String, dynamic> json) {
    final minatMap = <String, Minat>{};
    if (json['minat'] != null) {
      (json['minat'] as Map<String, dynamic>).forEach((key, value) {
        minatMap[key] = Minat.fromJson(value);
      });
    }
    return ProgramStudi(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      categories: (json['categories'] == null)
          ? []
          : List<String>.from(json['categories']),
      minat: minatMap,
    );
  }

  /// Jika not found, kembalikan empty
  factory ProgramStudi.empty() {
    return ProgramStudi(
      name: '',
      description: '',
      categories: [],
      minat: {},
    );
  }
}

/// Representasi Minat (sub-data program studi)
class Minat {
  final List<String> pertanyaan;
  final List<String> karir;
  final List<String> jurusanTerkait;

  Minat({
    required this.pertanyaan,
    required this.karir,
    required this.jurusanTerkait,
  });

  factory Minat.fromJson(Map<String, dynamic> json) {
    return Minat(
      pertanyaan: (json['pertanyaan'] == null)
          ? []
          : List<String>.from(json['pertanyaan']),
      karir: (json['karir'] == null) ? [] : List<String>.from(json['karir']),
      jurusanTerkait: (json['jurusan_terkait'] == null)
          ? []
          : List<String>.from(json['jurusan_terkait']),
    );
  }
}

/// Item pertanyaan di UI
class QuestionItem {
  final String id; // Q1, Q2, dst.
  final String programName; // ex: "IPA (Sains Murni) - Kerja"
  final String minatKey; // ex: "Kedokteran"
  final String questionText; // teks pertanyaan (tanpa [n])
  final String rawQuestionText; // teks asli (dengan [n])
  final int bobot; // ex: 6
  bool? userAnswer; // null=belum dijawab, true=Ya, false=Tidak

  QuestionItem({
    required this.id,
    required this.programName,
    required this.minatKey,
    required this.questionText,
    required this.rawQuestionText,
    required this.bobot,
    this.userAnswer,
  });
}

/// Fungsi ambil bobot [n] dari teks pertanyaan
int extractBobot(String pertanyaan) {
  final regex = RegExp(r"\[(\d+)\]");
  final match = regex.firstMatch(pertanyaan);
  if (match != null) {
    return int.parse(match.group(1)!);
  }
  return 0;
}

/// Fungsi buang [n] dari teks pertanyaan
String cleanPertanyaan(String pertanyaan) {
  return pertanyaan.replaceAll(RegExp(r"\[\d+\]"), "").trim();
}

/// Representasi rule IF-THEN sederhana
class Rule {
  final List<String> ifFacts;
  final void Function(Set<String> wm) thenAction;

  Rule({
    required this.ifFacts,
    required this.thenAction,
  });
}
