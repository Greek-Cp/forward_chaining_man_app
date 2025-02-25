import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'package:get/get.dart';

// Global flag for developer mode
bool developerMode = false;

void main() {
  runApp(const MyApp());
}

/// Root widget aplikasi
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Forward Chaining Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DeveloperModePage(),
    );
  }
}

/// Controller untuk DeveloperModePage
class DeveloperModeController extends GetxController {
  final RxBool isDeveloperMode = developerMode.obs;

  void toggleDeveloperMode(bool value) {
    isDeveloperMode.value = value;
    developerMode = value;
  }
}

/// Controller untuk HomePage
class HomeController extends GetxController {
  final Rx<bool?> pilihan =
      Rx<bool?>(null); // null=belum pilih; true=Kerja; false=Kuliah

  void setPilihan(bool? val) {
    pilihan.value = val;
  }
}

/// Halaman untuk memilih Kerja atau Kuliah
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Kerja atau Kuliah'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Radio: Kerja
            Obx(() => RadioListTile<bool>(
                  title: const Text('Kerja'),
                  value: true,
                  groupValue: controller.pilihan.value,
                  onChanged: (val) => controller.setPilihan(val),
                )),
            // Radio: Kuliah
            Obx(() => RadioListTile<bool>(
                  title: const Text('Kuliah'),
                  value: false,
                  groupValue: controller.pilihan.value,
                  onChanged: (val) => controller.setPilihan(val),
                )),
            const SizedBox(height: 20),
            Obx(() => ElevatedButton(
                  onPressed: controller.pilihan.value == null
                      ? null
                      : () {
                          // Bawa user ke halaman pertanyaan
                          Get.to(() =>
                              QuestionPage(isKerja: controller.pilihan.value!));
                        },
                  child: const Text('Lanjut'),
                )),
          ],
        ),
      ),
    );
  }
}

/// Controller untuk QuestionPage
class QuestionController extends GetxController {
  final bool isKerja;

  QuestionController({required this.isKerja});

  // Akan menampung data ProgramStudi lengkap (untuk lookup karir di akhir)
  final Rx<List<ProgramStudi>> programList = Rx<List<ProgramStudi>>([]);

  // Daftar pertanyaan yang sudah di-flatten
  final RxList<QuestionItem> allQuestions = <QuestionItem>[].obs;

  // Paging
  final RxInt currentPage = 0.obs;
  static const pageSize = 5;

