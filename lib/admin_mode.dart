import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;

void main() {
  runApp(const MyApp());
}

/// Widget utama Aplikasi
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forward Chaining Demo',
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
            // RadioButton: Kerja
            RadioListTile<bool>(
              title: const Text('Kerja'),
              value: true,
              groupValue: _pilihan,
              onChanged: (val) {
                setState(() => _pilihan = val);
              },
            ),
            // RadioButton: Kuliah
            RadioListTile<bool>(
              title: const Text('Kuliah'),
              value: false,
              groupValue: _pilihan,
              onChanged: (val) {
                setState(() => _pilihan = val);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pilihan == null
                  ? null
                  : () {
                      // Pergi ke halaman pertanyaan
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

/// Halaman yang menampilkan pertanyaan secara blok (5 soal per halaman)
class QuestionPage extends StatefulWidget {
  final bool isKerja; // true = Kerja, false = Kuliah

  const QuestionPage({Key? key, required this.isKerja}) : super(key: key);

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  late Future<List<QuestionItem>> futureQuestions;

  /// Indeks halaman/blok saat ini (tiap blok = 5 pertanyaan).
  int currentPageIndex = 0;

  /// Jawaban user (Map key = questionId, value = bool "Ya/Tidak")
  final Map<String, bool> userAnswers = {};

  @override
  void initState() {
    super.initState();
    futureQuestions = loadQuestions(widget.isKerja);
  }

  /// Memuat JSON (IPA Sains + IPA Teknik) => Flatten menjadi list [QuestionItem].
  Future<List<QuestionItem>> loadQuestions(bool isKerja) async {
    // Tentukan file JSON Sains
    final sainsFile = isKerja
        ? 'assets/ipa_sains_kerja.json'
        : 'assets/ipa_sains_kuliah.json';
    // Tentukan file JSON Teknik
    final teknikFile = isKerja
        ? 'assets/ipa_teknik_kerja.json'
        : 'assets/ipa_teknik_kuliah.json';

    // Baca JSON Sains
    final sainsString = await rootBundle.rootBundle.loadString(sainsFile);
    final sainsMap = json.decode(sainsString) as Map<String, dynamic>;

    // Baca JSON Teknik
    final teknikString = await rootBundle.rootBundle.loadString(teknikFile);
    final teknikMap = json.decode(teknikString) as Map<String, dynamic>;

    // Ubah ke list ProgramStudi
    final List<ProgramStudi> studiList = [];
    for (var mapEntry in sainsMap.entries) {
      studiList.add(ProgramStudi.fromJson(mapEntry.value));
    }
    for (var mapEntry in teknikMap.entries) {
      studiList.add(ProgramStudi.fromJson(mapEntry.value));
    }

    // Flatten -> Setiap minat dan setiap pertanyaan jadi satu item
    final List<QuestionItem> questionItems = [];

    for (var ps in studiList) {
      for (var minatEntry in ps.minat.entries) {
        final minatName = minatEntry.key;
        final minatData = minatEntry.value;
        // minatData.pertanyaan = [ "Teks [5]", "..." ]
        for (var q in minatData.pertanyaan) {
          final bobot = extractBobot(q);
          final teks = cleanPertanyaan(q);

          // Buat ID unik (supaya kita tahu ini pertanyaan apa)
          // Bisa gabung programName + minatName + index
          final uniqueId = '${ps.name}|$minatName|$q';

          questionItems.add(
            QuestionItem(
              id: uniqueId,
              programName: ps.name,
              minatName: minatName,
              pertanyaan: teks,
              bobot: bobot,
            ),
          );
        }
      }
    }

    // *Opsional*: bisa di-shuffle atau dibiarkan urut.
    // questionItems.shuffle();

    return questionItems;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isKerja ? 'Kerja' : 'Kuliah';
    return Scaffold(
      appBar: AppBar(title: Text('Pertanyaan $title')),
      body: FutureBuilder<List<QuestionItem>>(
        future: futureQuestions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final listQ = snapshot.data;
          if (listQ == null || listQ.isEmpty) {
            return const Center(child: Text('Data pertanyaan kosong.'));
          }

          // Tampilkan pertanyaan 5 per halaman
          final chunkSize = 5;
          final startIndex = currentPageIndex * chunkSize;
          final endIndex = (startIndex + chunkSize);
          final pageQuestions = listQ.sublist(
            startIndex,
            endIndex > listQ.length ? listQ.length : endIndex,
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: pageQuestions.length,
                    itemBuilder: (context, index) {
                      final item = pageQuestions[index];

                      // Cek jawaban user (default = false)
                      final currentAnswer = userAnswers[item.id] ?? false;

                      return CheckboxListTile(
                        title: Text(
                            '${startIndex + index + 1}. ${item.pertanyaan}'),
                        value: currentAnswer,
                        onChanged: (val) {
                          setState(() {
                            userAnswers[item.id] = val ?? false;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tombol Back (jika bukan di page pertama)
                    if (currentPageIndex > 0)
                      ElevatedButton(
                        onPressed: _prevPage,
                        child: const Text('Previous'),
                      )
                    else
                      const SizedBox(),
                    // Tombol Next / Finish
                    ElevatedButton(
                      onPressed: () {
                        // Jika masih ada halaman berikutnya -> Next
                        if ((endIndex) < listQ.length) {
                          _nextPage();
                        } else {
                          // Sudah di halaman terakhir -> Finish
                          _showRecommendation(listQ);
                        }
                      },
                      child: Text(endIndex < listQ.length ? 'Next' : 'Finish'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _prevPage() {
    setState(() {
      currentPageIndex--;
    });
  }

  void _nextPage() {
    setState(() {
      currentPageIndex++;
    });
  }

  /// Saat menekan Finish, kita hitung skor minat mana yang tertinggi
  void _showRecommendation(List<QuestionItem> allQuestions) {
    // Kumpulkan skor per-minat
    // Key = "${programName}|${minatName}"
    final Map<String, int> skorMap = {};

    for (var q in allQuestions) {
      final isYa = userAnswers[q.id] ?? false;
      if (isYa) {
        final keyMinat = '${q.programName}|${q.minatName}';
        skorMap[keyMinat] = (skorMap[keyMinat] ?? 0) + q.bobot;
      }
    }

    if (skorMap.isEmpty) {
      // Jika user belum jawab "Ya" satupun
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Rekomendasi'),
          content: const Text('Anda belum memilih apa pun (semua "Tidak").'),
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

    // Cari minat dgn skor tertinggi
    final best = skorMap.entries.reduce((a, b) => a.value > b.value ? a : b);
    final bestKey = best.key; // "NamaProgram|MinatName"
    final bestScore = best.value; // Skornya

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rekomendasi'),
        content: Text(
          'Minat Paling Cocok: $bestKey\n'
          'Skor: $bestScore',
        ),
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

////////////////////////////////////////////////////////////
/// Bagian Model & Fungsi Pendukung
////////////////////////////////////////////////////////////

/// Representasi data ProgramStudi (bawaan dari JSON)
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
      categories: json['categories'] == null
          ? []
          : List<String>.from(json['categories']),
      minat: minatMap,
    );
  }
}

/// Representasi data Minat (pertanyaan, karir, dsb.)
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
      pertanyaan: json['pertanyaan'] == null
          ? []
          : List<String>.from(json['pertanyaan']),
      karir: json['karir'] == null ? [] : List<String>.from(json['karir']),
      jurusanTerkait: json['jurusan_terkait'] == null
          ? []
          : List<String>.from(json['jurusan_terkait']),
    );
  }
}

/// Model flattened satu pertanyaan
class QuestionItem {
  final String id; // unique ID, misal "Program|Minat|Pertanyaan"
  final String programName; // ex: "IPA (Sains Murni) - Kerja"
  final String minatName; // ex: "Kedokteran"
  final String pertanyaan; // ex: "Apakah Anda ... ?"
  final int bobot; // ex: 5

  QuestionItem({
    required this.id,
    required this.programName,
    required this.minatName,
    required this.pertanyaan,
    required this.bobot,
  });
}

/// Fungsi untuk mengambil bobot [n] dari string pertanyaan
int extractBobot(String pertanyaan) {
  final regex = RegExp(r"\[(\d+)\]");
  final match = regex.firstMatch(pertanyaan);
  if (match != null) {
    return int.parse(match.group(1)!);
  }
  return 0;
}

/// Fungsi untuk menghapus teks [n] di akhir pertanyaan
String cleanPertanyaan(String pertanyaan) {
  return pertanyaan.replaceAll(RegExp(r"\[\d+\]"), "").trim();
}
