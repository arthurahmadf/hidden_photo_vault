import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/helpers/dialog_helper.dart';
import 'package:hidden_photo_vault/app/core/helpers/logger_helper.dart';
import 'package:hidden_photo_vault/app/core/services/dialog_service.dart';
import 'package:hidden_photo_vault/app/core/services/media_picker_service.dart';
import 'package:hidden_photo_vault/app/data/services/gallery_service.dart';
import 'package:hidden_photo_vault/app/modules/home/controllers/home_controller.dart';
import 'package:image_picker/image_picker.dart';

class FormAddMediaController extends GetxController {
  final GalleryService gs = GalleryService();
  final HomeController homeController = Get.find<HomeController>();
  final tagTextController = TextEditingController();
  XFile? file;
  MediaType? mediaType;

  void onSaveMediaPressed() async {
    if (file == null) return;
    DialogService.showLoading(dismissible: false);
    LoggerHelper.info("vaultId: ${homeController.selectedVault.value.id}");
    try {
      var isSuccess = await gs.insertMedia(
        file!,
        mediaType ?? MediaType.image,
        homeController.selectedVault.value.id ?? "public",
        tag: tagTextController.text.trim().isNotEmpty
            ? tagTextController.text.trim()
            : "default",
      );
      if (isSuccess) {
        closeDialog();
        Get.back(result: true);
        return;
      }
      LoggerHelper.info("Something went wrong pas saving gallery $isSuccess");
      closeDialog();
      Get.snackbar(
          'Could not save media', 'The selected format could not be imported.');
    } catch (e) {
      LoggerHelper.info(
          "Something went wrong pas saving gallery catched error ${e.toString()}");
      closeDialog();
      Get.snackbar('Could not save media', 'Please try another file.');
    }
  }

  @override
  void onClose() {
    tagTextController.dispose();
    super.onClose();
  }
}
