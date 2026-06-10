import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/style/app_colors.dart';
import 'package:hidden_photo_vault/app/core/style/app_fonts.dart';

import '../controllers/app_setting_controller.dart';

class AppSettingView extends GetView<AppSettingController> {
  const AppSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.appBarTitle, size: 18.w),
          onPressed: Get.back,
        ),
        title: Text('Settings', style: AppFonts.bold18.copyWith(color: AppColors.appBarTitle)),
      ),
      body: Obx(() => ListView(
            padding: EdgeInsets.symmetric(vertical: 16.w),
            children: [
              // ── Vault section ───────────────────────────────────────────────
              const _SectionHeader(title: 'Vault'),

              if (controller.isSecretVaultActive) ...[
                // Rename vault — inline
                _RenameVaultTile(controller: controller),

                // Change PIN
                _SettingsTile(
                  icon: Icons.pin_outlined,
                  title: 'Change PIN',
                  subtitle: 'Update your vault PIN',
                  onTap: controller.isChangingPin.value ? null : controller.onChangePinTapped,
                  trailing: controller.isChangingPin.value
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : null,
                ),

                // Export
                _SettingsTile(
                  icon: Icons.upload_outlined,
                  title: 'Export Vault',
                  subtitle: 'Save vault as .hpv file to Downloads',
                  onTap: controller.isExporting.value ? null : controller.onExportTapped,
                  trailing: controller.isExporting.value
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : null,
                ),

                // Export and Share
                _SettingsTile(
                  icon: Icons.share_outlined,
                  title: 'Export and Share Vault',
                  subtitle: 'Share .hpv via Drive, WhatsApp, etc.',
                  onTap: controller.isExporting.value ? null : controller.onShareVaultTapped,
                  trailing: controller.isExporting.value
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : null,
                ),
              ],

              // Import — always shown
              _SettingsTile(
                icon: Icons.download_outlined,
                title: 'Import Vault',
                subtitle: 'Restore a .hpv backup file',
                onTap: controller.isImporting.value ? null : controller.onImportTapped,
                trailing: controller.isImporting.value
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : null,
              ),

              const _SectionHeader(title: 'Display'),

              // Grid columns
              Obx(() {
                final current = controller.setting.value.gridItemCount;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(Icons.grid_view_rounded, size: 18.w, color: AppColors.iconPrimary),
                      ),
                      12.horizontalSpace,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Grid Columns', style: AppFonts.bold14.copyWith(color: AppColors.textPrimary)),
                            2.verticalSpace,
                            Text('$current columns',
                                style: AppFonts.medium14.copyWith(
                                  color: AppColors.textPrimary.withOpacity(0.5),
                                  fontSize: 12,
                                )),
                          ],
                        ),
                      ),
                      // stepper -/+
                      Row(
                        children: [
                          GestureDetector(
                            onTap: current! > 2 ? () => controller.updateGridCount(current - 1) : null,
                            child: Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(current > 2 ? 0.08 : 0.03),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Icon(Icons.remove,
                                  size: 16.w, color: AppColors.iconPrimary.withOpacity(current > 2 ? 1 : 0.2)),
                            ),
                          ),
                          12.horizontalSpace,
                          GestureDetector(
                            onTap: current < 6 ? () => controller.updateGridCount(current + 1) : null,
                            child: Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(current < 6 ? 0.08 : 0.03),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Icon(Icons.add,
                                  size: 16.w, color: AppColors.iconPrimary.withOpacity(current < 6 ? 1 : 0.2)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              // Tagged view toggle
              Obx(() => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(Icons.label_rounded, size: 18.w, color: AppColors.iconPrimary),
                        ),
                        12.horizontalSpace,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Group by Tag', style: AppFonts.bold14.copyWith(color: AppColors.textPrimary)),
                              2.verticalSpace,
                              Text('Show images grouped by tag',
                                  style: AppFonts.medium14.copyWith(
                                    color: AppColors.textPrimary.withOpacity(0.5),
                                    fontSize: 12,
                                  )),
                            ],
                          ),
                        ),
                        Switch(
                          value: controller.setting.value.preferTaggedView,
                          onChanged: controller.toggleTaggedView,
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  )),

              // Export directory
              _ExportDirTile(controller: controller),
              // ── App section ─────────────────────────────────────────────────
              const _SectionHeader(title: 'App'),

              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About',
                subtitle: 'Version info',
                onTap: () {},
              ),
            ],
          )),
    );
  }
}

class _ExportDirTile extends StatelessWidget {
  final AppSettingController controller;
  const _ExportDirTile({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dir = controller.setting.value.exportDir;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.folder_outlined, size: 18.w, color: AppColors.iconPrimary),
            ),
            12.horizontalSpace,
            Expanded(
              child: GestureDetector(
                onTap: () => _editDir(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Export Directory', style: AppFonts.bold14.copyWith(color: AppColors.primary)),
                    2.verticalSpace,
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dir,
                            style: AppFonts.medium14.copyWith(
                              color: AppColors.primary.withOpacity(0.5),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        4.horizontalSpace,
                        Icon(Icons.edit_outlined, size: 12.w, color: AppColors.secondary.withOpacity(0.3)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _editDir(BuildContext context) {
    final tc = TextEditingController(text: controller.setting.value.exportDir);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export Directory'),
        content: TextField(
          controller: tc,
          decoration: const InputDecoration(hintText: '/storage/emulated/0/Download'),
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.updateExportDir(tc.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline rename tile
// ─────────────────────────────────────────────────────────────────────────────

class _RenameVaultTile extends StatelessWidget {
  final AppSettingController controller;
  const _RenameVaultTile({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.drive_file_rename_outline_rounded, size: 18.w, color: AppColors.secondary),
          ),
          12.horizontalSpace,
          Expanded(
            child: Obx(() => controller.isRenamingVault.value
                ? SizedBox(
                    height: 36.w,
                    child: TextField(
                      controller: controller.renameTextController,
                      autofocus: true,
                      onSubmitted: (_) => controller.saveVaultName(),
                      onTapOutside: (_) => controller.saveVaultName(),
                      style: AppFonts.bold14.copyWith(color: AppColors.secondary),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.w),
                        filled: true,
                        fillColor: AppColors.secondary.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: GestureDetector(
                          onTap: controller.saveVaultName,
                          child: Icon(Icons.check_rounded, color: AppColors.primary, size: 18.w),
                        ),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: controller.startRenamingVault,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vault Name', style: AppFonts.bold14.copyWith(color: AppColors.secondary)),
                        2.verticalSpace,
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                controller.home.selectedVault.value.name ?? 'Unnamed',
                                style: AppFonts.medium14.copyWith(
                                  color: AppColors.secondary.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            4.horizontalSpace,
                            Icon(Icons.edit_outlined, size: 12.w, color: AppColors.secondary.withOpacity(0.3)),
                          ],
                        ),
                      ],
                    ),
                  )),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 8.w, top: 4.w),
      child: Text(
        title.toUpperCase(),
        style: AppFonts.medium14.copyWith(
          color: AppColors.textPrimary.withOpacity(0.6),
          letterSpacing: 1.2,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings tile
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 18.w, color: AppColors.iconPrimary),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppFonts.bold14.copyWith(color: AppColors.primary)),
                    2.verticalSpace,
                    Text(
                      subtitle,
                      style: AppFonts.medium14.copyWith(
                        color: AppColors.primary.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(Icons.chevron_right_rounded, size: 20.w, color: AppColors.iconPrimary.withOpacity(1)),
            ],
          ),
        ),
      ),
    );
  }
}
