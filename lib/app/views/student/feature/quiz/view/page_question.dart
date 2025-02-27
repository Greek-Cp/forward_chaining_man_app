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
// Modifikasi metode _showAutoFillOptions
  void _showAutoFillOptions(
      BuildContext context, QuestionController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Auto Fill Options (Testing)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 20),
              // Opsi untuk mengisi & lanjut ke halaman berikutnya
              _buildAutoFillOption(
                context,
                icon: Icons.fast_forward,
                label: 'Lanjut ke Halaman Berikutnya',
                color: Colors.blue.shade600,
                onTap: () {
                  controller.autoFillAnswers(true);
                  Navigator.pop(context);
                  // Langsung lanjut ke halaman berikutnya
                  if (controller.currentPage.value <
                      controller.totalPages - 1) {
                    controller.nextPage();
                  } else {
                    // Jika halaman terakhir, tampilkan hasil
                    final results = controller.runForwardChaining();
                    controller.saveResultsToFirestore(results).then((_) {
                      showRecommendationResultsGetx(results);
                    });
                  }
                },
              ),
              const Divider(height: 1),
              // Opsi untuk mengisi & menyelesaikan semua halaman
              _buildAutoFillOption(
                context,
                icon: Icons.done_all,
                label: 'Selesaikan Semua & Lihat Hasil',
                color: Colors.green.shade600,
                onTap: () {
                  Navigator.pop(context);
                  // Isi semua pertanyaan di semua halaman
                  controller.autoFillAllPages(true).then((_) {
                    // Kemudian jalankan forward chaining
                    final results = controller.runForwardChaining();
                    controller.saveResultsToFirestore(results).then((_) {
                      showRecommendationResultsGetx(results);
                    });
                  });
                },
              ),
              const Divider(height: 1),
              // Opsi mengisi secara acak & menyelesaikan semua
              _buildAutoFillOption(
                context,
                icon: Icons.shuffle,
                label: 'Isi Acak & Lihat Hasil',
                color: Colors.purple.shade600,
                onTap: () {
                  Navigator.pop(context);
                  // Isi semua pertanyaan secara acak
                  controller.autoFillAllPages(null).then((_) {
                    // Kemudian jalankan forward chaining
                    final results = controller.runForwardChaining();
                    controller.saveResultsToFirestore(results).then((_) {
                      showRecommendationResultsGetx(results);
                    });
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper untuk item menu auto fill
  Widget _buildAutoFillOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuestionController>();
    // Tambahkan ScrollController untuk mengontrol scrolling
    final scrollController = ScrollController();

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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber.shade600,
        onPressed: () {
          _showAutoFillOptions(context, controller);
        },
        child: const Icon(Icons.bolt, size: 28),
        tooltip: 'Auto Fill (Testing)',
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

          // Jika flag scroll ke atas aktif, lakukan scrolling
          if (controller.shouldScrollToTop) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                scrollController.animateTo(0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut);
                // Reset flag
                controller.shouldScrollToTop = false;
              }
            });
          }

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
                          controller: scrollController, // Tambahkan controller
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          itemCount: questionsThisPage.length,
                          itemBuilder: (context, index) {
                            final qItem = questionsThisPage[index];
                            final globalIndex = startIndex + index;

                            return Obx(() {
                              // Cek apakah pertanyaan ini perlu di-highlight
                              final isHighlighted = controller
                                  .highlightedQuestionIds
                                  .contains(qItem.id);

                              // Cek status jawaban dari pertanyaan ini
                              final isAnswered = controller.allQuestions
                                      .firstWhere((q) => q.id == qItem.id)
                                      .userAnswer !=
                                  null;

                              return Card(
                                key: ValueKey(
                                    'question_${qItem.id}'), // Key untuk identifikasi
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shadowColor: Colors.black.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                // Wrap dengan Container biasa agar tidak memicu animasi saat jawaban dipilih
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isHighlighted
                                          ? Colors.amber.shade500
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: isHighlighted
                                        ? [
                                            BoxShadow(
                                              color: Colors.amber.shade200
                                                  .withOpacity(0.5),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Question header
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isHighlighted
                                              ? Colors.amber.shade50
                                              : Colors.blue.shade50,
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
                                                color: isHighlighted
                                                    ? Colors.amber.shade600
                                                    : Colors.blue.shade600,
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
                                            // Badge untuk pertanyaan yang di-highlight
                                            if (isHighlighted && !isAnswered)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: Colors
                                                          .amber.shade600),
                                                ),
                                                child: Text(
                                                  'Belum Diisi',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.amber.shade900,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Answer options
                                      Column(
                                        children: [
                                          _buildAnswerOption(
                                            icon: Icons.check_circle_outline,
                                            label: 'Ya',
                                            isSelected: controller.allQuestions
                                                    .firstWhere(
                                                        (q) => q.id == qItem.id)
                                                    .userAnswer ==
                                                true,
                                            onTap: () {
                                              controller.setAnswer(qItem, true);
                                              // Hapus highlight saat jawaban dipilih
                                              if (controller
                                                  .highlightedQuestionIds
                                                  .contains(qItem.id)) {
                                                controller
                                                    .highlightedQuestionIds
                                                    .remove(qItem.id);
                                              }
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
                                            isSelected: controller.allQuestions
                                                    .firstWhere(
                                                        (q) => q.id == qItem.id)
                                                    .userAnswer ==
                                                false,
                                            onTap: () {
                                              controller.setAnswer(
                                                  qItem, false);
                                              // Hapus highlight saat jawaban dipilih
                                              if (controller
                                                  .highlightedQuestionIds
                                                  .contains(qItem.id)) {
                                                controller
                                                    .highlightedQuestionIds
                                                    .remove(qItem.id);
                                              }
                                            },
                                            activeColor: Colors.red.shade600,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            });
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
                                    ? () {
                                        // Hapus semua highlight sebelum pindah halaman
                                        controller.highlightedQuestionIds
                                            .clear();
                                        controller.prevPage();
                                        // Set flag untuk scroll ke atas
                                        controller.shouldScrollToTop = true;
                                      }
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
                                bool allAnswered =
                                    controller.allAnsweredThisPage;
                                final isLastPage =
                                    controller.currentPage.value ==
                                        controller.totalPages - 1;

                                return ElevatedButton.icon(
                                  onPressed: () {
                                    if (allAnswered) {
                                      // Hapus semua highlight sebelum pindah halaman
                                      controller.highlightedQuestionIds.clear();

                                      if (!isLastPage) {
                                        controller.nextPage();
                                        // Set flag untuk scroll ke atas
                                        controller.shouldScrollToTop = true;
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
                                    } else {
                                      // Highlight pertanyaan yang belum dijawab
                                      controller.highlightUnansweredQuestions(
                                          scrollController);
                                    }
                                  },
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
                                        null, // Hapus ini agar tombol selalu aktif
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

  // Fungsi helper yang sama seperti sebelumnya
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
}
