import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/quiz/controller/question_controller.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/quiz/view/page_select_economy.dart';
import 'package:forward_chaining_man_app/app/views/student/model/data_student.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import models
// Pastikan path import disesuaikan dengan struktur proyek Anda
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

// Import models
// Pastikan path import disesuaikan dengan struktur proyek Anda

/// Halaman untuk mengumpulkan feedback dari pengguna untuk evaluasi akurasi sistem
class FeedbackEvaluationPage extends StatefulWidget {
  final RecommendationResult recommendationResults;
  final String majorType; // "SAINS" atau "TEKNIK"
  final bool isKerja; // true untuk karir, false untuk pendidikan

  const FeedbackEvaluationPage({
    Key? key,
    required this.recommendationResults,
    required this.majorType,
    required this.isKerja,
  }) : super(key: key);

  @override
  State<FeedbackEvaluationPage> createState() => _FeedbackEvaluationPageState();
}

class _FeedbackEvaluationPageState extends State<FeedbackEvaluationPage> {
  String? selectedMinat;
  String? confidenceLevel;
  final commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Tambahkan variabel untuk skala Likert tambahan
  final Map<String, String> likertRatings = {
    'relevance': '3', // Relevansi pertanyaan
    'difficulty': '3', // Tingkat kesulitan kuesioner
    'interface': '3', // Kemudahan antarmuka
    'satisfaction': '3', // Kepuasan keseluruhan
  };

  // Teks untuk setiap kategori penilaian
  final Map<String, String> likertLabels = {
    'relevance': 'Relevansi pertanyaan dengan minat saya',
    'difficulty': 'Tingkat kesulitan dalam menjawab kuesioner',
    'interface': 'Kemudahan penggunaan aplikasi',
    'satisfaction': 'Kepuasan keseluruhan dengan rekomendasi',
  };

  // Daftar minat berdasarkan jurusan yang dipilih user
  late List<String> availableMinat = [];

  @override
  void initState() {
    super.initState();
    _initializeMinatList();
  }

  /// Inisialisasi daftar minat berdasarkan majorType yang dipilih
  void _initializeMinatList() {
    // Mulai dengan set kosong untuk menghindari duplikasi
    Set<String> minatSet = {};

    try {
      // Coba dapatkan QuestionController untuk mengakses data program studi
      final questionController = Get.find<QuestionController>();

      // Tambahkan SEMUA minat yang sesuai dengan majorType (SAINS atau TEKNIK)
      for (var program in questionController.programList.value) {
        // Filter berdasarkan nama program yang mengandung majorType
        if (program.name
            .toLowerCase()
            .contains(widget.majorType.toLowerCase())) {
          // Tambahkan semua minat dari program ini
          for (var minatEntry in program.minat.entries) {
            final minatKey = '${program.name}|${minatEntry.key}';
            minatSet.add(minatKey);
            print('Menambahkan minat: $minatKey');
          }
        }
      }

      // Jika tidak ada minat yang ditemukan dari controller, gunakan alternatif dari data statis
      if (minatSet.isEmpty) {
        // Gunakan daftar statis berdasarkan majorType
        if (widget.majorType.toLowerCase().contains('sains')) {
          // Daftar minat IPA Sains
          minatSet.addAll([
            'IPA (Sains Murni)|Biologi',
            'IPA (Sains Murni)|Kimia',
            'IPA (Sains Murni)|Fisika',
            'IPA (Sains Murni)|Matematika',
            'IPA (Sains Murni)|Kesehatan',
            'IPA (Sains Murni)|Farmasi',
            'IPA (Sains Murni)|Kedokteran',
            'IPA (Sains Murni)|Lingkungan',
          ]);
        } else if (widget.majorType.toLowerCase().contains('teknik')) {
          // Daftar minat IPA Teknik
          minatSet.addAll([
            'IPA (Teknik)|Teknik Sipil',
            'IPA (Teknik)|Teknik Elektro',
            'IPA (Teknik)|Teknik Mesin',
            'IPA (Teknik)|Informatika',
            'IPA (Teknik)|Arsitektur',
            'IPA (Teknik)|Robotik',
            'IPA (Teknik)|Telekomunikasi',
            'IPA (Teknik)|Industri',
          ]);
        }
      }
    } catch (e) {
      print('Error saat mengambil minat dari controller: $e');

      // Jika error, gunakan data dari rekomendasi sebagai fallback terakhir
      for (var rec in widget.recommendationResults.recommendations) {
        minatSet.add(rec.title);
      }
    }

    // Jika masih kosong, tambahkan pesan error
    if (minatSet.isEmpty) {
      minatSet.add('Error|Tidak ada data minat');
    }

    // Konversi ke list dan urutkan
    availableMinat = minatSet.toList();
    availableMinat.sort();

    // Debug info
    print('Total minat tersedia: ${availableMinat.length}');
    print('Daftar minat: $availableMinat');
  }

