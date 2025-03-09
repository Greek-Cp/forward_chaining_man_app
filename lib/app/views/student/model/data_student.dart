/// Tambahan untuk Model Minat dengan RIASEC
class Minat {
  final List<String> pertanyaan;
  final List<Map<String, dynamic>> riasecType; // Baru: list tipe RIASEC
  final List<String> karir;
  final List<String> karir_riasec; // Baru: kode RIASEC untuk setiap karir
  final List<String> jurusanTerkait;
  final List<String>? rekomendasi_kursus;
  final List<String>? universitas_rekomendasi;

  Minat({
    required this.pertanyaan,
    this.riasecType = const [], // Baru
    required this.karir,
    this.karir_riasec = const [], // Baru
    required this.jurusanTerkait,
    this.rekomendasi_kursus,
    this.universitas_rekomendasi,
  });

  factory Minat.fromJson(Map<String, dynamic> json) {
    return Minat(
      pertanyaan: List<String>.from(json['pertanyaan'] ?? []),
      // Parsing untuk riasecType
      riasecType: List<Map<String, dynamic>>.from((json['riasecType'] ?? [])
          .map((item) => Map<String, dynamic>.from(item))),
      karir: List<String>.from(json['karir'] ?? []),
      // Parsing untuk karir_riasec
      karir_riasec: List<String>.from(json['karir_riasec'] ?? []),
      jurusanTerkait: List<String>.from(json['jurusan_terkait'] ?? []),
      rekomendasi_kursus: List<String>.from(json['rekomendasi_kursus'] ?? []),
      universitas_rekomendasi:
          List<String>.from(json['universitas_rekomendasi'] ?? []),
    );
  }
}

/// Tambahan untuk ProgramStudi dengan RIASEC
class ProgramStudi {
  final String name;
  final String description;
  final List<String> categories;
  final Map<String, dynamic>? riasec; // Baru: info RIASEC program studi
  final Map<String, Minat> minat;

  ProgramStudi({
    required this.name,
    required this.description,
    required this.categories,
    this.riasec, // Baru
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
      // Parsing untuk riasec
      riasec: json['riasec'] != null
          ? Map<String, dynamic>.from(json['riasec'])
          : null,
      minat: minat,
    );
  }

  factory ProgramStudi.empty() {
    return ProgramStudi(
      name: '',
      description: '',
      categories: [],
      riasec: null,
      minat: {},
    );
  }
}

/// Tambahan untuk QuestionItem dengan RIASEC
class QuestionItem {
  final String id;
  final String programName;
  final String minatKey;
  final String questionText;
  final String rawQuestionText;
  final int bobot;
  final List<String>? riasecTypes; // Baru: tipe RIASEC pertanyaan
  final List<int>? riasecBobot; // Baru: bobot RIASEC pertanyaan
  bool? userAnswer;

  QuestionItem({
    required this.id,
    required this.programName,
    required this.minatKey,
    required this.questionText,
    required this.rawQuestionText,
    required this.bobot,
    this.riasecTypes, // Baru
    this.riasecBobot, // Baru
    this.userAnswer,
  });
}

/// Model untuk hasil profil RIASEC
class RiasecProfile {
  final Map<String, int> scores; // Skor untuk masing-masing tipe (R,I,A,S,E,C)
  final List<String> dominantTypes; // Tipe dominan, misal ["R", "I", "C"]
  final String code; // Kode RIASEC, misal "RIC"
  final List<String> matchingCareers; // Karir yang cocok berdasarkan RIASEC

  RiasecProfile({
    required this.scores,
    required this.dominantTypes,
    required this.code,
    required this.matchingCareers,
  });
}

/// Tambahan untuk RecommendationResult dengan RIASEC
class RecommendationResult {
  final List<String> workingMemory;
  final List<RecommendationItem> recommendations;
  final RiasecProfile? riasecProfile; // Baru: profil RIASEC pengguna

  RecommendationResult({
    required this.workingMemory,
    required this.recommendations,
    this.riasecProfile, // Baru
  });
}

/// Tambahan untuk RecommendationItem dengan kesesuaian RIASEC
class RecommendationItem {
  final String title;
  final int score;
  final List<String> careers;
  final List<String> majors;
  final List<String> rules;
  final int index;
  final List<String>? recommendedCourses;
  final List<String>? recommendedUniversities;
  final double? riasecCompatibility; // Baru: persentase kesesuaian RIASEC
  final List<String>? matchingRiasecCareers; // Baru: karir yang cocok RIASEC

  RecommendationItem({
    required this.title,
    required this.score,
    required this.careers,
    required this.majors,
    required this.rules,
    required this.index,
    this.recommendedCourses,
    this.recommendedUniversities,
    this.riasecCompatibility, // Baru
    this.matchingRiasecCareers, // Baru
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
