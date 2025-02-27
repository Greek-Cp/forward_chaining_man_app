import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'package:flutter/services.dart';
import 'package:forward_chaining_man_app/app/controllers/developer_controller.dart';
import 'package:forward_chaining_man_app/app/views/about/page_about.dart';
import 'package:forward_chaining_man_app/app/views/developer/page/page_developer_viewer.dart';
import 'package:forward_chaining_man_app/app/views/page_intro.dart';
import 'package:forward_chaining_man_app/app/views/page_login.dart';
import 'package:forward_chaining_man_app/app/views/page_profile.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/quiz/view/page_select_major.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/recomendation_screen/view/page_recmendation_detail_screen.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/recomendation_screen/view/page_recomendation_screen_history.dart';
import 'package:forward_chaining_man_app/app/views/student/model/data_student.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

import 'feature/quiz/view/page_select_economy.dart';

class DevDataViewerController extends GetxController {
  final RxList<ProgramStudi> programStudiKerja = <ProgramStudi>[].obs;
  final RxList<ProgramStudi> programStudiKuliah = <ProgramStudi>[].obs;
  final RxString currentView =
      'overview'.obs; // overview, kerja, kuliah, rules, ugm
  final RxBool isLoading = true.obs;
  final RxString loadingError = ''.obs;
  final RxList<Map<String, dynamic>> rulesData = <Map<String, dynamic>>[].obs;

  // Data for UGM tuition fees
  final RxList<Map<String, dynamic>> biayaKuliahD4UGM =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> biayaKuliahS1UGM =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  /// Load all data for analysis
  void loadAllData() async {
    isLoading.value = true;
    loadingError.value = '';

    try {
      // Load Kerja data
      await loadProgramData(true, programStudiKerja);

      // Load Kuliah data
      await loadProgramData(false, programStudiKuliah);

      // Load UGM tuition fee data
      await loadUGMTuitionData();

      // Generate sample rules for analysis
      generateSampleRules();

      isLoading.value = false;
    } catch (e) {
      loadingError.value = e.toString();
      isLoading.value = false;
    }
  }

  void setCurrentView(String view) {
    currentView.value = view;
  }

  /// Memuat data ProgramStudi dari file JSON (Sains + Teknik) tergantung Kerja/Kuliah
  Future<void> loadProgramData(
      bool isKerja, RxList<ProgramStudi> target) async {
    // Tentukan file sains
    final sainsFile = isKerja
        ? 'assets/ipa_sains_kerja.json'
        : 'assets/ipa_sains_kuliah.json';

    // File teknik
    final teknikFile = isKerja
        ? 'assets/ipa_teknik_kerja.json'
        : 'assets/ipa_teknik_kuliah.json';

    // Baca JSON sains
    final sainsString = await rootBundle.rootBundle.loadString(sainsFile);
    final sainsMap = json.decode(sainsString) as Map<String, dynamic>;

    // Baca JSON teknik
    final teknikString = await rootBundle.rootBundle.loadString(teknikFile);
    final teknikMap = json.decode(teknikString) as Map<String, dynamic>;

    // Ubah ke list ProgramStudi
    final programs = <ProgramStudi>[];
    // Parsing sains
    for (var entry in sainsMap.entries) {
      programs.add(ProgramStudi.fromJson(entry.value));
    }
    // Parsing teknik
    for (var entry in teknikMap.entries) {
      programs.add(ProgramStudi.fromJson(entry.value));
    }

    target.value = programs;
  }

  /// Load UGM tuition fee data
  Future<void> loadUGMTuitionData() async {
    try {
      // Load D4 data
      final d4String = await rootBundle.rootBundle
          .loadString('assets/biaya_kuliah_d4_ugm.json');
      final d4List = json.decode(d4String) as List<dynamic>;
      biayaKuliahD4UGM.value = d4List.cast<Map<String, dynamic>>();

      // Load S1 data
      final s1String = await rootBundle.rootBundle
          .loadString('assets/biaya_kuliah_s1_ugm.json');
      final s1List = json.decode(s1String) as List<dynamic>;
      biayaKuliahS1UGM.value = s1List.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error loading UGM data: $e');
      // Continue even if UGM data fails to load
    }
  }

