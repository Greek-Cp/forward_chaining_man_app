import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'package:flutter/services.dart';
import 'package:forward_chaining_man_app/admin_mode.dart';
import 'package:forward_chaining_man_app/app/views/about/page_about.dart';
import 'package:forward_chaining_man_app/app/views/page_intro.dart';
import 'package:forward_chaining_man_app/app/views/page_login.dart';
import 'package:forward_chaining_man_app/app/views/page_profile.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/quiz/controller/question_controller.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/quiz/view/page_question.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/quiz/view/page_select_major.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/recomendation_screen/view/page_recomendation_screen.dart';
import 'package:forward_chaining_man_app/app/views/student/model/data_student.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart' as intl;

import 'package:url_launcher/url_launcher.dart';

// Helper function to replace the simple dialog with our new UI
void showRecommendationResultsGetx(RecommendationResult result,
    {String rawMessage = ''}) {
  Get.to(() => RecommendationResultsScreen(
        result: result,
        rawMessage: rawMessage,
      ));
}

class HomeController extends GetxController {
  final Rx<bool?> pilihan =
      Rx<bool?>(null); // null=belum pilih; true=Kerja; false=Kuliah
  final RxString selectedKode =
      "".obs; // Menyimpan kode pilihan yang dipilih user

  // Dapatkan preferensi minat dari controller sebelumnya
  final majorPrefController = Get.find<MajorPreferenceController>();

  void setPilihan(String kode) {
    if (selectedKode.value == kode)
      return; // Jika memilih yang sama, tidak berubah
    selectedKode.value = kode;

    // Logika pemilihan: Kuliah atau Kerja
    if (kode == "E01" || kode == "E02" || kode == "E03") {
      pilihan.value = false; // Kuliah
    } else if (kode == "E04" || kode == "E05") {
      pilihan.value = true; // Kerja
    }
  }

  // Tambahkan getter untuk memudahkan akses preferensi minat
  String get selectedMajor => majorPrefController.selectedMajor.value;
  bool get isSainsMajor => selectedMajor == "SAINS";
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.indigo.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Pilih Rencana Anda',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.lightbulb_outline,
                                size: 24,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kondisi Ekonomi',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pilih situasi yang paling sesuai',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Options List
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                Obx(() => buildOptionCard(
                                      title:
                                          "Kondisi ekonomi cukup untuk kuliah",
                                      subtitle:
                                          "Memiliki dana untuk pendidikan lanjutan",
                                      kode: "E01",
                                      icon: Icons.school,
                                      controller: controller,
                                    )),

                                Obx(() => buildOptionCard(
                                      title: "Ekonomi terbatas",
                                      subtitle:
                                          "Perlu mempertimbangkan biaya kuliah",
                                      kode: "E02",
                                      icon: Icons.attach_money,
                                      controller: controller,
                                    )),

                                Obx(() => buildOptionCard(
                                      title: "Mencari beasiswa",
                                      subtitle:
                                          "Berminat kuliah dengan bantuan biaya",
                                      kode: "E03",
                                      icon: Icons.card_giftcard,
                                      controller: controller,
                                    )),

                                Obx(() => buildOptionCard(
                                      title: "Memilih bekerja atau usaha",
                                      subtitle:
                                          "Ingin langsung terjun ke dunia kerja",
                                      kode: "E04",
                                      icon: Icons.work,
                                      controller: controller,
                                    )),

                                Obx(() => buildOptionCard(
                                      title: "Bekerja dulu, kuliah nanti",
                                      subtitle: "Menunda kuliah untuk bekerja",
                                      kode: "E05",
                                      icon: Icons.timeline,
                                      controller: controller,
                                    )),

                                // Add some space at the bottom for better scrolling
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Next Button
                        Obx(() => AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: controller.selectedKode.value.isEmpty
                                  ? 0.6
                                  : 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow:
                                      controller.selectedKode.value.isEmpty
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: Colors.blue.shade300
                                                    .withOpacity(0.4),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                ),
                                child: ElevatedButton(
                                  onPressed: controller
                                          .selectedKode.value.isEmpty
                                      ? null
                                      : () {
                                          // Buat instance QuestionController dengan preferensi yang sesuai
                                          final questionController =
                                              Get.put(QuestionController(
                                            isKerja: controller.pilihan.value!,
                                            majorType: controller.selectedMajor,
                                          ));

                                          // Navigasi ke halaman pertanyaan
                                          Get.to(() => QuestionPage(
                                                isKerja:
                                                    controller.pilihan.value!,
                                              ));
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    minimumSize:
                                        const Size(double.infinity, 54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                    disabledBackgroundColor:
                                        Colors.blue.shade200,
                                    disabledForegroundColor: Colors.white70,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        controller.selectedKode.value.isEmpty
                                            ? 'Pilih Salah Satu Opsi'
                                            : 'Lanjutkan',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            )),
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

  /// Widget untuk membuat tampilan pilihan lebih menarik dan modern
  Widget buildOptionCard({
    required String title,
    required String subtitle,
    required String kode,
    required IconData icon,
    required HomeController controller,
  }) {
    final isSelected = controller.selectedKode.value == kode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.setPilihan(kode),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected ? Colors.blue.shade50 : Colors.white,
              border: Border.all(
                color: isSelected ? Colors.blue.shade400 : Colors.grey.shade200,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade400
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.blue.shade800
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? Colors.blue.shade600
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
