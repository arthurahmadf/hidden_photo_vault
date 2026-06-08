import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/routes/app_pages.dart';

class SplashscreenController extends GetxController {
  @override
  void onReady() async {
    super.onReady();
    redirToHome();
  }

  void redirToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    Get.offAllNamed(Routes.HOME);
  }

  Future<void> cleanEmptyVaults()async{}
}
