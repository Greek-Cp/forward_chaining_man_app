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

/// Halaman untuk melihat data dan analisis forward chaining (developer mode)

class DevDataViewerPage extends StatelessWidget {
  const DevDataViewerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DevDataViewerController());

    // Define theme colors
    final primaryColor = Colors.blue.shade800;
    final secondaryColor = Colors.indigo.shade900;
    final bgGradient = LinearGradient(
      colors: [primaryColor, secondaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Data Viewer',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
                const SizedBox(height: 16),
                Text('Loading data...',
                    style: TextStyle(
                        color: primaryColor, fontWeight: FontWeight.w500))
              ],
            ));
          }

          if (controller.loadingError.value.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Colors.red.shade700),
                  const SizedBox(height: 16),
                  Text('Error: ${controller.loadingError.value}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => controller.loadAllData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }

          return Column(
            children: [
              // Tab navigation with improved styling
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTab(
                          controller, 'overview', 'Overview', primaryColor),
                      _buildTab(
                          controller, 'kerja', 'Kerja Data', primaryColor),
                      _buildTab(
                          controller, 'kuliah', 'Kuliah Data', primaryColor),
                      _buildTab(controller, 'rules', 'Rules', primaryColor),
                      _buildTab(controller, 'analysis', 'Model Analysis',
                          primaryColor),
                      _buildTab(controller, 'ugm', 'UGM Data', primaryColor),
                    ],
                  ),
                ),
              ),

              // Content based on selected tab
              Expanded(
                child: buildContent(controller, primaryColor, secondaryColor),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTab(DevDataViewerController controller, String viewName,
      String label, Color primaryColor) {
    final isSelected = controller.currentView.value == viewName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.setCurrentView(viewName),
          borderRadius: BorderRadius.circular(24),
          splashColor: primaryColor.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade800,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildContent(DevDataViewerController controller, Color primaryColor,
      Color secondaryColor) {
    switch (controller.currentView.value) {
      case 'overview':
        return buildOverviewTab(controller, primaryColor, secondaryColor);
      case 'kerja':
        return buildDataTab(controller, controller.programStudiKerja, 'Kerja',
            primaryColor, secondaryColor);
      case 'kuliah':
        return buildDataTab(controller, controller.programStudiKuliah, 'Kuliah',
            primaryColor, secondaryColor);
      case 'rules':
        return buildRulesTab(controller, primaryColor, secondaryColor);
      case 'analysis':
        return buildAnalysisTab(controller, primaryColor, secondaryColor);
      case 'ugm':
        return buildUGMDataTab(controller, primaryColor, secondaryColor);
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              const Text('Unknown view', style: TextStyle(fontSize: 18)),
            ],
          ),
        );
    }
  }

  /// Tab Overview - statistik umum with improved UI
  Widget buildOverviewTab(DevDataViewerController controller,
      Color primaryColor, Color secondaryColor) {
    // Prepare data for charts
    final List<PieChartSectionData> minatDistribution = [];
    final Map<String, int> minatCounts = {};

    // Count minat by category
    for (var prog in [
      ...controller.programStudiKerja,
      ...controller.programStudiKuliah
    ]) {
      for (var minatKey in prog.minat.keys) {
        if (minatCounts.containsKey(minatKey)) {
          minatCounts[minatKey] = minatCounts[minatKey]! + 1;
        } else {
          minatCounts[minatKey] = 1;
        }
      }
    }

    // Convert to pie chart data
    List<Color> colorList = [
      Colors.blue.shade400,
      Colors.indigo.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.cyan.shade400,
      Colors.green.shade400,
      Colors.amber.shade400,
      Colors.orange.shade400,
    ];

    int colorIndex = 0;
    minatCounts.forEach((key, value) {
      if (colorIndex >= colorList.length) colorIndex = 0;

      if (minatDistribution.length < 6) {
        // Limit to top 6 for visibility
        minatDistribution.add(PieChartSectionData(
          value: value.toDouble(),
          title: key,
          radius: 100,
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          color: colorList[colorIndex++],
        ));
      }
    });

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            secondaryColor.withOpacity(0.9),
            primaryColor.withOpacity(0.9),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const Text(
              'Data Aplikasi',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Visualisasi data yang digunakan dalam analisis forward chaining',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const Divider(color: Colors.white30, thickness: 1, height: 32),

            // Stats Cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  'Total Questions',
                  controller.getTotalQuestions().toString(),
                  Icons.question_answer,
                  onTap: () => _showQuestionsDialog(controller, primaryColor),
                  primaryColor: primaryColor,
                ),
                _buildStatCard(
                  'Total Rules',
                  controller.rulesData.length.toString(),
                  Icons.rule,
                  onTap: () => _showRulesDialog(controller, primaryColor),
                  primaryColor: primaryColor,
                ),
                _buildStatCard(
                  'Total Minat',
                  controller.getTotalMinat().toString(),
                  Icons.category,
                  onTap: () => _showMinatDialog(controller, primaryColor),
                  primaryColor: primaryColor,
                ),
                _buildStatCard(
                  'Total Jurusan',
                  controller.getTotalJurusan().toString(),
                  Icons.school,
                  onTap: () => _showJurusanDialog(controller, primaryColor),
                  primaryColor: primaryColor,
                ),
                _buildStatCard(
                  'Total Karir',
                  controller.getTotalKarir().toString(),
                  Icons.work,
                  onTap: () => _showKarirDialog(controller, primaryColor),
                  primaryColor: primaryColor,
                ),
                _buildStatCard(
                  'Data Sources',
                  '6 JSON Files',
                  Icons.data_array,
                  primaryColor: primaryColor,
                ),
              ],
            ),

            // Charts Section
            const SizedBox(height: 30),
            Card(
              elevation: 8,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribusi Minat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sections: minatDistribution,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                              // You can implement touch interaction if needed
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Visualisasi distribusi minat berdasarkan frekuensi kemunculan',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Question Distribution per Program Study
            const SizedBox(height: 30),
            Card(
              elevation: 8,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribusi Pertanyaan per Program Studi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 300,
                      child: buildQuestionDistributionChart(
                          controller, primaryColor, secondaryColor),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Forward Chaining Explanation with improved styling
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: primaryColor, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Implementasi Forward Chaining',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Model ini mengimplementasikan pendekatan Forward Chaining berbasis aturan dengan:',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    icon: Icons.memory,
                    title: 'Memori Kerja',
                    description: 'Menyimpan fakta seperti "Q1=Ya" / "Q1=Tidak"',
                    color: primaryColor,
                  ),
                  _buildFeatureItem(
                    icon: Icons.rule_folder,
                    title: 'Basis Aturan',
                    description: 'Aturan dalam bentuk "JIKA kondisi MAKA aksi"',
                    color: primaryColor,
                  ),
                  _buildFeatureItem(
                    icon: Icons.sync,
                    title: 'Mesin Inferensi',
                    description:
                        'Menerapkan aturan pada memori kerja untuk mendapatkan skor',
                    color: primaryColor,
                  ),
                  _buildFeatureItem(
                    icon: Icons.balance,
                    title: 'Pembobotan Skor',
                    description:
                        'Setiap pertanyaan memiliki bobot yang berkontribusi pada skor akhir',
                    color: primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: const Text(
                      'Implementasi ini adalah sistem produksi klasik dengan siklus cocok-selesaikan-bertindak yang berlanjut hingga tidak ada lagi aturan yang dapat dijalankan.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Visualisasi Flow Forward Chaining with improved styling
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_tree, color: primaryColor, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Alur Forward Chaining',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  buildForwardChainingFlowchart(primaryColor, secondaryColor),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget buildForwardChainingFlowchart(
      Color primaryColor, Color secondaryColor) {
    return Container(
      height: 420,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildFlowStep(
                number: "1",
                text:
                    "Pengguna menjawab pertanyaan (Ya/Tidak) untuk menetapkan fakta awal",
                primaryColor: primaryColor),
            _buildFlowArrow(),
            _buildFlowStep(
                number: "2",
                text:
                    "Fakta ditambahkan ke dalam memori kerja (misalnya, \"Q1=Ya\")",
                primaryColor: primaryColor),
            _buildFlowArrow(),
            _buildFlowStep(
                number: "3",
                text:
                    "Aturan yang sesuai dengan fakta dalam memori kerja dijalankan",
                primaryColor: primaryColor),
            _buildFlowArrow(),
            _buildFlowStep(
                number: "4",
                text:
                    "Setiap aturan yang dijalankan menambahkan skor ke minat yang sesuai",
                primaryColor: primaryColor),
            _buildFlowArrow(),
            _buildFlowStep(
                number: "5",
                text:
                    "Setelah semua aturan dievaluasi, minat diurutkan berdasarkan skor",
                primaryColor: primaryColor),
            _buildFlowArrow(),
            _buildFlowStep(
                number: "6",
                text: "Tiga minat teratas disajikan sebagai rekomendasi",
                primaryColor: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowStep(
      {required String number,
      required String text,
      required Color primaryColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Icon(
        Icons.arrow_downward,
        color: Colors.grey.shade400,
        size: 20,
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildQuestionDistributionChart(DevDataViewerController controller,
      Color primaryColor, Color secondaryColor) {
    // Prepare the data
    final Map<String, int> questionCounts = {};

    // Count questions per program
    for (var prog in controller.programStudiKerja) {
      int count = 0;
      for (var minat in prog.minat.values) {
        count += minat.pertanyaan.length;
      }
      questionCounts["${prog.name} (Kerja)"] = count;
    }

    for (var prog in controller.programStudiKuliah) {
      int count = 0;
      for (var minat in prog.minat.values) {
        count += minat.pertanyaan.length;
      }
      questionCounts["${prog.name} (Kuliah)"] = count;
    }

    // Sort the data
    final sortedEntries = questionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 8 for readability
    final limitedEntries = sortedEntries.take(8).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: limitedEntries.isNotEmpty
            ? (limitedEntries.first.value * 1.2).toDouble()
            : 10,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${limitedEntries[groupIndex].key}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '${rod.toY.round()} questions',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
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
                if (value >= limitedEntries.length || value < 0)
                  return const Text('');
                // Abbreviate long program names
                String title = limitedEntries[value.toInt()].key;
                if (title.length > 15) {
                  title = '${title.substring(0, 13)}...';
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              },
              reservedSize: 44,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        barGroups: List.generate(
          limitedEntries.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: limitedEntries[index].value.toDouble(),
                color: primaryColor,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: limitedEntries.first.value * 1.2,
                  color: Colors.grey.shade200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      {VoidCallback? onTap, required Color primaryColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Reduced padding slightly
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10), // Reduced padding
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(icon, size: 24, color: primaryColor), // Smaller icon
              ),
              const SizedBox(height: 12), // Less space
              Container(
                width: double.infinity, // Forces wrapping
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13, // Smaller font
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // Allow up to 2 lines
                  overflow:
                      TextOverflow.ellipsis, // Show ellipsis if it overflows
                ),
              ),
              const SizedBox(height: 6), // Less space
              FittedBox(
                // This will scale text to fit
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22, // Smaller font
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  maxLines: 1,
                ),
              ),
              if (onTap != null) const SizedBox(height: 6),
              if (onTap != null)
                Row(
                  mainAxisSize: MainAxisSize.min, // Take only needed space
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      // Allow text to shrink if needed
                      child: Text(
                        'Lihat Detail',
                        style: TextStyle(
                          fontSize: 11, // Smaller font
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 10, // Smaller icon
                      color: primaryColor,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

// Add the dialog methods with improved styling
  void _showQuestionsDialog(
      DevDataViewerController controller, Color primaryColor) {
    final allQuestions = <Map<String, dynamic>>[];

    // Collect questions from Kerja
    for (var prog in controller.programStudiKerja) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;
        final minatVal = minatEntry.value;

        for (var p in minatVal.pertanyaan) {
          final bobot = extractBobot(p);
          final cleaned = cleanPertanyaan(p);

          allQuestions.add({
            'pertanyaan': cleaned,
            'bobot': bobot,
            'program': prog.name,
            'minat': minatKey,
            'type': 'Kerja',
          });
        }
      }
    }

    // Collect questions from Kuliah
    for (var prog in controller.programStudiKuliah) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;
        final minatVal = minatEntry.value;

        for (var p in minatVal.pertanyaan) {
          final bobot = extractBobot(p);
          final cleaned = cleanPertanyaan(p);

          allQuestions.add({
            'pertanyaan': cleaned,
            'bobot': bobot,
            'program': prog.name,
            'minat': minatKey,
            'type': 'Kuliah',
          });
        }
      }
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Questions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.question_answer,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total: ${allQuestions.length} questions',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // Add search functionality here if needed
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: allQuestions.length,
                  itemBuilder: (context, index) {
                    final q = allQuestions[index];
                    final isKerja = q['type'] == 'Kerja';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with number and question
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Number avatar
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isKerja
                                      ? Colors.blue.shade700
                                      : Colors.green.shade700,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Question text
                                Expanded(
                                  child: Text(
                                    q['pertanyaan'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Tags as Wrap to handle overflow
                            Wrap(
                              spacing: 8, // horizontal space between tags
                              runSpacing: 8, // vertical space between lines
                              children: [
                                _buildQuestionTag(
                                  isKerja ? 'Kerja' : 'Kuliah',
                                  isKerja ? Colors.blue : Colors.green,
                                ),
                                _buildQuestionTag(
                                  q['program'],
                                  Colors.indigo,
                                ),
                                _buildQuestionTag(
                                  'Bobot: ${q['bobot']}',
                                  Colors.amber.shade800,
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Minat info
                            Row(
                              children: [
                                Icon(Icons.interests,
                                    size: 12, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Minat: ${q['minat']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  // Improved question tag to prevent overflow
  Widget _buildQuestionTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  void _showRulesDialog(
      DevDataViewerController controller, Color primaryColor) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Rules',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.rule,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total: ${controller.rulesData.length} rules',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.rulesData.length,
                  itemBuilder: (context, index) {
                    final rule = controller.rulesData[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          '${rule['condition']} ${rule['action']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Question: ${rule['question']}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildQuestionTag(
                                  'Weight: ${rule['weight']}',
                                  Colors.amber.shade800,
                                ),
                                const SizedBox(width: 8),
                                _buildQuestionTag(
                                  rule['programName'],
                                  Colors.indigo,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildQuestionTag(
                                    'Minat: ${rule['minatKey']}',
                                    Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber.shade700,
                          child: Text(
                            rule['id'].toString().replaceAll('R', ''),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  void _showMinatDialog(
      DevDataViewerController controller, Color primaryColor) {
    final allMinat = <Map<String, dynamic>>[];

    // Collect minat from Kerja with additional details
    for (var prog in controller.programStudiKerja) {
      for (var minatEntry in prog.minat.entries) {
        allMinat.add({
          'name': minatEntry.key,
          'program': prog.name,
          'type': 'Kerja',
          'jumlahPertanyaan': minatEntry.value.pertanyaan.length,
          'jumlahKarir': minatEntry.value.karir.length,
          'jumlahJurusan': minatEntry.value.jurusanTerkait.length,
          // Store the actual data for detailed view
          'pertanyaan': minatEntry.value.pertanyaan,
          'karir': minatEntry.value.karir,
          'jurusanTerkait': minatEntry.value.jurusanTerkait,
        });
      }
    }

    // Collect minat from Kuliah with additional details
    for (var prog in controller.programStudiKuliah) {
      for (var minatEntry in prog.minat.entries) {
        allMinat.add({
          'name': minatEntry.key,
          'program': prog.name,
          'type': 'Kuliah',
          'jumlahPertanyaan': minatEntry.value.pertanyaan.length,
          'jumlahKarir': minatEntry.value.karir.length,
          'jumlahJurusan': minatEntry.value.jurusanTerkait.length,
          // Store the actual data for detailed view
          'pertanyaan': minatEntry.value.pertanyaan,
          'karir': minatEntry.value.karir,
          'jurusanTerkait': minatEntry.value.jurusanTerkait,
        });
      }
    }

    // Sort by number of questions
    allMinat
        .sort((a, b) => b['jumlahPertanyaan'].compareTo(a['jumlahPertanyaan']));

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Minat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.interests,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total: ${allMinat.length} minat',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: allMinat.length,
                  itemBuilder: (context, index) {
                    final minat = allMinat[index];
                    final isKerja = minat['type'] == 'Kerja';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor:
                              Colors.transparent, // Remove the default divider
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            minat['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          subtitle: Wrap(
                            // Use Wrap to prevent overflow
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildQuestionTag(
                                isKerja ? 'Kerja' : 'Kuliah',
                                isKerja ? Colors.blue : Colors.green,
                              ),
                              _buildQuestionTag(
                                minat['program'],
                                Colors.indigo,
                              ),
                            ],
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isKerja
                                ? Colors.blue.shade700
                                : Colors.green.shade700,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),

                                  // Overall stats
                                  Container(
                                    margin: const EdgeInsets.only(
                                        top: 8, bottom: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildMinatInfoCounter(
                                            icon: Icons.question_answer,
                                            title: 'Pertanyaan',
                                            count: minat['jumlahPertanyaan'],
                                            color: Colors.blue,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildMinatInfoCounter(
                                            icon: Icons.work,
                                            title: 'Karir',
                                            count: minat['jumlahKarir'],
                                            color: Colors.orange,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildMinatInfoCounter(
                                            icon: Icons.school,
                                            title: 'Jurusan',
                                            count: minat['jumlahJurusan'],
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Detailed sections using DefaultTabController for better organization
                                  Container(
                                    height:
                                        300, // Fixed height for the tab view
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: DefaultTabController(
                                      length: 3,
                                      child: Column(
                                        children: [
                                          TabBar(
                                            tabs: const [
                                              Tab(text: 'Pertanyaan'),
                                              Tab(text: 'Karir'),
                                              Tab(text: 'Jurusan'),
                                            ],
                                            indicatorColor: primaryColor,
                                            labelColor: primaryColor,
                                            unselectedLabelColor:
                                                Colors.grey.shade600,
                                            labelStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Expanded(
                                            child: TabBarView(
                                              children: [
                                                // Pertanyaan tab
                                                _buildPertanyaanTabContent(
                                                    minat),

                                                // Karir tab
                                                _buildKarirTabContent(minat),

                                                // Jurusan tab
                                                _buildJurusanTabContent(minat),
                                              ],
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
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  // Helper widget for the stats counter
  Widget _buildMinatInfoCounter({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Tab content for Pertanyaan
  Widget _buildPertanyaanTabContent(Map<String, dynamic> minat) {
    final List<dynamic> pertanyaanList = minat['pertanyaan'];

    if (pertanyaanList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Tidak ada pertanyaan'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: pertanyaanList.length,
      itemBuilder: (context, index) {
        final String question = pertanyaanList[index];
        final bobot = extractBobot(question);
        final cleaned = cleanPertanyaan(question);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}.',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cleaned,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Bobot: $bobot',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Tab content for Karir
  Widget _buildKarirTabContent(Map<String, dynamic> minat) {
    final List<dynamic> karirList = minat['karir'];

    if (karirList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Tidak ada karir terkait'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: karirList.map<Widget>((karir) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.work,
                  size: 14,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    karir,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Tab content for Jurusan
  Widget _buildJurusanTabContent(Map<String, dynamic> minat) {
    final List<dynamic> jurusanList = minat['jurusanTerkait'];

    if (jurusanList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Tidak ada jurusan terkait'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: jurusanList.length,
      itemBuilder: (context, index) {
        final String jurusan = jurusanList[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.school,
                size: 18,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  jurusan,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMinatInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  void _showJurusanDialog(
      DevDataViewerController controller, Color primaryColor) {
    // Collect all unique jurusan with their associated minat and program
    final Map<String, List<Map<String, dynamic>>> jurusanMap = {};

    // Helper function to add jurusan data
    void addJurusanData(
        String jurusan, String program, String minat, String type) {
      if (!jurusanMap.containsKey(jurusan)) {
        jurusanMap[jurusan] = [];
      }

      jurusanMap[jurusan]!.add({
        'program': program,
        'minat': minat,
        'type': type,
      });
    }

    // Collect from Kerja
    for (var prog in controller.programStudiKerja) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;

        for (var jurusan in minatEntry.value.jurusanTerkait) {
          addJurusanData(jurusan, prog.name, minatKey, 'Kerja');
        }
      }
    }

    // Collect from Kuliah
    for (var prog in controller.programStudiKuliah) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;

        for (var jurusan in minatEntry.value.jurusanTerkait) {
          addJurusanData(jurusan, prog.name, minatKey, 'Kuliah');
        }
      }
    }

    // Convert to list for display
    final jurusanList = jurusanMap.entries.map((entry) {
      return {
        'name': entry.key,
        'count': entry.value.length,
        'references': entry.value,
      };
    }).toList();

    // Sort by frequency
    jurusanList
        .sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Jurusan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.school,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total: ${jurusanList.length} jurusan',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: jurusanList.length,
                  itemBuilder: (context, index) {
                    final jurusan = jurusanList[index];
                    final references =
                        jurusan['references'] as List<Map<String, dynamic>>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          jurusan['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.indigo.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'Referenced ${jurusan['count']} times',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                          ],
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        children: [
                          const Divider(indent: 16, endIndent: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Text(
                              'Referenced in:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: references.length,
                            itemBuilder: (context, i) {
                              final ref = references[i];
                              final isKerja = ref['type'] == 'Kerja';

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 4,
                                ),
                                title: Row(
                                  children: [
                                    _buildQuestionTag(
                                      isKerja ? 'Kerja' : 'Kuliah',
                                      isKerja ? Colors.blue : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ref['program'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Minat: ${ref['minat']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                leading: Icon(
                                  isKerja ? Icons.work : Icons.school,
                                  color: isKerja ? Colors.blue : Colors.green,
                                  size: 20,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  void _showKarirDialog(
      DevDataViewerController controller, Color primaryColor) {
    // Collect all unique karir with their associated minat and program
    final Map<String, List<Map<String, dynamic>>> karirMap = {};

    // Helper function to add karir data
    void addKarirData(String karir, String program, String minat, String type) {
      if (!karirMap.containsKey(karir)) {
        karirMap[karir] = [];
      }

      karirMap[karir]!.add({
        'program': program,
        'minat': minat,
        'type': type,
      });
    }

    // Collect from Kerja
    for (var prog in controller.programStudiKerja) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;

        for (var karir in minatEntry.value.karir) {
          addKarirData(karir, prog.name, minatKey, 'Kerja');
        }
      }
    }

    // Collect from Kuliah
    for (var prog in controller.programStudiKuliah) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;

        for (var karir in minatEntry.value.karir) {
          addKarirData(karir, prog.name, minatKey, 'Kuliah');
        }
      }
    }

    // Convert to list for display
    final karirList = karirMap.entries.map((entry) {
      return {
        'name': entry.key,
        'count': entry.value.length,
        'references': entry.value,
      };
    }).toList();

    // Sort by frequency
    karirList.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Karir',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.work,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total: ${karirList.length} karir',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: karirList.length,
                  itemBuilder: (context, index) {
                    final karir = karirList[index];
                    final references =
                        karir['references'] as List<Map<String, dynamic>>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          karir['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.teal.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'Referenced ${karir['count']} times',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        children: [
                          const Divider(indent: 16, endIndent: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Text(
                              'Referenced in:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: references.length,
                            itemBuilder: (context, i) {
                              final ref = references[i];
                              final isKerja = ref['type'] == 'Kerja';

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 4,
                                ),
                                title: Row(
                                  children: [
                                    _buildQuestionTag(
                                      isKerja ? 'Kerja' : 'Kuliah',
                                      isKerja ? Colors.blue : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ref['program'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Minat: ${ref['minat']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                leading: Icon(
                                  isKerja ? Icons.work : Icons.school,
                                  color: isKerja ? Colors.blue : Colors.green,
                                  size: 20,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  /// Tab untuk menampilkan data ProgramStudi (Kerja atau Kuliah) dengan UI yang ditingkatkan
  Widget buildDataTab(
      DevDataViewerController controller,
      List<ProgramStudi> data,
      String type,
      Color primaryColor,
      Color secondaryColor) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (type == 'Kerja' ? Colors.blue : Colors.green)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  type == 'Kerja' ? Icons.work : Icons.school,
                  color: type == 'Kerja' ? Colors.blue : Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$type Dataset',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${data.length} Program Studi',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final program = data[index];
              final minatCount = program.minat.length;
              int pertanyaanCount = 0;

              // Count pertanyaan
              for (var minat in program.minat.values) {
                pertanyaanCount += minat.pertanyaan.length;
              }

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    program.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildCompactTag(
                            '$minatCount minat',
                            type == 'Kerja' ? Colors.blue : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _buildCompactTag(
                            '$pertanyaanCount pertanyaan',
                            Colors.amber.shade800,
                          ),
                        ],
                      ),
                      if (program.categories.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Categories: ${program.categories.join(", ")}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Program description
                    if (program.description.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              program.description,
                              style: const TextStyle(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Minat details
                    ...program.minat.entries.map((minatEntry) {
                      final minatKey = minatEntry.key;
                      final minatValue = minatEntry.value;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            childrenPadding: const EdgeInsets.only(
                              bottom: 16,
                              left: 16,
                              right: 16,
                            ),
                            title: Text(
                              'Minat: $minatKey',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              '${minatValue.pertanyaan.length} pertanyaan',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  (type == 'Kerja' ? Colors.blue : Colors.green)
                                      .withOpacity(0.2),
                              child: Icon(
                                Icons.interests,
                                color: type == 'Kerja'
                                    ? Colors.blue
                                    : Colors.green,
                                size: 20,
                              ),
                            ),
                            children: [
                              // Pertanyaan
                              if (minatValue.pertanyaan.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                _buildMinatSectionHeader(
                                    'Pertanyaan', Icons.question_answer),
                                const SizedBox(height: 8),
                                ...minatValue.pertanyaan.map((p) {
                                  final bobot = extractBobot(p);
                                  final cleaned = cleanPertanyaan(p);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ',
                                            style: TextStyle(fontSize: 15)),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cleaned,
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                              const SizedBox(height: 2),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Bobot: $bobot',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        Colors.amber.shade800,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],

                              // Karir
                              if (minatValue.karir.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildMinatSectionHeader('Karir', Icons.work),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: minatValue.karir
                                      .map((k) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.teal.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.teal.shade200,
                                              ),
                                            ),
                                            child: Text(
                                              k,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.teal.shade700,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],

                              // Jurusan Terkait
                              if (minatValue.jurusanTerkait.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildMinatSectionHeader(
                                    'Jurusan Terkait', Icons.school),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: minatValue.jurusanTerkait
                                      .map((j) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.indigo.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.indigo.shade200,
                                              ),
                                            ),
                                            child: Text(
                                              j,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.indigo.shade700,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMinatSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade700,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Tab untuk menampilkan rules dengan UI yang ditingkatkan
  Widget buildRulesTab(DevDataViewerController controller, Color primaryColor,
      Color secondaryColor) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.rule,
                  color: Colors.amber.shade800,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Forward Chaining Rules',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${controller.rulesData.length} Rules',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildRuleFilterButton(controller, primaryColor),
            ],
          ),
        ),

        // Rule visualization using fl_chart
        Container(
          height: 180,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rule Distribution by Weight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Visualization of rule weights across the system',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: buildRuleWeightChart(
                    controller, primaryColor, secondaryColor),
              ),
            ],
          ),
        ),

        // Rules list
        Expanded(
          child: ListView.builder(
            itemCount: controller.rulesData.length,
            itemBuilder: (context, index) {
              final rule = controller.rulesData[index];
              final weight = rule['weight'] as int;

              // Determine color based on weight
              final Color weightColor = weight >= 4
                  ? Colors.red.shade700
                  : weight >= 3
                      ? Colors.orange.shade700
                      : weight >= 2
                          ? Colors.amber.shade700
                          : Colors.green.shade700;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rule ID avatar
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.amber.shade700,
                            child: Text(
                              rule['id'].toString().replaceAll('R', ''),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Rule condition and action
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rule['condition'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  rule['action'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Weight indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: weightColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: weightColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Weight: ${rule['weight']}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: weightColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),

                      // Question, program and minat details
                      Text(
                        'Question: ${rule['question']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildRuleTag(
                            rule['programName'],
                            Colors.indigo,
                            Icons.category,
                          ),
                          const SizedBox(width: 8),
                          _buildRuleTag(
                            'Minat: ${rule['minatKey']}',
                            Colors.teal,
                            Icons.interests,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRuleFilterButton(
      DevDataViewerController controller, Color primaryColor) {
    // You can implement filtering functionality here if needed
    return InkWell(
      onTap: () {
        // Show filter options
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_list,
              size: 16,
              color: primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Filter',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleTag(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRuleWeightChart(DevDataViewerController controller,
      Color primaryColor, Color secondaryColor) {
    // Count rules by weight
    final Map<int, int> weightCounts = {};

    for (var rule in controller.rulesData) {
      final weight = rule['weight'] as int;
      if (weightCounts.containsKey(weight)) {
        weightCounts[weight] = weightCounts[weight]! + 1;
      } else {
        weightCounts[weight] = 1;
      }
    }

    // Sort weights
    final sortedWeights = weightCounts.keys.toList()..sort();

    // Prepare bar chart data
    final List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < sortedWeights.length; i++) {
      final weight = sortedWeights[i];
      final count = weightCounts[weight]!;

      // Different colors for different weights
      final Color barColor = weight >= 4
          ? Colors.red.shade700
          : weight >= 3
              ? Colors.orange.shade700
              : weight >= 2
                  ? Colors.amber.shade700
                  : Colors.green.shade700;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: barColor,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final weight = sortedWeights[group.x.toInt()];
              return BarTooltipItem(
                'Weight $weight\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '${rod.toY.round()} rules',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
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
                if (value >= sortedWeights.length || value < 0)
                  return const Text('');
                return Text(
                  'W${sortedWeights[value.toInt()]}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                if (value % 1 != 0) return const Text('');
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }

  /// Tab untuk analisis kesesuaian dengan metode Forward Chaining dengan UI yang ditingkatkan
  Widget buildAnalysisTab(DevDataViewerController controller,
      Color primaryColor, Color secondaryColor) {
    // Prepare data for radar chart
    final List<double> scores = [
      90,
      75,
      80,
      95,
      85
    ]; // Implementation, Rule Structure, Inference, Explanation, Overall

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  secondaryColor,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Forward Chaining Model Analysis',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Evaluation of implementation quality',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Radar Chart
                Container(
                  height: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: buildAnalysisRadarChart(
                      scores, primaryColor, secondaryColor),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Analysis sections
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnalysisSection(
                  'Implementation Accuracy',
                  [
                    'The implementation correctly follows forward chaining principles:',
                    '• Uses a working memory to store facts',
                    '• Has a rule base of IF-THEN rules',
                    '• Implements pattern matching to find applicable rules',
                    '• Rules fire when their conditions match working memory',
                    '• Actions of fired rules can update scores (modify state)',
                  ],
                  90,
                  Icons.check_circle,
                  primaryColor,
                ),
                _buildAnalysisSection(
                  'Rule Structure',
                  [
                    'Rules follow standard structure but with simplifications:',
                    '• Conditions only check for presence of "Qn=Yes"',
                    '• More complex conditions (e.g., AND/OR combinations) aren\'t implemented',
                    '• Rule actions only increase scores instead of adding new facts',
                    '• The system does not support rule chaining (where firing one rule enables another)',
                  ],
                  75,
                  Icons.rule,
                  primaryColor,
                ),
                _buildAnalysisSection(
                  'Inference Process',
                  [
                    'The inference process is partially implemented:',
                    '• Rules are checked against working memory',
                    '• Matched rules are fired and actions executed',
                    '• The process loops until no more rules can fire',
                    '• However, since rules don\'t add new facts, the process completes in one iteration',
                    '• There\'s no conflict resolution strategy as all applicable rules are fired',
                  ],
                  80,
                  Icons.psychology,
                  primaryColor,
                ),
                _buildAnalysisSection(
                  'Results Explanation',
                  [
                    'The system provides good explanation capabilities:',
                    '• Shows which rules contributed to each recommendation',
                    '• Displays the questions that influenced the result',
                    '• Shows the weights/scores that led to the final ranking',
                    '• This transparency is a strength of the implementation',
                  ],
                  95,
                  Icons.info,
                  primaryColor,
                ),
                _buildAnalysisSection(
                  'Overall Assessment',
                  [
                    'This is a simplified but valid forward chaining implementation:',
                    '• It follows the core principles of the forward chaining method',
                    '• The implementation is well-suited for its specific use case',
                    '• The scoring mechanism is an appropriate adaptation for the recommendation context',
                    '• Areas for potential enhancement: more complex rule conditions, true fact generation, and multi-stage inference',
                  ],
                  85,
                  Icons.assessment,
                  primaryColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Improvement suggestions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: Colors.amber.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Improvement Suggestions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildImprovementItem(
                      'Implement full fact generation (not just scoring)',
                      1,
                      Colors.blue,
                    ),
                    _buildImprovementItem(
                      'Support complex conditions with AND/OR operators',
                      2,
                      Colors.green,
                    ),
                    _buildImprovementItem(
                      'Enable multi-stage inference with rule chaining',
                      3,
                      Colors.purple,
                    ),
                    _buildImprovementItem(
                      'Add conflict resolution strategies for rule prioritization',
                      4,
                      Colors.orange,
                    ),
                    _buildImprovementItem(
                      'Consider implementing backward chaining to complement forward chaining',
                      5,
                      Colors.teal,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget buildAnalysisRadarChart(
      List<double> scores, Color primaryColor, Color secondaryColor) {
    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        radarBorderData: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
        gridBorderData: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
        titlePositionPercentageOffset: 0.2,
        tickCount: 5,
        dataSets: [
          RadarDataSet(
            dataEntries: [
              RadarEntry(value: scores[0]), // Implementation
              RadarEntry(value: scores[1]), // Rule Structure
              RadarEntry(value: scores[2]), // Inference
              RadarEntry(value: scores[3]), // Explanation
              RadarEntry(value: scores[4]), // Overall
            ],
            fillColor: primaryColor.withOpacity(0.2),
            borderColor: primaryColor,
            borderWidth: 2,
            entryRadius: 4,
          ),
        ],
        ticksTextStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
        ),
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        getTitle: (index, angle) {
          final titles = [
            'Implementation',
            'Rule\nStructure',
            'Inference\nProcess',
            'Results\nExplanation',
            'Overall\nAssessment',
          ];
          return RadarChartTitle(
            text: titles[index],
            angle: angle,
            positionPercentageOffset: 0.1,
          );
        },
      ),
    );
  }

  Widget _buildAnalysisSection(String title, List<String> points,
      int scorePercent, IconData icon, Color primaryColor) {
    final Color scoreColor = _getScoreColor(scorePercent);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scoreColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '$scorePercent%',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            ...points.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    point,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: point.startsWith('•')
                          ? Colors.grey.shade800
                          : Colors.grey.shade900,
                      fontWeight: point.startsWith('•')
                          ? FontWeight.normal
                          : FontWeight.w500,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementItem(String text, int number, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green.shade700;
    if (score >= 80) return Colors.teal.shade700;
    if (score >= 70) return Colors.blue.shade700;
    if (score >= 60) return Colors.amber.shade700;
    if (score >= 50) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  Widget buildUGMDataTab(DevDataViewerController controller, Color primaryColor,
      Color secondaryColor) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  icon: Icon(Icons.school, color: primaryColor),
                  text: 'Program S1',
                ),
                Tab(
                  icon: Icon(Icons.school, color: secondaryColor),
                  text: 'Program D4',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // S1 Data Tab
                buildUGMProgramTab(controller.biayaKuliahS1UGM, 'S1',
                    primaryColor, secondaryColor),
                // D4 Data Tab
                buildUGMProgramTab(controller.biayaKuliahD4UGM, 'D4',
                    primaryColor, secondaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget to build UGM program data tab content with improved UI
  Widget buildUGMProgramTab(List<Map<String, dynamic>> data, String programType,
      Color primaryColor, Color secondaryColor) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No data available for this program type',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate average UKT for visualization
    final List<double> avgUktByCategory = [];
    final List<Map<String, dynamic>> filteredData =
        data.where((row) => row['NO'] != '').toList();

    for (int i = 1; i <= 6; i++) {
      double sum = 0;
      int count = 0;
      for (var row in filteredData) {
        final value = row['UKT_KELOMPOK_$i'];
        if (value != null && value.toString().isNotEmpty) {
          // Remove currency format and convert to double
          final cleanValue = value
              .toString()
              .replaceAll('Rp', '')
              .replaceAll('.', '')
              .replaceAll(',', '')
              .trim();
          if (cleanValue.isNotEmpty) {
            sum += double.tryParse(cleanValue) ?? 0;
            count++;
          }
        }
      }
      avgUktByCategory.add(count > 0 ? sum / count : 0);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  secondaryColor,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biaya Kuliah UGM - Program $programType',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${filteredData.length} program studi',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // UKT Chart
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rata-rata UKT per Kelompok',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Visualisasi biaya rata-rata per kelompok UKT',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: buildUktChart(
                            avgUktByCategory, primaryColor, secondaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Data Table
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Lengkap UKT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 15,
                          horizontalMargin: 10,
                          headingRowColor: MaterialStateProperty.all(
                              primaryColor.withOpacity(0.1)),
                          headingTextStyle: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          border: TableBorder(
                            borderRadius: BorderRadius.circular(8),
                            verticalInside: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                            horizontalInside: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          columns: [
                            const DataColumn(label: Text('NO')),
                            const DataColumn(label: Text('PROGRAM')),
                            const DataColumn(label: Text('NAMA PROGRAM STUDI')),
                            const DataColumn(label: Text('BKT')),
                            const DataColumn(label: Text('UKT 1')),
                            const DataColumn(label: Text('UKT 2')),
                            const DataColumn(label: Text('UKT 3')),
                            const DataColumn(label: Text('UKT 4')),
                            const DataColumn(label: Text('UKT 5')),
                            const DataColumn(label: Text('UKT 6')),
                          ],
                          rows: filteredData.map((row) {
                            return DataRow(
                              cells: [
                                DataCell(Text(row['NO'] ?? '')),
                                DataCell(Text(row['PROGRAM'] ?? '')),
                                DataCell(Text(row['NAMA PROGRAM STUDI'] ?? '')),
                                DataCell(Text(row['BKT PER SEMESTER'] ?? '')),
                                DataCell(_buildUktCell(
                                    row['UKT_KELOMPOK_1'] ?? '', primaryColor)),
                                DataCell(_buildUktCell(
                                    row['UKT_KELOMPOK_2'] ?? '', primaryColor)),
                                DataCell(_buildUktCell(
                                    row['UKT_KELOMPOK_3'] ?? '', primaryColor)),
                                DataCell(_buildUktCell(
                                    row['UKT_KELOMPOK_4'] ?? '', primaryColor)),
                                DataCell(_buildUktCell(
                                    row['UKT_KELOMPOK_5'] ?? '', primaryColor)),
                                DataCell(_buildUktCell(
                                    row['UKT_KELOMPOK_6'] ?? '', primaryColor)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // UKT Explanation
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Penjelasan UKT',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildUktInfo(
                      'UKT Kelompok 1',
                      'Pendidikan Unggul Bersubsidi 100%',
                      1,
                      primaryColor,
                    ),
                    _buildUktInfo(
                      'UKT Kelompok 2',
                      'Pendidikan Unggul Bersubsidi 100%',
                      2,
                      primaryColor,
                    ),
                    _buildUktInfo(
                      'UKT Kelompok 3',
                      'Pendidikan Unggul Bersubsidi 75%',
                      3,
                      primaryColor,
                    ),
                    _buildUktInfo(
                      'UKT Kelompok 4',
                      'Pendidikan Unggul Bersubsidi 50%',
                      4,
                      primaryColor,
                    ),
                    _buildUktInfo(
                      'UKT Kelompok 5',
                      'Pendidikan Unggul Bersubsidi 25%',
                      5,
                      primaryColor,
                    ),
                    _buildUktInfo(
                      'UKT Kelompok 6',
                      'Pendidikan Unggul (Biaya Penuh)',
                      6,
                      primaryColor,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildUktInfoNote(
                      'BKT: Biaya Kuliah Tunggal',
                      'Biaya operasional per mahasiswa per semester',
                      Icons.account_balance_wallet,
                      Colors.amber.shade700,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUktCell(String value, Color color) {
    if (value.isEmpty) return const Text('-');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color:
            value.contains('0') ? Colors.grey.shade100 : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontWeight: value.contains('0') ? FontWeight.normal : FontWeight.w500,
          color: value.contains('0') ? Colors.grey.shade600 : Colors.black,
        ),
      ),
    );
  }

  Widget _buildUktInfo(
      String title, String description, int group, Color color) {
    // Determine color based on group
    final Color groupColor = group <= 2
        ? Colors.green.shade700
        : group <= 4
            ? Colors.amber.shade700
            : Colors.red.shade700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: groupColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: groupColor,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                group.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: groupColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
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
    );
  }

  Widget _buildUktInfoNote(
      String title, String description, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildUktChart(
      List<double> data, Color primaryColor, Color secondaryColor) {
    final List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < data.length; i++) {
      // Determine color based on UKT group
      final Color barColor = i <= 1
          ? Colors.green.shade700
          : i <= 3
              ? Colors.amber.shade700
              : Colors.red.shade700;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: data[i],
              color: barColor,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              // Format currency
              final formattedValue = _formatCurrency(rod.toY);

              return BarTooltipItem(
                'UKT Kelompok ${groupIndex + 1}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: formattedValue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
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
                return Text(
                  'K${value.toInt() + 1}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                // Show abbreviated values (e.g., 1M for 1,000,000)
                String label = '';
                if (value >= 1000000) {
                  label = '${(value / 1000000).toStringAsFixed(1)}M';
                } else if (value >= 1000) {
                  label = '${(value / 1000).toStringAsFixed(0)}K';
                } else {
                  label = value.toStringAsFixed(0);
                }
                return Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1000000, // 1 million
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value == 0) return 'Rp 0';

    // Format as Indonesian Rupiah
    final formatted = value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match.group(1)}.');

    return 'Rp $formatted';
  }
}
