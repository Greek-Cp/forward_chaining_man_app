import 'package:flutter/material.dart';
import 'package:forward_chaining_man_app/app/views/page_login.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherRegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Text controllers for registration form
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final schoolController = TextEditingController();
  final subjectController = TextEditingController();

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    schoolController.dispose();
    subjectController.dispose();
    super.onClose();
  }

  // Register new teacher account
  Future<void> registerTeacher() async {
    try {
      // Reset error message
      errorMessage.value = '';

      // Basic validation
      if (nameController.text.trim().isEmpty ||
          emailController.text.trim().isEmpty ||
          passwordController.text.isEmpty ||
          confirmPasswordController.text.isEmpty ||
          schoolController.text.trim().isEmpty) {
        errorMessage.value = 'Semua kolom wajib diisi';
        return;
      }

      // Password validation
      if (passwordController.text.length < 6) {
        errorMessage.value = 'Password minimal 6 karakter';
        return;
      }

      // Confirm password validation
      if (passwordController.text != confirmPasswordController.text) {
        errorMessage.value = 'Password tidak sama';
        return;
      }

      // Start loading
      isLoading.value = true;

      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (userCredential.user != null) {
        // Add teacher data to Firestore
        await _firestore
            .collection('teachers')
            .doc(userCredential.user!.uid)
            .set({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'school': schoolController.text.trim(),
          'subject': subjectController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'role': 'teacher',
        });

        // Show success message
        Get.snackbar(
          'Berhasil',
          'Akun guru berhasil dibuat',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );

        // Navigate back to login
        Get.back();
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage.value = 'Email sudah digunakan';
          break;
        case 'invalid-email':
          errorMessage.value = 'Format email tidak valid';
          break;
        case 'weak-password':
          errorMessage.value = 'Password terlalu lemah';
          break;
        default:
          errorMessage.value = 'Gagal mendaftar: ${e.message}';
      }
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
}

class TeacherRegisterPage extends StatelessWidget {
  const TeacherRegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TeacherRegisterController());

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
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Back button at the top
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.arrow_back, size: 18),
                              SizedBox(width: 8),
                              Text('Kembali ke Halaman Login'),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // App Logo with Hero animation
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.psychology,
                            size: 60,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // App Title
                    const Text(
                      'EduGuide',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Register Subtitle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Daftar Akun Guru',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Registration Card
                    Obx(() => Container(
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
                                // Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.app_registration_rounded,
                                        color: Colors.blue.shade600,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Daftar Akun Baru',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Lengkapi data diri Anda',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 30),

                                // Name field
                                CustomTextField(
                                  controller: controller.nameController,
                                  label: 'Nama Lengkap',
                                  prefixIcon: Icons.person_outline,
                                ),

                                const SizedBox(height: 16),

                                // Email field
                                CustomTextField(
                                  controller: controller.emailController,
                                  label: 'Email',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),

                                const SizedBox(height: 16),

                                // School field
                                CustomTextField(
                                  controller: controller.schoolController,
                                  label: 'Sekolah',
                                  prefixIcon: Icons.school_outlined,
                                ),

                                const SizedBox(height: 16),

                                // Subject field
                                CustomTextField(
                                  controller: controller.subjectController,
                                  label: 'Mata Pelajaran (Opsional)',
                                  prefixIcon: Icons.book_outlined,
                                ),

                                const SizedBox(height: 16),

                                // Password field
                                CustomTextField(
                                  controller: controller.passwordController,
                                  label: 'Password',
                                  prefixIcon: Icons.lock_outline,
                                  isPassword: true,
                                ),

                                const SizedBox(height: 16),

                                // Confirm Password field
                                CustomTextField(
                                  controller:
                                      controller.confirmPasswordController,
                                  label: 'Konfirmasi Password',
                                  prefixIcon: Icons.lock_outline,
                                  isPassword: true,
                                ),

                                const SizedBox(height: 24),

                                // Error message
                                Obx(() => controller
                                        .errorMessage.value.isNotEmpty
                                    ? Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.red.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error_outline,
                                                color: Colors.red.shade800),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                controller.errorMessage.value,
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink()),

                                const SizedBox(height: 24),

                                // Register button
                                _buildPrimaryButton(
                                  label: 'Daftar',
                                  icon: Icons.how_to_reg,
                                  isLoading: controller.isLoading.value,
                                  onPressed: controller.registerTeacher,
                                ),
                              ],
                            ),
                          ),
                        )),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build text fields

  // Helper method to build primary button
  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
        disabledBackgroundColor: Colors.blue.shade300,
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
    );
  }
}
