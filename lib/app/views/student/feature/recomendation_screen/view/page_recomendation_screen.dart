import 'dart:convert';
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
import 'package:forward_chaining_man_app/app/views/student/model/data_student.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart' as intl;

import 'package:url_launcher/url_launcher.dart';

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
    extends State<RecommendationResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _formatProgramName(String name) {
    return name
        .split('_')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = widget.result.recommendations;

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
              _buildAppBar(context),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeInAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: recommendations.isEmpty
                        ? _buildEmptyState()
                        : _buildResultContent(recommendations),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Hasil Rekomendasi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Berbagi hasil akan segera tersedia')),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.share_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Rekomendasi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Silakan lengkapi kuisioner minat dan bakat untuk mendapatkan rekomendasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade900,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Mulai Kuisioner',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent(List<RecommendationItem> recommendations) {
    return Column(
      children: [
        _buildScoreIndicator(recommendations),
        const SizedBox(height: 16),
        _buildPageIndicator(recommendations.length),
        const SizedBox(height: 8),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              return _buildRecommendationCard(recommendations[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScoreIndicator(List<RecommendationItem> recommendations) {
    // Create a list of score items for the bar chart
    final items = recommendations.take(5).toList();
    final maxScore = items.map((e) => e.score).reduce(math.max);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kesesuaian Dengan Minat & Bakat Kamu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Geser kartu untuk melihat detail rekomendasi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxScore.toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < items.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _formatProgramName(items[index].title)
                                    .split(' ')
                                    .first,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final color = index == _currentIndex
                        ? Colors.amber.shade300
                        : Colors.white.withOpacity(0.7);

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: item.score.toDouble(),
                          color: color,
                          width: 18,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxScore.toDouble(),
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                swapAnimationDuration: const Duration(milliseconds: 300),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int length) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentIndex == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentIndex == index
                ? Colors.white
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(RecommendationItem item) {
    final friendlyExplanations = item.rules.map((rule) {
      // Clean up the rule text first
      String cleanedRule = rule.trim();

      // Try different patterns to extract questions
      String question = "";

      // Pattern for finding quoted text that looks like a question
      final pattern = RegExp(r'["""]([^"""]+)["""]');
      final match = pattern.firstMatch(cleanedRule);

      if (match != null && match.group(1) != null) {
        question = match.group(1)!.trim();
      } else {
        // If no match found, use a generic placeholder
        question = "terkait minat ini";
      }

      // Create a friendly explanation
      return "Kamu menjawab \"Ya\" untuk pertanyaan \"$question\" yang menunjukkan ketertarikan pada bidang ${_formatProgramName(item.title)}";
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildScoreCard(item),
          const SizedBox(height: 16),
          _buildDetailCard(item, friendlyExplanations),
          const SizedBox(height: 16),
          if (item.careers.isNotEmpty) _buildCareersCard(item),
          if (item.careers.isNotEmpty) const SizedBox(height: 16),
          if (item.majors.isNotEmpty) _buildMajorsCard(item),
          if (item.majors.isNotEmpty) const SizedBox(height: 16),
          if (item.recommendedCourses != null &&
              item.recommendedCourses!.isNotEmpty)
            _buildCoursesCard(item),
          if (item.recommendedCourses != null &&
              item.recommendedCourses!.isNotEmpty)
            const SizedBox(height: 16),
          if (item.recommendedUniversities != null &&
              item.recommendedUniversities!.isNotEmpty)
            _buildUniversitiesCard(item),
          if (item.recommendedUniversities != null &&
              item.recommendedUniversities!.isNotEmpty)
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildScoreCard(RecommendationItem item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              _formatProgramName(item.title),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularScoreIndicator(item.score),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getScoreText(item.score),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(item.score),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getScoreDescription(item.score),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularScoreIndicator(int score) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 80,
              width: 80,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    AlwaysStoppedAnimation<Color>(_getScoreColor(score)),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(value * 100).toInt()}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                Text(
                  'skor',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _getScoreText(int score) {
    if (score >= 90) return 'Sangat Cocok';
    if (score >= 75) return 'Cocok';
    if (score >= 60) return 'Cukup Cocok';
    if (score >= 45) return 'Kurang Cocok';
    return 'Tidak Cocok';
  }

  String _getScoreDescription(int score) {
    if (score >= 90) {
      return 'Rekomendasi terbaik berdasarkan minat dan bakatmu';
    }
    if (score >= 75) {
      return 'Potensi keberhasilan tinggi di bidang ini';
    }
    if (score >= 60) {
      return 'Ada beberapa kecocokan dengan minatmu';
    }
    if (score >= 45) {
      return 'Mungkin bukan pilihan utama untukmu';
    }
    return 'Pertimbangkan opsi lain yang lebih sesuai';
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green.shade600;
    if (score >= 75) return Colors.teal.shade600;
    if (score >= 60) return Colors.blue.shade600;
    if (score >= 45) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  Widget _buildDetailCard(RecommendationItem item, List<String> explanations) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Mengapa Ini Direkomendasikan',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.blue.shade900,
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
              'Alasan utama (${explanations.length} faktor):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ...explanations.asMap().entries.map((entry) {
              final index = entry.key;
              final explanation = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      height: 18,
                      width: 18,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        explanation,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCareersCard(RecommendationItem item) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.work_outline_rounded,
                    color: Colors.indigo.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Prospek Karir',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.indigo.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.careers.map((career) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Text(
                    career,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMajorsCard(RecommendationItem item) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.school_outlined,
                    color: Colors.purple.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Jurusan yang Disarankan',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.purple.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.majors.map((major) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade100),
                  ),
                  child: Text(
                    major,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.purple.shade700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesCard(RecommendationItem item) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: Colors.teal.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Mata Pelajaran Penunjang',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.teal.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...item.recommendedCourses!.map((course) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Colors.teal.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      course,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUniversitiesCard(RecommendationItem item) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: Colors.amber.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Universitas Terkait',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.recommendedUniversities!.map((university) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade100),
                  ),
                  child: Text(
                    university,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailRecommendationScreen extends StatelessWidget {
  final RecommendationItem item;

  const DetailRecommendationScreen({required this.item, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parsing title
    final parts = item.title.split('-');
    String program = parts[0].trim();
    String concentration = parts.length > 1 ? parts[1].trim() : '';

    // Further clean up if needed
    if (program.contains('|')) {
      final subParts = program.split('|');
      program = subParts[0].trim();
      if (concentration.isEmpty && subParts.length > 1) {
        concentration = subParts[1].trim();
      }
    }

    // Warna berdasarkan peringkat
    final medalColors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];

    final medalColor = item.index < medalColors.length
        ? medalColors[item.index]
        : Colors.blue.shade300;

    final isTopRecommendation = item.index == 0;

    // Check if we have course or university recommendations
    final hasCourses =
        item.recommendedCourses != null && item.recommendedCourses!.isNotEmpty;
    final hasUniversities = item.recommendedUniversities != null &&
        item.recommendedUniversities!.isNotEmpty;

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
                      'Detail Rekomendasi',
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

              // Header with rank and title
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Medal/Ranking indicator
                    Container(
                      width: 60,
                      height: 60,
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${item.index + 1}',
                              style: TextStyle(
                                color: medalColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              'Terbaik',
                              style: TextStyle(
                                color: medalColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            program,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Skor: ${item.score}',
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
                  ],
                ),
              ),

              // Scrollable content
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Explanation Section
                        _buildExplanationSection(item),
                        const SizedBox(height: 24),

                        // Careers section
                        if (item.careers.isNotEmpty) ...[
                          _buildSectionTitle('Karir yang Cocok:', Icons.work),
                          const SizedBox(height: 12),
                          _buildDetailedItemsList(item.careers,
                              Icons.work_outline, Colors.blue.shade700),
                          const SizedBox(height: 24),
                        ],

                        // Majors section
                        if (item.majors.isNotEmpty) ...[
                          _buildSectionTitle('Jurusan Terkait:', Icons.school),
                          const SizedBox(height: 12),
                          _buildDetailedItemsList(item.majors,
                              Icons.school_outlined, Colors.purple.shade700),
                          const SizedBox(height: 24),
                        ],

                        // Recommended Courses section
                        if (hasCourses) ...[
                          _buildSectionTitle(
                              'Kursus yang Direkomendasikan:', Icons.book),
                          const SizedBox(height: 12),
                          _buildDetailedItemsList(item.recommendedCourses!,
                              Icons.book_outlined, Colors.teal.shade700),
                          const SizedBox(height: 24),
                        ],

                        // Recommended Universities section
                        if (hasUniversities) ...[
                          _buildSectionTitle(
                              'Universitas yang Direkomendasikan:',
                              Icons.account_balance),
                          const SizedBox(height: 12),
                          _buildDetailedItemsList(
                              item.recommendedUniversities!,
                              Icons.account_balance_outlined,
                              Colors.amber.shade700),
                          const SizedBox(height: 24),
                        ],

                        // Rules section
                        if (item.rules.isNotEmpty) ...[
                          _buildSectionTitle(
                              'Detail Analisis:', Icons.psychology),
                          const SizedBox(height: 12),
                          _buildRulesList(item.rules),
                          const SizedBox(height: 24),
                        ],
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

  // Widget untuk judul section
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
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  // Widget untuk daftar item detail
  Widget _buildDetailedItemsList(
      List<String> items, IconData icon, Color color) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  items[index],
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget untuk daftar rules
  Widget _buildRulesList(List<String> rules) {
    return Container(
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
        children: rules.map((rule) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Widget untuk section penjelasan
  Widget _buildExplanationSection(RecommendationItem item) {
    // Process rules into friendly explanations
    final friendlyExplanations = item.rules.map((rule) {
      // Clean up the rule text first
      String cleanedRule = rule.trim();

      // Try different patterns to extract questions
      String question = "";

      // Pattern for finding quoted text that looks like a question
      final pattern = RegExp(r'["""]([^"""]+)["""]');
      final match = pattern.firstMatch(cleanedRule);

      if (match != null && match.group(1) != null) {
        question = match.group(1)!.trim();
      } else {
        // If no match found, use a generic placeholder
        question = "terkait minat ini";
      }

      // Create a friendly explanation
      return "Kamu menjawab \"Ya\" untuk pertanyaan \"$question\" yang menunjukkan ketertarikan pada bidang ${_formatProgramName(item.title)}";
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

          // Daftar penjelasan
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: friendlyExplanations.length,
            itemBuilder: (context, index) {
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
                        friendlyExplanations[index],
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
            },
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

  // Helper method untuk memformat nama program
  String _formatProgramName(String title) {
    final parts = title.split('-');
    if (parts.length > 1) {
      final program = parts[0].trim();
      final concentration = parts[1].trim();

      if (program.contains('|')) {
        final subParts = program.split('|');
        if (subParts.length > 1) {
          return "${subParts[1].trim()} di bidang ${subParts[0].trim()}";
        }
        return "$concentration di bidang ${subParts[0].trim()}";
      }

      return "$concentration di bidang $program";
    }

    if (title.contains('|')) {
      final subParts = title.split('|');
      if (subParts.length > 1) {
        return "${subParts[1].trim()} di bidang ${subParts[0].trim()}";
      }
    }

    return title;
  }
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

class _RecommendationCardState extends State<RecommendationCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

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
    final parts = widget.item.title.split('-');
    String program = parts[0].trim();
    String concentration = parts.length > 1 ? parts[1].trim() : '';

    // Further clean up if needed
    if (program.contains('|')) {
      final subParts = program.split('|');
      program = subParts[0].trim();
      if (concentration.isEmpty && subParts.length > 1) {
        concentration = subParts[1].trim();
      }
    }

    // Check if this is the top recommendation
    final isTopRecommendation = widget.item.index == 0;

    // Check if we have course or university recommendations
    final hasCourses = widget.item.recommendedCourses != null &&
        widget.item.recommendedCourses!.isNotEmpty;
    final hasUniversities = widget.item.recommendedUniversities != null &&
        widget.item.recommendedUniversities!.isNotEmpty;

    return Hero(
      tag: 'recommendation_${widget.item.index}',
      child: Container(
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
            onTap: _toggleExpanded,
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
                        RotationTransition(
                          turns: _iconTurns,
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey.shade600,
                            size: 18,
                          ),
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
                          _buildItemsList(widget.item.careers,
                              Colors.blue.shade50, Colors.blue.shade700),
                          const SizedBox(height: 20),
                        ],

                        // Majors section
                        if (widget.item.majors.isNotEmpty) ...[
                          _buildSectionTitle('Jurusan Terkait:', Icons.school),
                          const SizedBox(height: 12),
                          _buildItemsList(widget.item.majors,
                              Colors.purple.shade50, Colors.purple.shade700),
                          const SizedBox(height: 20),
                        ],

                        // New section for Recommended Courses
                        if (hasCourses) ...[
                          _buildSectionTitle(
                              'Kursus yang Direkomendasikan:', Icons.book),
                          const SizedBox(height: 12),
                          _buildItemsList(widget.item.recommendedCourses!,
                              Colors.teal.shade50, Colors.teal.shade700),
                          const SizedBox(height: 20),
                        ],

                        // New section for Recommended Universities
                        if (hasUniversities) ...[
                          _buildSectionTitle(
                              'Universitas yang Direkomendasikan:',
                              Icons.account_balance),
                          const SizedBox(height: 12),
                          _buildItemsList(widget.item.recommendedUniversities!,
                              Colors.amber.shade50, Colors.amber.shade700),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                              onPressed: _toggleExpanded,
                              icon: RotationTransition(
                                turns: _iconTurns,
                                child: const Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 18,
                                ),
                              ),
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
      ),
    );
  }

// Fungsi untuk membuat judul seksi dengan ikon
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

// Fungsi untuk membuat daftar item dengan warna yang dapat disesuaikan
  Widget _buildItemsList(List<String> items, Color bgColor, Color iconColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.3),
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
                color: bgColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIconForItem(item),
                  size: 14,
                  color: iconColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

// Fungsi helper untuk mendapatkan ikon yang sesuai berdasarkan konten item
  IconData _getIconForItem(String item) {
    final itemLower = item.toLowerCase();

    if (itemLower.contains('universitas') ||
        itemLower.contains('institut') ||
        itemLower.contains('politeknik')) {
      return Icons.account_balance;
    } else if (itemLower.contains('sertifikasi') ||
        itemLower.contains('kursus') ||
        itemLower.contains('pelatihan')) {
      return Icons.school;
    } else if (itemLower.contains('insinyur') ||
        itemLower.contains('engineer') ||
        itemLower.contains('teknisi')) {
      return Icons.engineering;
    } else if (itemLower.contains('teknik') || itemLower.contains('ilmu')) {
      return Icons.science;
    } else if (itemLower.contains('dokter') || itemLower.contains('medis')) {
      return Icons.medical_services;
    } else if (itemLower.contains('konsultan') ||
        itemLower.contains('manager')) {
      return Icons.business;
    } else if (itemLower.contains('developer') ||
        itemLower.contains('programmer')) {
      return Icons.code;
    }

    return Icons.check_circle_outline;
  }

// Helper method untuk memformat nama program agar lebih mudah dibaca
  String _formatProgramName(String title) {
    // Penanganan format "Program - Konsentrasi"
    final parts = title.split('-');
    if (parts.length > 1) {
      final program = parts[0].trim();
      final concentration = parts[1].trim();

      // Penanganan tambahan jika program berisi format "Program|Konsentrasi"
      if (program.contains('|')) {
        final subParts = program.split('|');
        // Jika kedua bagian tersedia, format sebagai "Konsentrasi di bidang Program"
        if (subParts.length > 1) {
          return "${subParts[1].trim()} di bidang ${subParts[0].trim()}";
        }
        // Jika hanya ada program, gunakan konsentrasi dari bagian kedua title
        return "$concentration di bidang ${subParts[0].trim()}";
      }

      // Format standar "Konsentrasi di bidang Program"
      return "$concentration di bidang $program";
    }

    // Penanganan format "Program|Konsentrasi" tanpa pemisah dash
    if (title.contains('|')) {
      final subParts = title.split('|');
      if (subParts.length > 1) {
        return "${subParts[1].trim()} di bidang ${subParts[0].trim()}";
      }
    }

    // Kembalikan title asli jika tidak ada pola yang cocok
    return title;
  }

// Helper method untuk membuat item-item penjelasan
  List<Widget> _buildExplanationItems(List<String> explanations) {
    return explanations.asMap().entries.map((entry) {
      final index = entry.key;
      final explanation = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nomor dalam lingkaran
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
            // Teks penjelasan
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

  // New method to build the explanation section
  Widget _buildExplanationSection(RecommendationItem item) {
    // Process rules into friendly explanations
    final friendlyExplanations = item.rules.map((rule) {
      // Clean up the rule text first
      String cleanedRule = rule.trim();

      // Try different patterns to extract questions
      String question = "";

      // Pattern for finding quoted text that looks like a question
      final pattern = RegExp(r'["""]([^"""]+)["""]');
      final match = pattern.firstMatch(cleanedRule);

      if (match != null && match.group(1) != null) {
        question = match.group(1)!.trim();
      } else {
        // If no match found, use a generic placeholder
        question = "terkait minat ini";
      }

      // Create a friendly explanation
      return "Kamu menjawab \"Ya\" untuk pertanyaan \"$question\" yang menunjukkan ketertarikan pada bidang ${_formatProgramName(item.title)}";
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
}
