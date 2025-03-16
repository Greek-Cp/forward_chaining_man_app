import 'package:flutter/material.dart';
import 'package:forward_chaining_man_app/app/views/page_intro.dart';
import 'package:forward_chaining_man_app/app/views/page_login.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var isEditing = false.obs;
  var userProfile = Rx<Map<String, dynamic>>({});
  var schoolId = ''.obs;

  final nameController = TextEditingController();
  final selectedClass = Rx<String?>(null);

  // Class options for the dropdown
  final List<String> classOptions = [
    'X IPA A (1)',
    'X IPA B (2)',
    'X IPA C (3)',
    'X IPA D (4)',
    'XI IPA A (1)',
    'XI IPA B (2)',
    'XI IPA C (3)',
    'XI IPA D (4)',
    'XII IPA A (1)',
    'XII IPA B (2)',
    'XII IPA C (3)',
    'XII IPA D (4)',
  ];

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;

      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        Get.offAll(() => StudentLoginPage());
        return;
      }

      // Get schoolId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedSchoolId = prefs.getString('school_id');

      if (storedSchoolId != null && storedSchoolId.isNotEmpty) {
        schoolId.value = storedSchoolId;

        // Get student data from the subcollection
        final docSnapshot = await _firestore
            .collection('schools')
            .doc(schoolId.value)
            .collection('students')
            .doc(currentUser.uid)
            .get();

        if (docSnapshot.exists) {
          userProfile.value = docSnapshot.data() as Map<String, dynamic>;

          // Initialize controllers with current values
          nameController.text = userProfile.value['name'] ?? '';
          selectedClass.value = userProfile.value['class'];
        } else {
          // Student not found in this school
          await _findStudentInAllSchools(currentUser);
        }
      } else {
        // School ID not found in shared preferences, search in all schools
        await _findStudentInAllSchools(currentUser);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat profil: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to find a student in all schools
  Future<void> _findStudentInAllSchools(User currentUser) async {
    try {
      final schoolsSnapshot = await _firestore.collection('schools').get();
      bool found = false;

      for (var schoolDoc in schoolsSnapshot.docs) {
        final studentDoc = await schoolDoc.reference
            .collection('students')
            .doc(currentUser.uid)
            .get();

        if (studentDoc.exists) {
          // Found the student
          schoolId.value = schoolDoc.id;
          userProfile.value = studentDoc.data() as Map<String, dynamic>;

          // Save school ID to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('school_id', schoolId.value);

          // Initialize controllers with current values
          nameController.text = userProfile.value['name'] ?? '';
          selectedClass.value = userProfile.value['class'];
          found = true;
          break;
        }
      }

      // If student was not found in any school
      if (!found) {
        nameController.text = currentUser.displayName ?? '';
        selectedClass.value = null;

        Get.snackbar(
          'Perhatian',
          'Profil tidak ditemukan. Silakan lengkapi data profil Anda.',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );

        // Enter edit mode automatically
        isEditing.value = true;
      }
    } catch (e) {
      print('Error finding student in schools: $e');
      throw e;
    }
  }

  void toggleEditMode() {
    isEditing.value = !isEditing.value;

    // Reset controllers to current values when canceling edit
    if (!isEditing.value) {
      nameController.text = userProfile.value['name'] ?? '';
      selectedClass.value = userProfile.value['class'];
    } else {
      selectedClass.value = "";
    }
  }

  Future<void> saveProfile() async {
    try {
      isLoading.value = true;

      if (nameController.text.trim().isEmpty ||
          selectedClass.value == null ||
          selectedClass.value!.isEmpty) {
        Get.snackbar(
          'Error',
          'Nama dan kelas tidak boleh kosong',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return;
      }

      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return;
      }

      // If schoolId is empty, we need to select a school
      if (schoolId.value.isEmpty) {
        // For simplicity, using the first school available
        // In a real app, you might want to show a school selection UI
        final schoolsSnapshot = await _firestore.collection('schools').get();
        if (schoolsSnapshot.docs.isNotEmpty) {
          schoolId.value = schoolsSnapshot.docs.first.id;

          // Save school ID to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('school_id', schoolId.value);
        } else {
          Get.snackbar(
            'Error',
            'Tidak ada sekolah yang tersedia',
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
          return;
        }
      }

      // Update Firestore in the appropriate subcollection
      await _firestore
          .collection('schools')
          .doc(schoolId.value)
          .collection('students')
          .doc(currentUser.uid)
          .set({
        'name': nameController.text.trim(),
        'class': selectedClass.value,
        'email': currentUser.email,
        'photoURL': currentUser.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update display name if needed
      if (currentUser.displayName != nameController.text.trim()) {
        await currentUser.updateDisplayName(nameController.text.trim());
      }

      // Reload profile
      await loadUserProfile();

      // Exit edit mode
      isEditing.value = false;

      Get.snackbar(
        'Sukses',
        'Profil berhasil diperbarui',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyimpan profil: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Sign out from Firebase
      await _auth.signOut();

      // Navigate to login page
      Get.offAll(() => IntroPage());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal keluar: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(
            () => controller.isEditing.value
                ? IconButton(
                    onPressed: controller.toggleEditMode,
                    icon: const Icon(Icons.close),
                    tooltip: 'Batal',
                  )
                : IconButton(
                    onPressed: controller.toggleEditMode,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Profil',
                  ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade800,
              Colors.blue.shade800,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Obx(
            () => controller.isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Profile Header
                          _buildProfileHeader(controller),

                          const SizedBox(height: 30),

                          // Profile Content
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Informasi Profil',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade800,
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Profile Fields
                                  Obx(
                                    () => controller.isEditing.value
                                        ? _buildEditFields(controller)
                                        : _buildDisplayFields(controller),
                                  ),

                                  const SizedBox(height: 24),

                                  // Save Button (only in edit mode)
                                  Obx(
                                    () => controller.isEditing.value
                                        ? ElevatedButton(
                                            onPressed: controller.saveProfile,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.indigo.shade800,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                              minimumSize: const Size(
                                                  double.infinity, 56),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Icon(Icons.save, size: 20),
                                                SizedBox(width: 10),
                                                Text(
                                                  'Simpan Perubahan',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),

                                  const SizedBox(height: 8),

                                  // Logout Button
                                  ElevatedButton(
                                    onPressed: () {
                                      Get.dialog(
                                        AlertDialog(
                                          title: const Text('Konfirmasi'),
                                          content: const Text(
                                              'Apakah Anda yakin ingin keluar?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Get.back(),
                                              child: const Text('Batal'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Get.back();
                                                controller.logout();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              child: const Text('Keluar'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade50,
                                      foregroundColor: Colors.red.shade700,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      minimumSize:
                                          const Size(double.infinity, 56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.logout, size: 20),
                                        SizedBox(width: 10),
                                        Text(
                                          'Keluar Akun',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // App version
                                  Center(
                                    child: Text(
                                      'App Version 1.0.0',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ProfileController controller) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Column(
      children: [
        // Profile Picture
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          backgroundImage: currentUser?.photoURL != null
              ? NetworkImage(currentUser!.photoURL!)
              : null,
          child: currentUser?.photoURL == null
              ? Text(
                  controller.userProfile.value['name'] != null
                      ? controller.userProfile.value['name']
                          .substring(0, 1)
                          .toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                )
              : null,
        ),

        const SizedBox(height: 16),

        // Name
        Text(
          controller.userProfile.value['name'] ?? 'Siswa',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 4),

        // Email
        Text(
          currentUser?.email ?? '',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),

        const SizedBox(height: 8),

        // Class Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                controller.userProfile.value['class'] ?? 'Kelas tidak diatur',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayFields(ProfileController controller) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Column(
      children: [
        // Name field
        _buildInfoItem(
          icon: Icons.person,
          title: 'Nama Lengkap',
          value: controller.userProfile.value['name'] ?? '-',
        ),

        const SizedBox(height: 16),

        // Class field
        _buildInfoItem(
          icon: Icons.school,
          title: 'Kelas',
          value: controller.userProfile.value['class'] ?? '-',
        ),

        const SizedBox(height: 16),

        // Email field
        _buildInfoItem(
          icon: Icons.email,
          title: 'Email',
          value: currentUser?.email ?? '-',
        ),

        const SizedBox(height: 16),

        // Registration Type
        _buildInfoItem(
          icon: Icons.login,
          title: 'Jenis Registrasi',
          value: controller.userProfile.value['registrationType'] == 'google'
              ? 'Google'
              : 'Email & Password',
        ),

        const SizedBox(height: 16),

        // Join Date
        _buildInfoItem(
          icon: Icons.calendar_today,
          title: 'Tanggal Bergabung',
          value: controller.userProfile.value['createdAt'] != null
              ? _formatTimestamp(controller.userProfile.value['createdAt'])
              : '-',
        ),
      ],
    );
  }

  Widget _buildEditFields(ProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field
        const Text(
          'Nama Lengkap',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.nameController,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.person, color: Colors.indigo.shade300),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.indigo.shade500),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),

        const SizedBox(height: 20),

        // Class dropdown
        const Text(
          'Kelas',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Obx(() {
            // Validate that value exists in items list
            final currentValue = controller.selectedClass.value;
            final isValueValid = currentValue != null &&
                controller.classOptions.contains(currentValue);

            return DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                // Only set value if it's valid
                value: isValueValid ? currentValue : null,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.school_outlined,
                          color: Colors.indigo.shade300),
                      const SizedBox(width: 12),
                      const Text('Pilih Kelas'),
                    ],
                  ),
                ),
                isExpanded: true,
                borderRadius: BorderRadius.circular(15),
                icon: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(Icons.arrow_drop_down,
                      color: Colors.indigo.shade400),
                ),
                items: controller.classOptions.map((String kelas) {
                  return DropdownMenuItem<String>(
                    value: kelas,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.school_outlined,
                              color: Colors.indigo.shade300),
                          const SizedBox(width: 12),
                          Text(kelas),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  controller.selectedClass.value = newValue;
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.indigo.shade400,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '-';

    try {
      if (timestamp is Timestamp) {
        final DateTime dateTime = timestamp.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      print('Error formatting timestamp: $e');
    }

    return '-';
  }
}
