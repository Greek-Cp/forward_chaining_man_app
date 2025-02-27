import 'package:flutter/material.dart';
import 'package:forward_chaining_man_app/app/views/student/feature/quiz/view/page_select_economy.dart';
import 'package:get/get.dart';

class MajorPreferenceController extends GetxController {
  final RxString selectedMajor = "".obs;

  void setMajor(String major) {
    if (selectedMajor.value == major) return;
    selectedMajor.value = major;
  }
}

class MajorPreferencePage extends StatelessWidget {
  const MajorPreferencePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MajorPreferenceController());

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
              // Custom App Bar
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
                    const Text(
                      'Pilih Minat Anda',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.school_outlined,
                                size: 24,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Minat IPA',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pilih bidang yang paling Anda minati',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Options List
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                // IPA Sains Option
                                Obx(() => buildMajorCard(
                                      title: "IPA (Sains Murni)",
                                      subtitle:
                                          "Fokus: Biologi, Kimia, Fisika (kedokteran, farmasi, sains)",
                                      description:
                                          "Pilihan yang tepat jika Anda tertarik pada ilmu-ilmu murni seperti biologi, kimia, dan fisika. Ideal untuk karir di bidang kedokteran, farmasi, penelitian ilmiah, atau bidang kesehatan lainnya.",
                                      kode: "SAINS",
                                      icon: Icons.biotech,
                                      controller: controller,
                                    )),

                                const SizedBox(height: 16),

                                // IPA Teknik Option
                                Obx(() => buildMajorCard(
                                      title: "IPA (Teknik)",
                                      subtitle:
                                          "Fokus: Matematika, Fisika, IT (arah teknik/teknologi)",
                                      description:
                                          "Cocok jika Anda memiliki minat kuat di bidang matematika, fisika terapan, dan teknologi informasi. Ideal untuk karir di bidang teknik, IT, rekayasa, atau arsitektur.",
                                      kode: "TEKNIK",
                                      icon: Icons.engineering,
                                      controller: controller,
                                    )),

                                // Add some space at the bottom for better scrolling
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Next Button
                        Obx(() => AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: controller.selectedMajor.value.isEmpty
                                  ? 0.6
                                  : 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow:
                                      controller.selectedMajor.value.isEmpty
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: Colors.blue.shade300
                                                    .withOpacity(0.4),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                ),
                                child: ElevatedButton(
                                  onPressed:
                                      controller.selectedMajor.value.isEmpty
                                          ? null
                                          : () {
                                              // Navigate to economic preference page
                                              Get.to(() => HomePage());
                                            },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    minimumSize:
                                        const Size(double.infinity, 54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                    disabledBackgroundColor:
                                        Colors.blue.shade200,
                                    disabledForegroundColor: Colors.white70,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        controller.selectedMajor.value.isEmpty
                                            ? 'Pilih Salah Satu Minat'
                                            : 'Lanjutkan',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                      ],
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

  /// Widget untuk membuat card pilihan minat
  Widget buildMajorCard({
    required String title,
    required String subtitle,
    required String description,
    required String kode,
    required IconData icon,
    required MajorPreferenceController controller,
  }) {
    final isSelected = controller.selectedMajor.value == kode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.setMajor(kode),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            border: Border.all(
              color: isSelected ? Colors.blue.shade400 : Colors.grey.shade200,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade400
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.blue.shade800
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? Colors.blue.shade600
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
