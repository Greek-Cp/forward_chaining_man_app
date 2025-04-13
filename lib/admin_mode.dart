import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;

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
  final String id; // unique ID, misal "Q1", "Q2"
  final String programName; // ex: "IPA (Sains Murni) - Kerja"
  final String minatKey; // ex: "Kedokteran"
  final String questionText; // Cleaned question text
  final String rawQuestionText; // Original question text with code
  final int bobot; // ex: 5
  bool? userAnswer; // Jawaban user: true, false, atau null

  // Add this field to store the question code
  final String questionCode; // ex: "KUL04"

  // Add any other existing fields...

  QuestionItem({
    required this.id,
    required this.programName,
    required this.minatKey,
    required this.questionText,
    required this.rawQuestionText,
    required this.bobot,
    this.userAnswer,
    required this.questionCode, // Add to constructor
    // Add any other existing parameters...
  });

  // If needed, you can keep a factory method to extract code from raw text
  factory QuestionItem.fromRawQuestion({
    required String id,
    required String programName,
    required String minatKey,
    required String questionText,
    required String rawQuestionText,
    required int bobot,
    bool? userAnswer,
    // Any other existing parameters...
  }) {
    // Extract question code
    final regex = RegExp(r'([A-Z]+\d+):');
    final match = regex.firstMatch(rawQuestionText);
    final questionCode = match != null && match.groupCount >= 1
        ? match.group(1)!
        : id; // Fallback to ID if no code found

    return QuestionItem(
      id: id,
      programName: programName,
      minatKey: minatKey,
      questionText: questionText,
      rawQuestionText: rawQuestionText,
      bobot: bobot,
      userAnswer: userAnswer,
      questionCode: questionCode,
      // Pass any other existing parameters...
    );
  }
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
