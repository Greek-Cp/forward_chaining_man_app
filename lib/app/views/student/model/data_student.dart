// Models for the recommendation results
class RecommendationResult {
  final List<String> workingMemory;
  final List<RecommendationItem> recommendations;

  RecommendationResult({
    required this.workingMemory,
    required this.recommendations,
  });
}

// Using your existing RecommendationItem class
class RecommendationItem {
  final String title;
  final int score;
  final List<String> careers;
  final List<String> majors;
  final List<String> rules;
  final int index;
  final List<String>? recommendedCourses; // Baru
  final List<String>? recommendedUniversities; // Baru

  RecommendationItem({
    required this.title,
    required this.score,
    required this.careers,
    required this.majors,
    required this.rules,
    required this.index,
    this.recommendedCourses,
    this.recommendedUniversities,
  });
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
    final Map<String, dynamic> rawMinat = json['minat'] ?? {};
    final Map<String, Minat> minat = {};

    rawMinat.forEach((key, value) {
      minat[key] = Minat.fromJson(value);
    });

    return ProgramStudi(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      minat: minat,
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
  final List<String>? rekomendasi_kursus; // Baru
  final List<String>? universitas_rekomendasi; // Baru

  Minat({
    required this.pertanyaan,
    required this.karir,
    required this.jurusanTerkait,
    this.rekomendasi_kursus,
    this.universitas_rekomendasi,
  });

  factory Minat.fromJson(Map<String, dynamic> json) {
    return Minat(
      pertanyaan: List<String>.from(json['pertanyaan'] ?? []),
      karir: List<String>.from(json['karir'] ?? []),
      jurusanTerkait: List<String>.from(json['jurusan_terkait'] ?? []),
      // Tambahkan parsing untuk field baru
      rekomendasi_kursus: List<String>.from(json['rekomendasi_kursus'] ?? []),
      universitas_rekomendasi:
          List<String>.from(json['universitas_rekomendasi'] ?? []),
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
