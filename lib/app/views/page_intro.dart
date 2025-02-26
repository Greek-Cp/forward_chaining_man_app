import 'package:flutter/material.dart';
import 'package:forward_chaining_man_app/app/views/page_login.dart';
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

class _IntroPageState extends State<IntroPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  int _currentPage = 0;

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
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
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
        child: SafeArea(
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
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: screenHeight * 0.05),

                            // App Logo with Hero animation
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
                                child: _buildAnimatedLogo(),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // App Title
                            const Text(
                              'Forward Chaining',
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
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

                            SizedBox(height: screenHeight * 0.05),

                            // Onboarding page content
                            Column(
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _onboardingPages[index]['icon'],
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Title
                                Text(
                                  _onboardingPages[index]['title'],
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Description
                                Text(
                                  _onboardingPages[index]['description'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: screenHeight * 0.05),

                            // Visual content based on page
                            SizedBox(
                              height: screenHeight * 0.2,
                              child: _buildPageVisualization(index),
                            ),

                            SizedBox(height: screenHeight * 0.03),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Page indicator and navigation
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    // Page indicator dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_onboardingPages.length, (index) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    // Next/Start button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _currentPage < _onboardingPages.length - 1
                          ? _buildButton(
                              label: 'Lanjut',
                              icon: Icons.arrow_forward,
                              onTap: _goToNextPage,
                            )
                          : _buildRoleSelectionSection(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Rotating ring
            Transform.rotate(
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
            ),

            // Main icon
            Transform.scale(
              scale: 0.9 +
                  0.1 * math.sin(_animationController.value * 2 * math.pi),
              child: const Icon(
                Icons.psychology,
                size: 50,
                color: Colors.indigo,
              ),
            ),
          ],
        );
      },
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
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final delay = index * 0.2;
            final animValue = (_animationController.value + delay) % 1.0;
            final isActive = animValue > 0.3 && animValue < 0.7;

            return Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.deepPurple.withOpacity(0.6)
                        : Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    index == 0
                        ? Icons.question_mark
                        : index == 1
                            ? Icons.rule
                            : index == 2
                                ? Icons.compare_arrows
                                : Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (index < 3)
                  Container(
                    width: 30,
                    height: 2,
                    color: isActive
                        ? Colors.white.withOpacity(0.8)
                        : Colors.white.withOpacity(0.2),
                  ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildWorkflowVisualization() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepBox('Pertanyaan', Icons.help_outline, 0),
                const Icon(Icons.arrow_forward, color: Colors.white),
                _buildStepBox('Jawaban', Icons.chat_bubble_outline, 0.2),
              ],
            ),
            const Icon(Icons.arrow_downward, color: Colors.white),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepBox('Rekomendasi', Icons.lightbulb_outline, 0.4),
                const Icon(Icons.arrow_forward, color: Colors.white),
                _buildStepBox('Analisis', Icons.analytics_outlined, 0.6),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepBox(String text, IconData icon, double delay) {
    final animValue = (_animationController.value + delay) % 1.0;
    final pulseScale = 0.9 + 0.1 * math.sin(animValue * 2 * math.pi);

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(4),
      width: 100,
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
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedVisualization() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildRoleIcon(Icons.school, 'Siswa', 0),
        const SizedBox(width: 60),
        _buildRoleIcon(Icons.person_pin, 'Guru', 0.5),
      ],
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
                  size: 40,
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
              () => const StudentLoginPage(),
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
        padding: const EdgeInsets.all(20),
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
              width: 50,
              height: 50,
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
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
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
