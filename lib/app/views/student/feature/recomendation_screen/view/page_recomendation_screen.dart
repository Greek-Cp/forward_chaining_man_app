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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class RecommendationResultsScreen extends StatelessWidget {
  final RecommendationResult result;
  final String rawMessage;

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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 180,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Hasil Rekomendasi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.blue.shade900.withOpacity(0.8),
                            Colors.indigo.shade800.withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -50,
                            top: -50,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ),
                          Positioned(
                            left: -30,
                            bottom: -30,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ),
                          Center(
                            child: Icon(
                              Icons.emoji_events_rounded,
                              size: 60,
                              color: Colors.amber.shade300,
                            )
                                .animate(
                                    onPlay: (controller) => controller.repeat())
                                .shimmer(
                                    duration: const Duration(seconds: 2),
                                    color: Colors.white)
                                .animate()
                                .scale(
                                  duration: const Duration(seconds: 2),
                                  curve: Curves.easeInOut,
                                  begin: const Offset(1, 1),
                                  end: const Offset(1.05, 1.05),
                                )
                                .then()
                                .scale(
                                  duration: const Duration(seconds: 2),
                                  curve: Curves.easeInOut,
                                  begin: const Offset(1.05, 1.05),
                                  end: const Offset(1, 1),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon:
                          const Icon(Icons.share_rounded, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded,
                          color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildScoreCard(context),
                        const SizedBox(height: 24),
                        _buildTopRecommendations(context),
                        const SizedBox(height: 24),
                        _buildRiasecProfile(context, result),
                        const SizedBox(height: 24),
                        _buildCareerPathways(context),
                        const SizedBox(height: 24),
                        _buildSkillDistributionChart(context),
                        const SizedBox(height: 24),
                        _buildRecommendedCourses(context),
                        const SizedBox(height: 24),
                        _buildRecommendedUniversities(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.amber.shade400,
          onPressed: () {},
          child: const Icon(Icons.chat_bubble_outline_rounded,
              color: Colors.white),
        ).animate(onPlay: (controller) => controller.repeat()));
  }

  String _getRiasecFullName(String code) {
    switch (code) {
      case 'R':
        return 'Realistic';
      case 'I':
        return 'Investigative';
      case 'A':
        return 'Artistic';
      case 'S':
        return 'Social';
      case 'E':
        return 'Enterprising';
      case 'C':
        return 'Conventional';
      default:
        return code;
    }
  }

  Widget _buildRiasecProfile(
      BuildContext context, RecommendationResult result) {
    // Jika tidak ada profil RIASEC, return widget kosong
    if (result.riasecProfile == null) {
      return const SizedBox.shrink();
    }

    final riasecProfile = result.riasecProfile!;

    // Tentukan warna untuk setiap tipe RIASEC
    final riasecColors = {
      'R': Colors.blue.shade700, // Realistic
      'I': Colors.purple.shade700, // Investigative
      'A': Colors.red.shade700, // Artistic
      'S': Colors.green.shade700, // Social
      'E': Colors.amber.shade700, // Enterprising
      'C': Colors.teal.shade700, // Conventional
    };

    // Deskripsi setiap tipe RIASEC
    final riasecDescriptions = {
      'R': 'Praktis, menyukai bekerja dengan alat, mesin, dan objek nyata.',
      'I': 'Analitis, menyukai pemecahan masalah dan penelitian.',
      'A': 'Kreatif, menyukai ekspresi diri melalui seni dan desain.',
      'S': 'Membantu, menyukai bekerja dengan orang dan mendukung orang lain.',
      'E': 'Persuasif, menyukai memimpin dan mempengaruhi orang lain.',
      'C':
          'Terorganisir, menyukai bekerja dengan data dan detail yang terstruktur.'
    };

    final sortedScores = riasecProfile.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil RIASEC Kamu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 8,
          shadowColor: Colors.black38,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: Colors.indigo.shade800,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kode RIASEC Kamu',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            riasecProfile.code,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Deskripsi kode RIASEC
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Apa itu RIASEC?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RIASEC adalah model yang mengklasifikasikan minat dan kepribadian karir ke dalam 6 tipe: Realistic (R), Investigative (I), Artistic (A), Social (S), Enterprising (E), dan Conventional (C). Tipe dominanmu adalah kombinasi dari tipe-tipe teratas.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'Tipe Dominan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                  ),
                ),
                const SizedBox(height: 12),

                // Tipe dominan dengan deskripsi
                ...riasecProfile.dominantTypes.map((type) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: riasecColors[type] ?? Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    riasecColors[type] ?? Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _getRiasecFullName(type),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${type})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    riasecColors[type] ?? Colors.grey.shade700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Skor: ${riasecProfile.scores[type] ?? 0}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          riasecDescriptions[type] ?? 'Tidak ada deskripsi',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 20),

                // Bar chart untuk semua skor RIASEC
                Container(
                  height: 230,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distribusi Skor RIASEC',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: sortedScores.isNotEmpty
                                ? (sortedScores[0].value * 1.2).toDouble()
                                : 10,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  final riasecType =
                                      sortedScores[groupIndex].key;
                                  return BarTooltipItem(
                                    '${_getRiasecFullName(riasecType)}\n',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            '${sortedScores[groupIndex].value}',
                                        style: const TextStyle(
                                          color: Colors.amber,
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
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                    final index = value.toInt();
                                    if (index >= 0 &&
                                        index < sortedScores.length) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          sortedScores[index].key,
                                          style: TextStyle(
                                            color: riasecColors[
                                                    sortedScores[index].key] ??
                                                Colors.grey.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        value.toInt().toString(),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  },
                                  reservedSize: 40,
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: false,
                            ),
                            barGroups: List.generate(
                              sortedScores.length,
                              (index) => BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: sortedScores[index].value.toDouble(),
                                    color:
                                        riasecColors[sortedScores[index].key] ??
                                            Colors.grey.shade700,
                                    width: 20,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(6),
                                      topRight: Radius.circular(6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey.shade200,
                                strokeWidth: 1,
                              ),
                            ),
                          ),
                          swapAnimationDuration:
                              const Duration(milliseconds: 1500),
                        ),
                      ),
                    ],
                  ),
                ),

                // Karir yang cocok dengan RIASEC
                if (riasecProfile.matchingCareers.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Karir yang Cocok dengan Profil RIASEC',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Career items with icons
                        ...riasecProfile.matchingCareers.map((career) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    career,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade800,
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
                ],
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 300))
            .slideY(begin: 0.2, end: 0),
      ],
    );
  }

