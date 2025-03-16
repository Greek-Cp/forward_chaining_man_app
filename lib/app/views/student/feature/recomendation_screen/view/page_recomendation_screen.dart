import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'package:flutter/services.dart';
import 'package:forward_chaining_man_app/app/views/about/page_about.dart';
import 'package:forward_chaining_man_app/app/views/page_intro.dart';
import 'package:forward_chaining_man_app/app/views/page_login.dart';
import 'package:forward_chaining_man_app/app/views/page_profile.dart';
import 'package:forward_chaining_man_app/app/views/splash_screen/page/page_splash_screen.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/recomendation_screen/page_cetak_sertifikat.dart';
import 'package:forward_chaining_man_app/app/views/student/model/data_student.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart' as intl;

import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';

class RecommendationResultsScreen extends StatefulWidget {
  final RecommendationResult result;
  final String rawMessage;

  const RecommendationResultsScreen({
    required this.result,
    this.rawMessage = '',
    Key? key,
  }) : super(key: key);

  @override
  State<RecommendationResultsScreen> createState() =>
      _RecommendationResultsScreenState();
}

class _RecommendationResultsScreenState
    extends State<RecommendationResultsScreen> with TickerProviderStateMixin {
  // Controller untuk berbagai animasi
  late AnimationController _swipeController;
  late AnimationController _swipePromptController;
  late AnimationController _introController;
  late AnimationController _cardController;
  late AnimationController _confettiController;
  late List<AnimationController> _itemControllers;
  late AnimationController _networkController;
  // Animasi
  late Animation<double> _swipeAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // State untuk tracking progres interaksi
  bool _hasRevealed = false;
  bool _hasConfetti = false;
  double _swipeProgress = 0.0;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  // Warna untuk peringkat
  final Color _goldColor = const Color.fromARGB(255, 29, 255, 120);
  final Color _silverColor = const Color(0xFFC0C0C0);
  final Color _bronzeColor = const Color(0xFFCD7F32);

  // Emoji untuk setiap peringkat
  final List<String> _rankEmojis = ['🏆', '🥈', '🥉'];

  // Gradient warna
  final List<Color> _gradientColors = [
    Colors.blue.shade800,
    Colors.indigo.shade900,
  ];

  @override
  void initState() {
    super.initState();

    // Separate slow controller for network animations - 15 seconds and repeat
    _networkController = AnimationController(
      duration: const Duration(milliseconds: 15000),
      vsync: this,
    );

    // Inisialisasi controller animasi
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controller khusus untuk animasi prompt swipe
    _swipePromptController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _introController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..forward();

    _cardController = AnimationController(
      duration: const Duration(
          milliseconds: 1200), // Lebih lama untuk efek lebih halus
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(
          milliseconds: 4000), // Lebih lama untuk efek lebih lengkap
      vsync: this,
    );

    // Inisialisasi controller untuk setiap rekomendasi
    _itemControllers = List.generate(
      math.min(3, widget.result.recommendations.length),
      (index) => AnimationController(
        duration: Duration(
            milliseconds:
                800 + (index * 300)), // Lebih lama untuk efek yang lebih jelas
        vsync: this,
      ),
    );

    // Animasi swipe
    _swipeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _swipeController,
        curve: Curves.easeOutBack,
      ),
    );

    // Animasi fade
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Animasi scale
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _swipePromptController.dispose();
    _introController.dispose();
    _cardController.dispose();
    _confettiController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onSwipeComplete() {
    setState(() {
      _hasRevealed = true;
    });
    _cardController.forward();

    // Mulai animasi confetti setelah kartu muncul
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _hasConfetti = true;
        });
        _confettiController.forward();
      }
    });

    // Animasikan item rekomendasi secara berurutan dengan jeda yang lebih pendek
    for (int i = 0; i < _itemControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 150 + (i * 200)), () {
        if (mounted) {
          _itemControllers[i].forward();
        }
      });
    }
  }

