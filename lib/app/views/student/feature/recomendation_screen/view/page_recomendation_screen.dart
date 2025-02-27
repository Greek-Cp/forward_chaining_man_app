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
import 'package:forward_chaining_man_app/app/views/student/model/data_student.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart' as intl;

import 'package:url_launcher/url_launcher.dart';

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

  // Widget untuk tampilan card kompak yang dapat diklik
  Widget _buildCompactRecommendationCard(
      BuildContext context, RecommendationItem item) {
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

    return GestureDetector(
      onTap: () {
        _showDetailRecommendation(context, item);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isTopRecommendation
                  ? Colors.amber.shade200.withOpacity(0.5)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
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
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
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
                          '${item.index + 1}',
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
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            program,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
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
                            '${item.score}',
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

              // Preview content
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview karir
                    if (item.careers.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 18,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Karir: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.careers.take(2).join(', ') +
                                  (item.careers.length > 2 ? ', ...' : ''),
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
                      const SizedBox(height: 8),
                    ],

                    // Preview jurusan
                    if (item.majors.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 18,
                            color: Colors.purple.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Jurusan: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.majors.take(2).join(', ') +
                                  (item.majors.length > 2 ? ', ...' : ''),
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
                      const SizedBox(height: 8),
                    ],

                    // Tampilkan tombol lihat detail
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showDetailRecommendation(context, item);
                          },
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('Lihat Detail Lengkap'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isTopRecommendation
                                ? Colors.amber.shade500
                                : Colors.blue.shade500,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }

  // Fungsi untuk menampilkan detail rekomendasi dalam fullscreen scrollable view
  void _showDetailRecommendation(
      BuildContext context, RecommendationItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailRecommendationScreen(item: item),
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