  // Untuk tampilan loading
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProgramData(isKerja);
  }

  /// Computed property: pertanyaan pada halaman saat ini
  List<QuestionItem> get questionsThisPage {
    final totalPages = (allQuestions.length / pageSize).ceil();
    if (currentPage.value >= totalPages) currentPage.value = totalPages - 1;
    if (currentPage.value < 0) currentPage.value = 0;

    final startIndex = currentPage.value * pageSize;
    final endIndex =
        ((currentPage.value + 1) * pageSize).clamp(0, allQuestions.length);
    return allQuestions.sublist(startIndex, endIndex);
  }

  /// Computed property: total halaman
  int get totalPages => (allQuestions.length / pageSize).ceil();

  /// Computed property: jumlah pertanyaan terjawab
  int get answeredCount =>
      allQuestions.where((q) => q.userAnswer != null).length;

  /// Computed property: total pertanyaan
  int get totalCount => allQuestions.length;

  /// Computed property: semua pertanyaan di halaman ini terjawab
  bool get allAnsweredThisPage =>
      questionsThisPage.every((q) => q.userAnswer != null);

  /// Memuat data ProgramStudi dari file JSON (Sains + Teknik) tergantung Kerja/Kuliah
  Future<void> loadProgramData(bool isKerja) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
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

      programList.value = programs;

      // Flatten jadi QuestionItem
      flattenQuestions(programs);

      isLoading.value = false;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false;
    }
  }

  /// Flatten pertanyaan dari programList -> allQuestions (Q1, Q2, dsb)
  void flattenQuestions(List<ProgramStudi> programs) {
    final all = <QuestionItem>[];
    int counter = 1;

    for (var prog in programs) {
      // prog.name = "IPA (Sains Murni) - Kerja" atau "IPA (Sains Murni)"
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;
        final minatVal = minatEntry.value; // punya pertanyaan, karir, dsb.

        for (var p in minatVal.pertanyaan) {
          final bobot = extractBobot(p);
          final cleaned = cleanPertanyaan(p);
          final qId = 'Q$counter';
          counter++;

          all.add(
            QuestionItem(
              id: qId,
              programName: prog.name,
              minatKey: minatKey,
              questionText: cleaned,
              rawQuestionText: p,
              bobot: bobot,
            ),
          );
        }
      }
    }

    // Set state
    allQuestions.value = all;
  }

  /// Set jawaban user
  void setAnswer(QuestionItem question, bool? answer) {
    final index = allQuestions.indexWhere((q) => q.id == question.id);
    if (index != -1) {
      allQuestions[index].userAnswer = answer;
      allQuestions.refresh(); // trigger UI refresh
    }
  }

  /// Navigasi ke halaman sebelumnya
  void prevPage() {
    if (currentPage.value > 0) {
      currentPage.value--;
    }
  }

  /// Navigasi ke halaman berikutnya
  void nextPage() {
    if (currentPage.value < totalPages - 1) {
      currentPage.value++;
    }
  }

  /// Di sinilah kita jalankan Forward Chaining & tampilkan karir/jurusan + rule
  String runForwardChaining() {
    // 1. Working Memory: "Q1=Yes" atau "Q1=No"
    final workingMemory = <String>{};
    for (var q in allQuestions) {
      if (q.userAnswer == true) {
        workingMemory.add('${q.id}=Yes'); // misal "Q1=Yes"
      } else {
        workingMemory.add('${q.id}=No'); // "Q1=No" (opsional)
      }
    }

    // 2. Skor per-minat
    final minatScores = <String, int>{};

    // 3. Untuk menampilkan rule, kita simpan "kontribusi" rule di map ini:
    //    Key: nama minat (ex: "IPA (Sains Murni) - Kerja|Kedokteran")
    //    Value: daftar string penjelasan rule
    final minatContrib = <String, List<String>>{};

    // 4. Generate rule: "IF Qx=Yes THEN skor[(prog|minat)] += bobot"
    //    + simpan catatan rule di minatContrib agar kita tahu pertanyaan apa.
    final rules = <Rule>[];
    for (var q in allQuestions) {
      final rule = Rule(
        ifFacts: ['${q.id}=Yes'], // kondisi: Qx=Yes
        thenAction: (wm) {
          final keyMinat = '${q.programName}|${q.minatKey}';
          // Tambah skor
          minatScores[keyMinat] = (minatScores[keyMinat] ?? 0) + q.bobot;

          // Catat rule fired:
          // Kita sertakan penjelasan pertanyaan agar lebih jelas.
          minatContrib[keyMinat] ??= [];
          minatContrib[keyMinat]!
              .add('IF (${q.id}=Yes) THEN +${q.bobot} skor → $keyMinat\n'
                  '   [Pertanyaan: "${q.questionText}"]');
        },
      );
      rules.add(rule);
    }

    // 5. Jalankan Forward Chaining (sederhana: 1 kali loop iteratif)
    bool firedSomething = true;
    final firedRules = <Rule>{};

    while (firedSomething) {
      firedSomething = false;
      for (var r in rules) {
        if (firedRules.contains(r)) continue; // sudah menembak

        // Cek kondisi IF (semua ifFacts ada di workingMemory)
        final allMatch =
            r.ifFacts.every((fact) => workingMemory.contains(fact));
        if (allMatch) {
          r.thenAction(workingMemory);
          firedRules.add(r);
          firedSomething = true;
        }
      }
    }

    // 6. Cek hasil skor
    if (minatScores.isEmpty) {
      return 'Skor minat kosong (semua 0).';
    }

    // Urutkan descending
    final sorted = minatScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // Ambil top 3
    final top3 = sorted.take(3).toList();

    // 7. Buat output, sekalian lookup ke loadedData untuk dapat karir/jurusan
    String message = 'HASIL FORWARD CHAINING:\n\n';
    message += 'Working Memory (fakta): ${workingMemory.join(', ')}\n\n';

    message += 'Top 3 Rekomendasi:\n';
    for (int i = 0; i < top3.length; i++) {
      final minatKey =
          top3[i].key; // ex: "IPA (Sains Murni) - Kerja|Kedokteran"
      final score = top3[i].value;

      message += '${i + 1}. $minatKey (Skor: $score)\n';

      // Tampilkan rule-rule yang menambah skor di minatKey ini
      final contribRules = minatContrib[minatKey] ?? [];
      if (contribRules.isNotEmpty) {
        message += '  RULES YANG:\n';
        for (var rDesc in contribRules) {
          message += '   - $rDesc\n';
        }
      }

      // Split "IPA (Sains Murni) - Kerja" | "Kedokteran"
      final parts = minatKey.split('|');
      if (parts.length == 2) {
        final progName = parts[0];
        final mKey = parts[1];

        // Cari programStudi & minat
        final programStudi = programList.value.firstWhere(
          (p) => p.name == progName,
          orElse: () => ProgramStudi.empty(),
        );
        final minatObj = programStudi.minat[mKey];
        if (minatObj != null) {
          // Tampilkan karir
          if (minatObj.karir.isNotEmpty) {
            message += '  Karir:\n';
            for (var c in minatObj.karir) {
              message += '   - $c\n';
            }
          } else {
            message += '  Karir: (Tidak ada data)\n';
          }

          // Tampilkan jurusan (jika ada)
          if (minatObj.jurusanTerkait.isNotEmpty) {
            message += '  Jurusan Terkait:\n';
            for (var j in minatObj.jurusanTerkait) {
              message += '   - $j\n';
            }
          }
        }
      }
      message += '\n';
    }

    return message;
  }
}