  /// Generate sample rules untuk analisis
  void generateSampleRules() {
    final rules = <Map<String, dynamic>>[];

    // Flatten pertanyaan dari programStudiKerja untuk contoh rules
    int counter = 1;
    for (var prog in programStudiKerja) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;
        final minatVal = minatEntry.value;

        for (var p in minatVal.pertanyaan) {
          final bobot = extractBobot(p);
          final cleaned = cleanPertanyaan(p);
          final qId = 'Q$counter';
          counter++;

          rules.add({
            'id': 'R$counter',
            'type': 'Forward Chaining Rule',
            'condition': 'IF $qId = Yes',
            'action': 'THEN Score("${prog.name}|$minatKey") += $bobot',
            'question': cleaned,
            'weight': bobot,
            'programName': prog.name,
            'minatKey': minatKey,
          });
        }
      }
    }

    rulesData.value = rules;
  }

  /// Get total question count
  int getTotalQuestions() {
    int count = 0;

    // Count questions from kerja
    for (var prog in programStudiKerja) {
      for (var minat in prog.minat.values) {
        count += minat.pertanyaan.length;
      }
    }

    // Count questions from kuliah
    for (var prog in programStudiKuliah) {
      for (var minat in prog.minat.values) {
        count += minat.pertanyaan.length;
      }
    }

    return count;
  }

  /// Count total minat
  int getTotalMinat() {
    int kerjaMinat =
        programStudiKerja.fold(0, (sum, prog) => sum + prog.minat.length);
    int kuliahMinat =
        programStudiKuliah.fold(0, (sum, prog) => sum + prog.minat.length);
    return kerjaMinat + kuliahMinat;
  }

  /// Count total jurusan
  int getTotalJurusan() {
    Set<String> allJurusan = {};

    // Collect unique jurusan from Kerja
    for (var prog in programStudiKerja) {
      for (var minat in prog.minat.values) {
        allJurusan.addAll(minat.jurusanTerkait);
      }
    }

    // Collect unique jurusan from Kuliah
    for (var prog in programStudiKuliah) {
      for (var minat in prog.minat.values) {
        allJurusan.addAll(minat.jurusanTerkait);
      }
    }

    return allJurusan.length;
  }

  /// Count total karir
  int getTotalKarir() {
    Set<String> allKarir = {};

    // Collect unique karir from Kerja
    for (var prog in programStudiKerja) {
      for (var minat in prog.minat.values) {
        allKarir.addAll(minat.karir);
      }
    }

    // Collect unique karir from Kuliah
    for (var prog in programStudiKuliah) {
      for (var minat in prog.minat.values) {
        allKarir.addAll(minat.karir);
      }
    }

    return allKarir.length;
  }
}

