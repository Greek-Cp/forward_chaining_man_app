import 'package:get/get.dart';

/// Controller untuk HomePage
class HomeController extends GetxController {
  final Rx<bool?> pilihan =
      Rx<bool?>(null); // null=belum pilih; true=Kerja; false=Kuliah

  void setPilihan(bool? val) {
    pilihan.value = val;
  }
}
