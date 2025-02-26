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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Data Viewer'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.loadingError.value.isNotEmpty) {
          return Center(child: Text('Error: ${controller.loadingError.value}'));
        }

        return Column(
          children: [
            // Tab navigation
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTab(controller, 'overview', 'Overview'),
                    _buildTab(controller, 'kerja', 'Kerja Data'),
                    _buildTab(controller, 'kuliah', 'Kuliah Data'),
                    _buildTab(controller, 'rules', 'Rules'),
                    _buildTab(controller, 'analysis', 'Model Analysis'),
                    _buildTab(controller, 'ugm', 'UGM Data'),
                  ],
                ),
              ),
            ),

            // Content based on selected tab
            Expanded(
              child: buildContent(controller),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTab(
      DevDataViewerController controller, String viewName, String label) {
    return InkWell(
      onTap: () => controller.setCurrentView(viewName),
      splashColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: controller.currentView.value == viewName
              ? Colors.blue
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: controller.currentView.value == viewName
                ? Colors.white
                : Colors.black,
            fontWeight: controller.currentView.value == viewName
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget buildContent(DevDataViewerController controller) {
    switch (controller.currentView.value) {
      case 'overview':
        return buildOverviewTab(controller);
      case 'kerja':
        return buildDataTab(controller, controller.programStudiKerja, 'Kerja');
      case 'kuliah':
        return buildDataTab(
            controller, controller.programStudiKuliah, 'Kuliah');
      case 'rules':
        return buildRulesTab(controller);
      case 'analysis':
        return buildAnalysisTab(controller);
      case 'ugm':
        return buildUGMDataTab(controller);
      default:
        return const Center(child: Text('Unknown view'));
    }
  }

  /// Tab Overview - statistik umum
  Widget buildOverviewTab(DevDataViewerController controller) {
    return Container(
      color: Colors.blueAccent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Data Aplikasi',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Stats Cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  'Total Questions',
                  controller.getTotalQuestions().toString(),
                  Icons.question_answer,
                  onTap: () => _showQuestionsDialog(controller),
                ),
                _buildStatCard(
                  'Total Rules',
                  controller.rulesData.length.toString(),
                  Icons.rule,
                  onTap: () => _showRulesDialog(controller),
                ),
                _buildStatCard(
                  'Total Minat',
                  controller.getTotalMinat().toString(),
                  Icons.category,
                  onTap: () => _showMinatDialog(controller),
                ),
                _buildStatCard(
                  'Total Jurusan',
                  controller.getTotalJurusan().toString(),
                  Icons.school,
                  onTap: () => _showJurusanDialog(controller),
                ),
                _buildStatCard(
                  'Total Karir',
                  controller.getTotalKarir().toString(),
                  Icons.work,
                  onTap: () => _showKarirDialog(controller),
                ),
                _buildStatCard(
                    'Data Sources', '6 JSON Files', Icons.data_array),
              ],
            ),

            const SizedBox(height: 30),

            // Forward Chaining Explanation
            const Text(
              'Implementasi Forward Chaining',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Model ini mengimplementasikan pendekatan Forward Chaining berbasis aturan dengan:'),
                    SizedBox(height: 8),
                    Text(
                        '• Memori Kerja: Menyimpan fakta seperti "Q1=Ya" / "Q1=Tidak"'),
                    Text(
                        '• Basis Aturan: Aturan dalam bentuk "JIKA kondisi MAKA aksi"'),
                    Text(
                        '• Mesin Inferensi: Menerapkan aturan pada memori kerja untuk mendapatkan skor'),
                    Text(
                        '• Pembobotan Skor: Setiap pertanyaan memiliki bobot yang berkontribusi pada skor akhir'),
                    SizedBox(height: 8),
                    Text(
                        'Implementasi ini adalah sistem produksi klasik dengan siklus cocok-selesaikan-bertindak yang berlanjut hingga tidak ada lagi aturan yang dapat dijalankan.'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Visualisasi Flow Forward Chaining
            const Text(
              'Alur Forward Chaining',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '1. Pengguna menjawab pertanyaan (Ya/Tidak) untuk menetapkan fakta awal'),
                    Text(
                        '2. Fakta ditambahkan ke dalam memori kerja (misalnya, "Q1=Ya")'),
                    Text(
                        '3. Aturan yang sesuai dengan fakta dalam memori kerja dijalankan'),
                    Text(
                        '4. Setiap aturan yang dijalankan menambahkan skor ke minat yang sesuai'),
                    Text(
                        '5. Setelah semua aturan dievaluasi, minat diurutkan berdasarkan skor'),
                    Text('6. Tiga minat teratas disajikan sebagai rekomendasi'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 5),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              if (onTap != null) const SizedBox(height: 5),
              if (onTap != null)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lihat Detail',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.touch_app,
                      size: 12,
                      color: Colors.blue,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  } // Add the dialog methods to show detailed information when a card is tapped

  void _showQuestionsDialog(DevDataViewerController controller) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'All Questions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Total: ${allQuestions.length} questions'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: allQuestions.length,
                  itemBuilder: (context, index) {
                    final q = allQuestions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(q['pertanyaan']),
                        subtitle: Text(
                          '${q['type']} | ${q['program']} | ${q['minat']} | Bobot: ${q['bobot']}',
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              q['type'] == 'Kerja' ? Colors.blue : Colors.green,
                          child: Text('${index + 1}'),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRulesDialog(DevDataViewerController controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'All Rules',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Total: ${controller.rulesData.length} rules'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.rulesData.length,
                  itemBuilder: (context, index) {
                    final rule = controller.rulesData[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${rule['condition']} ${rule['action']}'),
                        subtitle: Text(
                          'Question: ${rule['question']}\nProgram: ${rule['programName']} | Minat: ${rule['minatKey']} | Weight: ${rule['weight']}',
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber,
                          child:
                              Text(rule['id'].toString().replaceAll('R', '')),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMinatDialog(DevDataViewerController controller) {
    final allMinat = <Map<String, dynamic>>[];

    // Collect minat from Kerja
    for (var prog in controller.programStudiKerja) {
      for (var minatEntry in prog.minat.entries) {
        allMinat.add({
          'name': minatEntry.key,
          'program': prog.name,
          'type': 'Kerja',
          'jumlahPertanyaan': minatEntry.value.pertanyaan.length,
          'jumlahKarir': minatEntry.value.karir.length,
          'jumlahJurusan': minatEntry.value.jurusanTerkait.length,
        });
      }
    }

    // Collect minat from Kuliah
    for (var prog in controller.programStudiKuliah) {
      for (var minatEntry in prog.minat.entries) {
        allMinat.add({
          'name': minatEntry.key,
          'program': prog.name,
          'type': 'Kuliah',
          'jumlahPertanyaan': minatEntry.value.pertanyaan.length,
          'jumlahKarir': minatEntry.value.karir.length,
          'jumlahJurusan': minatEntry.value.jurusanTerkait.length,
        });
      }
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'All Minat',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Total: ${allMinat.length} minat'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: allMinat.length,
                  itemBuilder: (context, index) {
                    final minat = allMinat[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(minat['name']),
                        subtitle: Text(
                          '${minat['type']} | ${minat['program']}\nPertanyaan: ${minat['jumlahPertanyaan']} | Karir: ${minat['jumlahKarir']} | Jurusan: ${minat['jumlahJurusan']}',
                        ),
                        leading: CircleAvatar(
                          backgroundColor: minat['type'] == 'Kerja'
                              ? Colors.blue
                              : Colors.green,
                          child: Text('${index + 1}'),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJurusanDialog(DevDataViewerController controller) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'All Jurusan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Total: ${jurusanList.length} jurusan'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: jurusanList.length,
                  itemBuilder: (context, index) {
                    final jurusan = jurusanList[index];
                    final references =
                        jurusan['references'] as List<Map<String, dynamic>>;

                    return ExpansionTile(
                      title: Text(jurusan['name'] as String),
                      subtitle: Text('Referenced ${jurusan['count']} times'),
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Text('${index + 1}'),
                      ),
                      children: [
                        ...references.map((ref) {
                          return ListTile(
                            title: Text('${ref['type']} | ${ref['program']}'),
                            subtitle: Text('Minat: ${ref['minat']}'),
                            leading: Icon(
                              ref['type'] == 'Kerja'
                                  ? Icons.work
                                  : Icons.school,
                              color: ref['type'] == 'Kerja'
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showKarirDialog(DevDataViewerController controller) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'All Karir',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Total: ${karirList.length} karir'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: karirList.length,
                  itemBuilder: (context, index) {
                    final karir = karirList[index];
                    final references =
                        karir['references'] as List<Map<String, dynamic>>;

                    return ExpansionTile(
                      title: Text(karir['name'] as String),
                      subtitle: Text('Referenced ${karir['count']} times'),
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Text('${index + 1}'),
                      ),
                      children: [
                        ...references.map((ref) {
                          return ListTile(
                            title: Text('${ref['type']} | ${ref['program']}'),
                            subtitle: Text('Minat: ${ref['minat']}'),
                            leading: Icon(
                              ref['type'] == 'Kerja'
                                  ? Icons.work
                                  : Icons.school,
                              color: ref['type'] == 'Kerja'
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab untuk menampilkan data ProgramStudi (Kerja atau Kuliah)
  /// Tab untuk menampilkan data ProgramStudi (Kerja atau Kuliah)
  Widget buildDataTab(DevDataViewerController controller,
      List<ProgramStudi> data, String type) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '$type Dataset - ${data.length} Program Studi',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

              return ExpansionTile(
                title: Text(program.name),
                subtitle:
                    Text('$minatCount minat, $pertanyaanCount pertanyaan'),
                children: [
                  // Program description
                  if (program.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text('Description: ${program.description}'),
                    ),

                  // Categories
                  if (program.categories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child:
                          Text('Categories: ${program.categories.join(", ")}'),
                    ),

                  // Minat details
                  ...program.minat.entries.map((minatEntry) {
                    final minatKey = minatEntry.key;
                    final minatValue = minatEntry.value;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ExpansionTile(
                          title: Text('Minat: $minatKey'),
                          subtitle: Text(
                              '${minatValue.pertanyaan.length} pertanyaan'),
                          children: [
                            // Pertanyaan
                            if (minatValue.pertanyaan.isNotEmpty)
                              ListTile(
                                title: const Text('Pertanyaan:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: minatValue.pertanyaan.map((p) {
                                    final bobot = extractBobot(p);
                                    final cleaned = cleanPertanyaan(p);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text('• $cleaned [bobot: $bobot]'),
                                    );
                                  }).toList(),
                                ),
                              ),

                            // Karir
                            if (minatValue.karir.isNotEmpty)
                              ListTile(
                                title: const Text('Karir:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: minatValue.karir
                                      .map((k) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Text('• $k'),
                                          ))
                                      .toList(),
                                ),
                              ),

                            // Jurusan Terkait
                            if (minatValue.jurusanTerkait.isNotEmpty)
                              ListTile(
                                title: const Text('Jurusan Terkait:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: minatValue.jurusanTerkait
                                      .map((j) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Text('• $j'),
                                          ))
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Tab untuk menampilkan rules
  Widget buildRulesTab(DevDataViewerController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Forward Chaining Rules - ${controller.rulesData.length} Rules',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // Search & Filter controls could be added here

        Expanded(
          child: ListView.builder(
            itemCount: controller.rulesData.length,
            itemBuilder: (context, index) {
              final rule = controller.rulesData[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(
                      '${rule['id']}: ${rule['condition']} ${rule['action']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Question: ${rule['question']}'),
                      Text(
                          'Weight: ${rule['weight']} | Program: ${rule['programName']} | Minat: ${rule['minatKey']}'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Tab untuk analisis kesesuaian dengan metode Forward Chaining
  Widget buildAnalysisTab(DevDataViewerController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Forward Chaining Model Analysis',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 16),

          // Analysis of implementation
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
          ),

          const SizedBox(height: 30),

          // Recommendations for improvement
          const Text(
            'Improvement Suggestions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Implement full fact generation (not just scoring)'),
                  Text('2. Support complex conditions with AND/OR operators'),
                  Text('3. Enable multi-stage inference with rule chaining'),
                  Text(
                      '4. Add conflict resolution strategies for rule prioritization'),
                  Text(
                      '5. Consider implementing backward chaining to complement forward chaining'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUGMDataTab(DevDataViewerController controller) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Program S1'),
              Tab(text: 'Program D4'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // S1 Data Tab
                buildUGMProgramTab(controller.biayaKuliahS1UGM, 'S1'),
                // D4 Data Tab
                buildUGMProgramTab(controller.biayaKuliahD4UGM, 'D4'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget to build UGM program data tab content
  Widget buildUGMProgramTab(
      List<Map<String, dynamic>> data, String programType) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available for this program type'),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biaya Kuliah UGM - Program $programType',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Data Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 15,
                horizontalMargin: 10,
                headingRowColor:
                    MaterialStateProperty.all(Colors.blue.shade100),
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
                rows: data
                    .where((row) => row['NO'] != '') // Skip header row
                    .map((row) {
                  return DataRow(
                    cells: [
                      DataCell(Text(row['NO'] ?? '')),
                      DataCell(Text(row['PROGRAM'] ?? '')),
                      DataCell(Text(row['NAMA PROGRAM STUDI'] ?? '')),
                      DataCell(Text(row['BKT PER SEMESTER'] ?? '')),
                      DataCell(Text(row['UKT_KELOMPOK_1'] ?? '')),
                      DataCell(Text(row['UKT_KELOMPOK_2'] ?? '')),
                      DataCell(Text(row['UKT_KELOMPOK_3'] ?? '')),
                      DataCell(Text(row['UKT_KELOMPOK_4'] ?? '')),
                      DataCell(Text(row['UKT_KELOMPOK_5'] ?? '')),
                      DataCell(Text(row['UKT_KELOMPOK_6'] ?? '')),
                    ],
                  );
                }).toList(),
              ),
            ),

            // Semester Fee Summary
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Penjelasan UKT (Uang Kuliah Tunggal)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        '• UKT Kelompok 1: Pendidikan Unggul Bersubsidi 100%'),
                    const Text(
                        '• UKT Kelompok 2: Pendidikan Unggul Bersubsidi 100%'),
                    const Text(
                        '• UKT Kelompok 3: Pendidikan Unggul Bersubsidi 75%'),
                    const Text(
                        '• UKT Kelompok 4: Pendidikan Unggul Bersubsidi 50%'),
                    const Text(
                        '• UKT Kelompok 5: Pendidikan Unggul Bersubsidi 25%'),
                    const Text(
                        '• UKT Kelompok 6: Pendidikan Unggul (Biaya Penuh)'),
                    const SizedBox(height: 8),
                    const Text(
                        'BKT: Biaya Kuliah Tunggal (Biaya operasional per mahasiswa per semester)'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(
      String title, List<String> points, int scorePercent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getScoreColor(scorePercent),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '$scorePercent%',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            ...points.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(point),
                )),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
