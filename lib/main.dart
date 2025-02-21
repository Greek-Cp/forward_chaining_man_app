import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;

void main() {
  runApp(const MyApp());
}

/// Root widget aplikasi
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forward Chaining IF-THEN Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

/// Halaman untuk memilih Kerja atau Kuliah
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool? _pilihan; // null = belum pilih; true = Kerja; false = Kuliah

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Kerja atau Kuliah'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RadioListTile<bool>(
              title: const Text('Kerja'),
              value: true,
              groupValue: _pilihan,
              onChanged: (val) => setState(() => _pilihan = val),
            ),
            RadioListTile<bool>(
              title: const Text('Kuliah'),
              value: false,
              groupValue: _pilihan,
              onChanged: (val) => setState(() => _pilihan = val),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pilihan == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuestionPage(isKerja: _pilihan!),
                        ),
                      );
                    },
              child: const Text('Lanjut'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Halaman menampilkan pertanyaan (5 per halaman), wajib jawab semua
class QuestionPage extends StatefulWidget {
  final bool isKerja;
  const QuestionPage({Key? key, required this.isKerja}) : super(key: key);

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  late Future<List<QuestionItem>> futureQuestions;

  int currentPage = 0;
  static const pageSize = 5;

  @override
  void initState() {
    super.initState();
    futureQuestions = _loadQuestions(widget.isKerja);
  }

  /// Memuat data JSON (Sains + Teknik), lalu 'flatten' semua pertanyaan
  /// Kita berikan ID pertanyaan: Q1, Q2, Q3, dst.
  Future<List<QuestionItem>> _loadQuestions(bool isKerja) async {
    final sainsFile = isKerja
        ? 'assets/ipa_sains_kerja.json'
        : 'assets/ipa_sains_kuliah.json';
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
    final programList = <ProgramStudi>[];
    for (var entry in sainsMap.entries) {
      programList.add(ProgramStudi.fromJson(entry.value));
    }
    for (var entry in teknikMap.entries) {
      programList.add(ProgramStudi.fromJson(entry.value));
    }

    // Flatten semua pertanyaan
    // Kita siapkan list, lalu berikan ID unik (Q1, Q2, dsb) secara urut
    final allQuestions = <QuestionItem>[];
    var questionCounter = 1;

    for (var prog in programList) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;
        final minatVal = minatEntry.value;

        for (var p in minatVal.pertanyaan) {
          final bobot = extractBobot(p);
          final cleaned = cleanPertanyaan(p);

          final questionId = 'Q$questionCounter';
          questionCounter++;

          allQuestions.add(
            QuestionItem(
              id: questionId,
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
    return allQuestions;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isKerja ? 'Kerja' : 'Kuliah';

    return Scaffold(
      appBar: AppBar(title: Text('Forward Chaining IF-THEN ($title)')),
      body: FutureBuilder<List<QuestionItem>>(
        future: futureQuestions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('Data Kosong'));
          }

          final totalPages = (data.length / pageSize).ceil();
          if (currentPage >= totalPages) currentPage = totalPages - 1;
          if (currentPage < 0) currentPage = 0;

          final startIndex = currentPage * pageSize;
          final endIndex = ((currentPage + 1) * pageSize).clamp(0, data.length);
          final questionsThisPage = data.sublist(startIndex, endIndex);

          final answeredCount = data.where((q) => q.userAnswer != null).length;
          final totalCount = data.length;

          final allAnsweredThisPage =
              questionsThisPage.every((q) => q.userAnswer != null);

          return Column(
            children: [
              // Label Info
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Text(
                      'Halaman ${currentPage + 1} / $totalPages',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Anda telah mengisi $answeredCount dari $totalCount pertanyaan',
                      style: const TextStyle(fontSize: 14),
                    ),
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
                            Row(
                              children: [
                                // Checkbox "Ya"
                                Checkbox(
                                  value: qItem.userAnswer == true,
                                  onChanged: (bool? val) {
                                    setState(() {
                                      if (val == true) {
                                        qItem.userAnswer = true;
                                      } else {
                                        qItem.userAnswer = null;
                                      }
                                    });
                                  },
                                ),
                                const Text('Ya'),
                                const SizedBox(width: 20),
                                // Checkbox "Tidak"
                                Checkbox(
                                  value: qItem.userAnswer == false,
                                  onChanged: (bool? val) {
                                    setState(() {
                                      if (val == true) {
                                        qItem.userAnswer = false;
                                      } else {
                                        qItem.userAnswer = null;
                                      }
                                    });
                                  },
                                ),
                                const Text('Tidak'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
<<<<<<< HEAD
=======
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _allQuestionsAnswered(int start, int end) {
    for (int i = start; i < end; i++) {
      // Pastikan key 'i' sudah ada di map answers
      if (!answers.containsKey(i)) {
        return false;
      }
    }
    return true;
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Kuisioner Selesai"),
          content: Text("Terima kasih telah mengisi kuisioner!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                // Hasil forward chaining
                List<Map<String, String>> results = _calculateRecommendations();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProgressTrackingScreen(
                      recommendedSteps: results,
                    ),
                  ),
                );
              },
              child: Text("Lihat Rekomendasi"),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, String>> _calculateRecommendations() {
    // 1) Hitung total "Ya"
    int totalYes = answers.values.where((v) => v == true).length;

    // 2) Buat map untuk menampung skor per minat dan pertanyaan yang dipilih
    Map<String, int> minatScores = {};
    Map<String, List<String>> minatPertanyaan =
        {}; // Menyimpan pertanyaan yang dipilih untuk setiap minat

    // 3) Loop semua jawaban
    answers.forEach((index, isYes) {
      if (isYes == true) {
        // Cari minat pertanyaan ini
        final minat = questionIndexToMinat[index];
        if (minat != null) {
          // Tambah skor
          minatScores[minat] = (minatScores[minat] ?? 0) + 1;

          // Tambahkan pertanyaan ke daftar pertanyaan untuk minat ini
          final question = questions[index]; // Ambil pertanyaan dari indeks
          if (minatPertanyaan[minat] == null) {
            minatPertanyaan[minat] = [];
          }
          minatPertanyaan[minat]?.add(question);
        }
      }
    });

    // 4) Menilai minat tertinggi
    List<Map<String, String>> recommendations = [];

    // Jika tidak ada jawaban "Ya", tidak ada rekomendasi
    if (totalYes < 3) {
      recommendations.add({
        "title": "Kurang Berminat pada IPA",
        "description": "Hanya menjawab 'Ya' di bawah 3 pertanyaan",
        "category": "Umum"
      });
    } else {
      // 5) Jika ada minat tinggi, kita urutkan berdasarkan skor
      if (minatScores.isNotEmpty) {
        final sorted = minatScores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Ambil 3 rekomendasi paling tinggi
        int recommendationCount = 0;
        for (var entry in sorted) {
          final topMinat = entry.key;
          final topScore = entry.value;

          // Menambahkan rekomendasi berdasarkan minat
          recommendations.add({
            "title": "Cocok di $topMinat",
            "description": "Skor: $topScore",
            "category": topMinat,
            "pertanyaan": minatPertanyaan[topMinat]?.join("\n") ??
                "Tidak ada pertanyaan terkait",
          });

          recommendationCount++;
          if (recommendationCount >= 3) {
            break; // Ambil hanya 3 rekomendasi paling tinggi
          }
        }
      }
    }

    // Tambahkan hasil akhir atau informasi tambahan setelah rekomendasi
    recommendations.add({
      "title": "Hasil Akhir",
      "description":
          "Berdasarkan jawaban Anda, kami telah memberikan beberapa rekomendasi terbaik.",
      "category": "Informasi"
    });

    return recommendations;
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Peringatan"),
          content: Text(
              "Silakan jawab semua pertanyaan di halaman ini terlebih dahulu."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
}

class ProgressTrackingScreen extends StatefulWidget {
  final List<Map<String, String>> recommendedSteps;

  ProgressTrackingScreen({required this.recommendedSteps});

  @override
  _ProgressTrackingScreenState createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  Map<int, double> itemHeights = {}; // Menyimpan tinggi masing-masing item

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5), // Durasi animasi timeline
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  void _resetProgress() {
    _controller.reset();
    _controller.forward();
  }

  void updateItemHeight(int index, double height) {
    setState(() {
      itemHeights[index] = height;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ganti steps => widget.recommendedSteps
    final steps = widget.recommendedSteps;

    return Scaffold(
      appBar: AppBar(title: Text("Progress Tracking Timeline")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return SingleChildScrollView(
              child: Column(
                children: List.generate(steps.length, (index) {
                  double progressPerStep = 1.0 / steps.length;
                  bool isCompleted = _progressAnimation.value >= 1.0;
                  bool isActiveNow = (_progressAnimation.value >=
                          progressPerStep * index &&
                      _progressAnimation.value < progressPerStep * (index + 1));
                  bool isLineVisible =
                      _progressAnimation.value > (progressPerStep * index);
                  double lineHeight =
                      itemHeights[index] ?? 0.0; // Tinggi garis mengikuti item

                  // Tampilkan timeline item untuk pertanyaan yang dipilih
                  if (steps[index].containsKey("pertanyaan")) {
                    return TimelineTile(
                      step: index + 1,
                      title: steps[index]["pertanyaan"] ?? "",
                      description: steps[index]["description"] ?? "",
                      category: steps[index]["category"] ?? "",
                      isActive:
                          _progressAnimation.value > (progressPerStep * index),
                      isActiveNow: isActiveNow,
                      isLast: index == steps.length - 1,
                      isCompleted: isCompleted,
                      isLineVisible: isLineVisible,
                      lineHeight: max(0, lineHeight * 0.8),
                      onHeightCalculated: (height) =>
                          updateItemHeight(index, height),
                    );
                  }

                  return TimelineTile(
                    step: index + 1,
                    title: steps[index]["title"] ?? "",
                    description: steps[index]["description"] ?? "",
                    category: steps[index]["category"] ?? "",
                    isActive:
                        _progressAnimation.value > (progressPerStep * index),
                    isActiveNow: isActiveNow,
                    isLast: index == steps.length - 1,
                    isCompleted: isCompleted,
                    isLineVisible: isLineVisible,
                    lineHeight: max(0, lineHeight * 0.8),
                    onHeightCalculated: (height) =>
                        updateItemHeight(index, height),
                  );
                }),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetProgress,
        child: Icon(Icons.refresh),
        backgroundColor: Colors.blue,
        tooltip: "Reset Progress",
      ),
    );
  }
}

class TimelineTile extends StatefulWidget {
  final int step;
  final String title;
  final String description;
  final String category;
  final bool isActive;
  final bool isActiveNow;
  final bool isLast;
  final bool isCompleted;
  final bool isLineVisible;
  final double lineHeight;
  final Function(double) onHeightCalculated;

  TimelineTile({
    required this.step,
    required this.title,
    required this.description,
    required this.category,
    this.isActive = false,
    this.isActiveNow = false,
    this.isLast = false,
    this.isCompleted = false,
    this.isLineVisible = false,
    this.lineHeight = 0.0,
    required this.onHeightCalculated,
  });

  @override
  _TimelineTileState createState() => _TimelineTileState();
}

class _TimelineTileState extends State<TimelineTile> {
  final GlobalKey _containerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _getContainerHeight());
  }

  void _getContainerHeight() {
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      widget.onHeightCalculated(renderBox.size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color activeColor = widget.isCompleted ? Colors.green : Colors.blue;
    double scale = widget.isActiveNow ? 1.2 : 1.0;
    Color glowColor =
        widget.isActiveNow ? Colors.blue.withOpacity(0.8) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 1.0, end: scale),
                duration: Duration(milliseconds: 300),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: widget.isActive ? activeColor : Colors.grey,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glowColor,
                            blurRadius: 10,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.step.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
>>>>>>> 327b355ac598c3321f16164821daa1430c712555
              ),
              // Navigasi Bawah
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: (currentPage > 0)
                        ? () {
                            setState(() {
                              currentPage--;
                            });
                          }
                        : null,
                    child: const Text('Prev'),
                  ),
                  if (currentPage < totalPages - 1)
                    ElevatedButton(
                      onPressed: allAnsweredThisPage
                          ? () {
                              setState(() {
                                currentPage++;
                              });
                            }
                          : null,
                      child: const Text('Next'),
                    )
                  else
                    ElevatedButton(
                      onPressed: allAnsweredThisPage
                          ? () => _runForwardChaining(data)
                          : null,
                      child: const Text('Cek Rekomendasi'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  /// Di sinilah kita implementasikan Forward Chaining berbasis IF-THEN
  void _runForwardChaining(List<QuestionItem> allQuestions) {
    // 1. Buat Working Memory: kumpulan fakta, misal "Q1=Yes"
    final workingMemory = <String>{};

    for (var q in allQuestions) {
      if (q.userAnswer == true) {
        workingMemory.add('${q.id}=Yes'); // misal "Q1=Yes"
      } else {
        workingMemory
            .add('${q.id}=No'); // Opsional, agar terekam juga jika Tidak
      }
    }

    // 2. Siapkan struktur untuk menyimpan skor minat
    final minatScores = <String, int>{};

    // 3. Siapkan struktur untuk menyimpan catatan rule per-minat
    //    (Akan berisi daftar teks rule yang menambah skor ke minat tertentu)
    final minatContrib = <String, List<String>>{};

    // 4. Buat sekumpulan RULES IF-THEN
    //    (Generate rule otomatis: "IF Qx=Yes THEN skor[(prog|minat)] += bobot")
    final rules = <Rule>[];
    for (var q in allQuestions) {
      final rule = Rule(
        ifFacts: ['${q.id}=Yes'],
        thenAction: (wm) {
          final keyMinat = '${q.programName}|${q.minatKey}';
          // Tambah skor
          minatScores[keyMinat] = (minatScores[keyMinat] ?? 0) + q.bobot;
          // Catat rule/pertanyaan ini berkontribusi
          minatContrib[keyMinat] ??= [];
          minatContrib[keyMinat]!.add(
            'Rule fired: IF ${q.id}=Yes THEN +${q.bobot} → ${keyMinat}',
          );
        },
      );
      rules.add(rule);
    }

    // 5. Jalankan forward chaining secara iteratif
    bool firedSomething = true;
    final firedRules = <Rule>{};

    while (firedSomething) {
      firedSomething = false;
      for (var r in rules) {
        if (firedRules.contains(r)) {
          continue; // rule ini sudah menembak
        }
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
      // Mungkin semua jawaban "Tidak" atau bobot=0
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Rekomendasi'),
          content: const Text('Skor minat kosong (semua 0).'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
      return;
    }

    // 7. Urutkan descending & ambil top 3
    final sorted = minatScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).toList();

    // 8. Buat string output, per rekomendasi + rules
    String message = 'HASIL FORWARD CHAINING (IF-THEN):\n\n';
    message += 'Fakta di Working Memory: ${workingMemory.join(', ')}\n\n';

    message += 'Top 3 Minat (dengan rule yang berkontribusi):\n';
    for (int i = 0; i < top3.length; i++) {
      final minatKey = top3[i].key; // ex: "IPA(Sains Murni)|Farmasi"
      final score = top3[i].value;
      message += '${i + 1}. $minatKey (Skor: $score)\n';

      // Tampilkan catatan rule
      final listRules = minatContrib[minatKey] ?? [];
      if (listRules.isEmpty) {
        message += '  (Tidak ada catatan rule)\n\n';
      } else {
        message += '  Rules yang menambah skor:\n';
        for (var rText in listRules) {
          message += '   - $rText\n';
        }
        message += '\n';
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rekomendasi'),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }
}
//////////////////////////////////////////////
// Bagian Model, Fungsi Pendukung, & Rule
//////////////////////////////////////////////

/// Model ProgramStudi: menampung data dari JSON
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
}

/// Model Minat
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

/// Item pertanyaan (UI)
class QuestionItem {
  final String id; // misal "Q1", "Q2"
  final String programName; // ex: "IPA (Sains Murni) - Kerja"
  final String minatKey; // ex: "Kedokteran"
  final String questionText; // teks pertanyaan (bersih dari [n])
  final String rawQuestionText; // teks asli (berisi [n])
  final int bobot; // angkanya
  bool? userAnswer; // null=belum jawab, true=Ya, false=Tidak

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

/// Fungsi ambil bobot [n] dari pertanyaan
int extractBobot(String pertanyaan) {
  final regex = RegExp(r"\[(\d+)\]");
  final match = regex.firstMatch(pertanyaan);
  if (match != null) {
    return int.parse(match.group(1)!);
  }
  return 0;
}

/// Fungsi hapus [n] dari teks pertanyaan
String cleanPertanyaan(String pertanyaan) {
  return pertanyaan.replaceAll(RegExp(r"\[\d+\]"), "").trim();
}

/// Kelas Rule sederhana: IF [beberapa fakta] THEN jalankan aksi (tambah skor, dsb)
class Rule {
  final List<String> ifFacts;
  final void Function(Set<String> workingMemory) thenAction;

  Rule({
    required this.ifFacts,
    required this.thenAction,
  });

  // Biar bisa di-set (HashSet) kita override equality:
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rule &&
          runtimeType == other.runtimeType &&
          ifFacts == other.ifFacts; // cukup bandingkan list ifFacts

  @override
  int get hashCode => ifFacts.hashCode;
}
