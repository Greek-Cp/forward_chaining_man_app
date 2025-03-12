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
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';

class _DetailTabController extends GetxController {
  // Current tab index (0: Recommendations, 1: Answers, 2: Rules)
  final RxInt currentTab = 0.obs;

  void setTab(int index) {
    currentTab.value = index;
  }
}

class RecommendationDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String documentId;

  const RecommendationDetailPage({
    Key? key,
    required this.data,
    required this.documentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract basic data
    final questionMode = data['questionMode'] ?? 'Tidak diketahui';
    final timestamp = data['timestamp'] as Timestamp?;
    final formattedDate = timestamp != null
        ? intl.DateFormat('dd MMMM yyyy, HH:mm').format(timestamp.toDate())
        : 'Tidak ada tanggal';
    final totalQuestions = data['totalQuestions'] ?? 0;
    final answeredQuestions = data['answeredQuestions'] ?? 0;

    // Controller for tab view
    final tabController = Get.put(_DetailTabController());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom app bar with gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    questionMode.contains('Karir')
                        ? Colors.blue.shade800
                        : Colors.blue.shade800,
                    Colors.indigo.shade900,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Top bar with back button and actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Get.back(),
                        ),
                        Expanded(
                          child: Text(
                            questionMode,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: () => _shareResults(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.white),
                          onPressed: () => _confirmDelete(context),
                        ),
                      ],
                    ),
                  ),

                  // Date and stats info
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date row
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white.withOpacity(0.7),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Stats cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.question_answer_rounded,
                                title: 'Pertanyaan',
                                value: '$answeredQuestions/$totalQuestions',
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.lightbulb_outline,
                                title: 'Rekomendasi',
                                value: (data['recommendations'] as List?)
                                        ?.length
                                        .toString() ??
                                    '0',
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tab bar
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Obx(() => Row(
                            children: [
                              _buildTabButton(
                                title: 'Rekomendasi',
                                isActive: tabController.currentTab.value == 0,
                                onTap: () => tabController.setTab(0),
                              ),
                              const SizedBox(width: 16),
                              _buildTabButton(
                                title: 'Jawaban',
                                isActive: tabController.currentTab.value == 1,
                                onTap: () => tabController.setTab(1),
                              ),
                              const SizedBox(width: 16),
                              _buildTabButton(
                                title: 'Rules',
                                isActive: tabController.currentTab.value == 2,
                                onTap: () => tabController.setTab(2),
                              ),
                            ],
                          )),
                    ),
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: Container(
                color: Colors.white,
                child: Obx(() {
                  switch (tabController.currentTab.value) {
                    case 0:
                      return _buildRecommendationsTab();
                    case 1:
                      return _buildAnswersTab();
                    case 2:
                      return _buildRulesTab();
                    default:
                      return _buildRecommendationsTab();
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.indigo.shade800 : Colors.grey.shade500,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isActive ? Colors.indigo.shade800 : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  // RECOMMENDATION TAB
  Widget _buildRecommendationsTab() {
    final recommendations = data['recommendations'] as List? ?? [];

    if (recommendations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.lightbulb_outline,
        message: 'Tidak ada rekomendasi yang tersedia',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = recommendations[index];
        final title = recommendation['title'] ?? 'Tidak ada judul';
        final score = recommendation['score'] ?? 0;
        final careers = recommendation['careers'] as List? ?? [];
        final majors = recommendation['majors'] as List? ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recommendation header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      index == 0 ? Colors.amber.shade50 : Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: index == 0 ? Colors.amber : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: index == 0
                            ? Colors.amber.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Skor: $score',
                        style: TextStyle(
                          color: index == 0
                              ? Colors.amber.shade900
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Careers
              if (careers.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Karir:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...careers
                          .map((career) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.work_outline,
                                      size: 16,
                                      color: Colors.orange.shade400,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        career.toString(),
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
                if (majors.isNotEmpty)
                  Divider(color: Colors.grey.shade200, height: 1),
              ],

              // Majors
              if (majors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jurusan Terkait:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...majors
                          .map((major) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.school_outlined,
                                      size: 16,
                                      color: Colors.green.shade400,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        major.toString(),
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ANSWERS TAB
  Widget _buildAnswersTab() {
    final userAnswers = data['userAnswers'] as List? ?? [];

    if (userAnswers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.question_answer_outlined,
        message: 'Tidak ada jawaban yang tersedia',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: userAnswers.length,
      itemBuilder: (context, index) {
        final answer = userAnswers[index];
        final questionId = answer['questionId'] ?? '';
        final question = answer['question'] ?? '';
        final userAnswer = answer['answer'];
        final programName = answer['programName'] ?? '';
        final minatKey = answer['minatKey'] ?? '';

        String answerText;
        Color answerColor;
        IconData answerIcon;

        if (userAnswer == true) {
          answerText = 'Ya';
          answerColor = Colors.green.shade800;
          answerIcon = Icons.check_circle;
        } else if (userAnswer == false) {
          answerText = 'Tidak';
          answerColor = Colors.red.shade800;
          answerIcon = Icons.cancel;
        } else {
          answerText = 'Tidak Dijawab';
          answerColor = Colors.grey.shade800;
          answerIcon = Icons.help;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question ID and category
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        questionId,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$programName - $minatKey',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Question text
                Text(
                  question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                // Answer
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: userAnswer == true
                        ? Colors.green.shade50
                        : userAnswer == false
                            ? Colors.red.shade50
                            : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: userAnswer == true
                          ? Colors.green.shade200
                          : userAnswer == false
                              ? Colors.red.shade200
                              : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        answerIcon,
                        size: 14,
                        color: answerColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Jawaban: $answerText',
                        style: TextStyle(
                          color: answerColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // RULES TAB
  Widget _buildRulesTab() {
    final workingMemory = data['workingMemory'] as List? ?? [];
    final recommendations = data['recommendations'] as List? ?? [];

    if (workingMemory.isEmpty && recommendations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.code,
        message: 'Tidak ada rules yang tersedia',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Working memory
        if (workingMemory.isNotEmpty) ...[
          Text(
            'Working Memory:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: workingMemory
                  .map((memory) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          memory.toString(),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.indigo.shade800,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Rules per recommendation
        if (recommendations.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rules by Recommendation:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade800,
                ),
              ),
              // Copy button
              IconButton(
                onPressed: () => _copyRulesToClipboard(),
                icon: Icon(Icons.copy, color: Colors.indigo.shade600, size: 20),
                tooltip: 'Salin Rules',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recommendations.asMap().entries.map((entry) {
            final index = entry.key;
            final recommendation = entry.value;
            final title = recommendation['title'] ?? 'Tidak ada judul';
            final rules = recommendation['rules'] as List? ?? [];

            if (rules.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recommendation header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: index == 0
                          ? Colors.amber.shade50
                          : Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: index == 0 ? Colors.amber : Colors.grey,
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rules
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: rules
                          .map((rule) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Text(
                                    rule.toString(),
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  // Empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper functions
  void _shareResults() {
    // Format a shareable text
    final buffer = StringBuffer();

    // Basic info
    final questionMode = data['questionMode'] ?? 'Tidak diketahui';
    final timestamp = data['timestamp'] as Timestamp?;
    final formattedDate = timestamp != null
        ? intl.DateFormat('dd MMMM yyyy, HH:mm').format(timestamp.toDate())
        : 'Tidak ada tanggal';

    buffer.writeln('Hasil Rekomendasi - $questionMode');
    buffer.writeln('Tanggal: $formattedDate');
    buffer.writeln('');

    // Recommendations
    final recommendations = data['recommendations'] as List? ?? [];
    if (recommendations.isNotEmpty) {
      buffer.writeln('TOP REKOMENDASI:');
      for (int i = 0; i < recommendations.length; i++) {
        final rec = recommendations[i];
        final title = rec['title'] ?? 'Tidak ada judul';
        final score = rec['score'] ?? 0;
        buffer.writeln('${i + 1}. $title (Skor: $score)');
      }
    }

    final shareText = buffer.toString();

    // Share the text
    Clipboard.setData(ClipboardData(text: shareText));
    Get.snackbar(
      'Disalin',
      'Hasil rekomendasi telah disalin ke clipboard',
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _copyRulesToClipboard() {
    // Format all rules as text
    final buffer = StringBuffer();

    // Working memory
    final workingMemory = data['workingMemory'] as List? ?? [];
    if (workingMemory.isNotEmpty) {
      buffer.writeln('WORKING MEMORY:');
      buffer.writeln(workingMemory.join(', '));
      buffer.writeln('');
    }

    // Rules by recommendation
    final recommendations = data['recommendations'] as List? ?? [];
    if (recommendations.isNotEmpty) {
      buffer.writeln('RULES BY RECOMMENDATION:');
      for (int i = 0; i < recommendations.length; i++) {
        final rec = recommendations[i];
        final title = rec['title'] ?? 'Tidak ada judul';
        final rules = rec['rules'] as List? ?? [];

        if (rules.isNotEmpty) {
          buffer.writeln('${i + 1}. $title:');
          for (final rule in rules) {
            buffer.writeln('   $rule');
          }
          buffer.writeln('');
        }
      }
    }

    final rulesText = buffer.toString();

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: rulesText));
    Get.snackbar(
      'Disalin',
      'Rules telah disalin ke clipboard',
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus riwayat rekomendasi ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecommendation();
            },
            icon: const Icon(Icons.delete),
            label: const Text('Hapus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _deleteRecommendation() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String? schoolId = prefs.getString('school_id');

      // Check if we have the schoolId
      if (schoolId == null || schoolId!.isEmpty) {
        // Try to get schoolId from SharedPreferences if not provided
        final prefs = await SharedPreferences.getInstance();
        schoolId = prefs.getString('school_id');

        if (schoolId == null || schoolId!.isEmpty) {
          Get.snackbar(
            'Error',
            'Tidak dapat menemukan data sekolah',
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      // Delete from school's recommendation_history subcollection
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('recommendation_history')
          .doc(documentId)
          .delete();

      // Show success message and go back
      Get.back();
      Get.snackbar(
        'Berhasil',
        'Riwayat rekomendasi telah dihapus',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menghapus riwayat: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
