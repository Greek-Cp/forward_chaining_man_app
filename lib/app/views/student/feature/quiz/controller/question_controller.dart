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
    // 1. Working Memory: "Q1=Yes" atau "Q1=No"
    final workingMemoryList = <String>[];
    final workingMemory = <String>{};

    for (var q in allQuestions) {
      if (q.userAnswer == true) {
        workingMemory.add('${q.id}=Yes'); // misal "Q1=Yes"
        workingMemoryList.add('${q.id}=Yes');
      } else if (q.userAnswer == false) {
        workingMemory.add('${q.id}=No'); // "Q1=No" (opsional)
        workingMemoryList.add('${q.id}=No');
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
      // Jika tidak ada hasil, kembalikan objek kosong
      return RecommendationResult(
        workingMemory: workingMemoryList,
        recommendations: [],
      );
    }

    // Urutkan descending
    final sorted = minatScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // Ambil top 3
    final top3 = sorted.take(3).toList();

    // 7. Buat list rekomendasi
    final recommendations = <RecommendationItem>[];

    for (int i = 0; i < top3.length; i++) {
      final minatKey =
          top3[i].key; // ex: "IPA (Sains Murni) - Kerja|Kedokteran"
      final score = top3[i].value;

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
          // Dapatkan careers dan majors dari minatObj
          final careers = minatObj.karir;
          final majors = minatObj.jurusanTerkait;

          // Dapatkan recommended courses dari rekomendasi_kursus (jika ada)
          List<String>? recommendedCourses;
          if (minatObj.rekomendasi_kursus != null &&
              minatObj.rekomendasi_kursus!.isNotEmpty) {
            recommendedCourses = minatObj.rekomendasi_kursus;
          }

          // Dapatkan recommended universities dari rekomendasi_universitas (jika ada)
          List<String>? recommendedUniversities;
          if (minatObj.universitas_rekomendasi != null &&
              minatObj.universitas_rekomendasi!.isNotEmpty) {
            recommendedUniversities = minatObj.universitas_rekomendasi;
          }

          // Dapatkan rules dari minatContrib
          final rules = minatContrib[minatKey] ?? [];

          // Add to recommendations with the additional data
          recommendations.add(
            RecommendationItem(
              title: minatKey,
              score: score,
              careers: careers,
              majors: majors,
              rules: rules,
              index: i,
              recommendedCourses: recommendedCourses,
              recommendedUniversities: recommendedUniversities,
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
