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
