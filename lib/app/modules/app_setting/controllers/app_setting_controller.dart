// app_setting_controller.dart
//
// Dependencies (add if not already in pubspec.yaml):
//   file_picker: ^8.1.2
//   permission_handler: ^11.3.1  (already in project)

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/style/app_colors.dart';
import 'package:hidden_photo_vault/app/core/style/app_fonts.dart';
import 'package:hidden_photo_vault/app/data/models/app_setting_model.dart';
import 'package:hidden_photo_vault/app/data/services/vault_service.dart';
import 'package:hidden_photo_vault/app/modules/home/controllers/home_controller.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/data_service.dart';

class AppSettingController extends GetxController {
  final HomeController home = Get.find<HomeController>();
  final vs = VaultService();

  final isExporting = false.obs;
  final isImporting = false.obs;
  final isChangingPin = false.obs;
  final isRenamingVault = false.obs;
  final setting = Rx<AppSetting>(AppSetting());

  late final TextEditingController renameTextController;

  @override
  void onInit() {
    super.onInit();
    renameTextController = TextEditingController();
    setting.value = DataService.setting.data ?? AppSetting();
  }

  @override
  void onClose() {
    renameTextController.dispose();
    super.onClose();
  }

  bool get isSecretVaultActive => home.selectedVault.value.id != 'public';

  void updateGridCount(int count) {
    setting.value = setting.value.copyWith(gridItemCount: count);
    DataService.setting.data = setting.value;
    home.gridCount.value = count;
    home.update();
  }

  void toggleTaggedView(bool value) {
    setting.value = setting.value.copyWith(preferTaggedView: value);
    DataService.setting.data = setting.value;
    home.isGrouped.value = value;
  }

  void updateExportDir(String dir) {
    setting.value = setting.value.copyWith(exportDir: dir.trim());
    DataService.setting.data = setting.value;
  }

  // ── Rename vault ────────────────────────────────────────────────────────────

