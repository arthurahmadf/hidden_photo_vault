import 'package:get/get.dart';

import '../controllers/app_setting_controller.dart';

class AppSettingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppSettingController>(
      () => AppSettingController(),
    );
  }
}
