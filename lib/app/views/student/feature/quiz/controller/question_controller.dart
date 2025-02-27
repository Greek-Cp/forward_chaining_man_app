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

    // 4. Menyimpan data tambahan per minat (seperti rekomendasi kursus, universitas, dll)
    final minatAdditionalData = <String, Map<String, dynamic>>{};

    // 5. Membuat rule berdasarkan pertanyaan
    final rules = <Rule>[];
    for (var q in allQuestions) {
      // Ekstrak bobot dari teks pertanyaan jika belum tersedia di objek q
      int bobot = q.bobot;
      if (bobot == 0) {
        // Extract from question text format: "Question [5]"
        final regex = RegExp(r'\[(\d+)\]');
        final match = regex.firstMatch(q.questionText);
        if (match != null && match.groupCount >= 1) {
          bobot = int.parse(match.group(1)!);
        } else {
          bobot = 5; // Default weight
        }
      }

      // Buat rule untuk jawaban Yes
      final ruleYes = Rule(
        ifFacts: ['${q.id}=Yes'],
        thenAction: (wm) {
          final keyMinat = '${q.programName}|${q.minatKey}';
          // Tambah skor sesuai bobot
          minatScores[keyMinat] = (minatScores[keyMinat] ?? 0) + bobot;

          // Catat rule yang dijalankan untuk penjelasan
          minatContrib[keyMinat] ??= [];
          minatContrib[keyMinat]!.add(
              'IF (${q.id}=Yes) THEN +$bobot skor → $keyMinat\n'
              '   [Pertanyaan: "${q.questionText.replaceAll(RegExp(r'\s*\[\d+\]'), '')}"]');
        },
      );
      rules.add(ruleYes);

      // Opsional: Buat rule untuk jawaban No (dengan pengurangan skor)
      // Uncomment jika ingin menerapkan pengurangan skor untuk jawaban "No"
      /*
    final ruleNo = Rule(
      ifFacts: ['${q.id}=No'],
      thenAction: (wm) {
        final keyMinat = '${q.programName}|${q.minatKey}';
        // Kurangi skor (opsional, bisa dikomenter jika tidak diinginkan)
        minatScores[keyMinat] = (minatScores[keyMinat] ?? 0) - bobot ~/ 2; // Kurangi setengah bobot
        
        // Catat rule yang dijalankan
        minatContrib[keyMinat] ??= [];
        minatContrib[keyMinat]!.add(
          'IF (${q.id}=No) THEN -${bobot ~/ 2} skor → $keyMinat\n'
          '   [Pertanyaan: "${q.questionText.replaceAll(RegExp(r'\s*\[\d+\]'), '')}"]'
        );
      },
    );
    rules.add(ruleNo);
    */
    }

    // 6. Tambahkan rule untuk memproses karir dengan bobot
    // Misalnya: "Dokter Umum [20]" memberikan bobot tambahan ke minat terkait
    for (var program in programList.value) {
      program.minat.forEach((minatKey, minat) {
        // Simpan data tambahan
        final additionalDataKey = '${program.name}|$minatKey';
        minatAdditionalData[additionalDataKey] = {
          'rekomendasi_kursus': minat.rekomendasi_kursus ?? [],
          'universitas_rekomendasi': minat.universitas_rekomendasi ?? [],
        };

        // Proses bobot karir (opsional)
        for (var career in minat.karir) {
          final regex = RegExp(r'\[(\d+)\]');
          final match = regex.firstMatch(career);
          if (match != null && match.groupCount >= 1) {
            final careerBobot = int.parse(match.group(1)!);

            // Buat rule khusus untuk karir dengan bobot tinggi
            if (careerBobot > 18) {
              // Hanya untuk karir dengan bobot tinggi
              final rule = Rule(
                // Rule ini selalu dijalankan (tanpa kondisi)
                ifFacts: [],
                thenAction: (wm) {
                  // Tambahkan sedikit bonus untuk karir berbobot tinggi
                  final keyMinat = '${program.name}|$minatKey';
                  minatScores[keyMinat] =
                      (minatScores[keyMinat] ?? 0) + (careerBobot - 18);

                  // Catat rule ini (opsional)
                  minatContrib[keyMinat] ??= [];
                  minatContrib[keyMinat]!.add(
                      'Bonus untuk karir prospektif: "${career.replaceAll(RegExp(r'\s*\[\d+\]'), '')}" +${careerBobot - 18} skor');
                },
              );
              rules.add(rule);
            }
          }
        }
      });
    }

    // 7. Jalankan Forward Chaining dengan agenda dan conflict resolution
    final agenda = <Rule>[...rules]; // Copy semua rule ke agenda
    final firedRules = <Rule>{};

    while (agenda.isNotEmpty) {
      // Conflict resolution: Ambil rule pertama dari agenda
      final rule = agenda.removeAt(0);

      if (firedRules.contains(rule)) continue; // Rule sudah dijalankan

      // Cek apakah semua kondisi IF terpenuhi
      bool allConditionsMet = true;
      for (final fact in rule.ifFacts) {
        if (!workingMemory.contains(fact)) {
          allConditionsMet = false;
          break;
        }
      }

      // Jika semua kondisi terpenuhi, jalankan rule
      if (allConditionsMet || rule.ifFacts.isEmpty) {
        rule.thenAction(workingMemory);
        firedRules.add(rule);
      }
    }

    // 8. Cek hasil skor
    if (minatScores.isEmpty) {
      return RecommendationResult(
        workingMemory: workingMemoryList,
        recommendations: [],
      );
    }

    // 9. Urutkan hasil berdasarkan skor (descending)
    final sorted = minatScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 10. Ambil top 3 (atau sesuaikan jumlahnya)
    final topResults = sorted.take(3).toList();

    // 11. Buat list rekomendasi
    final recommendations = <RecommendationItem>[];

    for (int i = 0; i < topResults.length; i++) {
      final minatKey = topResults[i].key; // format: "programName|minatKey"
      final score = topResults[i].value;

      // Split untuk mendapatkan program dan minat
      final parts = minatKey.split('|');
      if (parts.length == 2) {
        final progName = parts[0];
        final mKey = parts[1];

        // Cari program studi dan minat terkait
        final programStudi = programList.value.firstWhere(
          (p) => p.name == progName,
          orElse: () => ProgramStudi.empty(),
        );

        final minatObj = programStudi.minat[mKey];

        if (minatObj != null) {
          // Parse karir (hilangkan format bobot)
          final careers = minatObj.karir.map((career) {
            return career.replaceAll(RegExp(r'\s*\[\d+\]'), '').trim();
          }).toList();

          // Ambil jurusan terkait
          final majors = minatObj.jurusanTerkait;

          // Ambil rules yang dijalankan
          final rules = minatContrib[minatKey] ?? [];

          // Ambil data tambahan
          final additionalData = minatAdditionalData[minatKey] ?? {};
          print(
              "Data tambahan ${additionalData['universitas_rekomendasi']} ${progName}");
          // Tambahkan ke rekomendasi
          recommendations.add(
            RecommendationItem(
              title: '$progName - $mKey',
              score: score,
              careers: careers,
              majors: majors,
              rules: rules,
              index: i,
              // Tambahkan field baru jika diperlukan
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
