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
