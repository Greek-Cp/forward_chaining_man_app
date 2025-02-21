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
  bool? _pilihan; // null=belum pilih; true=Kerja; false=Kuliah

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
            // Radio: Kerja
            RadioListTile<bool>(
              title: const Text('Kerja'),
              value: true,
              groupValue: _pilihan,
              onChanged: (val) => setState(() => _pilihan = val),
            ),
            // Radio: Kuliah
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
                      // Bawa user ke halaman pertanyaan
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

/// Halaman menampilkan daftar pertanyaan (5 per halaman), lalu forward chaining
class QuestionPage extends StatefulWidget {
  final bool isKerja; // true=Kerja, false=Kuliah
  const QuestionPage({Key? key, required this.isKerja}) : super(key: key);

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  // Akan menampung data ProgramStudi lengkap (untuk lookup karir di akhir)
  late Future<List<ProgramStudi>> futureProgramList;

  // Daftar pertanyaan yang sudah di-flatten
  List<QuestionItem> allQuestions = [];

  // Paging
  int currentPage = 0;
  static const pageSize = 5;

  @override
  void initState() {
    super.initState();
    futureProgramList = _loadProgramData(widget.isKerja);
  }

  /// Memuat data ProgramStudi dari file JSON (Sains + Teknik) tergantung Kerja/Kuliah
  Future<List<ProgramStudi>> _loadProgramData(bool isKerja) async {
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
    final programList = <ProgramStudi>[];
    // Parsing sains
    for (var entry in sainsMap.entries) {
      programList.add(ProgramStudi.fromJson(entry.value));
    }
    // Parsing teknik
    for (var entry in teknikMap.entries) {
      programList.add(ProgramStudi.fromJson(entry.value));
    }

    // Flatten jadi QuestionItem
    _flattenQuestions(programList);

    return programList;
  }

  /// Flatten pertanyaan dari programList -> allQuestions (Q1, Q2, dsb)
  void _flattenQuestions(List<ProgramStudi> programList) {
    final all = <QuestionItem>[];
    int counter = 1;

    for (var prog in programList) {
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
    // simpan ke state
    allQuestions = all;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isKerja ? 'Kerja' : 'Kuliah';

    return Scaffold(
      appBar: AppBar(title: Text('Forward Chaining $title')),
      body: FutureBuilder<List<ProgramStudi>>(
        future: futureProgramList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final programList = snapshot.data;
          if (programList == null || programList.isEmpty) {
            return const Center(child: Text('Data Kosong'));
          }

          // Tampilkan pertanyaan per halaman
          final totalPages = (allQuestions.length / pageSize).ceil();
          if (currentPage >= totalPages) currentPage = totalPages - 1;
          if (currentPage < 0) currentPage = 0;

          final startIndex = currentPage * pageSize;
          final endIndex =
              ((currentPage + 1) * pageSize).clamp(0, allQuestions.length);
          final questionsThisPage = allQuestions.sublist(startIndex, endIndex);

          // Hitung berapa pertanyaan total yang dijawab
          final answeredCount =
              allQuestions.where((q) => q.userAnswer != null).length;
          final totalCount = allQuestions.length;

          final allAnsweredThisPage =
              questionsThisPage.every((q) => q.userAnswer != null);

          return Column(
            children: [
              // Info Halaman
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Text('Halaman ${currentPage + 1} / $totalPages'),
                    Text(
                        'Anda telah mengisi $answeredCount dari $totalCount pertanyaan'),
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
                                Checkbox(
                                  value: qItem.userAnswer == true,
                                  onChanged: (val) {
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
                                Checkbox(
                                  value: qItem.userAnswer == false,
                                  onChanged: (val) {
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
              ),
              // Navigasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: currentPage > 0
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
                          ? () => _runForwardChaining(programList)
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

  /// Di sinilah kita jalankan Forward Chaining & tampilkan karir/jurusan + rule
  void _runForwardChaining(List<ProgramStudi> loadedData) {
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
      _showResultDialog('Skor minat kosong (semua 0).');
      return;
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
        final programStudi = loadedData.firstWhere(
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

    _showResultDialog(message);
  }

  void _showResultDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rekomendasi'),
        content: SingleChildScrollView(child: Text(msg)),
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