// Fungsi untuk menampilkan kesesuaian RIASEC dalam detail rekomendasi
  Widget _buildRiasecCompatibility(RecommendationItem item) {
    // Jika tidak ada data kesesuaian RIASEC, return widget kosong
    if (item.riasecCompatibility == null ||
        item.matchingRiasecCareers == null ||
        item.matchingRiasecCareers!.isEmpty) {
      return const SizedBox.shrink();
    }

    final compatibility = item.riasecCompatibility!;
    final matchingCareers = item.matchingRiasecCareers!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionTitle('Kesesuaian RIASEC:', Icons.psychology),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Circular progress indicator untuk persentase kesesuaian
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      children: [
                        CircularProgressIndicator(
                          value: compatibility / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            compatibility >= 70
                                ? Colors.green.shade600
                                : compatibility >= 40
                                    ? Colors.amber.shade600
                                    : Colors.red.shade600,
                          ),
                        ),
                        Center(
                          child: Text(
                            '${compatibility.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kesesuaian dengan Profil RIASEC',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          compatibility >= 70
                              ? 'Sangat sesuai dengan kepribadian karir kamu'
                              : compatibility >= 40
                                  ? 'Cukup sesuai dengan kepribadian karir kamu'
                                  : 'Kurang sesuai dengan kepribadian karir kamu',
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
              if (matchingCareers.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Karir yang Cocok dengan Profil RIASEC Kamu:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: matchingCareers.map((career) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.purple.shade300,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.shade200.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.purple.shade700,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              career,
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
              ],
            ],
          ),
        ),
      ],
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

  Widget _buildScoreCard(BuildContext context) {
    // Get the top recommendation
    final topRecommendation =
        result.recommendations.isNotEmpty ? result.recommendations[0] : null;

    if (topRecommendation == null) return const SizedBox.shrink();

    return Card(
      elevation: 8,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.indigo.shade800,
                    size: 28,
                  ),
                )
                    .animate()
                    .fadeIn(
                      duration: Duration(milliseconds: 500),
                    )
                    .scale(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rekomendasi Terbaik',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatProgramName(topRecommendation.title),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildScoreIndicator(topRecommendation.score),
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.grey.shade200,
                ),
                _buildMatchStats(topRecommendation),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: const Duration(milliseconds: 300))
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildScoreIndicator(int score) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.indigo.shade200,
                    Colors.indigo.shade100,
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  score >= 80
                      ? Colors.green.shade700
                      : score >= 60
                          ? Colors.amber.shade700
                          : Colors.red.shade700,
                ),
              ),
            ).animate().custom(
                  duration: Duration(seconds: 1, milliseconds: 500),
                  builder: (context, value, child) {
                    return SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: score / 100 * value,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          score >= 80
                              ? Colors.green.shade700
                              : score >= 60
                                  ? Colors.amber.shade700
                                  : Colors.red.shade700,
                        ),
                      ),
                    );
                  },
                ),
            Text(
              '$score%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Match Score',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchStats(RecommendationItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
            const SizedBox(width: 8),
            Text(
              '${item.rules.length} faktor kecocokan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.lightbulb_outline,
                color: Colors.amber.shade700, size: 18),
            const SizedBox(width: 8),
            Text(
              '${item.careers.length} jalur karir',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.school_outlined,
                color: Colors.indigo.shade700, size: 18),
            const SizedBox(width: 8),
            Text(
              '${item.majors.length} jurusan kuliah',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopRecommendations(BuildContext context) {
    // Track which recommendation is selected for detailed view
    final selectedRecommendationIndex = ValueNotifier<int?>(-1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rekomendasi Utama',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade900, Colors.indigo.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.dashboard_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                label: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: Colors.amber.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Recommendations cards
        // Recommendations cards
        SizedBox(
          height: 250, // Increased height to prevent overflow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: math.min(result.recommendations.length, 5),
            itemBuilder: (context, index) {
              final item = result.recommendations[index];
              final rank = index + 1;
              final rankDescription = _getRankDescription(rank);

              // Define custom gradient based on rank
              final List<Color> cardGradient = rank == 1
                  ? [
                      Colors.amber.shade50,
                      Colors.amber.shade100,
                      Color(0xFFFFF8E1)
                    ]
                  : rank == 2
                      ? [
                          Colors.indigo.shade50,
                          Colors.indigo.shade100,
                          Color(0xFFE8EAF6)
                        ]
                      : rank == 3
                          ? [
                              Colors.blue.shade50,
                              Colors.blue.shade100,
                              Color(0xFFE3F2FD)
                            ]
                          : [
                              Colors.grey.shade50,
                              Colors.grey.shade100,
                              Color(0xFFF5F5F5)
                            ];

              return GestureDetector(
                onTap: () {
                  _showRecommendationBottomSheet(context, item, rank);
                },
                child: Container(
                  width: 250,
                  margin: const EdgeInsets.only(right: 16),
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.black38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: cardGradient,
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: rank == 1
                                ? Colors.amber.shade200.withOpacity(0.3)
                                : rank == 2
                                    ? Colors.indigo.shade200.withOpacity(0.3)
                                    : rank == 3
                                        ? Colors.blue.shade200.withOpacity(0.3)
                                        : Colors.grey.shade200.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: -4,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row with rank badge and score indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Rank badge with enhanced design
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: rank == 1
                                        ? [
                                            Colors.amber.shade200,
                                            Colors.amber.shade300,
                                          ]
                                        : rank == 2
                                            ? [
                                                Colors.indigo.shade200,
                                                Colors.indigo.shade300,
                                              ]
                                            : rank == 3
                                                ? [
                                                    Colors.blue.shade200,
                                                    Colors.blue.shade300,
                                                  ]
                                                : [
                                                    Colors.grey.shade200,
                                                    Colors.grey.shade300,
                                                  ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    rank == 1
                                        ? Icon(
                                            Icons.emoji_events_rounded,
                                            size: 16,
                                            color: Colors.amber.shade800,
                                          )
                                        : rank == 2
                                            ? Icon(
                                                Icons.star_rounded,
                                                size: 16,
                                                color: Colors.indigo.shade800,
                                              )
                                            : rank == 3
                                                ? Icon(
                                                    Icons
                                                        .workspace_premium_rounded,
                                                    size: 16,
                                                    color: Colors.blue.shade800,
                                                  )
                                                : const SizedBox.shrink(),
                                    rank <= 3
                                        ? const SizedBox(width: 4)
                                        : const SizedBox.shrink(),
                                    Text(
                                      rankDescription,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: rank == 1
                                            ? Colors.amber.shade800
                                            : rank == 2
                                                ? Colors.indigo.shade800
                                                : rank == 3
                                                    ? Colors.blue.shade800
                                                    : Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Score indicator (if needed)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${item.score}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Program title with improved styling
                          Text(
                            _formatProgramName(item.title),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.indigo.shade900,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 10),

                          // Program majors with improved styling
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.school_outlined,
                                  size: 14,
                                  color: Colors.indigo.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.majors.isNotEmpty
                                      ? item.majors.first
                                      : 'Program Studi Terkait',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Add divider for visual separation
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Divider(
                              color: Colors.grey.shade200,
                              thickness: 1,
                            ),
                          ),

                          // Action button with improved styling
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade600,
                                      Colors.indigo.shade700,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.indigo.shade900
                                          .withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      _showRecommendationBottomSheet(
                                          context, item, rank);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    splashColor: Colors.white.withOpacity(0.1),
                                    highlightColor:
                                        Colors.white.withOpacity(0.05),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Lihat Detail',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
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
              )
                  .animate(
                      onPlay: (controller) => controller.repeat(reverse: true))
                  .shimmer(
                      duration: Duration(seconds: 3),
                      color: Colors.white.withOpacity(0.05))
                  .animate()
                  .fadeIn(
                      duration: Duration(milliseconds: 500),
                      delay: Duration(milliseconds: index * 150))
                  .slide(
                      begin: Offset(0.2, 0),
                      end: Offset.zero,
                      curve: Curves.easeOutQuart);
            },
          ),
        ),
      ],
    );
  }

// Helper method to get rank description
  String _getRankDescription(int rank) {
    switch (rank) {
      case 1:
        return 'Terbaik';
      case 2:
        return 'Kedua';
      case 3:
        return 'Ketiga';
      default:
        return 'Peringkat $rank';
    }
  }

  Widget _buildDetailLeftColumn(BuildContext context, RecommendationItem item,
      MaterialColor accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEnhancedDetailSection(
          context,
          'Program Studi Terkait',
          item.majors.isEmpty ? ['Program Studi Umum'] : item.majors,
          Icons.school_rounded,
          Colors.indigo,
          0,
        ),
        SizedBox(height: 20),
        _buildEnhancedDetailSection(
          context,
          'Prospek Karir',
          item.careers.isEmpty ? ['Beragam Karir'] : item.careers,
          Icons.work_rounded,
          Colors.blue,
          200,
        ),
      ],
    );
  }

  Widget _buildDetailRightColumn(BuildContext context, RecommendationItem item,
      MaterialColor accentColor) {
    final courses =
        item.recommendedCourses ?? ['Matematika', 'Fisika', 'Kimia', 'Biologi'];
    final universities = item.recommendedUniversities ??
        [
          'Universitas Indonesia',
          'Institut Teknologi Bandung',
          'Universitas Gadjah Mada'
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEnhancedDetailSection(
          context,
          'Mata Kuliah Unggulan',
          courses,
          Icons.book_rounded,
          Colors.green,
          0,
        ),
        SizedBox(height: 20),
        _buildEnhancedDetailSection(
          context,
          'Universitas Terkemuka',
          universities,
          Icons.account_balance_rounded,
          Colors.amber,
          200,
        ),
      ],
    );
  }

