/// Controller untuk QuestionPage
/// import 'dart:convert';
import 'dart:convert';
import 'dart:math';

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

class QuestionController extends GetxController {
  final bool isKerja;
  final String majorType; // "SAINS" atau "TEKNIK"
  final RxList<String> highlightedQuestionIds = <String>[].obs;
  bool shouldScrollToTop = false;

  QuestionController({
    required this.isKerja,
    required this.majorType,
  });
  void autoFillAnswers(bool answer) {
    for (var q in questionsThisPage) {
      setAnswer(q, answer);
    }
  }
// Tambahkan metode berikut ke dalam QuestionController

// Metode untuk mengisi jawaban di semua halaman
  Future<void> autoFillAllPages(bool? answer) async {
    // Simpan halaman saat ini
    final currentPageValue = currentPage.value;

    // Iterasi melalui semua halaman
    for (var page = 0; page < totalPages; page++) {
      // Pindah ke halaman tersebut
      currentPage.value = page;

      // Tunggu rendering selesai
      await Future.delayed(const Duration(milliseconds: 10));

      // Isi jawaban pada halaman ini
      if (answer != null) {
        // Isi semua jawaban dengan nilai yang sama
        for (var q in questionsThisPage) {
          setAnswer(q, answer);
        }
      } else {
        // Isi jawaban secara acak
        final random = Random();
        for (var q in questionsThisPage) {
          setAnswer(q, random.nextBool());
        }
      }
    }

    // Pindah ke halaman terakhir
    currentPage.value = totalPages - 1;
  }

// Metode untuk mengisi jawaban secara acak
  void autoFillRandomAnswers() {
    final random = Random();
    for (var q in questionsThisPage) {
      setAnswer(q, random.nextBool());
    }
  }

// Metode untuk mengisi sebagian jawaban saja (antara 50-80%)
  void autoFillPartialAnswers() {
    final random = Random();

    // Acak urutan pertanyaan agar yang dijawab juga acak
    final shuffledQuestions = List<QuestionItem>.from(questionsThisPage)
      ..shuffle();

    // Tentukan berapa banyak yang akan dijawab (50-80%)
    final totalQuestions = questionsThisPage.length;
    final percentToAnswer = random.nextInt(31) + 50; // 50% - 80%
    final questionsToAnswer = (totalQuestions * percentToAnswer / 100).round();

    // Isi jawaban untuk pertanyaan yang dipilih
    for (var i = 0; i < questionsToAnswer; i++) {
      if (i < shuffledQuestions.length) {
        setAnswer(shuffledQuestions[i], random.nextBool());
      }
    }
  }

  // Akan menampung data ProgramStudi lengkap (untuk lookup karir di akhir)
  final Rx<List<ProgramStudi>> programList = Rx<List<ProgramStudi>>([]);

  // Daftar pertanyaan yang sudah di-flatten
  final RxList<QuestionItem> allQuestions = <QuestionItem>[].obs;
  void clearQuestion() {
    allQuestions.clear();
  }

