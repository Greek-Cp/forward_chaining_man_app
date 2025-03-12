import 'package:flutter/material.dart';
import 'package:forward_chaining_man_app/app/views/dashboard_teacher.dart';
import 'package:forward_chaining_man_app/app/views/page_login.dart';
import 'package:forward_chaining_man_app/app/views/page_teacher_register.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import your teacher dashboard or main page

class TeacherLoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Text controllers for login form
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    checkExistingSession();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // Check if user is already logged in
  Future<void> checkExistingSession() async {
    try {
      isLoading.value = true;

      // Check if we have a stored user_uid and role
      final prefs = await SharedPreferences.getInstance();
      final storedUid = prefs.getString('user_uid');
      final storedRole = prefs.getString('user_role');

      if (storedUid != null && storedRole == 'teacher') {
        // Verify if user exists in Firebase Auth
        User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          // Check if user data exists in Firestore
          final docSnapshot = await _firestore
              .collection('teachers')
              .doc(currentUser.uid)
              .get();

          if (docSnapshot.exists) {
            // Navigate to teacher dashboard
            Get.offAll(() => const TeacherDashboardPage());
            return;
          }
        }
      }
    } catch (e) {
      print('Error checking session: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Sign in with email and password
  Future<void> signInWithEmailPassword() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (emailController.text.trim().isEmpty ||
          passwordController.text.isEmpty) {
        errorMessage.value = 'Email dan password tidak boleh kosong';
        return;
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (userCredential.user != null) {
        // Check if this user is a teacher
        final teacherDoc = await _firestore
            .collection('teachers')
            .doc(userCredential.user!.uid)
            .get();

        if (!teacherDoc.exists) {
          // This user is not registered as a teacher
          errorMessage.value = 'Akun ini tidak terdaftar sebagai guru';
          await _auth.signOut();
          return;
        }

        // Save login session
        await saveLoginSession(userCredential.user!.uid, teacherDoc);

        // Navigate to teacher dashboard
        Get.offAll(() => const TeacherDashboardPage());
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          errorMessage.value = 'Email tidak terdaftar';
          break;
        case 'wrong-password':
          errorMessage.value = 'Password salah';
          break;
        case 'invalid-email':
          errorMessage.value = 'Format email tidak valid';
          break;
        default:
          errorMessage.value = 'Gagal masuk: ${e.message}';
      }
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

// Save login session to shared preferences
  Future<void> saveLoginSession(String uid, DocumentSnapshot teacherDoc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uid', uid);
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_role', 'teacher');

      // Extract schoolId from teacher document if it exists
      final teacherData = teacherDoc.data() as Map<String, dynamic>?;
      if (teacherData != null && teacherData.containsKey('schoolId')) {
        final schoolId = teacherData['schoolId'];
        if (schoolId != null && schoolId is String && schoolId.isNotEmpty) {
          // Save the school ID to shared preferences
          await prefs.setString('school_id', schoolId);
        }
      }

      // Update last login timestamp
      await _firestore.collection('teachers').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving session: $e');
    }
  }
}

class TeacherLoginPage extends StatelessWidget {
  const TeacherLoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TeacherLoginController());

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
                              Text('Kembali ke Pemilihan Peran'),
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
                            color: Colors.blue
                                .shade700, // Mengubah warna ikon sesuai dengan skema warna biru
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

                    // Teacher Login Subtitle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Portal Guru',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Login Card
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
                                        Icons.person_pin,
                                        color: Colors.blue.shade400,
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
                                            'Masuk sebagai Guru',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Masukkan kredensial Anda',
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

                                // Email field
                                CustomTextField(
                                  controller: controller.emailController,
                                  label: 'Email',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),

                                const SizedBox(height: 20),

                                // Password field
                                CustomTextField(
                                  controller: controller.passwordController,
                                  label: 'Password',
                                  prefixIcon: Icons.lock_outline,
                                  isPassword: true,
                                ),

                                const SizedBox(height: 12),

                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      // Handle forgot password
                                      Get.snackbar(
                                        'Lupa Password',
                                        'Silakan hubungi administrator untuk reset password',
                                        backgroundColor: Colors.blue.shade50,
                                        colorText: Colors.blue.shade800,
                                        snackPosition: SnackPosition.BOTTOM,
                                        margin: const EdgeInsets.all(16),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 30),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Lupa Password?',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
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

                                // Login and Register buttons
                                Column(
                                  children: [
                                    // Login button
                                    _buildPrimaryButton(
                                      label: 'Masuk',
                                      icon: Icons.login,
                                      isLoading: controller.isLoading.value,
                                      onPressed:
                                          controller.signInWithEmailPassword,
                                      primaryColor: Colors.blue.shade700,
                                      isOutlined: false,
                                    ),

                                    const SizedBox(height: 16),

                                    // Register button
                                    _buildPrimaryButton(
                                      label: 'Daftar Akun Baru',
                                      icon: Icons.person_add,
                                      isLoading: false,
                                      onPressed: () {
                                        Get.to(
                                            () => const TeacherRegisterPage());
                                      },
                                      primaryColor: Colors.blue.shade700,
                                      isOutlined: true,
                                    ),
                                  ],
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
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(prefixIcon, color: Colors.blue.shade300),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.blue.shade500, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  // Enhanced helper method to build primary/secondary buttons
  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isLoading,
    required Color primaryColor,
    required bool isOutlined,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.white : primaryColor,
        foregroundColor: isOutlined ? primaryColor : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: isOutlined
              ? BorderSide(color: primaryColor, width: 1.5)
              : BorderSide.none,
        ),
        elevation: isOutlined ? 0 : 2,
        disabledBackgroundColor:
            isOutlined ? Colors.grey.shade100 : primaryColor.withOpacity(0.6),
        disabledForegroundColor: isOutlined ? Colors.grey : Colors.white70,
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