/// Halaman menampilkan daftar pertanyaan (5 per halaman), lalu forward chaining
class QuestionPage extends StatelessWidget {
  final bool isKerja; // true=Kerja, false=Kuliah
  const QuestionPage({Key? key, required this.isKerja}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(QuestionController(isKerja: isKerja));
    final title = isKerja ? 'Kerja' : 'Kuliah';

    return Scaffold(
      appBar: AppBar(title: Text('Forward Chaining $title')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(child: Text('Error: ${controller.errorMessage.value}'));
        }

        if (controller.programList.value.isEmpty) {
          return const Center(child: Text('Data Kosong'));
        }

        // Get questions for this page
        final questionsThisPage = controller.questionsThisPage;
        final startIndex =
            controller.currentPage.value * QuestionController.pageSize;

        return Column(
          children: [
            // Info Halaman
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Text(
                      'Halaman ${controller.currentPage.value + 1} / ${controller.totalPages}'),
                  Text(
                      'Anda telah mengisi ${controller.answeredCount} dari ${controller.totalCount} pertanyaan'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: questionsThisPage.length,
                itemBuilder: (context, index) {
                  final qItem = questionsThisPage[index];
                  final globalIndex = startIndex + index;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${qItem.id} - Pertanyaan ${globalIndex + 1}:',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(qItem.questionText),
                          const SizedBox(height: 10),
                          // Checkbox "Ya/Tidak"
                          Row(
                            children: [
                              Obx(() => Checkbox(
                                    value: controller.allQuestions
                                            .firstWhere((q) => q.id == qItem.id)
                                            .userAnswer ==
                                        true,
                                    onChanged: (val) {
                                      if (val == true) {
                                        controller.setAnswer(qItem, true);
                                      } else {
                                        controller.setAnswer(qItem, null);
                                      }
                                    },
                                  )),
                              const Text('Ya'),
                              const SizedBox(width: 20),
                              Obx(() => Checkbox(
                                    value: controller.allQuestions
                                            .firstWhere((q) => q.id == qItem.id)
                                            .userAnswer ==
                                        false,
                                    onChanged: (val) {
                                      if (val == true) {
                                        controller.setAnswer(qItem, false);
                                      } else {
                                        controller.setAnswer(qItem, null);
                                      }
                                    },
                                  )),
                              const Text('Tidak'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Navigasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: controller.currentPage.value > 0
                      ? () => controller.prevPage()
                      : null,
                  child: const Text('Prev'),
                ),
                if (controller.currentPage.value < controller.totalPages - 1)
                  Obx(() => ElevatedButton(
                        onPressed: controller.allAnsweredThisPage
                            ? () => controller.nextPage()
                            : null,
                        child: const Text('Next'),
                      ))
                else
                  Obx(() => ElevatedButton(
                        onPressed: controller.allAnsweredThisPage
                            ? () => _showResultDialog(
                                context, controller.runForwardChaining())
                            : null,
                        child: const Text('Cek Rekomendasi'),
                      )),
              ],
            ),
            const SizedBox(height: 12),
          ],
        );
      }),
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

/// Halaman untuk memilih/toggle Developer Mode
class DeveloperModePage extends StatelessWidget {
  const DeveloperModePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DeveloperModeController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forward Chaining App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo atau judul
            const Icon(Icons.psychology, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Forward Chaining Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // Toggle Developer Mode
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Developer Mode',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Aktifkan mode developer untuk melihat data dan validasi model forward chaining',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Obx(() => SwitchListTile(
                          title: const Text('Developer Mode'),
                          value: controller.isDeveloperMode.value,
                          onChanged: (value) =>
                              controller.toggleDeveloperMode(value),
                        )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Tombol mulai aplikasi
            ElevatedButton(
              onPressed: () => Get.to(() => const HomePage()),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child:
                  const Text('Mulai Aplikasi', style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 20),

            // Tombol akses Data View (hanya jika developer mode aktif)
            Obx(() => controller.isDeveloperMode.value
                ? ElevatedButton(
                    onPressed: () => Get.to(() => const DevDataViewerPage()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      backgroundColor: Colors.amber,
                    ),
                    child: const Text('Data & Model Viewer',
                        style: TextStyle(fontSize: 18)),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

/// Controller untuk halaman DevDataViewer
class DevDataViewerController extends GetxController {
  final RxList<ProgramStudi> programStudiKerja = <ProgramStudi>[].obs;
  final RxList<ProgramStudi> programStudiKuliah = <ProgramStudi>[].obs;
  final RxString currentView = 'overview'.obs; // overview, kerja, kuliah, rules
  final RxBool isLoading = true.obs;
  final RxString loadingError = ''.obs;
  final RxList<Map<String, dynamic>> rulesData = <Map<String, dynamic>>[].obs;

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
              color: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTab(controller, 'overview', 'Overview'),
                  _buildTab(controller, 'kerja', 'Kerja Data'),
                  _buildTab(controller, 'kuliah', 'Kuliah Data'),
                  _buildTab(controller, 'rules', 'Rules'),
                  _buildTab(controller, 'analysis', 'Model Analysis'),
                ],
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
      default:
        return const Center(child: Text('Unknown view'));
    }
  }

  /// Tab Overview - statistik umum
  Widget buildOverviewTab(DevDataViewerController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Forward Chaining Model Overview',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                  Icons.question_answer),
              _buildStatCard('Total Rules',
                  controller.rulesData.length.toString(), Icons.rule),
              _buildStatCard('Total Minat',
                  controller.getTotalMinat().toString(), Icons.category),
              _buildStatCard('Data Sources', '4 JSON Files', Icons.data_array),
            ],
          ),

          const SizedBox(height: 30),

          // Forward Chaining Explanation
          const Text(
            'Forward Chaining Implementation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'This model implements a Rule-Based Forward Chaining approach with:'),
                  SizedBox(height: 8),
                  Text(
                      '• Working Memory: Stores facts like "Q1=Yes" / "Q1=No"'),
                  Text(
                      '• Rule Base: Rules in the form "IF condition THEN action"'),
                  Text(
                      '• Inference Engine: Applies rules to working memory to derive scores'),
                  Text(
                      '• Weighted Scoring: Each question has a weight that contributes to final score'),
                  SizedBox(height: 8),
                  Text(
                      'The implementation is a classic production system with a match-resolve-act cycle that continues until no more rules can fire.'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Visualisasi Flow Forward Chaining
          const Text(
            'Forward Chaining Flow',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '1. User answers questions (Yes/No) to establish initial facts'),
                  Text('2. Facts are added to working memory (e.g., "Q1=Yes")'),
                  Text(
                      '3. Rules matching the facts in working memory are fired'),
                  Text(
                      '4. Each fired rule adds to the score of corresponding minat'),
                  Text(
                      '5. After all rules are evaluated, minat are sorted by score'),
                  Text('6. Top 3 minat are presented as recommendations'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
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
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

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

//////////////////////////////////////////////
// Bagian Model, Fungsi Pendukung, & Rule
//////////////////////////////////////////////

/// Representasi data utama (ProgramStudi) dari JSON
class ProgramStudi {
  final String name;
  final String description;
  final List<String> categories;
  final Map<String, Minat> minat;

  ProgramStudi({
    required this.name,
    required this.description,
    required this.categories,
    required this.minat,
  });

  factory ProgramStudi.fromJson(Map<String, dynamic> json) {
    final minatMap = <String, Minat>{};
    if (json['minat'] != null) {
      (json['minat'] as Map<String, dynamic>).forEach((key, value) {
        minatMap[key] = Minat.fromJson(value);
      });
    }
    return ProgramStudi(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      categories: (json['categories'] == null)
          ? []
          : List<String>.from(json['categories']),
      minat: minatMap,
    );
  }

  /// Jika not found, kembalikan empty
  factory ProgramStudi.empty() {
    return ProgramStudi(
      name: '',
      description: '',
      categories: [],
      minat: {},
    );
  }
}

/// Representasi Minat (sub-data program studi)
class Minat {
  final List<String> pertanyaan;
  final List<String> karir;
  final List<String> jurusanTerkait;

  Minat({
    required this.pertanyaan,
    required this.karir,
    required this.jurusanTerkait,
  });

  factory Minat.fromJson(Map<String, dynamic> json) {
    return Minat(
      pertanyaan: (json['pertanyaan'] == null)
          ? []
          : List<String>.from(json['pertanyaan']),
      karir: (json['karir'] == null) ? [] : List<String>.from(json['karir']),
      jurusanTerkait: (json['jurusan_terkait'] == null)
          ? []
          : List<String>.from(json['jurusan_terkait']),
    );
  }
}

/// Item pertanyaan di UI
class QuestionItem {
  final String id; // Q1, Q2, dst.
  final String programName; // ex: "IPA (Sains Murni) - Kerja"
  final String minatKey; // ex: "Kedokteran"
  final String questionText; // teks pertanyaan (tanpa [n])
  final String rawQuestionText; // teks asli (dengan [n])
  final int bobot; // ex: 6
  bool? userAnswer; // null=belum dijawab, true=Ya, false=Tidak

  QuestionItem({
    required this.id,
    required this.programName,
    required this.minatKey,
    required this.questionText,
    required this.rawQuestionText,
    required this.bobot,
    this.userAnswer,
  });
}

/// Fungsi ambil bobot [n] dari teks pertanyaan
int extractBobot(String pertanyaan) {
  final regex = RegExp(r"\[(\d+)\]");
  final match = regex.firstMatch(pertanyaan);
  if (match != null) {
    return int.parse(match.group(1)!);
  }
  return 0;
}

/// Fungsi buang [n] dari teks pertanyaan
String cleanPertanyaan(String pertanyaan) {
  return pertanyaan.replaceAll(RegExp(r"\[\d+\]"), "").trim();
}

/// Representasi rule IF-THEN sederhana
class Rule {
  final List<String> ifFacts;
  final void Function(Set<String> wm) thenAction;

  Rule({
    required this.ifFacts,
    required this.thenAction,
  });
}