  void startRenamingVault() {
    renameTextController.text = home.selectedVault.value.name ?? '';
    renameTextController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: renameTextController.text.length,
    );
    isRenamingVault.value = true;
  }

  Future<void> saveVaultName() async {
    if (!isRenamingVault.value) return;
    isRenamingVault.value = false;

    final newName = renameTextController.text.trim();
    if (newName.isEmpty || newName == home.selectedVault.value.name) return;

    final success = await vs.renameVault(home.selectedVault.value, newName);
    if (success) {
      // Update reactive vault in HomeController
      home.selectedVault.value = home.selectedVault.value.copyWith(name: newName);
      home.selectedVault.refresh();
      _showSnack('Renamed', 'Vault renamed to "$newName".');
      home.update();
    } else {
      _showSnack('Error', 'Could not rename vault.', isError: true);
    }
  }

  // ── Change PIN ──────────────────────────────────────────────────────────────

  void onChangePinTapped() {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ChangePinSheet(
        onPinsConfirmed: (oldPin, newPin) => _doChangePin(oldPin, newPin),
      ),
    );
  }

  Future<void> _doChangePin(String oldPin, String newPin) async {
    isChangingPin.value = true;
    try {
      final success = await vs.changePin(home.selectedVault.value, oldPin, newPin);
      if (success) {
        // Update session PIN so future decryption uses new key
        home.selectedVaultPin = newPin;
        _showSnack('PIN changed', 'Your vault PIN has been updated.');
      } else {
        _showSnack('Error', 'Current PIN is incorrect.', isError: true);
      }
    } catch (e) {
      _showSnack('Error', e.toString(), isError: true);
    } finally {
      isChangingPin.value = false;
    }
  }
  // ── Export ──────────────────────────────────────────────────────────────────

  Future<void> onExportTapped() async {
    if (!isSecretVaultActive) return;
    final vault = home.selectedVault.value;
    final pin = home.selectedVaultPin;
    if (pin == null) return;
    if (home.images.isEmpty) {
      _showSnack('Nothing to export', 'Add some images to this vault first.');
      return;
    }
    isExporting.value = true;
    try {
      // Generate .hpv file
      final hpvFile = await vs.exportVault(vault, pin);
      if (hpvFile == null) {
        _showSnack('Export failed', 'Could not generate export file.', isError: true);
        return;
      }

      // Save to Downloads
      final saved = await _saveToDownloads(hpvFile);
      if (saved != null) {
        _showSnack('Export successful', 'Saved to Downloads: ${saved.path.split('/').last}');
      } else {
        _showSnack('Export failed', 'Could not save to Downloads.', isError: true);
      }
    } catch (e) {
      _showSnack('Export failed', e.toString(), isError: true);
    } finally {
      isExporting.value = false;
    }
  }

  // ── Export and Share ──────────────────────────────────────────────────────────────────
  Future<void> onShareVaultTapped() async {
    if (!isSecretVaultActive) return;
    final vault = home.selectedVault.value;
    final pin = home.selectedVaultPin;
    if (pin == null) return;
    if (home.images.isEmpty) {
      _showSnack('Nothing to export', 'Add some images to this vault first.');
      return;
    }
    isExporting.value = true;
    try {
      final hpvFile = await vs.exportVault(vault, pin);
      if (hpvFile == null) {
        _showSnack('Export failed', 'Could not generate export file.', isError: true);
        return;
      }
      await Share.shareXFiles(
        [XFile(hpvFile.path)],
        subject: '${vault.name} vault backup',
      );
    } catch (e) {
      _showSnack('Export failed', e.toString(), isError: true);
    } finally {
      isExporting.value = false;
    }
  }

  // ── Save to Download ──────────────────────────────────────────────────────────────────

  Future<File?> _saveToDownloads(File hpvFile) async {
    try {
      const downloadsPath = '/storage/emulated/0/Download';
      final downloadsDir = Directory(downloadsPath);
      if (!await downloadsDir.exists()) await downloadsDir.create(recursive: true);

      final fileName = hpvFile.path.split('/').last;
      final dest = File('$downloadsPath/$fileName');
      return await hpvFile.copy(dest.path);
    } catch (_) {
      return null;
    }
  }

  // ── Import ──────────────────────────────────────────────────────────────────

  Future<void> onImportTapped() async {
    // 1. Pick .hpv file
    home.isBusy = true;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    if (!path.endsWith('.hpv')) {
      _showSnack('Invalid file', 'Please select a .hpv file.', isError: true);
      return;
    }
    final hpvFile = File(result.files.single.path!);

    // 2. Show PIN pad bottom sheet
    if (!Get.context!.mounted) return;
    _showImportPinSheet(hpvFile);
  }

  void _showImportPinSheet(File hpvFile) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ImportPinSheet(
        onPinEntered: (pin) => _doImport(hpvFile, pin),
      ),
    );
  }

  Future<void> _doImport(File hpvFile, String pin) async {
    isImporting.value = true;
    try {
      final vault = await vs.importVault(hpvFile, pin);
      if (vault == null) {
        _showSnack('Import failed', 'Wrong PIN or corrupted file.', isError: true);
        return;
      }
      // Refresh home if the imported vault matches current active vault
      home.closeVault();
      _showSnack('Import successful', '"${vault.name}" has been restored.');
    } catch (e) {
      _showSnack('Import failed', e.toString(), isError: true);
    } finally {
      isImporting.value = false;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _showSnack(String title, String message, {bool isError = false}) {
    Get.snackbar(title, message,
        backgroundColor: isError ? AppColors.error : AppColors.secondary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(16.w),
        borderRadius: 12.r,
        duration: const Duration(seconds: 1));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Change PIN bottom sheet — two step: old PIN → new PIN
// ─────────────────────────────────────────────────────────────────────────────

enum _ChangePinStep { oldPin, newPin }

class _ChangePinSheet extends StatefulWidget {
  final Future<void> Function(String oldPin, String newPin) onPinsConfirmed;
  const _ChangePinSheet({required this.onPinsConfirmed});

  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  _ChangePinStep _step = _ChangePinStep.oldPin;
  String _oldPin = '';
  String _newPin = '';
  bool _loading = false;
  static const _pinLength = 6;

  void _onKeyTap(String key) {
    if (_loading) return;
    if (_step == _ChangePinStep.oldPin && _oldPin.length >= _pinLength) return;
    if (_step == _ChangePinStep.newPin && _newPin.length >= _pinLength) return;

    setState(() {
      if (_step == _ChangePinStep.oldPin) {
        _oldPin += key;
        if (_oldPin.length == _pinLength) _onOldPinComplete();
      } else {
        _newPin += key;
        if (_newPin.length == _pinLength) _onNewPinComplete();
      }
    });
  }

  void _onBackspace() {
    if (_loading) return;
    setState(() {
      if (_step == _ChangePinStep.oldPin && _oldPin.isNotEmpty) {
        _oldPin = _oldPin.substring(0, _oldPin.length - 1);
      } else if (_step == _ChangePinStep.newPin && _newPin.isNotEmpty) {
        _newPin = _newPin.substring(0, _newPin.length - 1);
      }
    });
  }

  void _onOldPinComplete() {
    // Advance to new PIN step after short delay so user sees 6 filled dots
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _step = _ChangePinStep.newPin);
    });
  }

  Future<void> _onNewPinComplete() async {
    setState(() => _loading = true);
    await widget.onPinsConfirmed(_oldPin, _newPin);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isOldStep = _step == _ChangePinStep.oldPin;
    final filledCount = isOldStep ? _oldPin.length : _newPin.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.only(
        top: 16.w,
        left: 24.w,
        right: 24.w,
        bottom: MediaQuery.of(context).padding.bottom + 32.w,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40.w,
            height: 4.w,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          24.verticalSpace,

          Icon(Icons.lock_reset_rounded, size: 40.w, color: AppColors.primary),
          16.verticalSpace,

          // Step title animates between steps
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Column(
              key: ValueKey(_step),
              children: [
                Text(
                  isOldStep ? 'Current PIN' : 'New PIN',
                  style: AppFonts.bold18.copyWith(color: AppColors.secondary),
                ),
                8.verticalSpace,
                Text(
                  isOldStep ? 'Enter your current PIN to continue' : 'Enter your new 6-digit PIN',
                  style: AppFonts.medium14.copyWith(color: AppColors.secondary.withOpacity(0.5)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          32.verticalSpace,

          // Step indicator pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepPill(active: isOldStep, done: !isOldStep),
              8.horizontalSpace,
              _StepPill(active: !isOldStep, done: false),
            ],
          ),

          24.verticalSpace,

          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pinLength, (i) {
              final filled = i < filledCount;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.symmetric(horizontal: 10.w),
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: filled ? AppColors.primary : AppColors.secondary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              );
            }),
          ),

          40.verticalSpace,

          // Numpad or loading
          if (_loading)
            SizedBox(
              height: 200.w,
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else
            _buildNumpad(),
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          _numpadRow(['1', '2', '3']),
          12.verticalSpace,
          _numpadRow(['4', '5', '6']),
          12.verticalSpace,
          _numpadRow(['7', '8', '9']),
          12.verticalSpace,
          Row(
            children: [
              const Expanded(child: SizedBox()),
              12.horizontalSpace,
              Expanded(child: _numKey('0')),
              12.horizontalSpace,
              Expanded(child: _iconKey(Icons.backspace_outlined, _onBackspace)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numpadRow(List<String> keys) {
    return Row(
      children: keys.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: e.key == 0 ? 0 : 12.w),
            child: _numKey(e.value),
          ),
        );
      }).toList(),
    );
  }

  Widget _numKey(String label) {
    return Material(
      color: AppColors.secondary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: () => _onKeyTap(label),
        borderRadius: BorderRadius.circular(16.r),
        child: SizedBox(
          height: 56.w,
          child: Center(child: Text(label, style: AppFonts.bold18.copyWith(color: AppColors.secondary))),
        ),
      ),
    );
  }

  Widget _iconKey(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.secondary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: SizedBox(
          height: 56.w,
          child: Center(child: Icon(icon, size: 20.w, color: AppColors.secondary)),
        ),
      ),
    );
  }
}