class PageStudentDashboard extends StatelessWidget {
  const PageStudentDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DeveloperModeController());
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Container(
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
        // Use a ListView as the main container instead of Column + SingleChildScrollView
        child: SafeArea(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            children: [
              // Top bar with buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Profile button
                  GestureDetector(
                    onTap: () {
                      Get.to(() => const ProfilePage());
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.indigo.shade100,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          currentUser?.photoURL != null
                              ? CircleAvatar(
                                  radius: 14,
                                  backgroundImage:
                                      NetworkImage(currentUser!.photoURL!),
                                )
                              : CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.indigo.shade100,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.indigo.shade700,
                                    size: 16,
                                  ),
                                ),
                          const SizedBox(width: 6),
                          Text(
                            "Profil",
                            style: TextStyle(
                              color: Colors.indigo.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // About button
                  GestureDetector(
                    onTap: () {
                      Get.to(() => AboutPage());
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.indigo.shade100,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.indigo.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Tentang",
                            style: TextStyle(
                              color: Colors.indigo.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // App Logo with Hero animation - centered
              Center(
                child: Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.psychology,
                        size: 60,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // App Title - centered
              Center(
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.8, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutQuad,
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      const Text(
                        'Forward Chaining',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sistem Rekomendasi Karir & Kuliah',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // User welcome section
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('students')
                    .doc(currentUser?.uid)
                    .get(),
                builder: (context, snapshot) {
                  String userName = "Siswa";
                  String userClass = "";

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    userName = userData['name'] ?? "Siswa";
                    userClass = userData['class'] ?? "";
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.waving_hand_rounded,
                          color: Colors.amber.shade300,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hai, $userName!',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (userClass.isNotEmpty)
                                Text(
                                  'Kelas $userClass',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // User Recommendation History
              if (currentUser != null) ...[
                // Recommendation History Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: Colors.amber.shade200,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Riwayat Rekomendasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Get.to(() => const RecommendationHistoryPage());
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              backgroundColor: Colors.blue.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Lihat Semua',
                              style: TextStyle(fontSize: 12),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 170, // Fixed height for the history list
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('recommendation_history')
                              .where('userId', isEqualTo: currentUser.uid)
                              .orderBy('timestamp', descending: true)
                              .limit(5)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white70),
                                  strokeWidth: 2,
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Container(
                                height: 170,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Belum ada riwayat rekomendasi.\nMulai aplikasi untuk mendapatkan rekomendasi.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                final doc = snapshot.data!.docs[index];
                                final data = doc.data() as Map<String, dynamic>;

                                // Extract recommendation data
                                String questionMode =
                                    data['questionMode'] ?? 'Tidak diketahui';
                                final timestamp =
                                    data['timestamp'] as Timestamp?;
                                final formattedDate = timestamp != null
                                    ? intl.DateFormat('dd/MM/yyyy HH:mm')
                                        .format(timestamp.toDate())
                                    : 'Tidak ada tanggal';

                                // Get top recommendation if available
                                String topRecommendation =
                                    'Tidak ada rekomendasi';
                                if (data['recommendations'] != null &&
                                    (data['recommendations'] as List)
                                        .isNotEmpty) {
                                  final recommendations =
                                      data['recommendations'] as List;
                                  if (recommendations.isNotEmpty) {
                                    topRecommendation = recommendations[0]
                                            ['title'] ??
                                        'Tidak ada judul';
                                  }
                                }

                                return GestureDetector(
                                  onTap: () {
                                    // Navigate to recommendation detail
                                    Get.to(() => RecommendationDetailPage(
                                          data: data,
                                          documentId: doc.id,
                                        ));
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: questionMode
                                                    .contains('Karir')
                                                ? Colors.orange.withOpacity(0.2)
                                                : Colors.green.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              questionMode.contains('Karir')
                                                  ? Icons.work
                                                  : Icons.school,
                                              color:
                                                  questionMode.contains('Karir')
                                                      ? Colors.orange.shade300
                                                      : Colors.green.shade300,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                topRecommendation,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$questionMode • $formattedDate',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: Colors.white.withOpacity(0.5),
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Main Content Area - Now directly in ListView, no nested scrolling
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    // Welcome message with visually distinct styling
                    Center(
                      child: Text(
                        'Selamat Datang!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subtitle with improved styling
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        'Aplikasi ini akan membantumu menemukan program studi dan karir yang paling sesuai dengan minatmu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Visual indicator to show content continues - arrow indicator
                    Center(
                      child: Icon(
                        Icons.keyboard_double_arrow_down,
                        color: Colors.indigo.shade200,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Developer Mode Card with improved visual cues
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.code,
                                    size: 20,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mode Developer',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Akses data & model AI',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Aktifkan mode developer untuk melihat data dan validasi model forward chaining yang digunakan dalam sistem rekomendasi.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Obx(() => Container(
                                  decoration: BoxDecoration(
                                    color: controller.isDeveloperMode.value
                                        ? Colors.indigo.shade50
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SwitchListTile(
                                    title: Text(
                                      controller.isDeveloperMode.value
                                          ? 'Developer Mode Aktif'
                                          : 'Developer Mode Nonaktif',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: controller.isDeveloperMode.value
                                            ? Colors.indigo.shade800
                                            : Colors.black54,
                                      ),
                                    ),
                                    value: controller.isDeveloperMode.value,
                                    onChanged: (value) =>
                                        controller.toggleDeveloperMode(value),
                                    activeColor: Colors.indigo,
                                    activeTrackColor: Colors.indigo.shade300,
                                    inactiveThumbColor: Colors.grey.shade400,
                                    inactiveTrackColor: Colors.grey.shade300,
                                    secondary: Icon(
                                      controller.isDeveloperMode.value
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: controller.isDeveloperMode.value
                                          ? Colors.indigo
                                          : Colors.grey.shade500,
                                      size: 20,
                                    ),
                                    dense: true,
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // User tips card with action indicator
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.blue.shade100,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.lightbulb_outline,
                                      size: 20,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Tips Penggunaan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Jawab pertanyaan dengan jujur untuk mendapatkan rekomendasi karir dan program studi yang paling sesuai dengan minat dan bakatmu.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Subtle indicator to show this is important
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons - with enhanced styling and visual cues
                    // Primary Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () =>
                            Get.to(() => const MajorPreferencePage()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.play_arrow_rounded, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Mulai Aplikasi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Developer mode button with attention-grabbing styling
                    Obx(() => controller.isDeveloperMode.value
                        ? Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () =>
                                  Get.to(() => const DevDataViewerPage()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.data_array, size: 22),
                                  SizedBox(width: 12),
                                  Text(
                                    'Data & Model Viewer',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink()),

                    const SizedBox(height: 16),

                    // Footer attribution
                    Center(
                      child: Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Bottom spacing
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