// Color helpers for medal colors
  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return Color.fromARGB(255, 0, 255, 140); // Gold
      case 1:
        return Color.fromARGB(255, 238, 213, 73); // Silver
      case 2:
        return Color.fromARGB(255, 255, 75, 39); // Bronze
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

  IconData _getMedalIcon(int index) {
    return Icons.workspace_premium;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors,
          ),
        ),
        child: Stack(
          children: [
            if (_hasRevealed)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: SafeArea(child: _buildPageIndicator()),
              ),

            // Header

            // Konten utama (berbeda berdasarkan status revealed)
            _hasRevealed
                ? SafeArea(
                    child: _buildRevealedContent(),
                    bottom: false,
                    left: false,
                  )
                : _buildInitialContent(),

            // Partikel confetti (hanya muncul setelah swipe)
            if (_hasConfetti) _buildConfetti(),
            // Indikator halaman
          ],
        ),
      ),
    );
  }

  Widget _buildInitialContent() {
    return GestureDetector(
      // Deteksi swipe gesture untuk interaksi yang lebih baik
      onVerticalDragUpdate: (details) {
        if (!_hasRevealed) {
          setState(() {
            // Hitung kemajuan swipe berdasarkan jarak
            _swipeProgress -= details.primaryDelta! / 200.0;
            _swipeProgress = _swipeProgress.clamp(0.0, 1.0);

            // Update controller animasi swipe berdasarkan kemajuan
            _swipeController.value = _swipeProgress;
          });

          // Jika swipe hampir selesai, otomatis selesaikan
          if (_swipeProgress > 0.7 && !_hasRevealed) {
            _swipeController
                .forward(from: _swipeController.value)
                .then((_) => _onSwipeComplete());
          }
        }
      },
      onVerticalDragEnd: (details) {
        if (!_hasRevealed) {
          if (_swipeProgress > 0.3) {
            // Jika swipe sudah cukup jauh, selesaikan
            _swipeController
                .forward(from: _swipeController.value)
                .then((_) => _onSwipeComplete());
          } else {
            // Jika belum cukup jauh, kembalikan
            _swipeController.reverse(from: _swipeController.value);
            setState(() {
              _swipeProgress = 0.0;
            });
          }
        }
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Panel animasi untuk feedback visual saat swipe
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _swipeController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                          0,
                          -MediaQuery.of(context).size.height *
                              _swipeController.value),
                      child: Container(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    );
                  },
                ),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon panah animasi dengan efek lebih menonjol
                    AnimatedBuilder(
                      animation: _swipePromptController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            0,
                            -20 * _swipePromptController.value,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(
                                      0.2 * _swipePromptController.value),
                                  blurRadius: 20 * _swipePromptController.value,
                                  spreadRadius:
                                      5 * _swipePromptController.value,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: Colors.white,
                              size: 60 + (10 * _swipePromptController.value),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [Colors.white, Colors.white.withOpacity(0.8)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds);
                      },
                      child: const Text(
                        'Swipe Ke Atas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Untuk Melihat Hasil Rekomendasimu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Animated hand icon
                    AnimatedBuilder(
                      animation: _swipePromptController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            0,
                            -10 *
                                math.sin(
                                    _swipePromptController.value * math.pi),
                          ),
                          child: Opacity(
                            opacity: 0.5 +
                                (0.5 *
                                    math.sin(_swipePromptController.value *
                                        math.pi)),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.touch_app,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        );
                      },
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

  Widget _buildRevealedContent() {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            (1 - _cardController.value) *
                MediaQuery.of(context).size.height *
                0.5,
          ),
          child: Opacity(
            opacity: _cardController.value,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildRecommendationPage(),
                _buildDetailPage(),
                _buildExplanationPage(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationPage() {
    final recommendations = widget.result.recommendations;
    final topRecommendations = recommendations.length > 3
        ? recommendations.sublist(0, 3)
        : recommendations;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Hasil Rekomendasimu! 🎉',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _cardController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _cardController.value * math.pi * 2,
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.yellow,
                        size: 32,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Berdasarkan jawabanmu di kuesioner, kami menemukan minat yang paling cocok untukmu',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // Top 3 Recommendations in a Row
// Top 3 Recommendations in a Row
            // Top 3 Recommendations in a Row (fully responsive)
            Container(
              margin: EdgeInsets.only(bottom: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: List.generate(
                    math.min(3, topRecommendations.length),
                    (index) {
                      final recommendation = topRecommendations[index];
                      final parts = recommendation.title.split('|');
                      final minatName = parts.length > 1 ? parts[1] : parts[0];
                      final programName = parts[0];

                      // Get medal color
                      final Color medalColor = _getMedalColor(index);

                      // Warna aksen untuk variasi
                      final Color accentColor = index == 0
                          ? Color.fromARGB(255, 108, 247, 84) // Gold accent
                          : index == 1
                              ? Color.fromARGB(
                                  255, 225, 193, 75) // Silver accent
                              : Color(0xFFE59866); // Bronze accent

                      return AnimatedBuilder(
                        animation: _itemControllers[index],
                        builder: (context, child) {
                          final progress = math.min(1.0,
                              math.max(0.0, _itemControllers[index].value));
                          final scale = 0.8 + (0.2 * progress);

                          return Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: progress,
                              child: Container(
                                width: 220,
                                height:
                                    450, // Fix height here - all cards will have the same height
                                margin: EdgeInsets.only(
                                    right: 16, top: 4, bottom: 4),
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) =>
                                          _buildDetailBottomSheet(
                                              recommendation, index),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      // Main card with gradient border
                                      Card(
                                        elevation: 8,
                                        shadowColor:
                                            medalColor.withOpacity(0.6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Container(
                                          height:
                                              450, // Fix height here too for consistency
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white,
                                                Colors.white,
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    medalColor.withOpacity(0.3),
                                                spreadRadius: 0,
                                                blurRadius: 15,
                                                offset: Offset(0, 8),
                                              )
                                            ],
                                            border: Border.all(
                                              width: 2,
                                              color: medalColor,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Stack(
                                              children: [
                                                // Animated background patterns
                                                Positioned.fill(
                                                  child: CustomPaint(
                                                    painter:
                                                        AnimatedBackgroundPainter(
                                                      color: medalColor,
                                                      accentColor: accentColor,
                                                      animationValue:
                                                          _itemControllers[
                                                                  index]
                                                              .value,
                                                    ),
                                                  ),
                                                ),

                                                // Blurred overlay for better readability
                                                Positioned.fill(
                                                  child: BackdropFilter(
                                                    filter: ImageFilter.blur(
                                                        sigmaX: 10, sigmaY: 10),
                                                    child: Container(
                                                      color: Colors.white
                                                          .withOpacity(0.8),
                                                    ),
                                                  ),
                                                ),

                                                // Medal icon
                                                Positioned(
                                                  top: -5,
                                                  left: -5,
                                                  child: Container(
                                                    height: 60,
                                                    width: 60,
                                                    child: CustomPaint(
                                                      painter:
                                                          MedalBadgePainter(
                                                        color: medalColor,
                                                        accentColor:
                                                            accentColor,
                                                        emoji: _getMedalEmoji(
                                                            index),
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // Content - made consistent for all cards
                                                Container(
                                                  padding: EdgeInsets.fromLTRB(
                                                      16, 30, 16, 16),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      // Top section
                                                      Column(
                                                        children: [
                                                          // Medal banner with shimmer effect
                                                          ShimmerText(
                                                            text: _getMedalLabel(
                                                                    index)
                                                                .toUpperCase(),
                                                            baseColor: medalColor
                                                                .withOpacity(
                                                                    0.7),
                                                            highlightColor:
                                                                accentColor,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              letterSpacing:
                                                                  1.2,
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      // Middle section (circular score)
                                                      Container(
                                                        width: 80,
                                                        height: 80,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Colors.white,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: medalColor
                                                                  .withOpacity(
                                                                      0.3),
                                                              blurRadius: 10,
                                                              spreadRadius: 1,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Stack(
                                                          children: [
                                                            // Animated circular progress
                                                            Positioned.fill(
                                                              child:
                                                                  TweenAnimationBuilder<
                                                                      double>(
                                                                tween: Tween<
                                                                        double>(
                                                                    begin: 0,
                                                                    end: recommendation
                                                                            .score /
                                                                        100),
                                                                duration: Duration(
                                                                    milliseconds:
                                                                        1500),
                                                                curve: Curves
                                                                    .easeOutCubic,
                                                                builder:
                                                                    (context,
                                                                        value,
                                                                        child) {
                                                                  return CustomPaint(
                                                                    painter:
                                                                        CircularScorePainter(
                                                                      progress:
                                                                          value,
                                                                      color:
                                                                          medalColor,
                                                                      strokeWidth:
                                                                          6,
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            ),

                                                            // Center text
                                                            Center(
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Text(
                                                                    '${recommendation.score}%',
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          22,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color:
                                                                          medalColor,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    'COCOK',
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          10,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .grey
                                                                          .shade600,
                                                                      letterSpacing:
                                                                          1,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      // Program & Minat name
                                                      Container(
                                                        width: double.infinity,
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                vertical: 8),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              programName,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .grey
                                                                    .shade600,
                                                                letterSpacing:
                                                                    0.5,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            SizedBox(height: 6),
                                                            Container(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          2),
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
                                                                      .centerLeft,
                                                                  end: Alignment
                                                                      .centerRight,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4),
                                                              ),
                                                              child: Text(
                                                                minatName,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      medalColor,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      // Preview content with icons - same height for all
                                                      Container(
                                                        height:
                                                            80, // Fixed height for this section
                                                        child: Row(
                                                          children: [
                                                            if (recommendation
                                                                .careers
                                                                .isNotEmpty)
                                                              Expanded(
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Container(
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              8),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: medalColor
                                                                            .withOpacity(0.1),
                                                                        shape: BoxShape
                                                                            .circle,
                                                                      ),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .work,
                                                                        color:
                                                                            medalColor,
                                                                        size:
                                                                            16,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            6),
                                                                    Text(
                                                                      recommendation
                                                                          .careers
                                                                          .first,
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        color: Colors
                                                                            .black87,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      maxLines:
                                                                          2,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            SizedBox(width: 10),
                                                            if (recommendation
                                                                .majors
                                                                .isNotEmpty)
                                                              Expanded(
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Container(
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              8),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: medalColor
                                                                            .withOpacity(0.1),
                                                                        shape: BoxShape
                                                                            .circle,
                                                                      ),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .school,
                                                                        color:
                                                                            medalColor,
                                                                        size:
                                                                            16,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            6),
                                                                    Text(
                                                                      recommendation
                                                                          .majors
                                                                          .first,
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        color: Colors
                                                                            .black87,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      maxLines:
                                                                          2,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),

                                                      // Button section
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                            top: 10),
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            colors: [
                                                              medalColor,
                                                              accentColor
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: medalColor
                                                                  .withOpacity(
                                                                      0.4),
                                                              blurRadius: 10,
                                                              offset:
                                                                  Offset(0, 4),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            onTap: () {
                                                              HapticFeedback
                                                                  .lightImpact();
                                                              showModalBottomSheet(
                                                                context:
                                                                    context,
                                                                isScrollControlled:
                                                                    true,
                                                                backgroundColor:
                                                                    Colors
                                                                        .transparent,
                                                                builder: (context) =>
                                                                    _buildDetailBottomSheet(
                                                                        recommendation,
                                                                        index),
                                                              );
                                                            },
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            splashColor: Colors
                                                                .white
                                                                .withOpacity(
                                                                    0.2),
                                                            highlightColor:
                                                                Colors.white
                                                                    .withOpacity(
                                                                        0.1),
                                                            child: Container(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          20,
                                                                      vertical:
                                                                          10),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Text(
                                                                    'Lihat Detail',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      width: 8),
                                                                  Icon(
                                                                    Icons
                                                                        .arrow_forward,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 14,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Glass reflection overlay
                                                Positioned(
                                                  top: 0,
                                                  left: 0,
                                                  right: 0,
                                                  height: 80,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: [
                                                          Colors.white
                                                              .withOpacity(0.3),
                                                          Colors.white
                                                              .withOpacity(0.1),
                                                          Colors.white
                                                              .withOpacity(0),
                                                        ],
                                                        stops: [0.0, 0.5, 1.0],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(20),
                                                        topRight:
                                                            Radius.circular(20),
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // Floating sparkles
                                                if (_itemControllers[index]
                                                        .value >
                                                    0.7)
                                                  ...List.generate(
                                                    5,
                                                    (i) => Positioned(
                                                      top: 10 +
                                                          (i *
                                                              30 *
                                                              (i % 2 + 1)),
                                                      right: 10 +
                                                          (i *
                                                              15 *
                                                              ((i + 1) % 2)),
                                                      child: AnimatedBuilder(
                                                        animation:
                                                            _itemControllers[
                                                                index],
                                                        builder:
                                                            (context, child) {
                                                          final sparkleAnim = math
                                                              .sin(_itemControllers[
                                                                          index]
                                                                      .value *
                                                                  (5 + i) *
                                                                  math.pi);
                                                          return Opacity(
                                                            opacity: 0.4 +
                                                                (sparkleAnim
                                                                        .abs() *
                                                                    0.6),
                                                            child: Transform
                                                                .rotate(
                                                              angle:
                                                                  sparkleAnim *
                                                                      0.3,
                                                              child: Icon(
                                                                Icons.star,
                                                                color:
                                                                    accentColor,
                                                                size:
                                                                    8 + (i * 2),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
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
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ...List.generate(
              math.min(3, topRecommendations.length),
              (index) {
                final recommendation = topRecommendations[index];
                final parts = recommendation.title.split('|');
                final minatName = parts.length > 1 ? parts[1] : parts[0];
                final programName = parts[0];

                // Get medal color
                final Color medalColor = _getMedalColor(index);

                // Segunda cor para os padrões e destaque
                final Color accentColor = index == 0
                    ? Color.fromARGB(255, 11, 185, 124) // Gold accent
                    : index == 1
                        ? Color(0xFFE59866) // Silver accent
                        : Color(0xFFE59866); // Bronze accent

                return AnimatedBuilder(
                  animation: _itemControllers[index],
                  builder: (context, child) {
                    final progress = math.min(
                        1.0, math.max(0.0, _itemControllers[index].value));
                    final adjustedProgress =
                        Curves.easeOutCubic.transform(progress);
                    final scale = 0.95 + (0.05 * adjustedProgress);

                    return Transform.translate(
                      offset: Offset(
                        (1.0 - adjustedProgress) * 50,
                        0,
                      ),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: adjustedProgress,
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Card(
                              elevation: 8,
                              shadowColor: medalColor.withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.white,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: medalColor.withOpacity(0.3),
                                      spreadRadius: 0,
                                      blurRadius: 15,
                                      offset: Offset(0, 8),
                                    )
                                  ],
                                  border: Border.all(
                                    width: 1.5,
                                    color: medalColor,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    children: [
                                      // Animated background patterns
                                      Positioned.fill(
                                        child: AnimatedBuilder(
                                          animation: _itemControllers[index],
                                          builder: (context, child) {
                                            return CustomPaint(
                                              painter:
                                                  AnimatedBackgroundPainter(
                                                color: medalColor,
                                                accentColor: accentColor,
                                                animationValue:
                                                    _itemControllers[index]
                                                        .value,
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      // Blurred overlay for better readability
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 10, sigmaY: 10),
                                            child: Container(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                      ),

                                      Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                        child: InkWell(
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder: (context) =>
                                                  _buildDetailBottomSheet(
                                                      recommendation, index),
                                            );
                                          },
                                          splashColor:
                                              medalColor.withOpacity(0.1),
                                          highlightColor:
                                              medalColor.withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Header with medal banner
                                              Container(
                                                width: double.infinity,
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 14,
                                                    horizontal: 16),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                    colors: [
                                                      medalColor,
                                                      accentColor,
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: medalColor
                                                          .withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            programName,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.9),
                                                              letterSpacing:
                                                                  0.5,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          SizedBox(height: 4),
                                                          ShimmerText(
                                                            text: minatName,
                                                            baseColor:
                                                                Colors.white,
                                                            highlightColor:
                                                                Colors.white
                                                                    .withOpacity(
                                                                        0.7),
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              letterSpacing:
                                                                  0.5,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.1),
                                                            blurRadius: 4,
                                                            offset:
                                                                Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            _getMedalEmoji(
                                                                index),
                                                            style: TextStyle(
                                                                fontSize: 16),
                                                          ),
                                                          SizedBox(width: 6),
                                                          ShimmerText(
                                                            text:
                                                                _getMedalLabel(
                                                                    index),
                                                            baseColor:
                                                                Colors.white,
                                                            highlightColor:
                                                                accentColor
                                                                    .withOpacity(
                                                                        0.8),
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 12,
                                                              letterSpacing: 1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Content
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Score with circular indicator
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 60,
                                                          height: 60,
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
                                                                spreadRadius: 1,
                                                              ),
                                                            ],
                                                          ),
                                                          child: Stack(
                                                            children: [
                                                              // Animated circular progress
                                                              Positioned.fill(
                                                                child:
                                                                    TweenAnimationBuilder<
                                                                        double>(
                                                                  tween: Tween<
                                                                          double>(
                                                                      begin: 0,
                                                                      end: recommendation
                                                                              .score /
                                                                          100),
                                                                  duration: Duration(
                                                                      milliseconds:
                                                                          1500),
                                                                  curve: Curves
                                                                      .easeOutCubic,
                                                                  builder:
                                                                      (context,
                                                                          value,
                                                                          child) {
                                                                    return CustomPaint(
                                                                      painter:
                                                                          CircularScorePainter(
                                                                        progress:
                                                                            value,
                                                                        color:
                                                                            medalColor,
                                                                        strokeWidth:
                                                                            5,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),

                                                              // Center text
                                                              Center(
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Text(
                                                                      '${recommendation.score}%',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color:
                                                                            medalColor,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      'Cocok',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            9,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: Colors
                                                                            .grey
                                                                            .shade600,
                                                                        letterSpacing:
                                                                            0.5,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        SizedBox(width: 16),
                                                        Expanded(
                                                          child: Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        14,
                                                                    vertical:
                                                                        10),
                                                            decoration:
                                                                BoxDecoration(
                                                              gradient:
                                                                  LinearGradient(
                                                                begin: Alignment
                                                                    .topLeft,
                                                                end: Alignment
                                                                    .bottomRight,
                                                                colors: [
                                                                  medalColor
                                                                      .withOpacity(
                                                                          0.1),
                                                                  accentColor
                                                                      .withOpacity(
                                                                          0.1),
                                                                ],
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              border:
                                                                  Border.all(
                                                                color: medalColor
                                                                    .withOpacity(
                                                                        0.3),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              'Kesesuaian tinggi dengan minat dan kemampuan Anda',
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: medalColor
                                                                    .withOpacity(
                                                                        0.8),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    SizedBox(height: 20),

                                                    // Careers and Majors with enhanced styling
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // Careers section
                                                        Expanded(
                                                          child:
                                                              _buildEnhancedInfoSection(
                                                            icon: Icons.work,
                                                            title: 'Karir',
                                                            items:
                                                                recommendation
                                                                    .careers,
                                                            color: medalColor,
                                                            accentColor:
                                                                accentColor,
                                                          ),
                                                        ),
                                                        SizedBox(width: 16),
                                                        // Majors section
                                                        Expanded(
                                                          child:
                                                              _buildEnhancedInfoSection(
                                                            icon: Icons.school,
                                                            title: 'Jurusan',
                                                            items:
                                                                recommendation
                                                                    .majors,
                                                            color: medalColor,
                                                            accentColor:
                                                                accentColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    // View Details button
                                                    Center(
                                                      child: Container(
                                                        margin: EdgeInsets.only(
                                                            top: 20),
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            colors: [
                                                              medalColor,
                                                              accentColor
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: medalColor
                                                                  .withOpacity(
                                                                      0.4),
                                                              blurRadius: 10,
                                                              offset:
                                                                  Offset(0, 4),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            onTap: () {
                                                              HapticFeedback
                                                                  .lightImpact();
                                                              showModalBottomSheet(
                                                                context:
                                                                    context,
                                                                isScrollControlled:
                                                                    true,
                                                                backgroundColor:
                                                                    Colors
                                                                        .transparent,
                                                                builder: (context) =>
                                                                    _buildDetailBottomSheet(
                                                                        recommendation,
                                                                        index),
                                                              );
                                                            },
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            splashColor: Colors
                                                                .white
                                                                .withOpacity(
                                                                    0.2),
                                                            highlightColor:
                                                                Colors.white
                                                                    .withOpacity(
                                                                        0.1),
                                                            child: Padding(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          20,
                                                                      vertical:
                                                                          12),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .info_outline,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 16,
                                                                  ),
                                                                  SizedBox(
                                                                      width: 8),
                                                                  Text(
                                                                    'Lihat Detail Lengkap',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      letterSpacing:
                                                                          0.5,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      width: 8),
                                                                  Icon(
                                                                    Icons
                                                                        .arrow_forward,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 14,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
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

                                      // Glass reflection overlay
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        height: 60,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.white.withOpacity(0.3),
                                                Colors.white.withOpacity(0.1),
                                                Colors.white.withOpacity(0),
                                              ],
                                              stops: [0.0, 0.5, 1.0],
                                            ),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Floating sparkles
                                      if (_itemControllers[index].value > 0.7)
                                        ...List.generate(
                                          3,
                                          (i) => Positioned(
                                            top: 40 + (i * 40 * (i % 2 + 1)),
                                            right:
                                                20 + (i * 20 * ((i + 1) % 2)),
                                            child: AnimatedBuilder(
                                              animation:
                                                  _itemControllers[index],
                                              builder: (context, child) {
                                                final sparkleAnim = math.sin(
                                                    _itemControllers[index]
                                                            .value *
                                                        (5 + i) *
                                                        math.pi);
                                                return Opacity(
                                                  opacity: 0.4 +
                                                      (sparkleAnim.abs() * 0.6),
                                                  child: Transform.rotate(
                                                    angle: sparkleAnim * 0.3,
                                                    child: Icon(
                                                      Icons.star,
                                                      color: accentColor,
                                                      size: 8 + (i * 2),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Swipe indicator yang lebih mencolok
            Center(
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.swipe,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Swipe untuk melihat detail lebih lanjut',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _swipePromptController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          8 *
                              math.sin(
                                  _swipePromptController.value * math.pi * 2),
                          0,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(RecommendationItem recommendation, int index) {
    final parts = recommendation.title.split('|');
    final programName = parts[0];
    final minatName = parts.length > 1 ? parts[1] : '';

    // List emoji yang menarik untuk tiap kategori
    final careerEmojis = ['👨‍💼', '👩‍💻', '👩‍🏫', '👨‍🔬', '👩‍⚕️', '👨‍🚀'];
    final majorEmojis = ['📚', '🎓', '🔬', '💻', '🎨', '📊'];

    // Pilih emoji secara random tapi konsisten untuk tiap kategori
    final random = math.Random(recommendation.title.hashCode);
    final careerEmoji = careerEmojis[random.nextInt(careerEmojis.length)];
    final majorEmoji = majorEmojis[random.nextInt(majorEmojis.length)];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getMedalColor(index).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _getMedalColor(index).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan warna medali dan animasi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getMedalColor(index).withOpacity(0.2),
                  Colors.white.withOpacity(0.9),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: _getMedalColor(index).withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _itemControllers[index],
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: math.sin(_itemControllers[index].value * 6) * 0.1,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getMedalColor(index).withOpacity(0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getMedalColor(index).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          _getMedalEmoji(index),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        programName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        minatName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge skor dengan animasi pulse
                AnimatedBuilder(
                  animation: _cardController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 +
                          0.1 * math.sin(_cardController.value * 6 * math.pi),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade100,
                              _getMedalColor(index).withOpacity(0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: _getMedalColor(index).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: _getMedalColor(index),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${recommendation.score}%",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade900,
                                fontSize: 14,
                              ),
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

          // Content dengan emoji untuk setiap bagian
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Karir dengan emoji
                _buildInfoSectionWithEmoji(
                  'Karir/Profesi Terkait:',
                  recommendation.careers,
                  careerEmoji,
                  Colors.orange,
                  animate: true,
                ),

                const SizedBox(height: 16),

                // Jurusan dengan emoji
                _buildInfoSectionWithEmoji(
                  'Jurusan yang Disarankan:',
                  recommendation.majors,
                  majorEmoji,
                  Colors.green,
                  animate: true,
                ),

                // Additional sections if available
                if (recommendation.recommendedCourses != null &&
                    recommendation.recommendedCourses!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoSectionWithEmoji(
                    'Mata Kuliah Rekomendasi:',
                    recommendation.recommendedCourses!,
                    '📝',
                    Colors.purple,
                    animate: true,
                  ),
                ],

                if (recommendation.recommendedUniversities != null &&
                    recommendation.recommendedUniversities!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoSectionWithEmoji(
                    'Universitas Rekomendasi:',
                    recommendation.recommendedUniversities!,
                    '🏛️',
                    Colors.blue,
                    animate: true,
                  ),
                ],

                // RIASEC compatibility if available
                if (recommendation.riasecCompatibility != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Text(
                          '🧠',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kesesuaian RIASEC:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Text(
                          '${(recommendation.riasecCompatibility! * 100).round()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (recommendation.matchingRiasecCareers != null &&
                    recommendation.matchingRiasecCareers!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(
                      'Karir RIASEC yang Cocok:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          recommendation.matchingRiasecCareers!.map((career) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Text(
                            career,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // Tombol detail dengan animasi
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _cardController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 +
                              0.05 *
                                  math.sin(_cardController.value * 4 * math.pi),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Implementasi untuk menampilkan dialog atau halaman detail lebih lanjut
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => _buildDetailBottomSheet(
                                    recommendation, index),
                              );
                            },
                            icon: Icon(
                              Icons.visibility,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              'Lihat Detail',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getMedalColor(index),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 5,
                              shadowColor:
                                  _getMedalColor(index).withOpacity(0.5),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSectionWithEmoji(
      String title, List<String> items, String emoji, MaterialColor color,
      {bool animate = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            animate
                ? AnimatedBuilder(
                    animation: _cardController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle:
                            math.sin(_cardController.value * 6 * math.pi) * 0.1,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(color: color.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: color.shade200.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: color.shade200),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return animate
                  ? AnimatedBuilder(
                      animation: _cardController,
                      builder: (context, child) {
                        // Delay berdasarkan indeks untuk efek staggered
                        final delay = index * 0.1;
                        double opacity = 0.0;

                        if (_cardController.value > delay) {
                          opacity = math.min(
                              1.0, (_cardController.value - delay) / 0.3);
                        }

                        return Opacity(
                          opacity: opacity,
                          child: Transform.translate(
                            offset: Offset(
                              (1.0 - opacity) * 20,
                              0,
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.shade50,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: color.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: color.shade100.withOpacity(0.5),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 12,
                            color: color.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.shade50,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: color.shade200),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 12,
                          color: color.shade700,
                        ),
                      ),
                    );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailBottomSheet(RecommendationItem recommendation, int index) {
    final parts = recommendation.title.split('|');
    final programName = parts[0];
    final minatName = parts.length > 1 ? parts[1] : '';

    // Medal color and accent color (following design system from the first UI)
    final Color medalColor = _getMedalColor(index);
    final Color accentColor = index == 0
        ? Color(0xFFF7D154) // Gold accent
        : index == 1
            ? Color(0xFFB3B6B7) // Silver accent
            : Color(0xFFE59866); // Bronze accent

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background subtle patterns
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: CustomPaint(
                    painter: AnimatedBackgroundPainter(
                      color: medalColor,
                      accentColor: accentColor,
                      animationValue: 0.5, // Fixed value for subtle animation
                    ),
                  ),
                ),
              ),

              // Blurred overlay for better readability
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          medalColor.withOpacity(0.5),
                          accentColor.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: medalColor.withOpacity(0.2),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),

                  // Medal icon + header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          medalColor.withOpacity(0.15),
                          Colors.white.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                medalColor.withOpacity(0.3),
                                accentColor.withOpacity(0.3),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: medalColor.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            _getMedalEmoji(index),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                programName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              ShimmerText(
                                text: minatName,
                                baseColor: medalColor,
                                highlightColor: accentColor,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                medalColor.withOpacity(0.3),
                                accentColor.withOpacity(0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: medalColor.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: medalColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${recommendation.score}%",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(
                    height: 1,
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          medalColor.withOpacity(0.3),
                          accentColor.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Explanation
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                medalColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: medalColor.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: medalColor.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          medalColor.withOpacity(0.2),
                                          accentColor.withOpacity(0.2)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.lightbulb_outline,
                                      color: medalColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tentang ${minatName}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: medalColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hasil analisis menunjukkan bahwa kamu memiliki kecocokan yang signifikan dengan bidang minat ini. Skor ${recommendation.score}% menggambarkan tingkat kesesuaian minatmu berdasarkan jawaban kuesioner.',
                                style: TextStyle(
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Career section with improved styling but same content
                        _buildDetailEnhancedInfoSection(
                          title: 'Karir dan Profesi',
                          items: recommendation.careers,
                          emoji: '👨‍💼',
                          color: medalColor,
                          accentColor: accentColor,
                        ),

                        const SizedBox(height: 24),

                        // Majors section with improved styling but same content
                        _buildDetailEnhancedInfoSection(
                          title: 'Jurusan yang Disarankan',
                          items: recommendation.majors,
                          emoji: '🎓',
                          color: medalColor,
                          accentColor: accentColor,
                        ),

                        const SizedBox(height: 24),

                        // Additional sections if available (maintaining exact same conditional logic)
                        if (recommendation.recommendedCourses != null &&
                            recommendation.recommendedCourses!.isNotEmpty) ...[
                          _buildDetailEnhancedInfoSection(
                            title: 'Mata Kuliah Rekomendasi',
                            items: recommendation.recommendedCourses!,
                            emoji: '📝',
                            color: medalColor,
                            accentColor: accentColor,
                          ),
                          const SizedBox(height: 24),
                        ],

                        if (recommendation.recommendedUniversities != null &&
                            recommendation
                                .recommendedUniversities!.isNotEmpty) ...[
                          _buildDetailEnhancedInfoSection(
                            title: 'Universitas Rekomendasi',
                            items: recommendation.recommendedUniversities!,
                            emoji: '🏛️',
                            color: medalColor,
                            accentColor: accentColor,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Rules section (why this recommendation) - preserving structure but enhancing style
                        if (recommendation.rules.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          accentColor.withOpacity(0.2),
                                          medalColor.withOpacity(0.2)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: accentColor.withOpacity(0.3)),
                                    ),
                                    child: const Text(
                                      '💡',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ShimmerText(
                                    text: 'Mengapa Ini Direkomendasikan?',
                                    baseColor: accentColor,
                                    highlightColor: medalColor,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 26),
                                child: Text(
                                  'Berdasarkan jawabanmu, kami menemukan kecocokan dengan minat ini karena:',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.only(left: 26),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: math.min(
                                      5,
                                      recommendation.rules
                                          .length), // Batasi ke 5 aturan saja
                                  itemBuilder: (context, index) {
                                    final rule = recommendation.rules[index];
                                    // Extract just the question text
                                    final questionTextMatch =
                                        RegExp(r'\[Pertanyaan: "(.*?)"\]')
                                            .firstMatch(rule);
                                    final questionText =
                                        questionTextMatch?.group(1) ?? '';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white,
                                            accentColor.withOpacity(0.05),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color:
                                                accentColor.withOpacity(0.3)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accentColor.withOpacity(0.1),
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  medalColor.withOpacity(0.2),
                                                  accentColor.withOpacity(0.2)
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check,
                                              color: medalColor,
                                              size: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              questionText,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // "Show more" button if there are more than 5 rules
                            ],
                          ),

                        // RIASEC placeholder with enhanced style but same content
                        const SizedBox(height: 24),

                        const SizedBox(height: 40),

                        // Action button with enhanced styling
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [medalColor, accentColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: medalColor.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 0,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                HapticFeedback.mediumImpact();
                              },
                              borderRadius: BorderRadius.circular(30),
                              splashColor: Colors.white.withOpacity(0.2),
                              highlightColor: Colors.white.withOpacity(0.1),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text(
                                    'Kembali',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),

              // Glass reflection overlay at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
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

// Enhanced info section specifically for the detail bottom sheet
  Widget _buildDetailEnhancedInfoSection({
    required String title,
    required List<String> items,
    required String emoji,
    required Color color,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      accentColor.withOpacity(0.2)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              ShimmerText(
                text: title,
                baseColor: color,
                highlightColor: accentColor,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items
              .map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          color.withOpacity(0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.05),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withOpacity(0.2),
                                accentColor.withOpacity(0.2)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: color,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildDetailPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Analisis Terperinci 📊',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Spinning gear animation
                AnimatedBuilder(
                  animation: _cardController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _cardController.value * math.pi * 2,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lihat bagaimana rekomendasi ini didapatkan berdasarkan jawabanmu',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // Chart
            _buildScoreChart(),

            const SizedBox(height: 24),

            // // Working Memory
            // Container(
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.circular(16),
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.black.withOpacity(0.1),
            //         blurRadius: 10,
            //         offset: const Offset(0, 4),
            //       ),
            //     ],
            //   ),
            //   child: ExpansionTile(
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(16),
            //     ),
            //     leading: Container(
            //       padding: const EdgeInsets.all(8),
            //       decoration: BoxDecoration(
            //         color: Colors.blue.shade50,
            //         shape: BoxShape.circle,
            //       ),
            //       child: Text(
            //         '🧠',
            //         style: TextStyle(fontSize: 16),
            //       ),
            //     ),
            //     title: const Text(
            //       'Data Jawaban (Working Memory)',
            //       style: TextStyle(
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //     childrenPadding: const EdgeInsets.all(16),
            //     children: [
            //       Text(
            //         'Berikut adalah daftar fakta-fakta yang digunakan dalam proses analisis:',
            //         style: TextStyle(
            //           fontSize: 14,
            //           color: Colors.grey.shade700,
            //         ),
            //       ),
            //       const SizedBox(height: 12),
            //       Container(
            //         width: double.infinity,
            //         padding: const EdgeInsets.all(12),
            //         decoration: BoxDecoration(
            //           color: Colors.grey.shade100,
            //           borderRadius: BorderRadius.circular(8),
            //           border: Border.all(color: Colors.grey.shade300),
            //         ),
            //         child: Wrap(
            //           spacing: 8,
            //           runSpacing: 8,
            //           children: widget.result.workingMemory.map((fact) {
            //             final isYes = fact.contains('=Yes');
            //             return Container(
            //               padding: const EdgeInsets.symmetric(
            //                   horizontal: 8, vertical: 4),
            //               decoration: BoxDecoration(
            //                 gradient: LinearGradient(
            //                   colors: isYes
            //                       ? [
            //                           Colors.green.shade50,
            //                           Colors.green.shade100
            //                         ]
            //                       : [Colors.red.shade50, Colors.red.shade100],
            //                   begin: Alignment.topLeft,
            //                   end: Alignment.bottomRight,
            //                 ),
            //                 borderRadius: BorderRadius.circular(6),
            //                 border: Border.all(
            //                   color: isYes
            //                       ? Colors.green.shade300
            //                       : Colors.red.shade300,
            //                 ),
            //                 boxShadow: [
            //                   BoxShadow(
            //                     color: isYes
            //                         ? Colors.green.withOpacity(0.1)
            //                         : Colors.red.withOpacity(0.1),
            //                     blurRadius: 3,
            //                     offset: const Offset(0, 1),
            //                   ),
            //                 ],
            //               ),
            //               child: Row(
            //                 mainAxisSize: MainAxisSize.min,
            //                 children: [
            //                   Icon(
            //                     isYes ? Icons.check_circle : Icons.cancel,
            //                     color: isYes
            //                         ? Colors.green.shade600
            //                         : Colors.red.shade600,
            //                     size: 12,
            //                   ),
            //                   const SizedBox(width: 4),
            //                   Text(
            //                     fact,
            //                     style: TextStyle(
            //                       fontSize: 12,
            //                       color: isYes
            //                           ? Colors.green.shade800
            //                           : Colors.red.shade800,
            //                       fontWeight: FontWeight.w500,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             );
            //           }).toList(),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            const SizedBox(height: 24),

            // Steps explanation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '⚙️',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Proses Analisis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sistem ini menggunakan metode Forward Chaining untuk menentukan rekomendasi paling cocok untukmu. Berikut caranya:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Animasi steps yang muncul satu per satu
                  AnimatedBuilder(
                    animation: _cardController,
                    builder: (context, child) {
                      return Column(
                        children: [
                          _buildAnimatedAnalysisStep(
                            '1',
                            'Jawaban kuesioner diubah menjadi fakta',
                            'Sistem mengumpulkan semua jawaban "Ya" dan "Tidak" dari kuesioner yang kamu isi.',
                            Colors.blue,
                            _cardController.value > 0.2
                                ? math.min(
                                    1.0, (_cardController.value - 0.2) / 0.2)
                                : 0.0,
                          ),
                          _buildAnimatedAnalysisStep(
                            '2',
                            'Fakta dicocokkan dengan aturan',
                            'Setiap jawaban "Ya" akan menambah skor pada minat yang sesuai.',
                            Colors.purple,
                            _cardController.value > 0.3
                                ? math.min(
                                    1.0, (_cardController.value - 0.3) / 0.2)
                                : 0.0,
                          ),
                          _buildAnimatedAnalysisStep(
                            '3',
                            'Skor dihitung untuk setiap minat',
                            'Sistem menghitung persentase kecocokan berdasarkan total bobot.',
                            Colors.orange,
                            _cardController.value > 0.4
                                ? math.min(
                                    1.0, (_cardController.value - 0.4) / 0.2)
                                : 0.0,
                          ),
                          _buildAnimatedAnalysisStep(
                            '4',
                            'Hasil diurutkan',
                            'Rekomendasi ditampilkan berdasarkan skor tertinggi.',
                            Colors.green,
                            _cardController.value > 0.5
                                ? math.min(
                                    1.0, (_cardController.value - 0.5) / 0.2)
                                : 0.0,
                            isLast: true,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Apa Artinya Ini? 🤔',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Thinking emoji animation
                AnimatedBuilder(
                  animation: _cardController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        5 * math.sin(_cardController.value * 3 * math.pi),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '🤔',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Penjelasan sederhana tentang hasil analisis dan apa yang bisa kamu lakukan selanjutnya',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // Explanation card with animated points
            AnimatedBuilder(
              animation: _cardController,
              builder: (context, child) {
                // Hitung progress animasi untuk masing-masing poin
                final point1Opacity = _cardController.value > 0.2
                    ? math.min(1.0, (_cardController.value - 0.2) / 0.2)
                    : 0.0;
                final point2Opacity = _cardController.value > 0.3
                    ? math.min(1.0, (_cardController.value - 0.3) / 0.2)
                    : 0.0;
                final point3Opacity = _cardController.value > 0.4
                    ? math.min(1.0, (_cardController.value - 0.4) / 0.2)
                    : 0.0;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '💡',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Apa Arti Hasil Ini?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Hasil analisis ini menunjukkan bidang minat yang paling sesuai denganmu berdasarkan jawaban yang kamu berikan dalam kuesioner.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedExplanationPoint(
                        'Persentase yang tinggi menunjukkan kecocokan yang lebih baik antara minatmu dan bidang tersebut.',
                        Icons.bar_chart,
                        Colors.blue,
                        point1Opacity,
                      ),
                      _buildAnimatedExplanationPoint(
                        'Rekomendasi karir dan jurusan dapat membantumu untuk merencanakan pendidikan dan masa depan.',
                        Icons.school,
                        Colors.green,
                        point2Opacity,
                      ),
                      _buildAnimatedExplanationPoint(
                        'Kamu bisa mendiskusikan hasil ini dengan guru BK, orang tua, atau konselor untuk mendapat saran lebih lanjut.',
                        Icons.people,
                        Colors.purple,
                        point3Opacity,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // What next card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.green.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '🚀',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Langkah Selanjutnya',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Animated steps with path connector
                  AnimatedBuilder(
                    animation: _cardController,
                    builder: (context, child) {
                      return Column(
                        children: [
                          _buildAnimatedNextStep(
                            'Jelajahi',
                            'Cari tahu lebih banyak tentang jurusan dan karir yang direkomendasikan.',
                            Icons.explore,
                            Colors.blue,
                            _cardController.value > 0.2
                                ? math.min(
                                    1.0, (_cardController.value - 0.2) / 0.2)
                                : 0.0,
                          ),
                          _buildAnimatedNextStep(
                            'Diskusikan',
                            'Bicarakan hasil ini dengan guru, orang tua, atau konselor.',
                            Icons.chat,
                            Colors.orange,
                            _cardController.value > 0.3
                                ? math.min(
                                    1.0, (_cardController.value - 0.3) / 0.2)
                                : 0.0,
                          ),
                          _buildAnimatedNextStep(
                            'Refleksikan',
                            'Pikirkan apakah rekomendasi ini sesuai dengan apa yang kamu inginkan.',
                            Icons.self_improvement,
                            Colors.purple,
                            _cardController.value > 0.4
                                ? math.min(
                                    1.0, (_cardController.value - 0.4) / 0.2)
                                : 0.0,
                          ),
                          _buildAnimatedNextStep(
                            'Rencanakan',
                            'Buat rencana pendidikan dan karir berdasarkan minatmu.',
                            Icons.checklist,
                            Colors.green,
                            _cardController.value > 0.5
                                ? math.min(
                                    1.0, (_cardController.value - 0.5) / 0.2)
                                : 0.0,
                            isLast: true,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // RIASEC info card with animated gradient

            const SizedBox(height: 32),

            // Share button with floating animation
            Center(
              child: AnimatedBuilder(
                animation: _cardController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      4 * math.sin(_cardController.value * 3 * math.pi),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CertificateReccomendationPage(
                              result: widget
                                  .result, // Gunakan DateTime.now().toString() atau format yang diinginkan
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text(
                        'Cetak Sertifikat',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.indigo.shade900,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                        shadowColor: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '📊',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Grafik Kesesuaian Minat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Berdasarkan jawaban kuesionermu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: AnimatedBuilder(
              animation: _cardController,
              builder: (context, child) {
                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final recommendation =
                              widget.result.recommendations[groupIndex];
                          final parts = recommendation.title.split('|');
                          final minatName =
                              parts.length > 1 ? parts[1] : parts[0];

                          return BarTooltipItem(
                            '$minatName\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '${rod.toY.round()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 ||
                                index >= widget.result.recommendations.length) {
                              return const SizedBox.shrink();
                            }
                            final parts = widget
                                .result.recommendations[index].title
                                .split('|');
                            String label =
                                parts.length > 1 ? parts[1] : parts[0];
                            if (label.length > 8) {
                              label = '${label.substring(0, 6)}...';
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: index < 3
                                      ? _getMedalColor(index)
                                      : Colors.grey.shade700,
                                ),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                '${value.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                          reservedSize: 30,
                          interval: 25,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: widget.result.recommendations
                        .asMap()
                        .entries
                        .map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      // Animasi bar dengan cardController
                      final barProgress = _cardController.value *
                          1.3; // Sedikit lebih cepat dari nilai controller
                      final barHeight = math.min(1.0, barProgress) * item.score;

                      // Set warna berdasarkan peringkat
                      Color barColor;
                      if (index == 0) {
                        barColor = _goldColor;
                      } else if (index == 1) {
                        barColor = _silverColor;
                      } else if (index == 2) {
                        barColor = _bronzeColor;
                      } else {
                        barColor = Colors.grey;
                      }

                      // Animasi spark di puncak bar
                      final bool showSpark = barProgress >= 0.95 && index < 3;

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: barHeight,
                            color: barColor,
                            width: 20,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 100,
                              color: Colors.grey.shade200,
                            ),
                            rodStackItems: showSpark
                                ? [
                                    BarChartRodStackItem(
                                      barHeight - 5,
                                      barHeight + 2,
                                      Colors.white.withOpacity(math.sin(
                                                  _cardController.value *
                                                      10 *
                                                      math.pi) *
                                              0.5 +
                                          0.5),
                                    ),
                                  ]
                                : [],
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedAnalysisStep(
    String number,
    String title,
    String description,
    MaterialColor color,
    double progress, {
    bool isLast = false,
  }) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset((1.0 - progress) * 50, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: color.shade300),
                boxShadow: [
                  BoxShadow(
                    color: color.shade100.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    color: color.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      height: 24,
                      width: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.shade300, color.shade100],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
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

  Widget _buildAnimatedExplanationPoint(
      String text, IconData icon, MaterialColor color, double progress) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset((1.0 - progress) * 50, 0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: color.shade100.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: color.shade600,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedNextStep(
    String title,
    String description,
    IconData icon,
    MaterialColor color,
    double progress, {
    bool isLast = false,
  }) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset((1.0 - progress) * 50, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _cardController,
              builder: (context, child) {
                final pulseScale =
                    1.0 + 0.1 * math.sin(_cardController.value * 6 * math.pi);
                return Transform.scale(
                  scale: pulseScale,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: color.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: color.shade100.withOpacity(0.5 * pulseScale),
                          blurRadius: 4 * pulseScale,
                          spreadRadius: 1 * pulseScale,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: color.shade600,
                      size: 18,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (!isLast) const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedRiasecItem(
      String letter, String fullName, MaterialColor color, double progress) {
    final effectiveProgress = math.max(0.0, math.min(1.0, progress));

    return Expanded(
      child: Opacity(
        opacity: effectiveProgress,
        child: Transform.translate(
          offset: Offset((1.0 - effectiveProgress) * 30, 0),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _cardController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: effectiveProgress > 0.5
                          ? math.sin(_cardController.value * 5 * math.pi) * 0.1
                          : 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color.shade100,
                          shape: BoxShape.circle,
                          boxShadow: effectiveProgress > 0.7
                              ? [
                                  BoxShadow(
                                    color: color.shade200.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            letter,
                            style: TextStyle(
                              color: color.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fullName,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 10,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? Colors.white
                  : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
              boxShadow: _currentPage == index
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        final particles = <Widget>[];
        final random = math.Random(42); // Fixed seed for consistent generation

        // Generate particles dinamis
        for (int i = 0; i < 100; i++) {
          final size = random.nextDouble() * 10 + 5;

          // Colors based on medal colors plus some extras
          final List<Color> particleColors = [
            _goldColor,
            _silverColor,
            _bronzeColor,
            Colors.red.shade400,
            Colors.blue.shade400,
            Colors.green.shade400,
            Colors.purple.shade400,
            Colors.pink.shade300,
          ];

          final color = particleColors[random.nextInt(particleColors.length)]
              .withOpacity(0.8);

          // Posisi awal (dari tengah atas layar dengan spread)
          final screenWidth = MediaQuery.of(context).size.width;
          final initialX = screenWidth * 0.5 +
              (random.nextDouble() - 0.5) * screenWidth * 0.8;
          final initialY = -size * 2;

          // Faktor waktu (0.0 - 1.0)
          final time = _confettiController.value;

          // Velocity dengan variasi
          final vx = (random.nextDouble() - 0.5) * 300;
          final vy = random.nextDouble() * 400 + 200;

          // Posisi saat ini dengan gravitasi
          final x = initialX + vx * time;
          final y = initialY +
              vy * time +
              400 * time * time; // Dengan akselerasi gravitasi

          // Rotasi dan randomness
          final rotation = random.nextDouble() * 360 * math.pi / 180;
          final rotationSpeed = (random.nextDouble() - 0.5) * 4;
          final currentRotation = rotation + rotationSpeed * time * 10;

          // Ukuran sesuai dengan fase animasi
          final sizeMultiplier = 1.0;

          // Opacity untuk fade out - PERBAIKAN: Pastikan nilai opacity selalu di antara 0.0 dan 1.0
          double opacity = 1.0;
          if (time > 0.7) {
            // Hitung opacity dan pastikan dalam range yang valid
            opacity = math.max(0.0, math.min(1.0, 1.0 - (time - 0.7) / 0.3));
          }

          // Bentuk partikel (circle, square, star/custom)
          final shape = random.nextInt(3);

          // Jangan tampilkan partikel yang sudah keluar layar
          if (y > MediaQuery.of(context).size.height ||
              x < 0 ||
              x > screenWidth) continue;

          // Tambahkan ke daftar partikel
          particles.add(
            Positioned(
              left: x,
              top: y,
              child: Transform.rotate(
                angle: currentRotation,
                child: Opacity(
                  opacity: opacity,
                  child: shape == 0
                      ? Container(
                          // Circle
                          width: size * sizeMultiplier,
                          height: size * sizeMultiplier,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        )
                      : shape == 1
                          ? Container(
                              // Square
                              width: size * sizeMultiplier,
                              height: size * sizeMultiplier,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : CustomPaint(
                              // Star
                              size: Size(size * 1.2 * sizeMultiplier,
                                  size * 1.2 * sizeMultiplier),
                              painter: StarPainter(color: color),
                            ),
                ),
              ),
            ),
          );
        }

        return Stack(
          children: particles,
        );
      },
    );
  }

  Widget _buildSimpleInfoSection({
    required String title,
    required IconData icon,
    required List<String> items,
    required Color color,
  }) {
    // Menampilkan maksimal 2 item
    final displayItems = items.take(2).toList();
    final hasMore = items.length > 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Items dalam Column dengan ukuran terbatas
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Daftar item
            for (var item in displayItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  "• $item",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Indikator "lainnya"
            if (hasMore)
              Text(
                "+ ${items.length - 2} lainnya...",
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
        ),
      ],
    );
  }

// Tambahkan fungsi helper untuk label dan warna
  String _getCompatibilityLabel(int index) {
    switch (index) {
      case 0:
        return 'Sangat Direkomendasikan';
      case 1:
        return 'Direkomendasikan';
      case 2:
        return 'Kurang Direkomendasikan';
      default:
        return 'Cukup';
    }
  }

  Color _getCompatibilityColor(int index) {
    switch (index) {
      case 0:
        return Colors.blue.shade700;
      case 1:
        return Colors.teal.shade600;
      case 2:
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getCompatibilityEmoji(int index) {
    switch (index) {
      case 0:
        return '⭐';
      case 1:
        return '✨';
      case 2:
        return '👍';
      default:
        return '✓';
    }
  }

  Widget _buildCompactInfoItem({
    required IconData icon,
    required String label,
    required String content,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                content,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

// Helper untuk section info yang responsif
  Widget _buildResponsiveInfoSection({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color color,
  }) {
    // Tentukan berapa item yang ditampilkan berdasarkan jumlah item
    final int itemsToShow = items.length > 2 ? 2 : items.length;
    final bool hasMore = items.length > itemsToShow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),

        // Items
        ...items.take(itemsToShow).map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "• ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        // "More" indicator if needed
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              "+ ${items.length - itemsToShow} lainnya",
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: color,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEnhancedInfoSection({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color color,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      accentColor.withOpacity(0.2)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...items
              .take(3)
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.arrow_right,
                          size: 16,
                          color: color.withOpacity(0.7),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${items.length - 3} lainnya',
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Animated Background Painter
class AnimatedBackgroundPainter extends CustomPainter {
  final Color color;
  final Color accentColor;
  final double animationValue;

  AnimatedBackgroundPainter({
    required this.color,
    required this.accentColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);

    // Draw floating circles
    for (int i = 0; i < 12; i++) {
      final paint = Paint()
        ..color = color.withOpacity(0.05 + (i % 3) * 0.03)
        ..style = PaintingStyle.fill;

      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final baseRadius = 5.0 + random.nextDouble() * 20;

      // Add animated movement
      final offsetX = math.sin((animationValue * 2 + i) * math.pi) * 10;
      final offsetY = math.cos((animationValue * 2 + i) * math.pi) * 10;

      canvas.drawCircle(
        Offset(baseX + offsetX, baseY + offsetY),
        baseRadius,
        paint,
      );
    }

    // Draw thin decorative lines
    for (int i = 0; i < 8; i++) {
      final linePaint = Paint()
        ..color = accentColor.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final angle = random.nextDouble() * math.pi * 2;
      final len = 30.0 + random.nextDouble() * 50;

      // Animate line rotation
      final rotatedAngle = angle + (animationValue * math.pi / 8);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(
          startX + math.cos(rotatedAngle) * len,
          startY + math.sin(rotatedAngle) * len,
        ),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Medal Badge Painter
class MedalBadgePainter extends CustomPainter {
  final Color color;
  final Color accentColor;
  final String emoji;

  MedalBadgePainter({
    required this.color,
    required this.accentColor,
    required this.emoji,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw corner badge
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw emoji text
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: 18,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width * 0.2 - textPainter.width / 2,
        size.height * 0.2 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Circular Score Painter
class CircularScorePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CircularScorePainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      progress * 2 * math.pi, // Convert progress to radians
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is CircularScorePainter) {
      return oldDelegate.progress != progress;
    }
    return true;
  }
}

// Shimmer Text Widget
class ShimmerText extends StatefulWidget {
  final String text;
  final Color baseColor;
  final Color highlightColor;
  final TextStyle style;

  const ShimmerText({
    Key? key,
    required this.text,
    required this.baseColor,
    required this.highlightColor,
    required this.style,
  }) : super(key: key);

  @override
  _ShimmerTextState createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
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
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              widget.baseColor,
              widget.highlightColor,
              widget.baseColor,
            ],
            stops: [
              0.0,
              _controller.value,
              1.0,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            transform: GradientRotation(_controller.value * math.pi * 2),
          ).createShader(bounds),
          child: Text(
            widget.text,
            style: widget.style.copyWith(color: Colors.white),
          ),
        );
      },
    );
  }
}

class LightPatternPainter extends CustomPainter {
  final Color color;
  final int seed;

  LightPatternPainter({required this.color, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Gambar pola dot ringan
    const int dotCount = 30;
    for (int i = 0; i < dotCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      canvas.drawCircle(
        Offset(x, y),
        random.nextDouble() * 1.5 + 0.5,
        paint,
      );
    }

    // Gambar garis dekoratif ringan
    for (int i = 0; i < 3; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final endX = startX + (random.nextDouble() - 0.5) * 30;
      final endY = startY + (random.nextDouble() - 0.5) * 30;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter untuk partikel bintang
class StarPainter extends CustomPainter {
  final Color color;

  StarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;

    final path = Path();

    for (int i = 0; i < 5; i++) {
      final double outerAngle = i * math.pi * 2 / 5 - math.pi / 2;
      final double innerAngle = outerAngle + math.pi / 5;

      final double outerX = centerX + radius * math.cos(outerAngle);
      final double outerY = centerY + radius * math.sin(outerAngle);

      final double innerX = centerX + radius * 0.4 * math.cos(innerAngle);
      final double innerY = centerY + radius * 0.4 * math.sin(innerAngle);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }

      path.lineTo(innerX, innerY);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
