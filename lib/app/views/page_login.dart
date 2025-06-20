import 'package:flutter/material.dart';
import 'package:forward_chaining_man_app/app/views/student/page_student_dashboard.dart';
import 'package:forward_chaining_man_app/main.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentLoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isRegistering = false.obs;
  var isRegisterUsingGoogle = false.obs;
  // Text controllers for login/register form
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final selectedClass = Rx<String?>(null);
  final selectedSchoolId = Rx<String?>(null);

  void checkValidClass() {
    if (selectedClass.value != null &&
        !classOptions.contains(selectedClass.value)) {
      selectedClass.value = null;
    }
  }

  final List<String> asalSekolah = ["MAN 1 NGANJUK"];

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
    checkValidClass();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.onClose();
  }

  // Check if user is already logged in
  Future<void> checkExistingSession() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Get the schoolId from shared preferences or another source
        final prefs = await SharedPreferences.getInstance();
        final schoolId = prefs.getString('school_id');

        if (schoolId != null) {
          // Check if user data exists in Firestore as a subcollection of schools
          final docSnapshot = await _firestore
              .collection('schools')
              .doc(schoolId)
              .collection('students')
              .doc(currentUser.uid)
              .get();

          if (docSnapshot.exists) {
            // Save login session
            await saveLoginSession(currentUser.uid, schoolId);
            // Navigate to main app
            Get.offAll(() => const PageStudentDashboard());
          } else {
            // User authenticated but no profile exists
            if (currentUser.displayName != null) {
              nameController.text = currentUser.displayName!;
            }
            isRegistering.value = true;
          }
        } else {
          // No school selected yet, user needs to complete registration
          if (currentUser.displayName != null) {
            nameController.text = currentUser.displayName!;
          }
          isRegistering.value = true;
        }
      }
    } catch (e) {
      print('Error checking session: $e');
    }
  }

  // Save login session to shared preferences
  Future<void> saveLoginSession(String uid, String schoolId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uid', uid);
      await prefs.setString('school_id', schoolId);
      await prefs.setBool('is_logged_in', true);

      // Update last login timestamp
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  // Toggle between login and register views
  void toggleRegistrationMode() {
    isRegistering.value = !isRegistering.value;
    errorMessage.value = '';

    // Clear fields when toggling
    if (!isRegistering.value) {
      nameController.clear();
      confirmPasswordController.clear();
      selectedClass.value = null;
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
        // Find which school this user belongs to
        String? schoolId;

        // Query all schools to find the student
        final schoolsSnapshot = await _firestore.collection('schools').get();

        for (var schoolDoc in schoolsSnapshot.docs) {
          final studentDoc = await schoolDoc.reference
              .collection('students')
              .doc(userCredential.user!.uid)
              .get();

          if (studentDoc.exists) {
            schoolId = schoolDoc.id;
            break;
          }
        }

        if (schoolId != null) {
          // Save login session with school ID
          await saveLoginSession(userCredential.user!.uid, schoolId);
          // Navigate to main app
          Get.offAll(() => const PageStudentDashboard());
        } else {
          errorMessage.value = 'Akun tidak ditemukan di sekolah manapun';
          await _auth.signOut();
        }
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

  // Register with email and password
  Future<void> registerWithEmailPassword() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Validasi input
      if (emailController.text.trim().isEmpty ||
          passwordController.text.isEmpty ||
          nameController.text.trim().isEmpty ||
          selectedClass.value == null ||
          selectedSchoolId.value == null) {
        errorMessage.value = 'Semua field harus diisi';
        return;
      }

      if (passwordController.text != confirmPasswordController.text) {
        errorMessage.value = 'Password tidak cocok';
        return;
      }

      if (passwordController.text.length < 6) {
        errorMessage.value = 'Password minimal 6 karakter';
        return;
      }

      // Buat akun user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (userCredential.user != null) {
        String studentId = userCredential.user!.uid;
        String schoolId = selectedSchoolId.value!; // Pastikan schoolId valid

        // Pastikan sekolah ada di Firestore
        DocumentReference schoolRef =
            _firestore.collection('schools').doc(schoolId);
        DocumentSnapshot schoolSnapshot = await schoolRef.get();

        if (!schoolSnapshot.exists) {
          errorMessage.value = 'Sekolah yang dipilih tidak ditemukan';
          return;
        }

        // Perbarui nama tampilan di Firebase Auth
        await userCredential.user!
            .updateDisplayName(nameController.text.trim());

        // Simpan data siswa dalam subkoleksi `students` di dalam `schools`
        await schoolRef.collection('students').doc(studentId).set({
          'name': nameController.text.trim(),
          'class': selectedClass.value,
          'email': userCredential.user!.email,
          'registrationType': 'email',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // Simpan sesi login
        await saveLoginSession(studentId, schoolId);

        // Navigasi ke dashboard siswa
        Get.offAll(() => const PageStudentDashboard());
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage.value = 'Email sudah terdaftar';
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

// First, add this to your StudentLoginController class:

// Add this reactive variable to track Google sign-in state

// Updated Google Sign-In method with the new variable
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Start the Google Sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        isLoading.value = false;
        return; // User canceled the sign-in
      }

      // Get authentication details from Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Find which school this user belongs to
        String? schoolId;
        bool userExists = false;

        // Query all schools to find the student
        final schoolsSnapshot = await _firestore.collection('schools').get();

        for (var schoolDoc in schoolsSnapshot.docs) {
          final studentDoc = await schoolDoc.reference
              .collection('students')
              .doc(user.uid)
              .get();

          if (studentDoc.exists) {
            schoolId = schoolDoc.id;
            userExists = true;
            // Update login time
            await schoolDoc.reference
                .collection('students')
                .doc(user.uid)
                .update({
              'lastLogin': FieldValue.serverTimestamp(),
            });
            break;
          }
        }

        if (userExists && schoolId != null) {
          // Existing user - save login session
          await saveLoginSession(user.uid, schoolId);
          // Navigate to main app
          Get.offAll(() => const PageStudentDashboard());
        } else {
          // New user - need to complete profile
          // Pre-fill name from Google account
          nameController.text = user.displayName ?? '';
          emailController.text = user.email ?? '';
          isRegistering.value = true;
          isRegisterUsingGoogle.value =
              true; // Set to true when signing in with Google

          // Show toast message
          Get.snackbar(
            'Lengkapi Profil',
            'Silakan pilih kelas dan sekolah untuk melanjutkan',
            backgroundColor: Colors.blue.shade100,
            colorText: Colors.blue.shade800,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
          );
        }
      }
    } catch (e) {
      errorMessage.value = 'Login gagal: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

// Modify the completeGoogleProfile method to use the isRegisterUsingGoogle flag
  Future<void> completeGoogleProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        errorMessage.value = 'Tidak ada user yang terautentikasi';
        return;
      }

      if (nameController.text.trim().isEmpty ||
          selectedClass.value == null ||
          selectedSchoolId.value == null) {
        errorMessage.value = 'Nama, kelas, dan sekolah tidak boleh kosong';
        return;
      }

      String studentId = currentUser.uid;
      String schoolId =
          selectedSchoolId.value!; // Pastikan schoolId dipilih dan valid

      // Pastikan sekolah sudah ada di Firestore
      DocumentReference schoolRef =
          _firestore.collection('schools').doc(schoolId);
      DocumentSnapshot schoolSnapshot = await schoolRef.get();

      if (!schoolSnapshot.exists) {
        errorMessage.value = 'Sekolah yang dipilih tidak ditemukan';
        return;
      }

      // Simpan data siswa dalam subkoleksi students di dalam sekolah
      await schoolRef.collection('students').doc(studentId).set({
        'name': nameController.text.trim(),
        'class': selectedClass.value,
        'email': currentUser.email,
        'photoURL': currentUser.photoURL,
        'registrationType': 'google',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Update display name jika perlu
      if (currentUser.displayName != nameController.text.trim()) {
        await currentUser.updateDisplayName(nameController.text.trim());
      }

      // Simpan sesi login
      await saveLoginSession(studentId, schoolId);

      // Reset the isRegisterUsingGoogle flag
      isRegisterUsingGoogle.value = false;

      // Navigasi ke dashboard
      Get.offAll(() => const PageStudentDashboard());
    } catch (e) {
      errorMessage.value = 'Gagal menyimpan profil: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
}

class StudentLoginPage extends StatelessWidget {
  String routeName = "/StudentLoginPage";
  StudentLoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentLoginController>();

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
                    // App Logo
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
                        child: const Center(
                          child: Icon(
                            Icons.psychology,
                            size: 60,
                            color: Colors.indigo,
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

                    const Text(
                      'Sistem Rekomendasi Karir & Kuliah',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Login/Register Card
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
                                Text(
                                  controller.isRegistering.value
                                      ? 'Daftar Akun'
                                      : 'Masuk Akun',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade800,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  controller.isRegistering.value
                                      ? 'Lengkapi informasi untuk mendaftar'
                                      : 'Masuk untuk melanjutkan ke aplikasi',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Registration form fields
                                if (controller.isRegistering.value) ...[
                                  // Name field
                                  _buildTextField(
                                    controller: controller.nameController,
                                    label: 'Nama Lengkap',
                                    prefixIcon: Icons.person_outline,
                                  ),
                                ],

                                const SizedBox(height: 24),
// Email field - Hide if Google sign-in
                                Obx(() => controller.isRegisterUsingGoogle.value
                                    ? const SizedBox
                                        .shrink() // Hide if Google sign-in
                                    : _buildTextField(
                                        controller: controller.emailController,
                                        label: 'Email',
                                        prefixIcon: Icons.email_outlined,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      )),

                                Obx(() => controller.isRegisterUsingGoogle.value
                                    ? const SizedBox
                                        .shrink() // No spacer if email is hidden
                                    : const SizedBox(height: 16)),

// Password field - Hide if Google sign-in
                                Obx(() => controller.isRegisterUsingGoogle.value
                                    ? const SizedBox
                                        .shrink() // Hide if Google sign-in
                                    : CustomTextField(
                                        controller:
                                            controller.passwordController,
                                        label: 'Password',
                                        prefixIcon: Icons.lock_outline,
                                        isPassword: true,
                                      )),

// Only show confirm password in registration mode and not Google sign-in
                                if (controller.isRegistering.value) ...[
                                  Obx(() => controller
                                          .isRegisterUsingGoogle.value
                                      ? const SizedBox
                                          .shrink() // No spacer if password is hidden
                                      : const SizedBox(height: 16)),

                                  // Confirm password field - Hide if Google sign-in
                                  Obx(() => controller
                                          .isRegisterUsingGoogle.value
                                      ? const SizedBox
                                          .shrink() // Hide if Google sign-in
                                      : CustomTextField(
                                          controller: controller
                                              .confirmPasswordController,
                                          label: 'Konfirmasi Password',
                                          prefixIcon: Icons.lock_outline,
                                          isPassword: true,
                                        )),

                                  const SizedBox(height: 16),

                                  // School selection - Always show in registration
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: Obx(() =>
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: controller
                                                .selectedSchoolId.value,
                                            hint: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.school_outlined,
                                                      color: Colors
                                                          .indigo.shade300),
                                                  const SizedBox(width: 12),
                                                  const Text('Pilih Sekolah'),
                                                ],
                                              ),
                                            ),
                                            isExpanded: true,
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            icon: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 16),
                                              child: Icon(Icons.arrow_drop_down,
                                                  color:
                                                      Colors.indigo.shade400),
                                            ),
                                            items: controller.asalSekolah
                                                .map((String kelas) {
                                              return DropdownMenuItem<String>(
                                                value: kelas,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                          Icons.school_outlined,
                                                          color: Colors
                                                              .indigo.shade300),
                                                      const SizedBox(width: 12),
                                                      Text(kelas),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              controller.selectedSchoolId
                                                  .value = newValue;
                                            },
                                          ),
                                        )),
                                  ),
                                  const SizedBox(height: 16),

                                  // Class dropdown - Always show in registration
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: Obx(() =>
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value:
                                                controller.selectedClass.value,
                                            hint: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.school_outlined,
                                                      color: Colors
                                                          .indigo.shade300),
                                                  const SizedBox(width: 12),
                                                  const Text('Pilih Kelas'),
                                                ],
                                              ),
                                            ),
                                            isExpanded: true,
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            icon: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 16),
                                              child: Icon(Icons.arrow_drop_down,
                                                  color:
                                                      Colors.indigo.shade400),
                                            ),
                                            items: controller.classOptions
                                                .map((String kelas) {
                                              return DropdownMenuItem<String>(
                                                value: kelas,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                          Icons.school_outlined,
                                                          color: Colors
                                                              .indigo.shade300),
                                                      const SizedBox(width: 12),
                                                      Text(kelas),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              controller.selectedClass.value =
                                                  newValue;
                                            },
                                          ),
                                        )),
                                  ),
                                ],

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

                                // Login/Register button
                                _buildPrimaryButton(
                                  label: controller.isRegistering.value
                                      ? 'Daftar'
                                      : 'Masuk',
                                  icon: controller.isRegistering.value
                                      ? Icons.person_add
                                      : Icons.login,
                                  isLoading: controller.isLoading.value,
                                  onPressed: () {
                                    if (controller.isRegistering.value) {
                                      // Check if completing Google profile or regular registration
                                      if (FirebaseAuth.instance.currentUser !=
                                              null &&
                                          FirebaseAuth.instance.currentUser!
                                              .providerData
                                              .any((provider) =>
                                                  provider.providerId ==
                                                  'google.com')) {
                                        controller.completeGoogleProfile();
                                      } else {
                                        controller.registerWithEmailPassword();
                                      }
                                    } else {
                                      controller.signInWithEmailPassword();
                                    }
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Google sign-in button
                                if (!controller.isRegistering.value ||
                                    FirebaseAuth.instance.currentUser == null)
                                  _buildGoogleButton(
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : controller.signInWithGoogle,
                                    isLoading: controller.isLoading.value,
                                  ),

                                const SizedBox(height: 24),

                                // Toggle between login and register
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      controller.isRegistering.value
                                          ? 'Sudah punya akun? '
                                          : 'Belum punya akun? ',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: controller.isLoading.value
                                          ? null
                                          : controller.toggleRegistrationMode,
                                      child: Text(
                                        controller.isRegistering.value
                                            ? 'Masuk'
                                            : 'Daftar',
                                        style: TextStyle(
                                          color: Colors.indigo.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),

                    const SizedBox(height: 20),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: Colors.indigo.shade300),
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
    );
  }

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
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
        disabledBackgroundColor: Colors.indigo.shade300,
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

  // Helper method to build Google button
  Widget _buildGoogleButton({
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/ic_google.png',
            height: 24,
            width: 24,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.g_mobiledata,
              size: 24,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Lanjutkan dengan Google',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  }) : super(key: key);

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.prefixIcon, color: Colors.indigo.shade300),
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
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}
