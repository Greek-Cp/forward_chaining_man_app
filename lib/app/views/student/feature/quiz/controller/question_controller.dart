/// Controller untuk QuestionPage
/// import 'dart:convert';
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
    // Implementation unchanged
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

  /// Modified: Return RecommendationResult object instead of a string
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

          // Dapatkan rules dari minatContrib
          final rules = minatContrib[minatKey] ?? [];

          // Add to recommendations using user's existing RecommendationItem structure
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
