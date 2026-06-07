import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/data/services/vault_service.dart';
import 'package:hidden_photo_vault/app/modules/home/controllers/home_controller.dart';
import 'package:uuid/uuid.dart';

class VaultController extends GetxController {
  final vs = VaultService();
  final home = Get.find<HomeController>();
  final _uuid = const Uuid();

  final pin = ''.obs;
  final isLoading = false.obs;
  final shakeNotifier = 0.obs; // increments to trigger shake

  static const _pinLength = 6;

  void onKeyTap(String key) {
    if (pin.value.length >= _pinLength) return;
    pin.value += key;
    if (pin.value.length == _pinLength) _onPinComplete();
  }

  void onBackspace() {
    if (pin.value.isEmpty) return;
    pin.value = pin.value.substring(0, pin.value.length - 1);
  }

  Future<void> _onPinComplete() async {
    isLoading.value = true;
    final entered = pin.value;

    final vault = vs.findVaultByPin(entered);
    if (vault != null) {
      home.selectedVault.value = vault;
      home.selectedVaultPin = entered;
      home.getImages();
      isLoading.value = false;
      Get.back(result: true);
    } else {
      // Decoy — silently create empty vault, shake, reset
      await vs.createVault(entered, 'Vault ${_uuid.v4().substring(0, 6)}');
      isLoading.value = false;
      shakeNotifier.value++; // triggers shake animation
      await Future.delayed(const Duration(milliseconds: 600));
      pin.value = '';
    }
  }
}
