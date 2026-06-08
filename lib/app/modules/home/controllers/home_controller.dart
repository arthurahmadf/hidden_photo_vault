import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/enums/load_state_enum.dart';
import 'package:hidden_photo_vault/app/core/helpers/dialog_helper.dart';
import 'package:hidden_photo_vault/app/core/helpers/logger_helper.dart';
import 'package:hidden_photo_vault/app/core/services/dialog_service.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';
import 'package:hidden_photo_vault/app/data/models/vault_model.dart';
import 'package:hidden_photo_vault/app/data/services/gallery_service.dart';
import 'package:hidden_photo_vault/app/modules/media_viewer/arguments/view_media_argument.dart';
import 'package:hidden_photo_vault/app/routes/app_pages.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  final GalleryService gs = GalleryService();
  String get activeEncKey =>
      selectedVault.value.id == 'public' ? GalleryService.publicKey : selectedVaultPin ?? GalleryService.publicKey;
  final galleryLoadState = LoadState.LOADING.obs;
  final images = <GalleryMedia>[].obs;
  final thumbCache = <String, Uint8List>{}.obs;
  final _vaultWasClosed = false.obs;
  final selectedVault = Vault(id: "public").obs;
  String? selectedVaultPin;

  @override
  void onInit() {
    super.onInit();
    print("object");
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    print("object");
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    getImages();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      closeVault();
    } else if (state == AppLifecycleState.resumed) {
      if (_vaultWasClosed.value) {
        LoggerHelper.info("Vault Closed on Background/Paused State");
        _vaultWasClosed.value = false;
      }
    }
  }

  Future<void> buildThumbnailCache() async {
    for (final img in images) {
      if (thumbCache.containsKey(img.id)) continue;

      final bytes = await gs.loadThumb(img, encryptionKey: selectedVaultPin ?? "public");
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
    selectedVaultPin = null;
    getImages();
    _vaultWasClosed.value = true;
    update();
  }

  void onMediaTapped(GalleryMedia mediaMeta, int index) {
    Get.toNamed(Routes.MEDIA_VIEWER, arguments: ViewMediaArgument(initialIndex: index));
  }

  Future<void> onBackPressed(bool didPop, BuildContext context) async {
    if (didPop) return;

    final isVaultOpen =
        selectedVault.value.id != "public" && selectedVaultPin != null && selectedVaultPin != "public";

    final result = await DialogService.showDoubleButtonDialog(
      title: isVaultOpen ? "Close Vault?" : "Exit App?",
      message: isVaultOpen
          ? "Are you sure you want to close the current vault?"
          : "Are you sure you want to close the app?",
      positiveText: isVaultOpen ? "Close Vault" : "Exit App",
      negativeText: isVaultOpen ? "Stay" : "Stay",
      onPositive: () => Get.back(result: true),
      onNegative: () => Get.back(result: false),
    );

    if (result == true) {
      if (isVaultOpen) {
        closeVault();
      } else if (context.mounted) {
        Navigator.of(context).pop();
        Get.back();
      }
    }
  }

  void onSettingTapped() {}
}