// Enhanced detail section with animations using FutureBuilder for delay
  Widget _buildEnhancedDetailSection(BuildContext context, String title,
      List<String> items, IconData icon, MaterialColor color, int delayMs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with animated icon using FutureBuilder
        FutureBuilder(
          future: Future.delayed(Duration(milliseconds: delayMs)),
          builder: (context, headerSnapshot) {
            final double headerValue =
                headerSnapshot.connectionState == ConnectionState.done
                    ? 1.0
                    : 0.0;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: headerValue),
              duration: Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Opacity(
                  opacity: value,
                  child: Row(
                    children: [
                      // Icon with scale animation
                      FutureBuilder(
                        future: Future.delayed(
                            Duration(milliseconds: delayMs + 200)),
                        builder: (context, iconSnapshot) {
                          final double iconValue =
                              iconSnapshot.connectionState ==
                                      ConnectionState.done
                                  ? 1.0
                                  : 0.0;

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: iconValue),
                            duration: Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            builder: (context, scaleValue, _) {
                              return Transform.scale(
                                scale: scaleValue,
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        color.shade50,
                                        color.shade100,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: -5,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 22,
                                    color: color.shade700,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      SizedBox(width: 14),
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [
                              color.shade800,
                              color.shade500,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds);
                        },
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),

        SizedBox(height: 15),

        // List items with staggered animations
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return FutureBuilder(
            future: Future.delayed(
                Duration(milliseconds: delayMs + 300 + (index * 100))),
            builder: (context, itemSnapshot) {
              final double itemValue =
                  itemSnapshot.connectionState == ConnectionState.done
                      ? 1.0
                      : 0.0;

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: itemValue),
                duration: Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(20 * (1 - value), 0),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 2),
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: color.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                size: 14,
                                color: color.shade700,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        }).toList(),
      ],
    );
  }

// Build a section in detail view
  Widget _buildDetailSection(
    String title,
    IconData icon,
    Color color, {
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

// Build detail item with icon
  Widget _buildDetailItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 8),
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
    );
  }

  void _showRecommendationBottomSheet(
      BuildContext context, RecommendationItem item, int rank) {
    // Define theme-specific colors
    final primaryGradient = [Colors.blue.shade700, Colors.indigo.shade800];
    final accentColor = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.indigo
            : rank == 3
                ? Colors.blue
                : Colors.grey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 400),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: CustomScrollView(
                      physics: BouncingScrollPhysics(),
                      controller: scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with shimmering effect and close button
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 600),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: Opacity(
                                        opacity: value,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            ShaderMask(
                                              shaderCallback: (bounds) {
                                                return LinearGradient(
                                                  colors: primaryGradient,
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ).createShader(bounds);
                                              },
                                              child: Text(
                                                'Detail Rekomendasi',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            TweenAnimationBuilder<double>(
                                              tween:
                                                  Tween(begin: 0.0, end: 1.0),
                                              duration:
                                                  Duration(milliseconds: 800),
                                              curve: Curves.elasticOut,
                                              builder: (context, value, child) {
                                                return Transform.rotate(
                                                  angle: (1 - value) * 1.5,
                                                  child: Transform.scale(
                                                    scale: value,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.1),
                                                            blurRadius: 8,
                                                            offset:
                                                                Offset(0, 3),
                                                          ),
                                                        ],
                                                      ),
                                                      child: IconButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        icon: Icon(
                                                          Icons.close_rounded,
                                                          color: Colors
                                                              .grey.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                SizedBox(height: 20),

                                // Program name with hover effect and shadow
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 700),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 30 * (1 - value)),
                                        child: Container(
                                          width: double.infinity,
                                          margin: EdgeInsets.only(bottom: 25),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: primaryGradient,
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.indigo.shade800
                                                    .withOpacity(0.4),
                                                blurRadius: 15,
                                                offset: Offset(0, 8),
                                                spreadRadius: -4,
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            children: [
                                              // Decorative elements
                                              ...List.generate(3, (index) {
                                                return Positioned(
                                                  right: 10 + (index * 20),
                                                  top: index * 10,
                                                  child: Opacity(
                                                    opacity: 0.1,
                                                    child: Icon(
                                                      Icons.school_rounded,
                                                      size: 24,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                );
                                              }),
                                              Center(
                                                child: Text(
                                                  _formatProgramName(
                                                      item.title),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                    letterSpacing: 0.5,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.black
                                                            .withOpacity(0.3),
                                                        blurRadius: 5,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // Badge with particle effects
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 30 * (1 - value)),
                                        child: Center(
                                          child: Container(
                                            margin: EdgeInsets.only(bottom: 25),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // Decorative shine effect - using Future.delayed approach
                                                ...List.generate(5, (index) {
                                                  return FutureBuilder(
                                                    future: Future.delayed(
                                                        Duration(
                                                            milliseconds: 1000 +
                                                                (index * 200))),
                                                    builder:
                                                        (context, snapshot) {
                                                      final isDelayComplete =
                                                          snapshot.connectionState ==
                                                              ConnectionState
                                                                  .done;
                                                      return Positioned(
                                                        left:
                                                            100 + (index * 10),
                                                        top: index * 3,
                                                        child: AnimatedOpacity(
                                                          duration: Duration(
                                                              milliseconds:
                                                                  500),
                                                          opacity:
                                                              isDelayComplete
                                                                  ? 0.2
                                                                  : 0,
                                                          child: Container(
                                                            width: 8,
                                                            height: 8,
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color: accentColor
                                                                  .shade300,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                }),

                                                // Actual badge
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 10),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        accentColor.shade100,
                                                        accentColor.shade200,
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: accentColor
                                                            .withOpacity(0.3),
                                                        blurRadius: 15,
                                                        spreadRadius: -2,
                                                        offset: Offset(0, 7),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      TweenAnimationBuilder<
                                                          double>(
                                                        tween: Tween(
                                                            begin: 0.0,
                                                            end: 1.0),
                                                        duration: Duration(
                                                            milliseconds: 1200),
                                                        curve:
                                                            Curves.elasticOut,
                                                        builder: (context,
                                                            value, child) {
                                                          return Transform
                                                              .scale(
                                                            scale: value,
                                                            child: rank <= 3
                                                                ? Icon(
                                                                    rank == 1
                                                                        ? Icons
                                                                            .emoji_events_rounded
                                                                        : rank ==
                                                                                2
                                                                            ? Icons.star_rounded
                                                                            : Icons.workspace_premium_rounded,
                                                                    size: 24,
                                                                    color: accentColor
                                                                        .shade800,
                                                                  )
                                                                : SizedBox
                                                                    .shrink(),
                                                          );
                                                        },
                                                      ),
                                                      rank <= 3
                                                          ? SizedBox(width: 12)
                                                          : SizedBox.shrink(),
                                                      Text(
                                                        _getRankDescription(
                                                            rank),
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                          color: accentColor
                                                              .shade800,
                                                          letterSpacing: 0.5,
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
                                    );
                                  },
                                ),

                                // Content sections with staggered animations
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth > 600) {
                                      // Two column layout for larger screens
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: _buildAnimatedDetailColumn(
                                              context,
                                              _buildDetailLeftColumn(
                                                  context, item, accentColor),
                                              100,
                                            ),
                                          ),
                                          SizedBox(width: 20),
                                          Expanded(
                                            child: _buildAnimatedDetailColumn(
                                              context,
                                              _buildDetailRightColumn(
                                                  context, item, accentColor),
                                              300,
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      // Single column layout for smaller screens
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildAnimatedDetailColumn(
                                            context,
                                            _buildDetailLeftColumn(
                                                context, item, accentColor),
                                            100,
                                          ),
                                          SizedBox(height: 20),
                                          _buildAnimatedDetailColumn(
                                            context,
                                            _buildDetailRightColumn(
                                                context, item, accentColor),
                                            300,
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                ),

                                // Animated action buttons
                                Padding(
                                  padding: EdgeInsets.only(top: 30, bottom: 20),
                                  child: Center(
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: Duration(milliseconds: 900),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(0, 40 * (1 - value)),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                _buildAnimatedActionButton(
                                                  'Lihat Kurikulum',
                                                  Icons.menu_book_rounded,
                                                  Colors.green.shade600,
                                                  () {},
                                                  800,
                                                ),
                                                SizedBox(width: 16),
                                                _buildAnimatedActionButton(
                                                  'Eksplorasi Karir',
                                                  Icons.trending_up_rounded,
                                                  Colors.amber.shade700,
                                                  () {},
                                                  1000,
                                                ),
                                              ],
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
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// Build action button
  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildCareerPathways(BuildContext context) {
    final topCareers = result.recommendations.isNotEmpty
        ? result.recommendations[0].careers
        : <String>[];

    if (topCareers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prospek Karir',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: math.min(topCareers.length, 4),
          itemBuilder: (context, index) {
            final iconList = [
              Icons.business_center_rounded,
              Icons.code_rounded,
              Icons.biotech_rounded,
              Icons.architecture_rounded,
            ];

            final icon =
                index < iconList.length ? iconList[index] : Icons.work_rounded;

            return Card(
              elevation: 4,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.blue.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.indigo.shade800,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        topCareers[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.indigo.shade900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: (150 * index).toInt()))
                .scaleXY(begin: 0.9, end: 1.0);
          },
        ),
      ],
    );
  }

  Widget _buildSkillDistributionChart(BuildContext context) {
    final topItem =
        result.recommendations.isNotEmpty ? result.recommendations[0] : null;

    if (topItem == null) return const SizedBox.shrink();

    // Generate sample data for the radar chart based on recommendation
    final List<double> skillValues = [
      topItem.score * 0.01,
      math.Random().nextDouble() * 0.6 +
          0.3, // Random value between 0.3 and 0.9
      math.Random().nextDouble() * 0.6 + 0.3,
      math.Random().nextDouble() * 0.6 + 0.3,
      math.Random().nextDouble() * 0.6 + 0.3,
    ];

    final List<String> skillLabels = [
      'Analytical',
      'Creative',
      'Technical',
      'Communication',
      'Leadership',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribusi Keterampilan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 6,
          shadowColor: Colors.black38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
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
            height: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Berdasarkan profil ${_formatProgramName(topItem.title)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: RadarChart(
                    RadarChartData(
                      dataSets: [
                        RadarDataSet(
                          dataEntries: List.generate(
                            skillValues.length,
                            (i) => RadarEntry(value: skillValues[i]),
                          ),
                          fillColor: Colors.blue.shade700.withOpacity(0.2),
                          borderColor: Colors.blue.shade700,
                          borderWidth: 2,
                        ),
                      ],
                      radarShape: RadarShape.polygon,
                      radarBorderData: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      tickCount: 5,
                      ticksTextStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                      gridBorderData: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                      titleTextStyle: TextStyle(
                        color: Colors.indigo.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      getTitle: (index, angle) {
                        // Return a RadarChartTitle object instead of just a string
                        return RadarChartTitle(
                          text: skillLabels[index],
                          angle: angle,
                        );
                      },
                      titlePositionPercentageOffset: 0.15,
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 1500),
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 400))
            .slideY(begin: 0.1, end: 0),
      ],
    );
  }

// Animated column wrapper using FutureBuilder for delay
  Widget _buildAnimatedDetailColumn(
      BuildContext context, Widget child, int delayMs) {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: delayMs)),
      builder: (context, snapshot) {
        final double animationValue =
            snapshot.connectionState == ConnectionState.done ? 1.0 : 0.0;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: animationValue),
          duration: Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 40 * (1 - value)),
                child: child,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnimatedActionButton(String text, IconData icon, Color color,
      VoidCallback onPressed, int delayMs) {
    return FutureBuilder(
        future: Future.delayed(Duration(milliseconds: delayMs)),
        builder: (context, snapshot) {
          final double animationValue =
              snapshot.connectionState == ConnectionState.done ? 1.0 : 0.0;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: animationValue),
            duration: Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        Color.lerp(color, Colors.black, 0.3)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPressed,
                      borderRadius: BorderRadius.circular(14),
                      splashColor: Colors.white.withOpacity(0.2),
                      highlightColor: Colors.white.withOpacity(0.1),
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 12),
                            Text(
                              text,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        });
  }

  Widget _buildRecommendedCourses(BuildContext context) {
    final topItem =
        result.recommendations.isNotEmpty ? result.recommendations[0] : null;

    if (topItem == null ||
        topItem.recommendedCourses == null ||
        topItem.recommendedCourses!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Check if majors list is not empty before accessing first element
    final majorText = topItem.majors.isNotEmpty
        ? 'Kelas prioritas untuk jurusan ${topItem.majors.first}'
        : 'Kelas prioritas untuk jurusan ini';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mata Pelajaran yang Direkomendasikan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: math.min(topItem.recommendedCourses!.length, 4),
          itemBuilder: (context, index) {
            // Make sure we don't go out of bounds
            if (index >= topItem.recommendedCourses!.length) {
              return const SizedBox.shrink();
            }

            final course = topItem.recommendedCourses![index];

            // Icons for different subjects
            final iconList = {
              'matematika': Icons.calculate_rounded,
              'fisika': Icons.science_rounded,
              'biologi': Icons.biotech_rounded,
              'kimia': Icons.science_rounded,
              'ekonomi': Icons.trending_up_rounded,
              'komputer': Icons.laptop_rounded,
              'bahasa': Icons.translate_rounded,
              'sejarah': Icons.history_edu_rounded,
            };

            // Find matching icon or use default
            IconData courseIcon = Icons.book_rounded;
            for (final entry in iconList.entries) {
              if (course.toLowerCase().contains(entry.key)) {
                courseIcon = entry.value;
                break;
              }
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 4,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        courseIcon,
                        color: Colors.indigo.shade800,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            majorText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.indigo.shade400,
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: (150 * index).toInt()))
                .slideX(begin: 0.05, end: 0);
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedUniversities(BuildContext context) {
    final topItem =
        result.recommendations.isNotEmpty ? result.recommendations[0] : null;

    if (topItem == null ||
        topItem.recommendedUniversities == null ||
        topItem.recommendedUniversities!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Universitas yang Direkomendasikan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: math.min(topItem.recommendedUniversities!.length, 5),
            itemBuilder: (context, index) {
              // Make sure we don't go out of bounds
              if (index >= topItem.recommendedUniversities!.length) {
                return const SizedBox.shrink();
              }

              final university = topItem.recommendedUniversities![index];

              return Container(
                width: 180,
                margin: const EdgeInsets.only(right: 16),
                child: Card(
                  elevation: 5,
                  shadowColor: Colors.black38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.shade800,
                          Colors.indigo.shade900,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          university,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: (150 * index).toInt()))
                  .slideY(begin: 0.2, end: 0);
            },
          ),
        ),
      ],
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

String _formatProgramName(String title) {
  // Capitalize each word and clean up the name
  final words = title.split(' ');

  // Map to capitalize first letter of each word
  final formattedWords = words.map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).toList();

  return formattedWords.join(' ');
}

// Widget for displaying the reasons why this recommendation matches
Widget _buildRecommendationDetails(
    BuildContext context, RecommendationItem item) {
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: friendlyExplanations.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      friendlyExplanations[index],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  );
}

// Widget for the bar chart to show comparison between different recommendation scores
Widget _buildComparisonChart(
    BuildContext context, List<RecommendationItem> recommendations) {
  // Only show top 5 recommendations for clarity
  final topRecommendations = recommendations.take(5).toList();

  return Card(
    elevation: 6,
    shadowColor: Colors.black38,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Container(
      padding: const EdgeInsets.all(20),
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
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perbandingan Skor Kesesuaian',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.indigo.shade900,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${topRecommendations[groupIndex].title}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.round()}%',
                            style: const TextStyle(
                              color: Colors.amber,
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
                      getTitlesWidget: (double value, TitleMeta meta) {
                        // Get abbreviated title for x-axis
                        final index = value.toInt();
                        if (index >= 0 && index < topRecommendations.length) {
                          final words =
                              topRecommendations[index].title.split(' ');
                          String abbr = '';
                          for (var word in words) {
                            if (word.isNotEmpty) {
                              abbr += word[0].toUpperCase();
                            }
                            if (abbr.length >= 3) break;
                          }

                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              abbr,
                              style: TextStyle(
                                color: Colors.indigo.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      interval: 20,
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: List.generate(
                  topRecommendations.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: topRecommendations[index].score.toDouble(),
                        color: index == 0
                            ? Colors.amber.shade700
                            : Colors.blue.shade600
                                .withOpacity(0.7 - (index * 0.1)),
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 1500),
            ),
          ),
        ],
      ),
    ),
  )
      .animate()
      .fadeIn(delay: Duration(milliseconds: 300))
      .slideY(begin: 0.1, end: 0);
}

// Widget for a pulsing button that draws attention
class PulsingButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const PulsingButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon).animate(onPlay: (controller) => controller.repeat()),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget for a custom progress indicator
class AnimatedProgressBar extends StatelessWidget {
  final double percentage;
  final String label;
  final Color color;

  const AnimatedProgressBar({
    Key? key,
    required this.percentage,
    required this.label,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ).animate().custom(
                duration: Duration(seconds: 1, milliseconds: 500),
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage * value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}
