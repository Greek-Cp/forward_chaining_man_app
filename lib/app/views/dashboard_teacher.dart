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
                        child: const Text('Keluar',
                            style: TextStyle(color: Colors.white)),
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
        // Header dengan padding yang konsisten
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              Icon(Icons.analytics, size: 18, color: Colors.blue.shade800),
              const SizedBox(width: 8),
              Text(
                'Statistik Hasil Kuisioner',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Row untuk Chart dan Stat Cards
        LayoutBuilder(
          builder: (context, constraints) {
            // Tentukan ukuran chart optimal berdasarkan lebar yang tersedia
            final isWideScreen = constraints.maxWidth > 600;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chart Container - flex yang lebih besar pada layar lebar
                Expanded(
                  flex: isWideScreen ? 3 : 2,
                  child: Container(
                    height: 210, // Sedikit ditambah untuk menampung legend
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chart title
                        Row(
                          children: [
                            Icon(Icons.pie_chart,
                                size: 14, color: Colors.blue.shade800),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Distribusi Jenis Rekomendasi',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Chart area
                        Expanded(
                          child: Obx(() {
                            final hasData =
                                controller.stats['totalStudents']! > 0;

                            return hasData
                                ? PieChartWidget(controller: controller)
                                : const EmptyChartMessage();
                          }),
                        ),

                        // Legend - hanya ditampilkan jika ada data
                        Obx(() {
                          final hasData =
                              controller.stats['totalStudents']! > 0;

                          return hasData
                              ? Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8, bottom: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildLegendItem(
                                          'Karir', Colors.blue.shade700),
                                      const SizedBox(width: 16),
                                      _buildLegendItem(
                                          'Kuliah', Colors.indigo.shade800),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Stat Cards Container
                Expanded(
                  flex:
                      isWideScreen ? 2 : 3, // Sesuaikan flex berdasarkan layar
                  child: Container(
                    height:
                        210, // Tinggi yang sama dengan chart untuk konsistensi
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Stat card untuk Total Siswa
                        Expanded(
                          child: _buildStatCard(
                            title: 'Total Siswa',
                            value: controller.stats['totalStudents'].toString(),
                            icon: Icons.people,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Stat card untuk Rekomendasi Karir
                        Expanded(
                          child: _buildStatCard(
                            title: 'Rekomendasi Karir',
                            value: controller.stats['careerRecommendations']
                                .toString(),
                            icon: Icons.work,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Stat card untuk Rekomendasi Kuliah
                        Expanded(
                          child: _buildStatCard(
                            title: 'Rekomendasi Kuliah',
                            value: controller.stats['studyRecommendations']
                                .toString(),
                            icon: Icons.school,
                            color: Colors.indigo.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
          ),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class PieChartWidget extends StatelessWidget {
  final TeacherDashboardController controller;

  const PieChartWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Hitung ukuran chart berdasarkan constraints
        final size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;

        return Center(
          child: SizedBox(
            width: size * 0.9, // Sedikit lebih kecil dari ruang yang tersedia
            height: size * 0.9,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: size * 0.15,
                sectionsSpace: 1,
                borderData: FlBorderData(show: false),
                centerSpaceColor: Colors.transparent,
                sections: controller.getPieChartData().map((section) {
                  return section.copyWith(
                    radius: size * 0.35,
                    showTitle: false,
                    titlePositionPercentageOffset: 0,
                  );
                }).toList(),
              ),
              swapAnimationDuration: const Duration(milliseconds: 800),
            ),
          ),
        );
      },
    );
  }
}

// Widget untuk menampilkan pesan saat tidak ada data
class EmptyChartMessage extends StatelessWidget {
  const EmptyChartMessage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 36,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 4),
          Text(
            'Belum ada data',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget untuk item legenda yang disederhanakan dan konsisten
Widget _buildLegendItem(String label, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
    ],
  );
}

class StudentResultDetailPage extends StatefulWidget {
  final DocumentSnapshot document;

  const StudentResultDetailPage({
    Key? key,
    required this.document,
  }) : super(key: key);

  @override
  State<StudentResultDetailPage> createState() =>
      _StudentResultDetailPageState();
}

class _StudentResultDetailPageState extends State<StudentResultDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey _headerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Delay to allow build to complete before animations start
    Future.delayed(Duration.zero, () {
      _startInitialAnimations();
    });
  }

  void _startInitialAnimations() {
    // Animation logic for initial page load
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.document.data() as Map<String, dynamic>;
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              expandedHeight: 180.0,
              backgroundColor: Colors.blue.shade800,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    Get.snackbar(
                      'Info',
                      'Fitur berbagi hasil sedang dalam pengembangan',
                      backgroundColor: Colors.blue.shade50,
                      colorText: Colors.blue.shade700,
                      snackPosition: SnackPosition.BOTTOM,
                      animationDuration: const Duration(milliseconds: 800),
                      duration: const Duration(seconds: 3),
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Detail Hasil $userName',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
                background: Hero(
                  tag: 'student_header_${widget.document.id}',
                  child: Container(
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
                    child: Stack(
                      children: [
                        Positioned(
                          right: -50,
                          bottom: -50,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: 0.2 * value,
                                child: Transform.scale(
                                  scale: value,
                                  child: Icon(
                                    isKerja ? Icons.work : Icons.school,
                                    size: 200,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 70,
                          left: 20,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(-20 * (1 - value), 0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            Colors.white.withOpacity(0.9),
                                        radius: 30,
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.blue.shade700,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['userName'] ?? 'Siswa',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          Text(
                                            data['userEmail'] ?? '',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(icon: Icon(Icons.person), text: 'Profil'),
                    Tab(icon: Icon(Icons.recommend), text: 'Rekomendasi'),
                    Tab(icon: Icon(Icons.question_answer), text: 'Jawaban'),
                    Tab(icon: Icon(Icons.memory), text: 'Working Memory'),
                  ],
                  labelColor: Colors.blue.shade700,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: Colors.blue.shade700,
                  indicatorWeight: 3,
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade50,
                Colors.blue.shade50,
              ],
              stops: const [0.7, 1.0],
            ),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(data),
              _buildRecommendationsTab(recommendations, isKerja),
              _buildAnswersTab(userAnswers),
              _buildWorkingMemoryTab(workingMemory),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] is Timestamp
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(timestamp);
    final isKerja = data['isKerja'] ?? false;
    final answeredQuestions = data['answeredQuestions'] ?? 0;
    final totalQuestions = data['totalQuestions'] ?? 0;
    final completionPercentage = totalQuestions > 0
        ? (answeredQuestions / totalQuestions * 100).round()
        : 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Informasi Siswa', Icons.info),
          const SizedBox(height: 12),
          _buildStudentInfoCard(data),
          const SizedBox(height: 24),
          _buildSectionHeader('Progres Pengerjaan', Icons.insights),
          const SizedBox(height: 12),
          _buildProgressCard(
              completionPercentage, answeredQuestions, totalQuestions),
          const SizedBox(height: 24),
          _buildSectionHeader('Statistik', Icons.bar_chart),
          const SizedBox(height: 12),
          _buildStatisticsCard(data),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int percentage, int answered, int total) {
    return Card(
      elevation: 4,
      shadowColor: Colors.blue.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: percentage / 100),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 120,
                          width: 120,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.shade500,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${(value * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            Text(
                              'Selesai',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProgressStat(
                          'Terjawab',
                          answered.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                        _buildProgressStat(
                          'Total',
                          total.toString(),
                          Icons.assignment,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(
      String label, String value, IconData icon, MaterialColor color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color.shade400,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(Map<String, dynamic> data) {
    // Sample data for demonstration
    final recommendations =
        List<Map<String, dynamic>>.from(data['recommendations'] ?? []);
    final scores =
        recommendations.map((r) => (r['score'] ?? 0) as num).toList();

    return Card(
      elevation: 4,
      shadowColor: Colors.blue.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribusi Skor Rekomendasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: scores.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada data rekomendasi',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final index = value.toInt();
                                if (index >= 0 &&
                                    index < recommendations.length) {
                                  return Text(
                                    'R${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                              reservedSize: 22,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                if (value == 0 || value == 50 || value == 100) {
                                  return Text(
                                    '${value.toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                              interval: 25,
                              reservedSize: 30,
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        barGroups: scores.asMap().entries.map((entry) {
                          final index = entry.key;
                          final value = entry.value;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: value.toDouble(),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade300,
                                    Colors.blue.shade700
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                width: 20,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade200,
                              strokeWidth: 1,
                            );
                          },
                        ),
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 800),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] is Timestamp
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(timestamp);
    final isKerja = data['isKerja'] ?? false;

    return Card(
      elevation: 4,
      shadowColor: Colors.blue.shade100,
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
                  backgroundColor: Colors.blue.shade50,
                  radius: 24,
                  child: Icon(
                    Icons.person,
                    color: Colors.blue.shade700,
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

  Widget _buildRecommendationsTab(
      List<Map<String, dynamic>> recommendations, bool isKerja) {
    return recommendations.isEmpty
        ? _buildEmptyCenteredMessage(
            'Tidak ada rekomendasi yang tersedia',
            Icons.search_off,
          )
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: recommendations.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Hasil Rekomendasi',
                      isKerja ? Icons.work : Icons.school,
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }

              final recommendationIndex = index - 1;
              final recommendation = recommendations[recommendationIndex];
              return _buildRecommendationCard(
                  recommendation, recommendationIndex, isKerja);
            },
          );
  }

  Widget _buildRecommendationCard(
      Map<String, dynamic> recommendation, int index, bool isKerja) {
    final score = recommendation['score']?.toString() ?? '0';
    final careers = List<String>.from(recommendation['careers'] ?? []);
    final majors = List<String>.from(recommendation['majors'] ?? []);
    final rules = List<String>.from(recommendation['rules'] ?? []);
    final title = recommendation['title'] ?? 'Rekomendasi ${index + 1}';

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              shadowColor: Colors.blue.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ExpansionTile(
                initiallyExpanded: index == 0, // First one expanded by default
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                leading: Hero(
                  tag: 'recommendation_$index',
                  child: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    radius: 20,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                          begin: 0.0, end: double.parse(score) / 100),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, value, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Skor: ${(value * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                value < 0.3
                                    ? Colors.red.shade400
                                    : value < 0.7
                                        ? Colors.orange.shade400
                                        : Colors.green.shade400,
                              ),
                              minHeight: 5,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                children: [
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
          ),
        );
      },
    );
  }

  Widget _buildAnswersTab(List<Map<String, dynamic>> userAnswers) {
    return userAnswers.isEmpty
        ? _buildEmptyCenteredMessage(
            'Tidak ada jawaban yang tersedia',
            Icons.question_mark,
          )
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: userAnswers.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Jawaban Siswa', Icons.question_answer),
                    const SizedBox(height: 16),
                  ],
                );
              }

              final answerIndex = index - 1;
              return _buildAnswerCard(userAnswers[answerIndex], answerIndex);
            },
          );
  }

  Widget _buildAnswerCard(Map<String, dynamic> answer, int index) {
    final questionText = answer['question'] ?? 'Pertanyaan tidak tersedia';
    final userAnswer = answer['answer'] ?? 'Tidak dijawab';
    final programName = answer['programName'] ?? '';
    final bobot = answer['bobot']?.toString() ?? '0';

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 3,
              shadowColor: Colors.blue.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
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
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
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
                            ],
                          ),
                          if (programName.isNotEmpty || bobot != '0') ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (programName.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      programName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                if (bobot != '0')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
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
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkingMemoryTab(Map<String, dynamic> workingMemory) {
    return workingMemory.isEmpty
        ? _buildEmptyCenteredMessage(
            'Working memory tidak tersedia',
            Icons.memory_outlined,
          )
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: workingMemory.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Working Memory',
                      Icons.memory,
                      tooltip:
                          'Data memori kerja yang digunakan saat proses inferensi',
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Variabel',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
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
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }

              final memoryIndex = index - 1;
              final entry = workingMemory.entries.elementAt(memoryIndex);
              return _buildWorkingMemoryItem(
                  entry.key, entry.value, memoryIndex);
            },
          );
  }

  Widget _buildWorkingMemoryItem(String key, dynamic value, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animValue)),
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 2,
              shadowColor: Colors.blue.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        key,
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
                          color: value is bool && value == true
                              ? Colors.green.shade50
                              : value is bool && value == false
                                  ? Colors.red.shade50
                                  : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          value.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: value is bool && value == true
                                ? Colors.green.shade700
                                : value is bool && value == false
                                    ? Colors.red.shade700
                                    : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCenteredMessage(String message, IconData icon) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Container(
                width: 250,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
            color: Colors.blue.shade400,
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

  Widget _buildSectionHeader(String title, IconData icon, {String? tooltip}) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.blue.shade700,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        if (tooltip != null) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: tooltip,
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade700,
      ),
    );
  }

  Widget _buildChipList(List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Chip(
                  label: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(color: Colors.blue.shade700),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  elevation: 1,
                  shadowColor: Colors.blue.shade100,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildRulesList(List<String> rules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rules.asMap().entries.map((entry) {
        final index = entry.key;
        final rule = entry.value;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(20 * (1 - value), 0),
                child: Padding(
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
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
