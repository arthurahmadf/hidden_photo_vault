import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/enums/load_state_enum.dart';
import 'package:hidden_photo_vault/app/core/helpers/dialog_helper.dart';
import 'package:hidden_photo_vault/app/core/services/dialog_service.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';
import 'package:hidden_photo_vault/app/data/models/vault_model.dart';
import 'package:hidden_photo_vault/app/data/services/gallery_service.dart';
import 'package:hidden_photo_vault/app/modules/media_viewer/arguments/view_media_argument.dart';
import 'package:hidden_photo_vault/app/routes/app_pages.dart';

class HomeController extends GetxController {
  final GalleryService gs = GalleryService();
  final galleryLoadState = LoadState.LOADING.obs;
  final selectedVault = Vault(id: "public").obs;
  final images = <GalleryMedia>[].obs;
  final thumbCache = <String, Uint8List>{}.obs;

  @override
  void onReady() {
    super.onReady();
    getImages();
  }

  Future<void> buildThumbnailCache() async {
    for (final img in images) {
      if (thumbCache.containsKey(img.id)) continue;
      final bytes = await gs.loadThumb(img);
      thumbCache[img.id!] = bytes;
    }
    update();
  }

  void onAddMediaPressed() async {
    var needRefresh = await Get.toNamed(Routes.FORM_ADD_MEDIA);
    if (needRefresh ?? false) {
      getImages();
    }
  }

  void onVaultTapped() {}
  void getImages() async {
    galleryLoadState.value = LoadState.LOADING;
    var snapshot = await gs.getImages(selectedVault.value.id!);
    images.assignAll(snapshot);
    buildThumbnailCache();
  }

  Future<void> refreshImages() async {
    images.value = await gs.getImages(selectedVault.value.id ?? 'public');
  }

  void onCloseVaultTapped() {
    DialogService.showDoubleButtonDialog(
      title: "Confirmation",
      message: "Exit from hidden Vault?",
      positiveText: "Exit",
      onPositive: closeVault,
      negativeText: "Cancel",
      onNegative: closeDialog,
    );
  }

  void closeVault() async {
    selectedVault.value = Vault(id: "public");
    getImages();
  }

  void onMediaTapped(GalleryMedia mediaMeta, int index) {
    Get.toNamed(Routes.MEDIA_VIEWER, arguments: ViewMediaArgument(initialIndex: index));
  }
}
