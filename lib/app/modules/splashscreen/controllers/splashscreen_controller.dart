import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/routes/app_pages.dart';

import '../../../data/services/vault_service.dart';
import '../../../data/services/gallery_service.dart';
import '../../../core/services/sensitive_cache_service.dart';

class SplashscreenController extends GetxController {
  @override
  void onReady() async {
    super.onReady();
    await VaultService().cleanupEmptyVaults(
      gracePeriod: const Duration(hours: 12),
    );
    await GalleryService().purgeExpiredTrash();
    await SensitiveCacheService.clearPlaintextTemporaryFiles();
    redirToHome();
  }

  void redirToHome() async {
    Get.offAllNamed(Routes.HOME);
  }
}
