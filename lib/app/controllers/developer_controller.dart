import 'package:get/get.dart';

bool developerMode = false;

/// Controller untuk DeveloperModePage
class DeveloperModeController extends GetxController {
  final RxBool isDeveloperMode = developerMode.obs;

  void toggleDeveloperMode(bool value) {
    isDeveloperMode.value = value;
    developerMode = value;
  }
}
