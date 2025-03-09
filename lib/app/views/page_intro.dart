import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:forward_chaining_man_app/app/views/page_login.dart';
import 'package:forward_chaining_man_app/app/views/splash_screen/page/page_splash_screen.dart';
import 'package:forward_chaining_man_app/app/views/teacher_page.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class IntroPage extends StatefulWidget {
  const IntroPage({Key? key}) : super(key: key);

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late AnimationController _networkController;
  int _currentPage = 0;

  // Network visualization data
  final List<NetworkNode> _nodes = [];
  final List<NetworkConnection> _connections = [];

  final List<Map<String, dynamic>> _onboardingPages = [
    {
      'title': 'Selamat Datang',
      'description':
          'Forward Chaining adalah aplikasi rekomendasi karir dan jurusan kuliah yang menggunakan sistem pakar berbasis aturan untuk memberikan hasil yang akurat.',
      'icon': Icons.psychology,
    },
    {
      'title': 'Cara Kerja Aplikasi',
      'description':
          'Aplikasi ini menggunakan metode Forward Chaining, yaitu teknik inferensi sistem pakar yang mengevaluasi fakta awal (jawaban Anda) dan mencocokkannya dengan aturan secara berurutan untuk mencapai kesimpulan terbaik.',
      'icon': Icons.sync_alt,
    },
    {
      'title': 'Alur Penggunaan',
      'description':
          'Anda akan menjawab pertanyaan seputar minat, bakat, dan kepribadian. Sistem kemudian menganalisis jawaban tersebut, menerapkan aturan Forward Chaining, dan menghasilkan rekomendasi karir atau jurusan kuliah yang paling sesuai.',
      'icon': Icons.question_answer,
    },
    {
      'title': 'Siap Memulai',
      'description':
          'Silakan pilih peran Anda sebagai Siswa untuk mendapatkan rekomendasi karir/kuliah atau sebagai Guru untuk memantau hasil rekomendasi siswa Anda.',
      'icon': Icons.rocket_launch,
    },
  ];

  @override
  void initState() {
    super.initState();

    // Create network nodes and connections
    _setupNetworkGraph();

    // Main controller for logo and elements animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Network animation controller
    _networkController = AnimationController(
      duration: const Duration(milliseconds: 15000),
      vsync: this,
    )..repeat();
  }

  // Setup network graph with nodes and connections
  void _setupNetworkGraph() {
    final random = math.Random(42); // Fixed seed for consistent layout

    // Create nodes - spreading them beyond screen boundaries
    for (int i = 0; i < 25; i++) {
      _nodes.add(
        NetworkNode(
          x: -0.3 + random.nextDouble() * 1.6,
          y: -0.3 + random.nextDouble() * 1.6,
          size: 3.0 + random.nextDouble() * 5.0,
        ),
      );
    }

    // Create connections between nodes
    for (int i = 0; i < _nodes.length; i++) {
      final connectionCount = 3 + random.nextInt(4);
      final connectedIndices = <int>{};

      for (int j = 0; j < connectionCount; j++) {
        int attempts = 0;
        while (attempts < 10) {
          final targetIndex = random.nextInt(_nodes.length);

          if (targetIndex != i && !connectedIndices.contains(targetIndex)) {
            connectedIndices.add(targetIndex);

            _connections.add(
              NetworkConnection(
                sourceIndex: i,
                targetIndex: targetIndex,
                pulseOffset: random.nextDouble(),
                pulseSpeed: 0.2 + random.nextDouble() * 0.3,
              ),
            );
            break;
          }
          attempts++;
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _networkController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
        child: Stack(
          children: [
            // Grid background pattern
            AnimatedBuilder(
              animation: _networkController,
              builder: (context, child) {
                return CustomPaint(
                  painter: GridPatternPainter(
                    progress: _networkController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            //
            // Subtle wave pattern in background
            AnimatedBuilder(
              animation: _networkController,
              builder: (context, child) {
                return CustomPaint(
                  painter: WavePatternPainter(
                    progress: _networkController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _onboardingPages.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return _buildPageContent(
                            index, screenHeight, screenWidth);
                      },
                    ),
                  ),

                  // Bottom navigation and indicators
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        // Page indicator dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              List.generate(_onboardingPages.length, (index) {
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 20),

                        // Next/Start button
                        _currentPage < _onboardingPages.length - 1
                            ? _buildButton(
                                label: 'Lanjut',
                                icon: Icons.arrow_forward,
                                onTap: _goToNextPage,
                              )
                            : _buildRoleSelectionSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(int index, double screenHeight, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // App Logo with Animation
          Hero(
            tag: 'app_logo',
            child: Container(
              width: 100,
              height: 100,
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated logo with glow
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animationController.value * 2 * math.pi,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Main icon with scale animation
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.9 +
                            0.1 *
                                math.sin(
                                    _animationController.value * 2 * math.pi),
                        child: Icon(
                          Icons.psychology,
                          size: 50,
                          color: Colors.indigo,
                        ),
                      );
                    },
                  ),

                  // Glowing effect
                  AnimatedBuilder(
                    animation: _networkController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: GlowingCirclePainter(
                          progress: _networkController.value,
                          color: Colors.blue.shade500,
                        ),
                        size: const Size(100, 100),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // App Title
          const Text(
            'EduGuide',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          // App Subtitle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Sistem Rekomendasi Karir & Kuliah',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 40),

          const SizedBox(height: 24),

          // Page Title
          Text(
            _onboardingPages[index]['title'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Page Description - Limited height and no scroll
          Container(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.15),
            child: Text(
              _onboardingPages[index]['description'],
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 5,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),

          // Visual content based on page
          SizedBox(
            height: screenHeight * 0.15,
            child: _buildPageVisualization(index),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade800,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 20),
        ],
      ),
    );
  }

  Widget _buildPageVisualization(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return _buildWelcomeVisualization();
      case 1:
        return _buildForwardChainingVisualization();
      case 2:
        return _buildWorkflowVisualization();
      case 3:
        return _buildGetStartedVisualization();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeVisualization() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: BrainNetworkPainter(
            animation: _animationController.value,
            color: Colors.white.withOpacity(0.6),
          ),
          size: const Size(300, 150),
        );
      },
    );
  }

  Widget _buildForwardChainingVisualization() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Animation cycle position (0-4)
        final cyclePosition = (_animationController.value * 4) % 4;
        final currentStep = cyclePosition.floor();
        final progress = cyclePosition - currentStep;

        // Define forward chaining steps
        final List<Map<String, dynamic>> steps = [
          {
            'icon': Icons.help_outline,
            'label': 'Input',
            'color': Colors.blue.shade400,
          },
          {
            'icon': Icons.psychology,
            'label': 'Proses',
            'color': Colors.purple.shade400,
          },
          {
            'icon': Icons.lightbulb_outline,
            'label': 'Analisis',
            'color': Colors.deepPurple.shade400,
          },
          {
            'icon': Icons.check_circle_outline,
            'label': 'Hasil',
            'color': Colors.green.shade400,
          },
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            return Container(
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  // Custom painted curved line
                  CustomPaint(
                    painter: CurvedWorkflowPainter(
                      progress: currentStep + progress,
                      maxProgress: steps.length - 1,
                      stepColors:
                          steps.map((s) => s['color'] as Color).toList(),
                    ),
                    size: Size(width, 100),
                  ),

                  // Step nodes
                  ...List.generate(4, (i) {
                    // Position calculation
                    final stepPosition =
                        width * 0.1 + (width * 0.8 * (i / (steps.length - 1)));

                    // Animation states
                    bool isActive = currentStep == i;
                    bool isPrevious = currentStep > i;
                    bool isNext = (currentStep + 1) % 4 == i;

                    double scale = 1.0;

                    if (isActive) {
                      scale = 1.0 + 0.1 * math.sin(progress * math.pi * 2);
                    } else if (isNext && progress > 0.5) {
                      scale = 0.8 +
                          (0.2 *
                              ((progress - 0.5) *
                                  2)); // Start scaling up at progress 0.5
                    } else {
                      scale = isPrevious ? 0.9 : 0.8;
                    }

                    Color nodeColor = isActive
                        ? steps[i]['color']
                        : isPrevious
                            ? steps[i]['color'].withOpacity(0.7)
                            : Colors.white.withOpacity(0.3);

                    // Calculate Y position with slight wave effect
                    final nodeY = i % 2 == 0 ? 10.0 : 40.0;

                    return Positioned(
                      top: nodeY,
                      left: stepPosition - 20, // Center node on position
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: nodeColor,
                                  width: 2,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: steps[i]['color']
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Icon(
                                  steps[i]['icon'],
                                  color: isActive || isPrevious
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            steps[i]['label'],
                            style: TextStyle(
                              color: isActive || isPrevious
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Animated pulse point on the curve
                  if (progress > 0 && progress < 1 && currentStep < 3)
                    AnimatedPulsePoint(
                      progress: currentStep + progress,
                      maxProgress: steps.length - 1,
                      width: width,
                      color: steps[(currentStep + 1) % 4]['color'],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// WORKFLOW VISUALIZATION - Untuk halaman "Alur Penggunaan"
  Widget _buildWorkflowVisualization() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Animation cycle position (0-4)
        final cyclePosition = (_animationController.value * 4) % 4;
        final currentStep = cyclePosition.floor();
        final progress = cyclePosition - currentStep;

        // Define workflow steps
        final List<Map<String, dynamic>> steps = [
          {
            'icon': Icons.question_answer_outlined,
            'label': 'Jawab',
            'color': Colors.orange.shade400,
          },
          {
            'icon': Icons.psychology,
            'label': 'Proses',
            'color': Colors.blue.shade400,
          },
          {
            'icon': Icons.integration_instructions_outlined,
            'label': 'Analisis',
            'color': Colors.purple.shade400,
          },
          {
            'icon': Icons.emoji_events_outlined,
            'label': 'Hasil',
            'color': Colors.green.shade400,
          },
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            return Container(
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  // Custom painted curved line
                  CustomPaint(
                    painter: CurvedWorkflowPainter(
                      progress: currentStep + progress,
                      maxProgress: steps.length - 1,
                      stepColors:
                          steps.map((s) => s['color'] as Color).toList(),
                    ),
                    size: Size(width, 100),
                  ),

                  // Step nodes
                  ...List.generate(4, (i) {
                    // Position calculation
                    final stepPosition =
                        width * 0.1 + (width * 0.8 * (i / (steps.length - 1)));

                    // Animation states
                    bool isActive = currentStep == i;
                    bool isPrevious = currentStep > i;
                    bool isNext = (currentStep + 1) % 4 == i;

                    double scale = 1.0;

                    if (isActive) {
                      scale = 1.0 + 0.1 * math.sin(progress * math.pi * 2);
                    } else if (isNext && progress > 0.5) {
                      scale = 0.8 +
                          (0.2 *
                              ((progress - 0.5) *
                                  2)); // Start scaling up at progress 0.5
                    } else {
                      scale = isPrevious ? 0.9 : 0.8;
                    }

                    Color nodeColor = isActive
                        ? steps[i]['color']
                        : isPrevious
                            ? steps[i]['color'].withOpacity(0.7)
                            : Colors.white.withOpacity(0.3);

                    // Calculate Y position with slight wave effect
                    final nodeY = i % 2 == 0 ? 10.0 : 40.0;

                    return Positioned(
                      top: nodeY,
                      left: stepPosition - 20, // Center node on position
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: nodeColor,
                                  width: 2,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: steps[i]['color']
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Icon(
                                  steps[i]['icon'],
                                  color: isActive || isPrevious
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            steps[i]['label'],
                            style: TextStyle(
                              color: isActive || isPrevious
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Animated pulse point on the curve
                  if (progress > 0 && progress < 1 && currentStep < 3)
                    AnimatedPulsePoint(
                      progress: currentStep + progress,
                      maxProgress: steps.length - 1,
                      width: width,
                      color: steps[(currentStep + 1) % 4]['color'],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStepBox(String text, IconData icon, double delay) {
    final animValue = (_animationController.value + delay) % 1.0;
    final pulseScale = 0.9 + 0.1 * math.sin(animValue * 2 * math.pi);

    return Container(
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.all(3),
      width: 85,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Transform.scale(
            scale: pulseScale,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedVisualization() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animValue = _animationController.value;

        return Container(
          height: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAnimatedRoleCard(
                title: 'Siswa',
                icon: Icons.school,
                color: Colors.blue.shade500,
                offset: 0,
              ),
              const SizedBox(width: 40),
              _buildAnimatedRoleCard(
                title: 'Guru',
                icon: Icons.person_pin,
                color: Colors.purple.shade500,
                offset: 0.5,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedRoleCard({
    required String title,
    required IconData icon,
    required Color color,
    required double offset,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animValue = (_animationController.value + offset) % 1.0;
        final scale = 0.9 + 0.1 * math.sin(animValue * 2 * math.pi);
        final bounce = math.sin(animValue * 2 * math.pi) * 5;

        return Transform.translate(
          offset: Offset(0, bounce),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleIcon(IconData icon, String label, double delay) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animValue = (_animationController.value + delay) % 1.0;
        final scale = 0.9 + 0.1 * math.sin(animValue * 2 * math.pi);

        return Column(
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoleSelectionSection() {
    return Column(
      children: [
        // Student Role Button
        _buildRoleButton(
          title: 'Siswa',
          subtitle: 'Dapatkan rekomendasi karir dan kuliah',
          icon: Icons.school,
          color: Colors.blue.shade600,
          onTap: () {
            _saveRole('student');
            Get.to(
              () => StudentLoginPage(),
              transition: Transition.rightToLeft,
              duration: const Duration(milliseconds: 400),
            );
          },
        ),

        const SizedBox(height: 16),

        // Teacher Role Button
        _buildRoleButton(
          title: 'Guru',
          subtitle: 'Kelola data dan pantau perkembangan siswa',
          icon: Icons.person_pin,
          color: Colors.deepPurple,
          onTap: () {
            _saveRole('teacher');
            Get.to(
              () => const TeacherLoginPage(),
              transition: Transition.rightToLeft,
              duration: const Duration(milliseconds: 400),
            );
          },
        ),
      ],
    );
  }

  // Helper method to save user role preference
  Future<void> _saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  // Helper method to build role selection button
  Widget _buildRoleButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: Colors.blue.shade600,
                size: 28,
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
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class WorkflowPathPainter extends CustomPainter {
  final double progress;
  final int currentStep;
  final List<Color> stepColors;

  WorkflowPathPainter({
    required this.progress,
    required this.currentStep,
    required this.stepColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pathPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint activePaint = Paint()
      ..color = stepColors[currentStep]
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // We'll draw a curved path connecting all points
    final Path path = Path();

    // Calculate arc path
    final width = size.width;
    final height = size.height * 0.5;
    final centerY = size.height * 0.5;

    // Start at left
    path.moveTo(width * 0.25, centerY);

    // Draw curve through points
    path.cubicTo(
      width * 0.4, centerY - height, // control point 1
      width * 0.6, centerY + height, // control point 2
      width * 0.75, centerY, // end point
    );

    // Draw the inactive path
    canvas.drawPath(path, pathPaint);

    // Draw the active progress path
    if (currentStep < 3) {
      // Determine path metrics for precise length calculations
      PathMetrics metrics = path.computeMetrics();
      PathMetric pathMetric = metrics.first;

      // Calculate the percentage of path to draw based on current step and progress
      double totalPathPercent = (currentStep + progress) / 3;

      // Extract the portion of the path that should be drawn
      Path extractPath = Path();
      extractPath.addPath(
        pathMetric.extractPath(0, pathMetric.length * totalPathPercent),
        Offset.zero,
      );

      // Draw the active portion of the path
      canvas.drawPath(extractPath, activePaint);

      // Add animated dots/pulse
      if (progress > 0 && progress < 1) {
        // Calculate the exact position for the animating dot
        double animatingPointPercent = (currentStep + progress) / 3;
        Tangent? tangent = pathMetric
            .getTangentForOffset(pathMetric.length * animatingPointPercent);

        if (tangent != null) {
          // Draw pulsing dot at the current animation point
          canvas.drawCircle(
              tangent.position,
              4 + 2 * math.sin(progress * math.pi), // Pulse effect
              Paint()..color = stepColors[(currentStep + 1) % 4]);
        }
      }
    } else {
      // If we're at the last step, animate the whole path
      canvas.drawPath(path, activePaint);
    }
  }

  @override
  bool shouldRepaint(WorkflowPathPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.currentStep != currentStep;
  }
}

// Node in the network
class NetworkNode {
  final double x; // Position (0-1)
  final double y;
  final double size;

  NetworkNode({
    required this.x,
    required this.y,
    required this.size,
  });
}

// Connection between nodes
class NetworkConnection {
  final int sourceIndex;
  final int targetIndex;
  final double pulseOffset; // Random offset for animation
  final double pulseSpeed; // Speed of pulse animation

  NetworkConnection({
    required this.sourceIndex,
    required this.targetIndex,
    required this.pulseOffset,
    required this.pulseSpeed,
  });
}

// Neural network visualization
class NetworkPainter extends CustomPainter {
  final double progress;
  final List<NetworkNode> nodes;
  final List<NetworkConnection> connections;

  NetworkPainter({
    required this.progress,
    required this.nodes,
    required this.connections,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw connections first (lines between nodes)
    for (final connection in connections) {
      final source = nodes[connection.sourceIndex];
      final target = nodes[connection.targetIndex];

      final sourcePos = Offset(source.x * size.width, source.y * size.height);
      final targetPos = Offset(target.x * size.width, target.y * size.height);

      // Calculate distance for line dashing
      final dx = targetPos.dx - sourcePos.dx;
      final dy = targetPos.dy - sourcePos.dy;
      final distance = math.sqrt(dx * dx + dy * dy);

      // Create a normalized direction vector
      final dirX = dx / distance;
      final dirY = dy / distance;

      // Calculate pulse position based on progress
      final pulseProgress =
          (progress * connection.pulseSpeed + connection.pulseOffset) % 1.0;
      final pulsePos = Offset(
        sourcePos.dx + dx * pulseProgress,
        sourcePos.dy + dy * pulseProgress,
      );

      // Draw the connection line
      final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawLine(sourcePos, targetPos, linePaint);

      // Draw pulse traveling along the connection
      final pulsePaint = Paint()
        ..color = Colors.blue.shade100.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pulsePos, 1.5, pulsePaint);

      // Add a subtle glow around the pulse
      final glowPaint = Paint()
        ..color = Colors.blue.shade100.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pulsePos, 5.0, glowPaint);
    }

    // Draw nodes
    for (final node in nodes) {
      final nodePos = Offset(node.x * size.width, node.y * size.height);

      // Node glow (outer circle)
      final glowPaint = Paint()
        ..color = Colors.blue.shade200.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(nodePos, node.size * 3.8, glowPaint);

      // Node main circle
      final nodePaint = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(nodePos, node.size, nodePaint);

      // Node inner circle
      final innerPaint = Paint()
        ..color = Colors.blue.shade100
        ..style = PaintingStyle.fill;

      canvas.drawCircle(nodePos, node.size * 0.6, innerPaint);
    }
  }

  @override
  bool shouldRepaint(NetworkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Glowing circle around the icon
class GlowingCirclePainter extends CustomPainter {
  final double progress;
  final Color color;

  GlowingCirclePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Pulsing circular glow - very subtle
    final double pulseSize = 1.0 + math.sin(progress * math.pi) * 0.08;

    // Draw multiple circles with diminishing opacity
    for (int i = 0; i < 3; i++) {
      final paint = Paint()
        ..color = color.withOpacity(0.2 - (i * 0.05))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 - (i * 0.5);

      // Each circle is larger than the previous
      canvas.drawCircle(
        center,
        (40 + i * 5) * pulseSize,
        paint,
      );
    }

    // Draw spinning arc - very slow
    final spinnerPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Rotation angle changes very slowly with progress
    final startAngle = progress * math.pi;
    const arcLength = math.pi * 1.2; // Longer arc

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 45),
      startAngle,
      arcLength,
      false,
      spinnerPaint,
    );

    // Second arc in opposite direction - even slower
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 35),
      -startAngle * 0.7,
      -arcLength * 0.8,
      false,
      spinnerPaint..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(GlowingCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// Custom painter for brain network visualization
class BrainNetworkPainter extends CustomPainter {
  final double animation;
  final Color color;

  BrainNetworkPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Create nodes
    final nodes = <Offset>[];
    final random = math.Random(42); // Fixed seed for consistent points
    for (int i = 0; i < 7; i++) {
      nodes.add(Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      ));
    }

    // Draw connections between nodes
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final distance = (nodes[i] - nodes[j]).distance;
        if (distance < size.width * 0.4) {
          // Only connect nearby nodes
          final path = Path()
            ..moveTo(nodes[i].dx, nodes[i].dy)
            ..lineTo(nodes[j].dx, nodes[j].dy);

          canvas.drawPath(path, paint);

          // Draw pulse along the line
          final progress = (animation + i * 0.1) % 1.0;
          final pointOffset = Offset.lerp(nodes[i], nodes[j], progress)!;
          canvas.drawCircle(pointOffset, 2.5, dotPaint);
        }
      }
    }

    // Draw nodes
    for (final node in nodes) {
      final animatedRadius =
          3.0 + 1.5 * math.sin(animation * 2 * math.pi + nodes.indexOf(node));
      canvas.drawCircle(node, animatedRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BrainNetworkPainter oldDelegate) {
    return true;
  }
}

class CurvedWorkflowPainter extends CustomPainter {
  final double progress;
  final double maxProgress;
  final List<Color> stepColors;

  CurvedWorkflowPainter({
    required this.progress,
    required this.maxProgress,
    required this.stepColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Create base path for the full curve
    final path = Path();
    path.moveTo(
        width * 0.1, height * 0.25); // Start at 10% from left, at 25% height

    // Control points for the curve
    List<Offset> points = [];

    // Calculate points for the S curve
    for (int i = 0; i < 4; i++) {
      final x = width * 0.1 + (width * 0.8 * (i / (maxProgress)));
      final y =
          i % 2 == 0 ? height * 0.25 : height * 0.55; // Alternate Y positions
      points.add(Offset(x, y));
    }

    // Draw curved path through points
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      // Middle point for control
      final midX = (current.dx + next.dx) / 2;

      // Add curve segment
      if (i == 0) {
        path.quadraticBezierTo(
          midX, current.dy, // Control point
          next.dx, next.dy, // End point
        );
      } else if (i == points.length - 2) {
        path.quadraticBezierTo(
          midX, current.dy, // Control point
          next.dx, next.dy, // End point
        );
      } else {
        path.cubicTo(
          midX, current.dy, // First control point
          midX, next.dy, // Second control point
          next.dx, next.dy, // End point
        );
      }
    }

    // Draw inactive path
    final inactivePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, inactivePaint);

    // Draw active progress path
    if (progress > 0) {
      // Calculate total length
      final PathMetrics pathMetrics = path.computeMetrics();
      final PathMetric pathMetric = pathMetrics.first;

      // Extract the active portion of the path
      final double pathLength = pathMetric.length;
      final double activePortion = (progress / maxProgress) * pathLength;

      final Path activePath = Path();
      activePath.addPath(
        pathMetric.extractPath(0, activePortion),
        Offset.zero,
      );

      // Create gradient for active path
      final activeGradient = LinearGradient(
        colors: [
          stepColors[0],
          stepColors[math.min(progress.floor(), stepColors.length - 1)],
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

      final activePaint = Paint()
        ..shader = activeGradient
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(activePath, activePaint);
    }
  }

  @override
  bool shouldRepaint(CurvedWorkflowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Animated pulse point that follows the curve
class AnimatedPulsePoint extends StatelessWidget {
  final double progress;
  final double maxProgress;
  final double width;
  final Color color;

  const AnimatedPulsePoint({
    required this.progress,
    required this.maxProgress,
    required this.width,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate position along the curve
    final double x = width * 0.1 + (width * 0.8 * (progress / maxProgress));

    // Calculate y position (alternating wave)
    final int floorPos = progress.floor();
    final double fraction = progress - floorPos;

    double y;
    if (floorPos % 2 == 0) {
      // Moving from top to bottom
      y = 30.0 + (40.0 * fraction);
    } else {
      // Moving from bottom to top
      y = 70.0 - (40.0 * fraction);
    }

    return Positioned(
      left: x - 4,
      top: y - 4,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
