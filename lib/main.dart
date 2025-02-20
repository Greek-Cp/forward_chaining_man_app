import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: KuisionerScreen(
        isKuliah: true,
      ),
    );
  }
}

class KuisionerScreen extends StatefulWidget {
  final bool isKuliah; // contoh jika Anda butuh parameter

  KuisionerScreen({this.isKuliah = true});

  @override
  _KuisionerScreenState createState() => _KuisionerScreenState();
}

class _KuisionerScreenState extends State<KuisionerScreen> {
  int currentPageIndex = 0; // Indeks halaman (tiap halaman 5 pertanyaan)
  Map<int, bool?> answers = {}; // Menyimpan jawaban (true = Ya, false = Tidak)
  List<String> questions = [];
  Map<int, String> questionIndexToMinat = {}; // mapping pertanyaan -> minat

  @override
  void initState() {
    super.initState();
    _loadQuestionsCombined(); // Contoh memuat pertanyaan
  }

  /// Contoh memuat 2 file JSON (IPA Sains + IPA Teknik) lalu gabung pertanyaannya
  /// Jika tidak butuh itu, Anda bisa ubah jadi 1 file JSON saja
  Future<void> _loadQuestionsCombined() async {
    try {
      // Misal default -> assets/ipa_sains_kuliah.json & assets/ipa_teknik_kuliah.json
      String sainsFile = 'assets/ipa_sains_kuliah.json';
      String teknikFile = 'assets/ipa_teknik_kuliah.json';

      // Muat isi JSON
      final sainsJsonStr = await rootBundle.loadString(sainsFile);
      final teknikJsonStr = await rootBundle.loadString(teknikFile);

      final sainsJson = json.decode(sainsJsonStr) as Map<String, dynamic>;
      final teknikJson = json.decode(teknikJsonStr) as Map<String, dynamic>;

      // Kita akan menyimpan semua pertanyaan di "loadedQuestions"
      // juga kita perlu simpan "index -> minat"
      List<String> loadedQuestions = [];
      int qIndex = 0; // Index global pertanyaan

      // ---- [1] Memasukkan pertanyaan dari Sains ----
      sainsJson.forEach((key, value) {
        // value seharusnya punya struktur "minat": {...}
        if (value["minat"] != null) {
          Map<String, dynamic> minatMap = value["minat"];
          // Loop di setiap "minat"
          minatMap.forEach((minatKey, minatValue) {
            if (minatValue["pertanyaan"] != null) {
              List pertanyaanList = minatValue["pertanyaan"];

              for (var p in pertanyaanList) {
                // Tambahkan pertanyaan ke list
                loadedQuestions.add(p.toString());
                // Tandai index pertanyaan ini -> minatKey
                questionIndexToMinat[qIndex] = minatKey;
                qIndex++;
              }
            }
          });
        }
      });

      // ---- [2] Memasukkan pertanyaan dari Teknik ----
      teknikJson.forEach((key, value) {
        if (value["minat"] != null) {
          Map<String, dynamic> minatMap = value["minat"];
          minatMap.forEach((minatKey, minatValue) {
            if (minatValue["pertanyaan"] != null) {
              List pertanyaanList = minatValue["pertanyaan"];

              for (var p in pertanyaanList) {
                loadedQuestions.add(p.toString());
                questionIndexToMinat[qIndex] = minatKey;
                qIndex++;
              }
            }
          });
        }
      });

      // Setelah semuanya digabung, update state
      setState(() {
        questions = loadedQuestions;
      });
    } catch (e) {
      print("Error loading JSON: $e");
      // Tangani kesalahan (misal tampilkan dialog)
    }
  }

  // Hitung berapa banyak pertanyaan yang sudah dijawab (Ya atau Tidak)
  int _answeredCount() {
    int count = 0;
    for (var entry in answers.entries) {
      if (entry.value != null) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    // Jika pertanyaan belum terisi (masih loading), tampilkan loading
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Kuisioner",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    int startIndex = currentPageIndex * 5;
    int endIndex = (startIndex + 5).clamp(0, questions.length);

    // =============================================
    // PROGRESS BAR: Berdasarkan jumlah jawaban user
    // =============================================
    int answered = _answeredCount();
    double progress = answered / questions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Kuisioner",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (currentPageIndex > 0) {
              setState(() {
                currentPageIndex--;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // Menampilkan X/Y berdasar "answered" vs total
            // --------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${answered}/${questions.length} Pertanyaan",
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: Colors.orange,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
            SizedBox(height: 20),

            // Deskripsi
            Text(
              "Jawab dengan jujur pertanyaan di bawah ini.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            SizedBox(height: 20),

            // Label "Pertanyaan"
            Text(
              "Pertanyaan",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Tampilkan 5 pertanyaan per halaman
            Expanded(
              child: ListView.builder(
                itemCount: endIndex - startIndex,
                itemBuilder: (context, index) {
                  int questionIndex = startIndex + index;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Garis vertikal biru
                      Column(
                        children: [
                          Container(
                            width: 4,
                            height: 15,
                            color: Colors.blue,
                          ),
                          Container(
                            width: 4,
                            height: 50,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                      SizedBox(width: 8),

                      // Teks pertanyaan + checkbox
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${questionIndex + 1}. ${questions[questionIndex]}",
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 10),

                            // Checkbox "Ya"
                            Row(
                              children: [
                                Checkbox(
                                  value: answers[questionIndex] == true,
                                  activeColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      // Pilih jawaban true
                                      answers[questionIndex] = true;
                                    });
                                  },
                                ),
                                Text("Ya"),
                              ],
                            ),

                            // Checkbox "Tidak"
                            Row(
                              children: [
                                Checkbox(
                                  value: answers[questionIndex] == false,
                                  activeColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      // Pilih jawaban false
                                      answers[questionIndex] = false;
                                    });
                                  },
                                ),
                                Text("Tidak"),
                              ],
                            ),

                            SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Tombol Navigasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol Sebelumnya
                if (currentPageIndex > 0)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentPageIndex--;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Sebelumnya",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),

                // Tombol Lanjut atau Selesai
                ElevatedButton(
                  onPressed: () {
                    // Cek apakah semua pertanyaan di halaman ini sudah dijawab
                    if (_allQuestionsAnswered(startIndex, endIndex)) {
                      // Jika masih ada halaman berikutnya
                      if (endIndex < questions.length) {
                        setState(() {
                          currentPageIndex++;
                        });
                      } else {
                        _showCompletionDialog();
                      }
                    } else {
                      _showWarningDialog();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    endIndex < questions.length ? "Lanjut" : "Selesai",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
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
              ),
              if (!widget.isLast)
                AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  width: 3,
                  height: widget.isLineVisible ? widget.lineHeight : 0,
                  color: widget.isActive ? activeColor : Colors.grey[300],
                ),
            ],
          ),
          SizedBox(width: 10),
          Expanded(
            child: Container(
              key: _containerKey, // Mengukur tinggi item
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.isActive ? activeColor : Colors.grey,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    widget.description,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  Text(
                    widget.category,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
