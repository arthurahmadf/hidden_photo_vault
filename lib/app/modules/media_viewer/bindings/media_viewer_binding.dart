import 'package:get/get.dart';

import '../controllers/media_viewer_controller.dart';

class MediaViewerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MediaViewerController>(
      () => MediaViewerController(),
    );
  }
}