  /// Mengambil label yang lebih mudah dibaca dari key minat
  String getReadableMinatLabel(String minatKey) {
    final parts = minatKey.split('|');
    if (parts.length != 2) return minatKey;

    String program = parts[0].trim();
    String minat = parts[1].trim();

    // Hapus prefix IPA jika ada
    if (program.startsWith('IPA')) {
      program = program.replaceFirst('IPA', '').trim();
      if (program.startsWith('(') && program.endsWith(')')) {
        program = program.substring(1, program.length - 1).trim();
      }
    }

    return "$program - $minat";
  }

  /// Mengolah key minat dari label yang dibaca
  String getMinatKeyFromLabel(String label, List<String> availableKeys) {
    // Cari key yang cocok dengan label
    for (var key in availableKeys) {
      if (getReadableMinatLabel(key) == label) {
        return key;
      }
    }
    return label; // Fallback jika tidak ditemukan
  }

  /// Menyimpan feedback dan menampilkan hasil rekomendasi
  Future<void> _submitFeedbackAndContinue() async {
    if (_formKey.currentState?.validate() != true) {
      // Tampilkan feedback visual untuk form yang belum lengkap
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar(
          'Error',
          'Anda perlu login untuk melanjutkan',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return;
      }

      // Dapatkan school_id dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? schoolId = prefs.getString('school_id');

      // Jika tidak ada, coba cari
      if (schoolId == null || schoolId.isEmpty) {
        schoolId = await _findStudentSchoolId(user.uid);
        if (schoolId != null) {
          await prefs.setString('school_id', schoolId);
        }
      }

      // Buat dokumen feedback untuk analisis akurasi
      final feedbackData = {
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName,
        'schoolId': schoolId,
        'timestamp': FieldValue.serverTimestamp(),
        'majorType': widget.majorType,
        'isKerja': widget.isKerja,
        'selectedMinat': selectedMinat,
        'confidenceLevel': confidenceLevel,
        'comment': commentController.text,

        // Data untuk evaluasi akurasi
        'systemRecommendations': widget.recommendationResults.recommendations
            .map((r) => r.title)
            .toList(),
        'topRecommendation':
            widget.recommendationResults.recommendations.isNotEmpty
                ? widget.recommendationResults.recommendations[0].title
                : null,
        'secondRecommendation':
            widget.recommendationResults.recommendations.length > 1
                ? widget.recommendationResults.recommendations[1].title
                : null,
        'thirdRecommendation':
            widget.recommendationResults.recommendations.length > 2
                ? widget.recommendationResults.recommendations[2].title
                : null,

        // Evaluation metrics yang akan dihitung
        'isCorrectTopPrediction': selectedMinat ==
            (widget.recommendationResults.recommendations.isNotEmpty
                ? widget.recommendationResults.recommendations[0].title
                : null),
        'isInTop3Predictions': widget.recommendationResults.recommendations
            .any((r) => r.title == selectedMinat),

        // Likert scale ratings untuk berbagai aspek
        'confidenceRating': confidenceLevel,
        'likertRatings': likertRatings,
      };

      // Simpan ke Firestore dalam koleksi terpisah untuk evaluasi
      String docId = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

      if (schoolId != null && schoolId.isNotEmpty) {
        // Simpan di bawah sekolah jika schoolId ada
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('accuracy_evaluations')
            .doc(docId)
            .set(feedbackData);
      } else {
        // Simpan di koleksi global jika tidak ada schoolId
        await FirebaseFirestore.instance
            .collection('accuracy_evaluations')
            .doc(docId)
            .set(feedbackData);
      }

      Get.snackbar(
        'Berhasil',
        'Terima kasih atas feedback Anda',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );

      // Tampilkan hasil rekomendasi
      showRecommendationResultsGetx(widget.recommendationResults);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyimpan feedback: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  /// Helper function untuk mencari schoolId berdasarkan userId
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
      print('Error finding school ID: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.indigo.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Evaluasi Sistem',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        widget.isKerja ? 'Karir' : 'Kuliah',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ikon dan judul
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.psychology_outlined,
                                    size: 24,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Bantu Kami Evaluasi Sistem',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Jawablah sesuai dengan pendapat Anda',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),

                            // Pertanyaan 1: Bidang Minat
                            Text(
                              'Menurut Anda, bidang minat apa yang paling sesuai dengan diri Anda?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pilih salah satu bidang minat yang menurut Anda paling mencerminkan diri Anda',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Daftar Minat
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: selectedMinat,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Silakan pilih bidang minat';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: InputBorder.none,
                                  hintText: 'Pilih Bidang Minat',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                icon: Icon(
                                  Icons.arrow_drop_down_circle,
                                  color: Colors.blue.shade700,
                                ),
                                isExpanded:
                                    true, // Pastikan dropdown bisa melebar penuh
                                menuMaxHeight:
                                    300, // Tinggi maksimum menu dropdown
                                dropdownColor:
                                    Colors.white, // Warna background dropdown
                                items: availableMinat
                                    .map((minat) => DropdownMenuItem<String>(
                                          value: minat,
                                          child: Text(
                                            getReadableMinatLabel(minat),
                                            style: const TextStyle(
                                              fontSize: 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedMinat = value;
                                    });
                                  }
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Pertanyaan 2: Tingkat Keyakinan (Skala Likert)
                            Text(
                              'Seberapa yakin Anda dengan pilihan tersebut?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Skala Likert untuk tingkat keyakinan
                            buildConfidenceLevelOptions(),

                            const SizedBox(height: 30),

                            // Penilaian Tambahan dengan Skala Likert
                            Text(
                              'Berikan Penilaian Sistem',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Berikan penilaian untuk aspek-aspek berikut',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Likert scales untuk berbagai aspek
                            ...likertLabels.entries.map((entry) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  buildLikertScale(entry.key),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }).toList(),

                            const SizedBox(height: 10),

                            // Pertanyaan 3: Komentar Tambahan
                            Text(
                              'Ada komentar tambahan? (Opsional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Text area untuk komentar
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: TextFormField(
                                controller: commentController,
                                decoration: InputDecoration(
                                  hintText: 'Tulis komentar Anda di sini...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: InputBorder.none,
                                ),
                                maxLines: 3,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Tombol Submit
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.blue.shade300.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _submitFeedbackAndContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isSubmitting
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Menyimpan...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Lihat Hasil Rekomendasi',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward,
                                              size: 20),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Skip button (with warning)
                            TextButton(
                              onPressed: () {
                                // Show confirmation dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Lewati Evaluasi?'),
                                    content: const Text(
                                        'Feedback Anda sangat penting untuk meningkatkan akurasi sistem. Yakin ingin melewati tahap ini?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('KEMBALI'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          showRecommendationResultsGetx(
                                              widget.recommendationResults);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade600,
                                        ),
                                        child: const Text('YA, LEWATI'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                minimumSize: const Size(double.infinity, 44),
                              ),
                              child: const Text(
                                'Lewati Evaluasi',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget untuk skala Likert (multiple scales)
  Widget buildLikertScale(String key) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (index) {
          final value = (index + 1).toString();
          final isSelected = likertRatings[key] == value;

          return InkWell(
            onTap: () {
              setState(() {
                likertRatings[key] = value;
              });
              HapticFeedback.selectionClick();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? getConfidenceColor(value)
                    : Colors.grey.shade200,
                border: Border.all(
                  color: isSelected
                      ? getConfidenceColor(value).withOpacity(0.8)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Widget untuk skala Likert tingkat keyakinan
  Widget buildConfidenceLevelOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skala 1-5:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Sangat Tidak Yakin',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Sangat Yakin',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildLikertOption('1', '1'),
              buildLikertOption('2', '2'),
              buildLikertOption('3', '3'),
              buildLikertOption('4', '4'),
              buildLikertOption('5', '5'),
            ],
          ),
        ),
        // Keterangan skala
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            return SizedBox(
              width: 50,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: index == 0
                    ? TextAlign.left
                    : (index == 4 ? TextAlign.right : TextAlign.center),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        // Deskripsi Skala
        buildLikertDescription(),
      ],
    );
  }

  /// Widget untuk tiap opsi skala Likert
  Widget buildLikertOption(String value, String label) {
    final isSelected = confidenceLevel == value;

    return InkWell(
      onTap: () {
        setState(() {
          confidenceLevel = value;
        });
        // Tambahkan haptic feedback untuk respon sentuhan
        HapticFeedback.selectionClick();
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? getConfidenceColor(value) : Colors.grey.shade200,
          border: Border.all(
            color: isSelected
                ? getConfidenceColor(value).withOpacity(0.8)
                : Colors.grey.shade400,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: getConfidenceColor(value).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  /// Mendapatkan warna berdasarkan level keyakinan
  Color getConfidenceColor(String value) {
    switch (value) {
      case '1':
        return Colors.red.shade600;
      case '2':
        return Colors.orange.shade600;
      case '3':
        return Colors.amber.shade600;
      case '4':
        return Colors.lightGreen.shade600;
      case '5':
        return Colors.green.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  /// Deskripsi untuk setiap skala Likert
  Widget buildLikertDescription() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keterangan Skala:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          buildLikertDescriptionItem(
              '1', 'Sangat Tidak Yakin', Colors.red.shade600),
          buildLikertDescriptionItem(
              '2', 'Tidak Yakin', Colors.orange.shade600),
          buildLikertDescriptionItem('3', 'Netral', Colors.amber.shade600),
          buildLikertDescriptionItem('4', 'Yakin', Colors.lightGreen.shade600),
          buildLikertDescriptionItem(
              '5', 'Sangat Yakin', Colors.green.shade600),
        ],
      ),
    );
  }

  /// Item deskripsi untuk setiap skala
  Widget buildLikertDescriptionItem(
      String scale, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Center(
              child: Text(
                scale,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// Tambahkan juga modifikasi di QuestionPage untuk mengarahkan ke FeedbackEvaluationPage

/// Helper function untuk menampilkan FeedbackEvaluationPage dari QuestionPage
/// Tambahkan ini ke QuestionPage atau buatkan extension
void showFeedbackEvaluationPage(
    RecommendationResult results, bool isKerja, String majorType) {
  Get.to(() => FeedbackEvaluationPage(
        recommendationResults: results,
        isKerja: isKerja,
        majorType: majorType,
      ));
}

/// Modifikasi fungsi di QuestionPage untuk menggunakan FeedbackEvaluationPage
///
/// // Di QuestionPage, ganti 
/// final results = controller.runForwardChaining();
/// controller.saveResultsToFirestore(results).then((_) {
///   showRecommendationResultsGetx(results);
/// });
///
/// // Menjadi
/// final results = controller.runForwardChaining();
/// controller.saveResultsToFirestore(results).then((_) {
///   showFeedbackEvaluationPage(results, controller.isKerja, controller.majorType);
/// });