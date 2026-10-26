import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/enums/load_state_enum.dart';
import 'package:hidden_photo_vault/app/core/helpers/dialog_helper.dart';
import 'package:hidden_photo_vault/app/core/helpers/logger_helper.dart';
import 'package:hidden_photo_vault/app/core/services/data_service.dart';
import 'package:hidden_photo_vault/app/core/services/dialog_service.dart';
import 'package:hidden_photo_vault/app/core/services/privacy_service.dart';
import 'package:hidden_photo_vault/app/core/services/sensitive_cache_service.dart';
import 'package:hidden_photo_vault/app/data/models/app_setting_model.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';
import 'package:hidden_photo_vault/app/data/models/vault_model.dart';
import 'package:hidden_photo_vault/app/data/services/gallery_service.dart';
import 'package:hidden_photo_vault/app/data/services/vault_crypto.dart';
import 'package:hidden_photo_vault/app/modules/media_viewer/arguments/view_media_argument.dart';
import 'package:hidden_photo_vault/app/routes/app_pages.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  final GalleryService gs = GalleryService();
  String get activeEncKey => selectedVault.value.id == 'public'
      ? GalleryService.publicKey
      : selectedVaultPin ?? GalleryService.publicKey;
  final galleryLoadState = LoadState.LOADING.obs;
  final images = <GalleryMedia>[].obs;
  final thumbCache = <String, Uint8List>{}.obs;
  final selectedVault = Vault(id: "public").obs;
  String? selectedVaultPin;
  final isGrouped = false.obs;
  bool isBusy = false;
  final gridCount = (DataService.setting.data?.gridItemCount ?? 4).obs;

  @override
  void onInit() {
    super.onInit();
    final s = DataService.setting.data ?? AppSetting();
    isGrouped.value = s.preferTaggedView;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    getImages();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Camera and file pickers can pause the app; keep the current vault open.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      thumbCache.clear();
      unawaited(
        SensitiveCacheService.clearPlaintextTemporaryFiles(
          includeActiveShares: false,
        ),
      );
    } else if (state == AppLifecycleState.resumed) {
      isBusy = false;
      if (images.isNotEmpty) {
        unawaited(buildThumbnailCache());
      }
    }
  }

  Map<String, List<GalleryMedia>> get groupedImages {
    final map = <String, List<GalleryMedia>>{};
    for (final img in images) {
      final tag = img.tag ?? 'default';
      map.putIfAbsent(tag, () => []).add(img);
    }
    return Map.fromEntries([
      if (map.containsKey('default')) MapEntry('default', map['default']!),
      ...map.entries.where((e) => e.key != 'default').toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    ]);
  }

  List<GalleryMedia> get visibleMediaOrder => isGrouped.value
      ? groupedImages.values.expand((items) => items).toList(growable: false)
      : images.toList(growable: false);

  Future<void> buildThumbnailCache() async {
    LoggerHelper.info(
        "building encrypted thumbnail cache | vaultId: ${selectedVault.value.id}");
    for (final img in images) {
      if (thumbCache.containsKey(img.id)) continue;
      try {
        final bytes = await gs.loadThumb(img,
            encryptionKey: selectedVaultPin ?? "public");
        thumbCache[img.id!] = bytes;
      } catch (_) {
        // A missing or unauthenticated thumbnail must not hide other media.
      }
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
    await buildThumbnailCache();
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
    final closingVaultId = selectedVault.value.id!;
    thumbCache.clear();
    if (Get.currentRoute != Routes.HOME) {
      Get.until((route) => route.settings.name == Routes.HOME);
    }
    selectedVault.value = Vault(id: "public");
    selectedVaultPin = null;
    VaultCrypto.lock(closingVaultId);
    await PrivacyService.setPrivateVaultOpen(false);
    getImages();
    update();
  }

  void onMediaTapped(GalleryMedia mediaMeta) async {
    final mediaIds = visibleMediaOrder
        .map((media) => media.id)
        .whereType<String>()
        .toList(growable: false);
    final tappedMediaId = mediaMeta.id;
    if (tappedMediaId == null) return;
    final initialIndex = mediaIds.indexOf(tappedMediaId);
    if (initialIndex < 0) return;

    Get.toNamed(Routes.MEDIA_VIEWER,
        arguments: ViewMediaArgument(
          initialIndex: initialIndex,
          mediaIds: mediaIds,
        ));
  }

  Future<void> onBackPressed(bool didPop, BuildContext context) async {
    if (didPop) return;

    final isVaultOpen = selectedVault.value.id != "public" &&
        selectedVaultPin != null &&
        selectedVaultPin != "public";

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
        SystemNavigator.pop();
      }
    }
  }

  void onSettingTapped() {
    Get.toNamed(Routes.APP_SETTING);
  }
}
