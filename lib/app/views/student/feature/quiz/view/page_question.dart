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
import 'package:forward_chaining_man_app/app/views/student/feature/quiz/controller/question_controller.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/quiz/view/page_select_economy.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart' as intl;

import 'package:url_launcher/url_launcher.dart';

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
                                            controller
                                                .saveResultsToFirestore(results)
                                                .then((_) {
                                              // Then show results to user
                                              showRecommendationResultsGetx(
                                                  results);
                                            });
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