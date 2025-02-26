import 'package:flutter/material.dart';
import 'package:forward_chaining_man_app/app/views/page_intro.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class TeacherDashboardController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = true.obs;
  var teacherName = ''.obs;
  var studentResults = <DocumentSnapshot>[].obs;
  var filteredResults = <DocumentSnapshot>[].obs;
  var selectedFilter = 'all'.obs;
  var stats = {
    'totalStudents': 0,
    'careerRecommendations': 0,
    'studyRecommendations': 0,
  }.obs;

  @override
  void onInit() {
    super.onInit();
    loadTeacherData();
    loadStudentResults();
  }

  Future<void> loadTeacherData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final teacherDoc =
            await _firestore.collection('teachers').doc(currentUser.uid).get();
        if (teacherDoc.exists) {
          teacherName.value = teacherDoc.data()?['name'] ?? 'Guru';
        }
      }
    } catch (e) {
      print('Error loading teacher data: $e');
    }
  }

  Future<void> loadStudentResults() async {
    try {
      isLoading.value = true;

      final QuerySnapshot querySnapshot = await _firestore
          .collection('recommendation_history')
          .orderBy('timestamp', descending: true)
          .get();

      studentResults.value = querySnapshot.docs;
      filterResults(selectedFilter.value);

      // Update stats
      stats['totalStudents'] = querySnapshot.docs.length;
      stats['careerRecommendations'] =
          querySnapshot.docs.where((doc) => doc['isKerja'] == true).length;
      stats['studyRecommendations'] =
          querySnapshot.docs.where((doc) => doc['isKerja'] == false).length;
    } catch (e) {
      print('Error loading student results: $e');
      Get.snackbar(
        'Error',
        'Gagal memuat data siswa: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void filterResults(String filter) {
    selectedFilter.value = filter;

    switch (filter) {
      case 'career':
        filteredResults.value =
            studentResults.where((doc) => doc['isKerja'] == true).toList();
        break;
      case 'study':
        filteredResults.value =
            studentResults.where((doc) => doc['isKerja'] == false).toList();
        break;
      case 'all':
      default:
        filteredResults.value = studentResults;
        break;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Navigate to login selection page
      Get.off(IntroPage());
    } catch (e) {
      print('Error signing out: $e');
      Get.snackbar(
        'Error',
        'Gagal keluar: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Waktu tidak tersedia';

    if (timestamp is Timestamp) {
      final DateTime dateTime = timestamp.toDate();
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    } else if (timestamp is String) {
      try {
        final DateTime dateTime = DateTime.parse(timestamp);
        return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
      } catch (e) {
        return timestamp;
      }
    }

    return 'Format waktu tidak valid';
  }

  void viewStudentDetail(DocumentSnapshot doc) {
    Get.to(() => StudentResultDetailPage(document: doc));
  }

  List<PieChartSectionData> getPieChartData() {
    return [
      PieChartSectionData(
        value: stats['careerRecommendations']!.toDouble(),
        title: 'Karir',
        color: Colors.deepPurple.shade700,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: stats['studyRecommendations']!.toDouble(),
        title: 'Kuliah',
        color: Colors.indigo.shade900,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }
}

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TeacherDashboardController());
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade800,
              Colors.indigo.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(controller),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: Obx(() => controller.isLoading.value
                        ? _buildLoadingView()
                        : _buildDashboardContent(controller, theme)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(TeacherDashboardController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.psychology,
              size: 30,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Forward Chaining',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Obx(() => Text(
                      'Selamat datang, ${controller.teacherName.value}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    )),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                // Refresh data
                controller.loadStudentResults();
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh Data',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                // Show sign out confirmation
                Get.dialog(
                  AlertDialog(
                    title: const Text('Konfirmasi'),
                    content: const Text('Apakah Anda yakin ingin keluar?'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          'Batal',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Get.back();
                          controller.signOut();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                        ),
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Keluar',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat data...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(
      TeacherDashboardController controller, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: controller.loadStudentResults,
      color: Colors.blue.shade700,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatisticsCards(controller),
          const SizedBox(height: 24),
          _buildFilterButtons(controller),
          const SizedBox(height: 24),
          _buildStudentList(controller),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(TeacherDashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, size: 20, color: Colors.blue.shade800),
            const SizedBox(width: 8),
            Text(
              'Statistik Hasil Kuisioner',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                height: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pie_chart,
                            size: 16, color: Colors.blue.shade800),
                        const SizedBox(width: 6),
                        Text(
                          'Distribusi Jenis Rekomendasi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Obx(() => controller.stats['totalStudents'] == 0
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bar_chart_outlined,
                                    size: 48,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Belum ada data',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : PieChart(
                              PieChartData(
                                sections: controller.getPieChartData(),
                                centerSpaceRadius: 40,
                                sectionsSpace: 2,
                              ),
                            )),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildStatCard(
                    title: 'Total Siswa',
                    value: controller.stats['totalStudents'].toString(),
                    icon: Icons.people,
                    color: Colors.blue.shade800,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    title: 'Rekomendasi Karir',
                    value: controller.stats['careerRecommendations'].toString(),
                    icon: Icons.work,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    title: 'Rekomendasi Kuliah',
                    value: controller.stats['studyRecommendations'].toString(),
                    icon: Icons.school,
                    color: Colors.indigo.shade800,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons(TeacherDashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.filter_list, size: 20, color: Colors.blue.shade800),
            const SizedBox(width: 8),
            Text(
              'Daftar Hasil Kuisioner Siswa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildFilterButton(
              label: 'Semua',
              value: 'all',
              controller: controller,
              icon: Icons.list_alt,
            ),
            const SizedBox(width: 12),
            _buildFilterButton(
              label: 'Karir',
              value: 'career',
              controller: controller,
              icon: Icons.work,
            ),
            const SizedBox(width: 12),
            _buildFilterButton(
              label: 'Kuliah',
              value: 'study',
              controller: controller,
              icon: Icons.school,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterButton({
    required String label,
    required String value,
    required TeacherDashboardController controller,
    required IconData icon,
  }) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == value;

      return Expanded(
        child: ElevatedButton(
          onPressed: () => controller.filterResults(value),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue.shade700 : Colors.white,
            foregroundColor: isSelected ? Colors.white : Colors.blue.shade700,
            elevation: isSelected ? 4 : 1,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                color: isSelected ? Colors.transparent : Colors.blue.shade200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStudentList(TeacherDashboardController controller) {
    return Obx(() {
      if (controller.filteredResults.isEmpty) {
        return Container(
          height: 200,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada data hasil kuisioner',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.filteredResults.length,
        itemBuilder: (context, index) {
          final doc = controller.filteredResults[index];
          final data = doc.data() as Map<String, dynamic>;
          final isKerja = data['isKerja'] ?? false;
          final recommendations =
              List<Map<String, dynamic>>.from(data['recommendations'] ?? []);

          // Get top recommendation
          String topRecommendation = 'Tidak ada';
          if (recommendations.isNotEmpty) {
            topRecommendation = recommendations[0]['title'] ?? 'Tidak ada';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              onTap: () => controller.viewStudentDetail(doc),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isKerja
                                ? Colors.blue.shade50
                                : Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isKerja ? Icons.work : Icons.school,
                            color: isKerja
                                ? Colors.blue.shade400
                                : Colors.indigo.shade400,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['userName'] ??
                                    data['userEmail'] ??
                                    'Siswa',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                controller.formatTimestamp(data['timestamp']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isKerja
                                ? Colors.blue.shade100
                                : Colors.indigo.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isKerja ? 'Karir' : 'Kuliah',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isKerja
                                  ? Colors.blue.shade700
                                  : Colors.indigo.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rekomendasi Utama',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                topRecommendation,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () => controller.viewStudentDetail(doc),
                            icon: const Icon(Icons.visibility),
                            color: Colors.blue.shade700,
                            tooltip: 'Lihat Detail',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class StudentResultDetailPage extends StatelessWidget {
  final DocumentSnapshot document;

  const StudentResultDetailPage({
    Key? key,
    required this.document,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = document.data() as Map<String, dynamic>;
    final isKerja = data['isKerja'] ?? false;
    final userName = data['userName'] ?? data['userEmail'] ?? 'Siswa';
    final recommendations =
        List<Map<String, dynamic>>.from(data['recommendations'] ?? []);
    final userAnswers =
        List<Map<String, dynamic>>.from(data['userAnswers'] ?? []);
    Map<String, dynamic> workingMemory = {};
    if (data['workingMemory'] != null) {
      if (data['workingMemory'] is Map) {
        workingMemory = Map<String, dynamic>.from(data['workingMemory']);
      } else if (data['workingMemory'] is List) {
        // Convert list to map with indices as keys
        final list = List.from(data['workingMemory']);
        for (int i = 0; i < list.length; i++) {
          workingMemory['item_$i'] = list[i];
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Hasil $userName'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade800,
                Colors.indigo.shade900,
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Implementation for sharing functionality
              Get.snackbar(
                'Info',
                'Fitur berbagi hasil sedang dalam pengembangan',
                backgroundColor: Colors.deepPurple.shade50,
                colorText: Colors.deepPurple.shade700,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStudentInfoCard(data),
            const SizedBox(height: 24),
            _buildRecommendationsSection(recommendations, isKerja),
            const SizedBox(height: 24),
            _buildUserAnswersSection(userAnswers),
            const SizedBox(height: 24),
            _buildWorkingMemorySection(workingMemory),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingMemorySection(Map<String, dynamic> workingMemory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.memory,
              color: Colors.deepPurple.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Working Memory',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Data memori kerja yang digunakan saat proses inferensi',
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        workingMemory.isEmpty
            ? _buildEmptyWorkingMemory()
            : Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Variabel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Nilai',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      ...workingMemory.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: entry.value is bool &&
                                            entry.value == true
                                        ? Colors.green.shade50
                                        : entry.value is bool &&
                                                entry.value == false
                                            ? Colors.red.shade50
                                            : Colors.deepPurple.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    entry.value.toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: entry.value is bool &&
                                              entry.value == true
                                          ? Colors.green.shade700
                                          : entry.value is bool &&
                                                  entry.value == false
                                              ? Colors.red.shade700
                                              : Colors.deepPurple.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyWorkingMemory() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.memory_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Working memory tidak tersedia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAnswersSection(List<Map<String, dynamic>> userAnswers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.question_answer,
              color: Colors.deepPurple.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Jawaban Siswa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        userAnswers.isEmpty
            ? _buildEmptyAnswers()
            : Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (int i = 0; i < userAnswers.length; i++)
                        _buildAnswerItem(userAnswers[i], i),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyAnswers() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.question_mark,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada jawaban yang tersedia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerItem(Map<String, dynamic> answer, int index) {
    final questionText = answer['question'] ?? 'Pertanyaan tidak tersedia';
    final userAnswer = answer['answer'] ?? 'Tidak dijawab';
    final programName = answer['programName'] ?? '';
    final bobot = answer['bobot']?.toString() ?? '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) const Divider(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.deepPurple.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    questionText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: userAnswer == 'Ya'
                                ? Colors.green.shade50
                                : userAnswer == 'Tidak'
                                    ? Colors.red.shade50
                                    : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: userAnswer == 'Ya'
                                  ? Colors.green.shade200
                                  : userAnswer == 'Tidak'
                                      ? Colors.red.shade200
                                      : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            'Jawaban: $userAnswer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: userAnswer == 'Ya'
                                  ? Colors.green.shade700
                                  : userAnswer == 'Tidak'
                                      ? Colors.red.shade700
                                      : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      if (programName.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            programName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                        ),
                      ],
                      if (bobot != '0') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Bobot: $bobot',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStudentInfoCard(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] is Timestamp
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(timestamp);
    final isKerja = data['isKerja'] ?? false;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade50,
                  radius: 24,
                  child: Icon(
                    Icons.person,
                    color: Colors.deepPurple.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userName'] ?? 'Siswa',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        data['userEmail'] ?? '',
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
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Tanggal',
                  value: formattedDate,
                ),
                _buildInfoItem(
                  icon: isKerja ? Icons.work : Icons.school,
                  label: 'Jenis Rekomendasi',
                  value: isKerja ? 'Karir' : 'Kuliah',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem(
                  icon: Icons.question_answer,
                  label: 'Total Pertanyaan',
                  value: data['totalQuestions']?.toString() ?? '0',
                ),
                _buildInfoItem(
                  icon: Icons.check_circle,
                  label: 'Pertanyaan Dijawab',
                  value: data['answeredQuestions']?.toString() ?? '0',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.deepPurple.shade400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(
    List<Map<String, dynamic>> recommendations,
    bool isKerja,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isKerja ? Icons.work : Icons.school,
              color: Colors.deepPurple.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Hasil Rekomendasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        recommendations.isEmpty
            ? _buildEmptyRecommendations()
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final recommendation = recommendations[index];
                  final score = recommendation['score']?.toString() ?? '0';
                  final careers =
                      List<String>.from(recommendation['careers'] ?? []);
                  final majors =
                      List<String>.from(recommendation['majors'] ?? []);
                  final rules =
                      List<String>.from(recommendation['rules'] ?? []);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.deepPurple.shade50,
                                radius: 20,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.deepPurple.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recommendation['title'] ?? 'Tanpa judul',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Skor: $score%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          if (isKerja && careers.isNotEmpty) ...[
                            _buildSectionTitle('Karir yang Direkomendasikan'),
                            const SizedBox(height: 8),
                            _buildChipList(careers),
                            const SizedBox(height: 16),
                          ],
                          if (!isKerja && majors.isNotEmpty) ...[
                            _buildSectionTitle('Jurusan yang Direkomendasikan'),
                            const SizedBox(height: 8),
                            _buildChipList(majors),
                            const SizedBox(height: 16),
                          ],
                          if (rules.isNotEmpty) ...[
                            _buildSectionTitle('Aturan yang Terpenuhi'),
                            const SizedBox(height: 8),
                            _buildRulesList(rules),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildEmptyRecommendations() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada rekomendasi yang tersedia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple.shade700,
      ),
    );
  }

  Widget _buildChipList(List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Chip(
          label: Text(
            item,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.deepPurple.shade50,
          labelStyle: TextStyle(color: Colors.deepPurple.shade700),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  Widget _buildRulesList(List<String> rules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rules.map((rule) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rule,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