// Step indicator pill
class _StepPill extends StatelessWidget {
  final bool active;
  final bool done;
  const _StepPill({required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 24.w : 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        color: done || active ? AppColors.primary : AppColors.secondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Import PIN bottom sheet — reuses your PIN pad style
// ─────────────────────────────────────────────────────────────────────────────

class _ImportPinSheet extends StatefulWidget {
  final Future<void> Function(String pin) onPinEntered;
  const _ImportPinSheet({required this.onPinEntered});

  @override
  State<_ImportPinSheet> createState() => _ImportPinSheetState();
}

class _ImportPinSheetState extends State<_ImportPinSheet> {
  String _pin = '';
  bool _loading = false;
  static const _pinLength = 6;

  void _onKeyTap(String key) {
    if (_pin.length >= _pinLength || _loading) return;
    setState(() => _pin += key);
    if (_pin.length == _pinLength) _onPinComplete();
  }

  void _onBackspace() {
    if (_pin.isEmpty || _loading) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onPinComplete() async {
    setState(() => _loading = true);
    await widget.onPinEntered(_pin);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.only(
        top: 16.w,
        left: 24.w,
        right: 24.w,
        bottom: MediaQuery.of(context).padding.bottom + 32.w,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40.w,
            height: 4.w,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          24.verticalSpace,

          Icon(Icons.lock_outline_rounded, size: 40.w, color: AppColors.primary),
          16.verticalSpace,
          Text('Enter Vault PIN', style: AppFonts.bold18.copyWith(color: AppColors.secondary)),
          8.verticalSpace,
          Text(
            'Enter the PIN used to encrypt this vault',
            style: AppFonts.medium14.copyWith(color: AppColors.secondary.withOpacity(0.5)),
            textAlign: TextAlign.center,
          ),
          32.verticalSpace,

          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pinLength, (i) {
              final filled = i < _pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.symmetric(horizontal: 10.w),
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: filled ? AppColors.primary : AppColors.secondary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              );
            }),
          ),

          40.verticalSpace,

          // Numpad
          if (_loading)
            SizedBox(
              height: 200.w,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else
            _buildNumpad(),
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          _numpadRow(['1', '2', '3']),
          12.verticalSpace,
          _numpadRow(['4', '5', '6']),
          12.verticalSpace,
          _numpadRow(['7', '8', '9']),
          12.verticalSpace,
          Row(
            children: [
              const Expanded(child: SizedBox()),
              12.horizontalSpace,
              Expanded(child: _numKey('0')),
              12.horizontalSpace,
              Expanded(
                child: _iconKey(Icons.backspace_outlined, _onBackspace),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numpadRow(List<String> keys) {
    return Row(
      children: keys.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: e.key == 0 ? 0 : 12.w),
            child: _numKey(e.value),
          ),
        );
      }).toList(),
    );
  }

  Widget _numKey(String label) {
    return Material(
      color: AppColors.secondary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: () => _onKeyTap(label),
        borderRadius: BorderRadius.circular(16.r),
        child: SizedBox(
          height: 56.w,
          child: Center(
            child: Text(
              label,
              style: AppFonts.bold18.copyWith(color: AppColors.secondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconKey(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.secondary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: SizedBox(
          height: 56.w,
          child: Center(
            child: Icon(icon, size: 20.w, color: AppColors.secondary),
          ),
        ),
      ),
    );
  }
}
