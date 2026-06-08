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
import 'package:hidden_photo_vault/app/data/services/vault_service.dart';
import 'package:hidden_photo_vault/app/modules/home/controllers/home_controller.dart';

class AppSettingController extends GetxController {
  final HomeController home = Get.find<HomeController>();
  final vs = VaultService();

  final isExporting = false.obs;
  final isImporting = false.obs;

  bool get isSecretVaultActive => home.selectedVault.value.id != 'public';

  // ── Export ──────────────────────────────────────────────────────────────────

  Future<void> onExportTapped() async {
    if (!isSecretVaultActive) return;
    final vault = home.selectedVault.value;
    final pin = home.selectedVaultPin;
    if (pin == null) return;

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
      await home.refreshImages();
      _showSnack('Import successful', '"${vault.name}" has been restored.');
    } catch (e) {
      _showSnack('Import failed', e.toString(), isError: true);
    } finally {
      isImporting.value = false;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _showSnack(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: isError ? AppColors.error : AppColors.secondary,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(16.w),
      borderRadius: 12.r,
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
