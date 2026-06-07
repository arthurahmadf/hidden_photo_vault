import 'package:get/get.dart';

import '../controllers/form_add_media_controller.dart';

class FormAddMediaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FormAddMediaController>(
      () => FormAddMediaController(),
    );
  }
}
