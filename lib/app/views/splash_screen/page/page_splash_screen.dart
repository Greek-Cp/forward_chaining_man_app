// SplashScreen - Halaman pertama yang muncul dengan animasi dan cek sesi
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:forward_chaining_man_app/app/views/page_intro.dart';
import 'package:forward_chaining_man_app/app/views/student/page_student_dashboard.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _networkController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _translateAnimation;

  // List of network nodes for neural network visualization
  final List<NetworkNode> _nodes = [];
  final List<NetworkConnection> _connections = [];

  @override
  void initState() {
    super.initState();

    // Create network nodes and connections
    _setupNetworkGraph();

    // Main controller for logo animations - 3 seconds
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Separate slow controller for network animations - 15 seconds and repeat
    _networkController = AnimationController(
      duration: const Duration(milliseconds: 15000),
      vsync: this,
    );

    // Fade in animation for text
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
    ));

    // Scale animation for logo - starts very small
    _scaleAnimation = Tween<double>(
      begin: 0.1,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
    ));

    // Translation animation - starts way below screen
    _translateAnimation = Tween<double>(
      begin: 300.0, // Start far below center
      end: 0.0, // End at center
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
    ));

    // Start animations
    _mainController.forward();
    _networkController.repeat(); // Continuous very slow animation for network

    // Check user session after animation completes
    Future.delayed(const Duration(milliseconds: 3500), () {
      checkExistingSession();
    });
  }

  // Setup network graph with nodes and connections
  void _setupNetworkGraph() {
    final random = math.Random(42); // Fixed seed for consistent layout

    // Create nodes - spreading them beyond screen boundaries
    for (int i = 0; i < 25; i++) {
      // Increased number of nodes
      _nodes.add(
        NetworkNode(
          x: -0.3 +
              random.nextDouble() *
                  1.6, // Expand beyond screen boundaries (-0.3 to 1.3)
          y: -0.3 + random.nextDouble() * 1.6,
          size: 3.0 + random.nextDouble() * 5.0, // Slightly larger nodes
        ),
      );
    }

    // Create connections between nodes - increased connections
    for (int i = 0; i < _nodes.length; i++) {
      // Each node connects to 3-6 other nodes
      final connectionCount = 3 + random.nextInt(4);
      final connectedIndices = <int>{};

      for (int j = 0; j < connectionCount; j++) {
        // Try to find a new node to connect to
        int attempts = 0;
        while (attempts < 10) {
          final targetIndex = random.nextInt(_nodes.length);

          // Don't connect to self and don't duplicate connections
          if (targetIndex != i && !connectedIndices.contains(targetIndex)) {
            connectedIndices.add(targetIndex);

            // Add the connection
            _connections.add(
              NetworkConnection(
                sourceIndex: i,
                targetIndex: targetIndex,
                pulseOffset: random.nextDouble(),
                pulseSpeed:
                    0.2 + random.nextDouble() * 0.3, // Slightly slower pulse
              ),
            );
            break;
          }
          attempts++;
        }
      }
    }
  }

  Future<void> checkExistingSession() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Check if user data exists in Firestore
        final docSnapshot =
            await _firestore.collection('students').doc(currentUser.uid).get();
        if (docSnapshot.exists) {
          // Navigate to dashboard
          Get.offAll(() => const PageStudentDashboard());
        } else {
          // User authenticated but no profile
          Get.offAll(() => const IntroPage());
        }
      } else {
        // User not logged in, go to intro
        Get.offAll(() => const IntroPage());
      }
    } catch (e) {
      print('Error checking session: $e');
      // If error, go to intro
      Get.offAll(() => const IntroPage());
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _networkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Beautiful gradient background
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

            // Neural network background - using CustomPaint for better performance
            AnimatedBuilder(
              animation: _networkController,
              builder: (context, child) {
                return CustomPaint(
                  painter: NetworkPainter(
                    progress: _networkController.value,
                    nodes: _nodes,
                    connections: _connections,
                  ),
                  size: Size.infinite,
                );
              },
            ),

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

            // Main content - centered column
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animation from bottom to center with scaling
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _translateAnimation.value),
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade700.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Brain icon with glow effect
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Icon(
                              Icons.psychology,
                              size: 95,
                              color: Colors.blue.shade700,
                            ),
                            // Animated glow around the icon
                            AnimatedBuilder(
                              animation: _networkController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: GlowingCirclePainter(
                                    progress: _networkController.value,
                                    color: Colors.blue.shade500,
                                  ),
                                  size: const Size(120, 120),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App title with fade animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Forward Chaining',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtitle with fade animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Rekomendasi Minat Bakat Anda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Loading indicator with delayed fade
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _mainController.value > 0.5
                            ? (_mainController.value - 0.5) * 2
                            : 0,
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.9)),
                        strokeWidth: 3,
                      ),
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

      canvas.drawCircle(pulsePos, 2.5, pulsePaint);

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

      canvas.drawCircle(nodePos, node.size * 1.8, glowPaint);

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
        (50 + i * 5) * pulseSize,
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
      Rect.fromCircle(center: center, radius: 55),
      startAngle,
      arcLength,
      false,
      spinnerPaint,
    );

    // Second arc in opposite direction - even slower
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 45),
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

// Subtle wave pattern in background
class WavePatternPainter extends CustomPainter {
  final double progress;

  WavePatternPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Very subtle horizontal waves
    final wavePaint = Paint()
      ..color = Colors.blue.shade200.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const waveCount = 4;
    final waveHeight = size.height / waveCount;

    for (int i = 0; i < waveCount; i++) {
      final path = Path();
      final baseY = i * waveHeight;
      final amplitude = 8.0; // Reduced wave height

      path.moveTo(0, baseY);

      // Draw a smooth sine wave across the screen - very slow movement
      for (double x = 0; x <= size.width; x += 10) {
        // Very slow wave movement (reduced multiplier from 0.5 to 0.2)
        final waveY = baseY +
            math.sin((x / size.width * 4) + progress * math.pi * 0.2) *
                amplitude;
        path.lineTo(x, waveY);
      }

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(WavePatternPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Grid background pattern
class GridPatternPainter extends CustomPainter {
  final double progress;

  GridPatternPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Create animated grid pattern
    final spacing = 35.0;
    final xCount = (size.width / spacing).ceil() + 1;
    final yCount = (size.height / spacing).ceil() + 1;
    final offset = progress * spacing * 0.5; // Slow movement

    // Horizontal lines
    for (int i = 0; i < yCount; i++) {
      final y = i * spacing - offset;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines
    for (int i = 0; i < xCount; i++) {
      final x = i * spacing - offset;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Add some diagonal lines for more depth
    final diagonalPaint = Paint()
      ..color = Colors.blue.shade100.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    final maxDim = math.max(size.width, size.height);
    final diagonalSpacing = 70.0;
    final diagCount = (maxDim / diagonalSpacing).ceil() * 2;
    final diagOffset = progress * diagonalSpacing * 0.3; // Very slow movement

    for (int i = -diagCount; i < diagCount; i++) {
      final startX = i * diagonalSpacing + diagOffset;
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + maxDim, maxDim),
        diagonalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPatternPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
