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
  final shakeNotifier = 0.obs;

  static const _pinLength = 6;

  void onKeyTap(String key) {
    if (pin.value.length >= _pinLength) return;
    pin.value += key;
    if (pin.value.length == _pinLength) onPinSubmit(pin.value);
  }

  void onBackspace() {
    if (pin.value.isEmpty) return;
    pin.value = pin.value.substring(0, pin.value.length - 1);
  }

  void onPinSubmit(String pin) async {
    final vault = vs.findVaultByPin(pin);
    if (vault != null) {
      home.selectedVault.value = vault;
      home.selectedVaultPin = pin;
      home.update();
      Get.back(result: true);
    } else {
      var newVault = await vs.createVault(pin, 'Vault ${_uuid.v4().substring(0, 6)}');
      home.selectedVault.value = newVault;
      home.selectedVaultPin = pin;
      home.update();
      Get.back(result: true);
    }
  }
}