  void highlightUnansweredQuestions(ScrollController scrollController) {
    // Reset daftar highlight
    highlightedQuestionIds.clear();

    // Kumpulkan semua pertanyaan yang belum dijawab di halaman ini
    final List<QuestionItem> unansweredQuestions = questionsThisPage
        .where((q) =>
            allQuestions.firstWhere((aq) => aq.id == q.id).userAnswer == null)
        .toList();

    if (unansweredQuestions.isEmpty) return;

    // Tambahkan semua ID pertanyaan yang belum dijawab ke daftar highlight
    highlightedQuestionIds
        .addAll(unansweredQuestions.map((q) => q.id).toList());

    // Scroll ke pertanyaan pertama yang belum dijawab (jika ada)
    if (unansweredQuestions.isNotEmpty && scrollController.hasClients) {
      // Cari posisi item yang belum dijawab di ListView
      final firstUnansweredIndex =
          questionsThisPage.indexOf(unansweredQuestions.first);

      if (firstUnansweredIndex != -1) {
        // Hitung perkiraan posisi pertanyaan berdasarkan indeks dan tinggi item
        // Asumsi bahwa setiap item pertanyaan memiliki tinggi sekitar 180 piksel
        // Anda dapat menyesuaikan nilai ini sesuai dengan tinggi sebenarnya
        final estimatedPosition = firstUnansweredIndex * 180.0;

        // Scroll ke posisi dengan offset sedikit di atas (50 piksel) agar lebih jelas
        scrollController.animateTo(
          estimatedPosition - 50,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }

    // Tambahkan getaran (vibration) untuk feedback tambahan
    HapticFeedback.mediumImpact();

    // Hapus highlight setelah beberapa detik
    Future.delayed(const Duration(seconds: 5), () {
      if (highlightedQuestionIds.isNotEmpty) {
        highlightedQuestionIds.clear();
      }
    });
  }

  // Paging
  final RxInt currentPage = 0.obs;
  static const pageSize = 5;

  // Untuk tampilan loading
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProgramData(isKerja, majorType);
  }

  void nextPage() {
    if (currentPage.value < totalPages - 1) {
      currentPage.value++;
      shouldScrollToTop = true;
    }
  }

  void prevPage() {
    if (currentPage.value > 0) {
      currentPage.value--;
      shouldScrollToTop = true;
    }
  }

  @override
  void onClose() {
    highlightedQuestionIds.clear();
    super.onClose();
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
  Future<void> loadProgramData(bool isKerja, String majorType) async {
    currentPage.value = 0;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      String jsonFile;

      // Tentukan file berdasarkan kombinasi preferensi
      if (majorType == "SAINS") {
        jsonFile = isKerja
            ? 'assets/ipa_sains_kerja.json'
            : 'assets/ipa_sains_kuliah.json';
      } else {
        // TEKNIK
        jsonFile = isKerja
            ? 'assets/ipa_teknik_kerja.json'
            : 'assets/ipa_teknik_kuliah.json';
      }

      // Baca file JSON
      final jsonString = await rootBundle.rootBundle.loadString(jsonFile);
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      // Ubah ke list ProgramStudi
      final programs = <ProgramStudi>[];
      for (var entry in jsonMap.entries) {
        programs.add(ProgramStudi.fromJson(entry.value));
      }

      programList.value = programs;

      // Flatten jadi QuestionItem dengan pengacakan
      randomizeQuestions(programs);

      isLoading.value = false;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false;
    }
  }

  void randomizeQuestions(List<ProgramStudi> programs) {
    // 1. Kumpulkan pertanyaan berdasarkan minat dan program (stratifikasi)
    final questionsByInterest = <String, List<QuestionItem>>{};

    for (var prog in programs) {
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;
        final minatVal = minatEntry.value;
        final minatIdentifier = '${prog.name}|$minatKey'; // Unique identifier

        questionsByInterest[minatIdentifier] = [];

        for (var p in minatVal.pertanyaan) {
          final bobot = extractBobot(p);
          final cleaned = cleanPertanyaan(p);

          questionsByInterest[minatIdentifier]!.add(
            QuestionItem(
              id: '', // Temporary, will assign later
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

    // 2. Acak masing-masing grup minat secara terpisah
    questionsByInterest.forEach((minat, questions) {
      questions.shuffle(Random());
    });

    // 3. Ambil pertanyaan secara bergantian dari setiap minat untuk distribusi merata
    final finalQuestions = <QuestionItem>[];
    bool continueRotation = true;
    int rotationIndex = 0;

    while (continueRotation) {
      continueRotation = false;

      // Iterasi melalui semua grup minat
      for (var minat in questionsByInterest.keys.toList()..shuffle(Random())) {
        final questions = questionsByInterest[minat]!;

        // Jika grup minat ini masih memiliki pertanyaan pada indeks rotasi ini
        if (rotationIndex < questions.length) {
          finalQuestions.add(questions[rotationIndex]);
          continueRotation = true;
        }
      }

      rotationIndex++;
    }

    // 4. Renumber pertanyaan setelah pengacakan
    for (int i = 0; i < finalQuestions.length; i++) {
      final q = finalQuestions[i];
      finalQuestions[i] = QuestionItem(
        id: 'Q${i + 1}',
        programName: q.programName,
        minatKey: q.minatKey,
        questionText: q.questionText,
        rawQuestionText: q.rawQuestionText,
        bobot: q.bobot,
      );
    }

    // 5. Acak sekali lagi untuk memastikan tidak ada pola yang dapat diprediksi
    // (Opsional: hapus baris ini jika Anda ingin mempertahankan pola rotasi yang sempurna)
    finalQuestions.shuffle(Random());

    // 6. Renumber lagi setelah pengacakan terakhir
    for (int i = 0; i < finalQuestions.length; i++) {
      final q = finalQuestions[i];
      finalQuestions[i] = QuestionItem(
        id: 'Q${i + 1}',
        programName: q.programName,
        minatKey: q.minatKey,
        questionText: q.questionText,
        rawQuestionText: q.rawQuestionText,
        bobot: q.bobot,
      );
    }

    // 7. Set state dengan hasil pengacakan stratifikasi
    allQuestions.value = finalQuestions;
  }

  void printDistributionSummary(List<QuestionItem> questions) {
    final countByInterest = <String, int>{};

    for (var q in questions) {
      final key = '${q.programName}|${q.minatKey}';
      countByInterest[key] = (countByInterest[key] ?? 0) + 1;
    }

    print('=== Distribusi Pertanyaan ===');
    countByInterest.forEach((minat, count) {
      print('$minat: $count pertanyaan');
    });

    // Analisis pengelompokan
    print('\n=== Analisis Urutan ===');
    String prevMinat = '';
    int switchCount = 0;

    for (var q in questions) {
      final currentMinat = '${q.programName}|${q.minatKey}';
      if (prevMinat != '' && prevMinat != currentMinat) {
        switchCount++;
      }
      prevMinat = currentMinat;
    }

    print(
        'Jumlah pergantian minat: $switchCount dari ${questions.length - 1} kemungkinan pergantian');
    final switchRatio = switchCount / (questions.length - 1);
    print('Rasio pergantian: ${(switchRatio * 100).toStringAsFixed(2)}%');
    print('Semakin tinggi rasio, semakin baik pengacakannya');
  }

  /// Flatten pertanyaan dari programList -> allQuestions (Q1, Q2, dsb)
  void flattenQuestions(List<ProgramStudi> programs) {
    // Implementation unchanged
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

  int extractWeight(String questionText) {
    final regex = RegExp(r'\[(\d+)\]');
    final match = regex.firstMatch(questionText);
    if (match != null && match.groupCount >= 1) {
      return int.parse(match.group(1)!);
    }
    return 5; // Default weight jika tidak ditemukan
  }

  /// Modified: Return RecommendationResult object instead of a string
  /// Modified: Return RecommendationResult object with balanced scoring
  RecommendationResult runForwardChaining() {
    // 1. Working Memory: Inisialisasi untuk menyimpan fakta yang diketahui
    final workingMemoryList = <String>[];
    final workingMemory = <String>{};

    // Populate working memory dari jawaban user
    for (var q in allQuestions) {
      if (q.userAnswer == true) {
        final fact = '${q.id}=Yes';
        workingMemory.add(fact);
        workingMemoryList.add(fact);
      } else if (q.userAnswer == false) {
        final fact = '${q.id}=No';
        workingMemory.add(fact);
        workingMemoryList.add(fact);
      }
    }

    // 2. Skor per-minat: menyimpan total skor untuk setiap bidang minat
    final minatScores = <String, int>{};

    // 3. Menyimpan kontribusi rule untuk penjelasan hasil
    final minatContrib = <String, List<String>>{};

    // 4. Menyimpan data tambahan per minat
    final minatAdditionalData = <String, Map<String, dynamic>>{};

    // 5. Menyimpan total pertanyaan per minat untuk perhitungan rasio
    final minatQuestionCount = <String, int>{};

    // 6. Membuat rule berdasarkan pertanyaan
    final rules = <Rule>[];
    for (var q in allQuestions) {
      // Ekstrak bobot dari teks pertanyaan
      int bobot = q.bobot;
      if (bobot == 0) {
        final regex = RegExp(r'\[(\d+)\]');
        final match = regex.firstMatch(q.questionText);
        if (match != null && match.groupCount >= 1) {
          bobot = int.parse(match.group(1)!);
        } else {
          bobot = 5; // Default weight
        }
      }

      // Hitung total pertanyaan per minat
      final keyMinat = '${q.programName}|${q.minatKey}';
      minatQuestionCount[keyMinat] = (minatQuestionCount[keyMinat] ?? 0) + 1;

      // Buat rule untuk jawaban Yes
      final ruleYes = Rule(
        ifFacts: ['${q.id}=Yes'],
        thenAction: (wm) {
          // Tambah skor sesuai bobot (tanpa multiplier)
          minatScores[keyMinat] = (minatScores[keyMinat] ?? 0) + bobot;

          // Catat rule yang dijalankan untuk penjelasan
          minatContrib[keyMinat] ??= [];
          minatContrib[keyMinat]!.add(
              'IF (${q.id}=Yes) THEN +$bobot skor → $keyMinat\n'
              '   [Pertanyaan: "${q.questionText.replaceAll(RegExp(r'\s*\[\d+\]'), '')}"]');
        },
      );
      rules.add(ruleYes);

      // Aktifkan rule untuk jawaban No
      final ruleNo = Rule(
        ifFacts: ['${q.id}=No'],
        thenAction: (wm) {
          // Kurangi skor dengan penalti kecil
          final penalty = bobot ~/ 3; // Penalti lebih kecil (1/3 dari bobot)
          minatScores[keyMinat] = (minatScores[keyMinat] ?? 0) - penalty;

          // Catat rule yang dijalankan
          minatContrib[keyMinat] ??= [];
          minatContrib[keyMinat]!.add(
              'IF (${q.id}=No) THEN -$penalty skor → $keyMinat\n'
              '   [Pertanyaan: "${q.questionText.replaceAll(RegExp(r'\s*\[\d+\]'), '')}"]');
        },
      );
      rules.add(ruleNo);
    }

    // 7. Tambahkan rule untuk memproses karir dengan bobot
    for (var program in programList.value) {
      program.minat.forEach((minatKey, minat) {
        // Simpan data tambahan
        final additionalDataKey = '${program.name}|$minatKey';
        minatAdditionalData[additionalDataKey] = {
          'rekomendasi_kursus': minat.rekomendasi_kursus ?? [],
          'universitas_rekomendasi': minat.universitas_rekomendasi ?? [],
        };

        // Proses bobot karir
        for (var career in minat.karir) {
          final regex = RegExp(r'\[(\d+)\]');
          final match = regex.firstMatch(career);
          if (match != null && match.groupCount >= 1) {
            final careerBobot = int.parse(match.group(1)!);

            // Buat rule khusus untuk karir dengan bobot tinggi
            if (careerBobot > 15) {
              // Turunkan threshold
              final rule = Rule(
                ifFacts: [],
                thenAction: (wm) {
                  // Tambahkan bonus untuk karir berbobot tinggi
                  final keyMinat = '${program.name}|$minatKey';
                  final bonusScore = (careerBobot - 15); // Bonus moderat
                  minatScores[keyMinat] =
                      (minatScores[keyMinat] ?? 0) + bonusScore;

                  // Catat rule ini
                  minatContrib[keyMinat] ??= [];
                  minatContrib[keyMinat]!.add(
                      'Bonus untuk karir prospektif: "${career.replaceAll(RegExp(r'\s*\[\d+\]'), '')}" +$bonusScore skor');
                },
              );
              rules.add(rule);
            }
          }
        }
      });
    }

    // 8. Jalankan Forward Chaining dengan agenda dan conflict resolution
    final agenda = <Rule>[...rules];
    final firedRules = <Rule>{};

    while (agenda.isNotEmpty) {
      final rule = agenda.removeAt(0);
      if (firedRules.contains(rule)) continue;

      bool allConditionsMet = true;
      for (final fact in rule.ifFacts) {
        if (!workingMemory.contains(fact)) {
          allConditionsMet = false;
          break;
        }
      }

      if (allConditionsMet || rule.ifFacts.isEmpty) {
        rule.thenAction(workingMemory);
        firedRules.add(rule);
      }
    }

    // 9. Cek hasil skor
    if (minatScores.isEmpty) {
      return RecommendationResult(
        workingMemory: workingMemoryList,
        recommendations: [],
      );
    }

    // 10. Hitung rasio jawaban Yes untuk tiap minat
    final minatYesRatio = <String, double>{};

    minatScores.forEach((minatKey, rawScore) {
      // Hitung total pertanyaan untuk minat ini
      final totalQuestions = minatQuestionCount[minatKey] ?? 1;

      // Jumlah jawaban "Yes" (estimasi berdasarkan skor)
      int estimatedYesCount = 0;

      // Cari rules yang berkontribusi ke minat ini (parsing untuk menghitung jawaban Yes)
      final contribs = minatContrib[minatKey] ?? [];
      for (final contrib in contribs) {
        if (contrib.contains('IF (') &&
            contrib.contains('=Yes)') &&
            !contrib.contains('Bonus')) {
          estimatedYesCount++;
        }
      }

      // Hitung rasio
      final ratio = estimatedYesCount / totalQuestions;
      minatYesRatio[minatKey] = ratio;
    });

    // 11. Normalisasi skor dengan pendekatan berjenjang
    final normalizedScores = <String, int>{};

    // Tentukan skor tertinggi dan terendah untuk distribusi
    final highestRawScore = minatScores.values.reduce((a, b) => a > b ? a : b);

    minatScores.forEach((minatKey, rawScore) {
      // Base score berdasarkan perbandingan dengan skor tertinggi
      double relativeFactor = rawScore / highestRawScore;

      // Rasio Yes juga mempengaruhi skor
      final yesRatio = minatYesRatio[minatKey] ?? 0.0;

      // Formula skor:
      // - 70% dari faktor relatif terhadap skor tertinggi
      // - 30% dari rasio jawaban Yes
      double scoreBase = (relativeFactor * 0.7) + (yesRatio * 0.3);

      // Scale ke rentang 0-100
      int finalScore = (scoreBase * 100).round();

      // Buat distribusi yang lebih beragam dengan kurva:
      // Skor tertinggi: 80-95
      // Skor rata-rata: 60-75
      // Skor rendah: 40-59
      if (finalScore >= 75) {
        // Top tier - max 95
        finalScore = 80 + ((finalScore - 75) * 15 ~/ 25);
      } else if (finalScore >= 50) {
        // Mid tier
        finalScore = 60 + ((finalScore - 50) * 15 ~/ 25);
      } else {
        // Low tier - min 40
        finalScore = 40 + ((finalScore) * 19 ~/ 50);
      }

      // Terapkan batas akhir
      finalScore = finalScore.clamp(40, 95);

      normalizedScores[minatKey] = finalScore;
    });

    // 12. Urutkan hasil berdasarkan skor normalisasi (descending)
    final sorted = normalizedScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 13. Ambil top 3 rekomendasi
    final topResults = sorted.take(3).toList();

    // 14. Pastikan ada perbedaan yang cukup antar rekomendasi
    if (topResults.length > 1) {
      // Pastikan ada gap minimal 5 point antara #1 dan #2
      if (topResults[0].value - topResults[1].value < 5) {
        topResults[1] = MapEntry(topResults[1].key, topResults[0].value - 5);
      }

      // Jika ada #3, pastikan ada gap minimal 3 point antara #2 dan #3
      if (topResults.length > 2 &&
          topResults[1].value - topResults[2].value < 3) {
        topResults[2] = MapEntry(topResults[2].key, topResults[1].value - 3);
      }
    }

    // 15. Buat list rekomendasi
    final recommendations = <RecommendationItem>[];

    for (int i = 0; i < topResults.length; i++) {
      final minatKey = topResults[i].key;
      final score = topResults[i].value;

      final parts = minatKey.split('|');
      if (parts.length == 2) {
        final progName = parts[0];
        final mKey = parts[1];

        final programStudi = programList.value.firstWhere(
          (p) => p.name == progName,
          orElse: () => ProgramStudi.empty(),
        );

        final minatObj = programStudi.minat[mKey];

        if (minatObj != null) {
          final careers = minatObj.karir.map((career) {
            return career.replaceAll(RegExp(r'\s*\[\d+\]'), '').trim();
          }).toList();

          final majors = minatObj.jurusanTerkait;
          final rules = minatContrib[minatKey] ?? [];
          final additionalData = minatAdditionalData[minatKey] ?? {};

          recommendations.add(
            RecommendationItem(
              title: '$progName - $mKey',
              score: score,
              careers: careers,
              majors: majors,
              rules: rules,
              index: i,
              recommendedCourses: additionalData['rekomendasi_kursus'],
              recommendedUniversities:
                  additionalData['universitas_rekomendasi'],
            ),
          );
        }
      }
    }

    return RecommendationResult(
      workingMemory: workingMemoryList,
      recommendations: recommendations,
    );
  }

  Future<void> saveResultsToFirestore(RecommendationResult results) async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar(
          'Error',
          'Kamu perlu login untuk menyimpan hasil',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Prepare data to save
      final timestamp = DateTime.now();
      final userAnswers = allQuestions
          .map((q) => {
                'questionId': q.id,
                'question': q.questionText,
                'rawQuestion': q.rawQuestionText,
                'answer': q.userAnswer,
                'programName': q.programName,
                'minatKey': q.minatKey,
                'bobot': q.bobot,
              })
          .toList();

      // Format recommendations for Firestore
      final recommendationsData = results.recommendations
          .map((rec) => {
                'title': rec.title,
                'score': rec.score,
                'careers': rec.careers,
                'majors': rec.majors,
                'rules': rec.rules,
                'index': rec.index,
              })
          .toList();

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('recommendation_history')
          .add({
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName,
        'timestamp': FieldValue.serverTimestamp(),
        'formattedTimestamp': timestamp.toString(),
        'isKerja': isKerja,
        'questionMode': isKerja ? 'Rekomendasi Karir' : 'Rekomendasi Kuliah',
        'userAnswers': userAnswers,
        'workingMemory': results.workingMemory,
        'recommendations': recommendationsData,
        'totalQuestions': totalCount,
        'answeredQuestions': answeredCount,
      });

      Get.snackbar(
        'Berhasil',
        'Hasil rekomendasi telah disimpan',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error saving results: $e');
      Get.snackbar(
        'Error',
        'Gagal menyimpan hasil: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Still needed for legacy reasons - converts the RecommendationResult to a string
  String runForwardChainingAsString() {
    final result = runForwardChaining();

    // Convert to string format (legacy format)
    String message = 'HASIL FORWARD CHAINING:\n\n';
    message += 'Working Memory (fakta): ${result.workingMemory.join(', ')}\n\n';

    message += 'Top 3 Rekomendasi:\n';
    for (int i = 0; i < result.recommendations.length; i++) {
      final rec = result.recommendations[i];
      message += '${i + 1}. ${rec.title} (Skor: ${rec.score})\n';

      // Rules
      if (rec.rules.isNotEmpty) {
        message += '  RULES YANG:\n';
        for (var rule in rec.rules) {
          message += '   - $rule\n';
        }
      }

      // Careers
      if (rec.careers.isNotEmpty) {
        message += '  Karir:\n';
        for (var career in rec.careers) {
          message += '   - $career\n';
        }
      } else {
        message += '  Karir: (Tidak ada data)\n';
      }

      // Majors
      if (rec.majors.isNotEmpty) {
        message += '  Jurusan Terkait:\n';
        for (var major in rec.majors) {
          message += '   - $major\n';
        }
      }

      message += '\n';
    }

    return message;
  }
}
