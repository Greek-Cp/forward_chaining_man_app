import 'package:flutter/material.dart';
import 'package:forward_chaining_man_app/app/views/dashboard_teacher.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class StudentDashboardPage extends StatelessWidget {
  final TeacherDashboardController controller =
      Get.put(TeacherDashboardController());

  StudentDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Siswa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadStudentResults(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatisticCards(),
              const SizedBox(height: 24),
              _buildCharts(),
              const SizedBox(height: 24),
              _buildFilters(),
              const SizedBox(height: 16),
              _buildStudentList(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatisticCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Siswa',
            controller.stats['totalStudents'].toString(),
            Colors.blue,
            Icons.people,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Rekomendasi Karir',
            controller.stats['careerRecommendations'].toString(),
            Colors.orange,
            Icons.work,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Rekomendasi Studi',
            controller.stats['studyRecommendations'].toString(),
            Colors.green,
            Icons.school,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visualisasi Data',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distribusi Rekomendasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: _buildPieChart(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tren Rekomendasi (Per Hari)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: _buildLineChart(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    final career = controller.stats['careerRecommendations']?.toDouble() ?? 0;
    final study = controller.stats['studyRecommendations']?.toDouble() ?? 0;

    // If no data, show a placeholder
    if (career == 0 && study == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Tidak ada data untuk ditampilkan',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: career,
            title: 'Karir\n${career.toInt()}',
            color: Colors.orange,
            radius: 70,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            titlePositionPercentageOffset: 0.55,
          ),
          PieChartSectionData(
            value: study,
            title: 'Studi\n${study.toInt()}',
            color: Colors.green,
            radius: 70,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            titlePositionPercentageOffset: 0.55,
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        startDegreeOffset: 180,
      ),
    );
  }

  Widget _buildLineChart() {
    // Group data by day for the chart
    Map<String, int> dailyData = {};

    for (var doc in controller.filteredResults) {
      final data = doc.data() as Map;
      if (data['timestamp'] != null) {
        final timestamp = data['timestamp'] as Timestamp;
        final date = timestamp.toDate();
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        if (dailyData.containsKey(dateStr)) {
          dailyData[dateStr] = dailyData[dateStr]! + 1;
        } else {
          dailyData[dateStr] = 1;
        }
      }
    }

    // Sort by date
    final sortedDates = dailyData.keys.toList()..sort();

    // Create spots for the chart
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyData[sortedDates[i]]!.toDouble()));
    }

    // If no data, show a placeholder
    if (spots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Tidak ada data untuk ditampilkan',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedDates.length) {
                  final date = DateTime.parse(sortedDates[index]);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.black12, width: 1),
        ),
        minX: 0,
        maxX: (sortedDates.length - 1).toDouble(),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filter',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterCategory(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterDate(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFilterClass(),
                const SizedBox(height: 12),
                _buildCustomDateRange(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => DropdownButtonFormField<String>(
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            value: controller.selectedCategoryFilter.value,
            onChanged: (value) {
              if (value != null) {
                controller.filterByCategory(value);
              }
            },
            items: const [
              DropdownMenuItem(
                value: 'all',
                child: Text('Semua Kategori'),
              ),
              DropdownMenuItem(
                value: 'career',
                child: Text('Rekomendasi Karir'),
              ),
              DropdownMenuItem(
                value: 'study',
                child: Text('Rekomendasi Studi'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Periode',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => DropdownButtonFormField<String>(
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            value: controller.selectedDateFilter.value,
            onChanged: (value) {
              if (value != null) {
                controller.filterByDate(value);
              }
            },
            items: const [
              DropdownMenuItem(
                value: 'all_time',
                child: Text('Semua Waktu'),
              ),
              DropdownMenuItem(
                value: 'today',
                child: Text('Hari Ini'),
              ),
              DropdownMenuItem(
                value: 'this_month',
                child: Text('Bulan Ini'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterClass() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kelas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => DropdownButtonFormField<String>(
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            value: controller.selectedClass.value,
            onChanged: (value) {
              if (value != null) {
                controller.filterByClass(value);
              }
            },
            items: controller.availableClasses.map((className) {
              return DropdownMenuItem(
                value: className,
                child: Text(className),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDateRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rentang Tanggal Kustom',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Tanggal Mulai',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  isDense: true,
                ),
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: Get.context!,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    // Handle start date selection
                    // Implement custom date range filter
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Tanggal Akhir',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  isDense: true,
                ),
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: Get.context!,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    // Handle end date selection
                    // Implement custom date range filter
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Apply custom date range filter
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Terapkan Filter'),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Data Siswa (${controller.filteredResults.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                // Export data functionality
                Get.snackbar(
                  'Info',
                  'Mengunduh data...',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.filteredResults.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = controller.filteredResults[index];
              final data = doc.data() as Map;

              final isKerja = data['isKerja'] ?? false;
              final username = data['username'] ?? 'Unknown';
              final timestamp = controller.formatTimestamp(data['timestamp']);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isKerja ? Colors.orange : Colors.green,
                  child: Icon(
                    isKerja ? Icons.work : Icons.school,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rekomendasi: ${isKerja ? 'Karir' : 'Studi'}'),
                    Text('Tanggal: $timestamp'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    // View detailed information
                    Get.toNamed('/student-detail', arguments: doc.id);
                  },
                ),
                onTap: () {
                  // Navigate to detail screen
                  Get.toNamed('/student-detail', arguments: doc.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Extended TeacherDashboardController with additional functions for custom date range
class TeacherDashboardControllerExtended extends TeacherDashboardController {
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);

  void setStartDate(DateTime date) {
    startDate.value = date;
    if (endDate.value != null) {
      applyCustomDateRange();
    }
  }

  void setEndDate(DateTime date) {
    endDate.value = date;
    if (startDate.value != null) {
      applyCustomDateRange();
    }
  }

  void applyCustomDateRange() {
    if (startDate.value == null || endDate.value == null) return;

    final start = DateTime(
      startDate.value!.year,
      startDate.value!.month,
      startDate.value!.day,
    );

    final end = DateTime(
      endDate.value!.year,
      endDate.value!.month,
      endDate.value!.day,
    ).add(const Duration(days: 1)); // Include the end date fully

    filteredResults.value = studentResults.where((doc) {
      final data = doc.data() as Map;
      if (data['timestamp'] == null) return false;

      final timestamp = data['timestamp'] as Timestamp;
      final date = timestamp.toDate();
      return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          date.isBefore(end);
    }).toList();
  }

  Future<void> exportData() async {
    // Implement data export functionality
    // This would typically involve creating a CSV file
    // and downloading it to the user's device
  }
}
