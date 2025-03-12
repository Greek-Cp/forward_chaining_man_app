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
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<void> autoFillAllPagesNotCorrect(bool? answer) async {
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

  /// Flatten pertanyaan dari programList -> allQuestions (Q1, Q2, dsb)
  void flattenQuestions(List<ProgramStudi> programs) {
    final all = <QuestionItem>[];
    int counter = 1;

    for (var prog in programs) {
      // prog.name = "IPA (Sains Murni) - Kerja" atau "IPA (Sains Murni)"
      for (var minatEntry in prog.minat.entries) {
        final minatKey = minatEntry.key;
        final minatVal = minatEntry.value; // punya pertanyaan, karir, dsb.

        for (int i = 0; i < minatVal.pertanyaan.length; i++) {
          final p = minatVal.pertanyaan[i];
          final bobot = extractBobot(p);
          final cleaned = cleanPertanyaan(p);
          final qId = 'Q$counter';
          counter++;

          // Ambil data RIASEC jika tersedia
          List<String>? riasecTypes;
          List<int>? riasecBobot;

          // Periksa apakah informasi RIASEC tersedia untuk pertanyaan ini
          if (minatVal.riasecType != null &&
              i < minatVal.riasecType.length &&
              minatVal.riasecType[i] != null) {
            final riasecInfo = minatVal.riasecType[i];
            if (riasecInfo['type'] != null) {
              riasecTypes = List<String>.from(riasecInfo['type']);
            }
            if (riasecInfo['bobot'] != null) {
              riasecBobot = List<int>.from(riasecInfo['bobot']);
            }
          }

          all.add(
            QuestionItem(
              id: qId,
              programName: prog.name,
              minatKey: minatKey,
              questionText: cleaned,
              rawQuestionText: p,
              bobot: bobot,
              riasecTypes: riasecTypes,
              riasecBobot: riasecBobot,
            ),
          );
        }
      }
    }

    // Set state
    allQuestions.value = all;
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

        for (int i = 0; i < minatVal.pertanyaan.length; i++) {
          final p = minatVal.pertanyaan[i];
          final bobot = extractBobot(p);
          final cleaned = cleanPertanyaan(p);

          // Ambil data RIASEC jika tersedia
          List<String>? riasecTypes;
          List<int>? riasecBobot;

          // Periksa apakah informasi RIASEC tersedia untuk pertanyaan ini
          if (minatVal.riasecType != null &&
              i < minatVal.riasecType.length &&
              minatVal.riasecType[i] != null) {
            final riasecInfo = minatVal.riasecType[i];
            if (riasecInfo['type'] != null) {
              riasecTypes = List<String>.from(riasecInfo['type']);
            }
            if (riasecInfo['bobot'] != null) {
              riasecBobot = List<int>.from(riasecInfo['bobot']);
            }
          }

          questionsByInterest[minatIdentifier]!.add(
            QuestionItem(
              id: '', // Temporary, will assign later
              programName: prog.name,
              minatKey: minatKey,
              questionText: cleaned,
              rawQuestionText: p,
              bobot: bobot,
              riasecTypes: riasecTypes,
              riasecBobot: riasecBobot,
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
        riasecTypes: q.riasecTypes,
        riasecBobot: q.riasecBobot,
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
        riasecTypes: q.riasecTypes,
        riasecBobot: q.riasecBobot,
      );
    }

    // 7. Set state dengan hasil pengacakan stratifikasi
    allQuestions.value = finalQuestions;

    // 8. Analisis distribusi (opsional)
    if (true) {
      printRiasecDistribution(finalQuestions);
    }
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

  void printRiasecDistribution(List<QuestionItem> questions) {
    // Hitung jumlah pertanyaan per tipe RIASEC
    final countByRiasecType = <String, int>{
      'R': 0,
      'I': 0,
      'A': 0,
      'S': 0,
      'E': 0,
      'C': 0
    };

    int questionsWithRiasec = 0;

    for (var q in questions) {
      if (q.riasecTypes != null && q.riasecTypes!.isNotEmpty) {
        questionsWithRiasec++;

        for (var type in q.riasecTypes!) {
          countByRiasecType[type] = (countByRiasecType[type] ?? 0) + 1;
        }
      }
    }

    print('\n=== Distribusi RIASEC ===');
    print(
        'Pertanyaan dengan informasi RIASEC: $questionsWithRiasec dari ${questions.length} (${(questionsWithRiasec / questions.length * 100).toStringAsFixed(1)}%)');

    countByRiasecType.forEach((type, count) {
      print('Tipe $type: $count pertanyaan');
    });

    // Hitung rata-rata jumlah tipe RIASEC per pertanyaan
    int totalTypes = 0;
    for (var q in questions) {
      if (q.riasecTypes != null) {
        totalTypes += q.riasecTypes!.length;
      }
    }

    final avgTypesPerQuestion =
        questionsWithRiasec > 0 ? totalTypes / questionsWithRiasec : 0;

    print(
        'Rata-rata tipe RIASEC per pertanyaan: ${avgTypesPerQuestion.toStringAsFixed(2)}');
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
    final workingMemoryList = <String>[];
    final workingMemory = <String>{};

    // 1️⃣ Menampilkan semua pertanyaan dan jawaban pengguna dengan detail lengkap
    print('📌 DAFTAR PERTANYAAN & JAWABAN PENGGUNA:');
    for (var q in allQuestions) {
      String answer = q.userAnswer == true ? "✅ Yes" : "❌ No";
      print('\n'
          '❓ ID: ${q.id}\n'
          '🔹 Program: ${q.programName}\n'
          '🔹 Minat: ${q.minatKey}\n'
          '🔹 Pertanyaan: ${q.questionText}\n'
          '🔹 Bobot: ${q.bobot}\n'
          '🔹 Raw Question: ${q.rawQuestionText}\n'
          '🔸 Jawaban: $answer\n');
    }

    // 2️⃣ Inisialisasi working memory
    print('\n🔹 Initial Working Memory: $workingMemoryList');

    for (var q in allQuestions) {
      if (q.userAnswer == true) {
        workingMemory.add('${q.id}=Yes');
        workingMemoryList.add('${q.id}=Yes');
      } else if (q.userAnswer == false) {
        workingMemory.add('${q.id}=No');
        workingMemoryList.add('${q.id}=No');
      }
    }

    print('🔹 Final Working Memory: $workingMemoryList\n');

    // 3️⃣ Inisialisasi struktur data untuk menyimpan informasi bobot
    final minatBobotTotal = <String, int>{};
    final minatBobotBenar = <String, int>{};
    final minatContrib = <String, List<String>>{};

    // 4️⃣ Hitung total bobot per minat
    for (var q in allQuestions) {
      final keyMinat = '${q.programName}|${q.minatKey}';
      minatBobotTotal[keyMinat] = (minatBobotTotal[keyMinat] ?? 0) + q.bobot;
    }

    print('📌 TOTAL BOBOT PER MINAT:');
    minatBobotTotal.forEach((key, value) {
      print('   🔹 $key → Total Bobot: $value');
    });
    print('');

    // 5️⃣ Generate rules untuk forward chaining
    final rules = <Rule>[];
    for (var q in allQuestions) {
      final rule = Rule(
        ifFacts: ['${q.id}=Yes'],
        thenAction: (wm) {
          final keyMinat = '${q.programName}|${q.minatKey}';

          // Tambahkan bobot ke skor benar
          minatBobotBenar[keyMinat] =
              (minatBobotBenar[keyMinat] ?? 0) + q.bobot;

          // Catat rule fired untuk penjelasan
          minatContrib[keyMinat] ??= [];
          minatContrib[keyMinat]!
              .add('✅ IF (${q.id}=Yes) THEN +${q.bobot} skor → $keyMinat\n'
                  '   [Pertanyaan: "${q.questionText}"]');
        },
      );
      rules.add(rule);
    }

    print('📌 GENERATED RULES:');
    for (var r in rules) {
      print('- IF ${r.ifFacts} THEN Update Skor');
    }
    print('');

    // 6️⃣ Jalankan Forward Chaining
    bool firedSomething = true;
    final firedRules = <Rule>{};

    print('🚀 Starting Forward Chaining...\n');

    while (firedSomething) {
      firedSomething = false;
      for (var r in rules) {
        if (firedRules.contains(r)) continue;
        final allMatch =
            r.ifFacts.every((fact) => workingMemory.contains(fact));

        if (allMatch) {
          r.thenAction(workingMemory);
          firedRules.add(r);
          firedSomething = true;
          print('🔥 Fired Rule: ${r.ifFacts}');
        }
      }
    }

    // 7️⃣ Hitung skor persentase per minat
    final minatScores = <String, int>{};

    print('\n📌 PERHITUNGAN SKOR MINAT:');
    for (var entry in minatBobotTotal.entries) {
      final keyMinat = entry.key;
      final totalBobot = entry.value;
      final bobotBenar = minatBobotBenar[keyMinat] ?? 0;
      int percentage = 0;

      if (totalBobot > 0) {
        percentage = ((bobotBenar / totalBobot) * 100).round();
      }

      minatScores[keyMinat] = percentage;

      print('➡️ $keyMinat: ($bobotBenar / $totalBobot) * 100 = $percentage%');
    }

    print('\n🔹 Final Minat Scores: $minatScores\n');

    // 8️⃣ Urutkan minat berdasarkan persentase tertinggi
    final sorted = minatScores.entries.toList();
    sorted.sort((a, b) {
      final percentageComparison = b.value.compareTo(a.value);
      if (percentageComparison != 0) {
        return percentageComparison;
      }
      return (minatBobotBenar[b.key] ?? 0)
          .compareTo(minatBobotBenar[a.key] ?? 0);
    });

    print('📌 Sorted Minat Scores: $sorted\n');

    // 9️⃣ Ambil top 3 rekomendasi
    final topRecommendations = sorted.take(3).toList();
    final recommendations = <RecommendationItem>[];

    print('📌 TOP RECOMMENDATIONS:');
    for (int i = 0; i < topRecommendations.length; i++) {
      final minatKey = topRecommendations[i].key;
      final score = topRecommendations[i].value;
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
          final careers = minatObj.karir;
          final majors = minatObj.jurusanTerkait;
          final rules = minatContrib[minatKey] ?? [];

          recommendations.add(
            RecommendationItem(
              title: minatKey,
              score: score,
              careers: careers,
              majors: majors,
              rules: rules,
              index: i,
            ),
          );

          print('⭐ Recommendation ${i + 1}: $minatKey');
          print('   🔹 Score: $score%');
          print('   📌 Careers: $careers');
          print('   🎓 Majors: $majors');
          print('   🔎 Rules Applied: $rules\n');
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

      // Get schoolId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? schoolId = prefs.getString('school_id');

      // If schoolId is not found in SharedPreferences, try to find it by searching all schools
      if (schoolId == null || schoolId.isEmpty) {
        schoolId = await _findStudentSchoolId(user.uid);

        if (schoolId == null || schoolId.isEmpty) {
          Get.snackbar(
            'Error',
            'Tidak dapat menemukan sekolah terkait',
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        // Save school ID for future use
        await prefs.setString('school_id', schoolId);
      }

      // Dapatkan informasi kelas siswa dari Firestore dengan struktur baru
      String? studentClass;
      try {
        DocumentSnapshot studentDoc = await FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('students')
            .doc(user.uid)
            .get();

        if (studentDoc.exists) {
          final data = studentDoc.data() as Map<String, dynamic>;
          studentClass = data['class'] as String?;
        }
      } catch (e) {
        print('Error fetching student class: $e');
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
                // Tambahkan data RIASEC jika ada
                'riasecTypes': q.riasecTypes ?? [],
                'riasecBobot': q.riasecBobot ?? [],
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
                'recommendedCourses': rec.recommendedCourses ?? [],
                'recommendedUniversities': rec.recommendedUniversities ?? [],
                // Tambahkan data RIASEC
                'riasecCompatibility': rec.riasecCompatibility ?? 0.0,
                'matchingRiasecCareers': rec.matchingRiasecCareers ?? [],
              })
          .toList();

      // Format RIASEC profile data jika ada
      Map<String, dynamic> riasecProfileData = {};
      if (results.riasecProfile != null) {
        riasecProfileData = {
          'scores': results.riasecProfile!.scores,
          'dominantTypes': results.riasecProfile!.dominantTypes,
          'code': results.riasecProfile!.code,
          'matchingCareers': results.riasecProfile!.matchingCareers,
        };
      }

      // Prepare recommendation data
      Map<String, dynamic> recommendationData = {
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName,
        'schoolId': schoolId, // Add schoolId to data
        'studentClass': studentClass,
        'timestamp': FieldValue.serverTimestamp(),
        'formattedTimestamp': timestamp.toString(),
        'isKerja': isKerja,
        'questionMode': isKerja ? 'Rekomendasi Karir' : 'Rekomendasi Kuliah',
        'userAnswers': userAnswers,
        'workingMemory': results.workingMemory,
        'recommendations': recommendationsData,
        'totalQuestions': totalCount,
        'answeredQuestions': answeredCount,
        'riasecProfile': riasecProfileData,
      };

      // Save to the school's recommendation_history subcollection with user ID as document ID
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('recommendation_history')
          .doc(user.uid)
          .set(recommendationData, SetOptions(merge: true));

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

// Helper function to find a student's school ID
  Future<String?> _findStudentSchoolId(String userId) async {
    try {
      final schoolsSnapshot =
          await FirebaseFirestore.instance.collection('schools').get();

      for (var schoolDoc in schoolsSnapshot.docs) {
        final studentDoc =
            await schoolDoc.reference.collection('students').doc(userId).get();

        if (studentDoc.exists) {
          return schoolDoc.id;
        }
      }
      return null;
    } catch (e) {
      print('Error finding student school ID: $e');
      return null;
    }
  }

  /// Still needed for legacy reasons - converts the RecommendationResult to a string
  String runForwardChainingAsString() {
    final result = runForwardChaining();

    // Convert to string format (legacy format)
    String message = 'HASIL FORWARD CHAINING:\n\n';
    message += 'Working Memory (fakta): ${result.workingMemory.join(', ')}\n\n';

    // Tambahkan informasi RIASEC profile jika ada
    if (result.riasecProfile != null) {
      message += 'PROFIL RIASEC:\n';
      message += 'Kode RIASEC: ${result.riasecProfile!.code}\n';
      message +=
          'Tipe Dominan: ${result.riasecProfile!.dominantTypes.join(", ")}\n';

      message += 'Skor per Tipe:\n';
      result.riasecProfile!.scores.forEach((type, score) {
        message += '  - $type: $score\n';
      });

      if (result.riasecProfile!.matchingCareers.isNotEmpty) {
        message += 'Karir yang Cocok dengan Profil RIASEC Anda:\n';
        for (var career in result.riasecProfile!.matchingCareers) {
          message += '  - $career\n';
        }
      }
      message += '\n';
    }

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

      // RIASEC matching careers (jika ada)
      if (rec.matchingRiasecCareers != null &&
          rec.matchingRiasecCareers!.isNotEmpty) {
        message +=
            '  Karir yang Cocok dengan Profil RIASEC Anda (${rec.riasecCompatibility?.toStringAsFixed(1)}% kecocokan):\n';
        for (var career in rec.matchingRiasecCareers!) {
          message += '   - $career\n';
        }
      }

      // Majors
      if (rec.majors.isNotEmpty) {
        message += '  Jurusan Terkait:\n';
        for (var major in rec.majors) {
          message += '   - $major\n';
        }
      }

      // Recommended Courses (jika ada)
      if (rec.recommendedCourses != null &&
          rec.recommendedCourses!.isNotEmpty) {
        message += '  Kursus yang Direkomendasikan:\n';
        for (var course in rec.recommendedCourses!) {
          message += '   - $course\n';
        }
      }

      // Recommended Universities (jika ada)
      if (rec.recommendedUniversities != null &&
          rec.recommendedUniversities!.isNotEmpty) {
        message += '  Universitas yang Direkomendasikan:\n';
        for (var university in rec.recommendedUniversities!) {
          message += '   - $university\n';
        }
      }

      message += '\n';
    }

    return message;
  }
}
