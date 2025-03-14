// Widget untuk animasi gelombang di bagian bawah dialog
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

// Fungsi untuk menampilkan dialog konfirmasi
void _showConfirmationDialog(BuildContext context, VoidCallback onConfirm) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Konfirmasi',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Container(); // Tidak digunakan, kita menggunakan transitionBuilder
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );

      return ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConfirmationDialogContent(onConfirm: onConfirm),
          ),
        ),
      );
    },
  );
}

// Widget konten dialog
class ConfirmationDialogContent extends StatefulWidget {
  final VoidCallback onConfirm;

  const ConfirmationDialogContent({
    Key? key,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<ConfirmationDialogContent> createState() =>
      _ConfirmationDialogContentState();
}

class _ConfirmationDialogContentState extends State<ConfirmationDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  final List<bool> _checkedItems = [false, false, false];
  bool get _allChecked => _checkedItems.every((element) => element);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 400,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background dengan gradien dan gelombang
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return ClipPath(
                  clipper: WaveClipper(_waveController.value),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.shade50,
                          Colors.blue.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),

          // Konten utama
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Konfirmasi Pemilihan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pastikan pilihan Anda sudah sesuai sebelum melanjutkan ke kuisioner',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Checklist konfirmasi
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Silakan konfirmasi bahwa Anda:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Checklist pertama
                    CheckboxListTile(
                      value: _checkedItems[0],
                      onChanged: (value) {
                        setState(() {
                          _checkedItems[0] = value ?? false;
                        });
                      },
                      title: const Text(
                        'Telah memilih minat yang benar-benar sesuai dengan diri Anda',
                        style: TextStyle(fontSize: 14),
                      ),
                      activeColor: Colors.blue.shade600,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),

                    // Checklist kedua
                    CheckboxListTile(
                      value: _checkedItems[1],
                      onChanged: (value) {
                        setState(() {
                          _checkedItems[1] = value ?? false;
                        });
                      },
                      title: const Text(
                        'Mempertimbangkan kondisi ekonomi keluarga dalam membuat pilihan',
                        style: TextStyle(fontSize: 14),
                      ),
                      activeColor: Colors.blue.shade600,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),

                    // Checklist ketiga
                    CheckboxListTile(
                      value: _checkedItems[2],
                      onChanged: (value) {
                        setState(() {
                          _checkedItems[2] = value ?? false;
                        });
                      },
                      title: const Text(
                        'Memiliki rencana yang jelas untuk masa depan Anda',
                        style: TextStyle(fontSize: 14),
                      ),
                      activeColor: Colors.blue.shade600,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                  ],
                ),
              ),

              // Pesan tentang kejujuran
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber.shade800,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Di halaman selanjutnya Anda akan menjawab beberapa pertanyaan. Pastikan untuk menjawab dengan jujur sesuai kondisi Anda.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tombol-tombol
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Row(
                  children: [
                    // Tombol Kembali
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          side: BorderSide(color: Colors.blue.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Kembali'),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Tombol Lanjutkan
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _allChecked
                            ? () {
                                Navigator.of(context).pop();
                                widget.onConfirm();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Ya, Lanjutkan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Lingkaran dekoratif di pojok
          Positioned(
            right: -15,
            top: -15,
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.blue.shade400.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -10,
            bottom: -10,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade400.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  final double animation;

  WaveClipper(this.animation);

  @override
  Path getClip(Size size) {
    final path = Path();
    final height = size.height;
    final width = size.width;

    path.lineTo(0, height * 0.7);

    // Buat gelombang dengan animasi
    final firstControlPoint = Offset(
        width * 0.25, height * (0.7 + 0.04 * math.sin(animation * math.pi)));
    final firstEndPoint = Offset(width * 0.5, height * 0.7);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    final secondControlPoint = Offset(
        width * 0.75, height * (0.7 - 0.04 * math.sin(animation * math.pi)));
    final secondEndPoint = Offset(width, height * 0.7);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) => true;
}
