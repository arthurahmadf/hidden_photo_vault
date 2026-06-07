import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/enums/load_state_enum.dart';
import 'package:hidden_photo_vault/app/core/helpers/dialog_helper.dart';
import 'package:hidden_photo_vault/app/core/services/dialog_service.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';
import 'package:hidden_photo_vault/app/data/models/vault_model.dart';
import 'package:hidden_photo_vault/app/data/services/gallery_service.dart';
import 'package:hidden_photo_vault/app/modules/media_viewer/arguments/view_media_argument.dart';
import 'package:hidden_photo_vault/app/routes/app_pages.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  final GalleryService gs = GalleryService();
  final galleryLoadState = LoadState.LOADING.obs;
  final selectedVault = Vault(id: "public").obs;
  final images = <GalleryMedia>[].obs;
  final thumbCache = <String, Uint8List>{}.obs;
  final _vaultWasClosed = false.obs;
  String? selectedVaultPin;

  @override
  void onInit() {
    super.onInit();
    print("object");
    // WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    // WidgetsBinding.instance.removeObserver(this);
    print("object");
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    getImages();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.paused) {
  //     closeVault();
  //   } else if (state == AppLifecycleState.resumed) {
  //     if (_vaultWasClosed.value) {
  //       Get.snackbar('Vault Closed', 'Vault was closed for security.');
  //       _vaultWasClosed.value = false;
  //     }
  //   }
  // }

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

  void onVaultTapped() async {
    var needRefresh = await Get.toNamed(Routes.VAULT);
    if (needRefresh ?? false) {
      getImages();
    }
  }

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
      onPositive: () {
        closeDialog();
        closeVault();
      },
      negativeText: "Cancel",
      onNegative: closeDialog,
    );
  }

  void closeVault() async {
    if (selectedVault.value.id == "public") return;
    selectedVault.value = Vault(id: "public");
    getImages();
    _vaultWasClosed.value = true;
    update();
  }

  void onMediaTapped(GalleryMedia mediaMeta, int index) {
    Get.toNamed(Routes.MEDIA_VIEWER, arguments: ViewMediaArgument(initialIndex: index));
  }

  void onSettingTapped() {}
}
