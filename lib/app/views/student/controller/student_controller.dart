import 'package:forward_chaining_man_app/app/controllers/developer_controller.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

/// Controller untuk DeveloperModePage
class DeveloperModeController extends GetxController {
  final RxBool isDeveloperMode = developerMode.obs;

  void toggleDeveloperMode(bool value) {
    isDeveloperMode.value = value;
    developerMode = value;
  }
}
