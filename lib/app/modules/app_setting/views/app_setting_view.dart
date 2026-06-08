// app_setting_view.dart
//
// Settings page — accessible from home app bar.
// Export: secret vault only, saves .hpv to Downloads.
// Import: always available, PIN pad bottom sheet → importVault().

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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.background, size: 18.w),
          onPressed: Get.back,
        ),
        title: Text('Settings', style: AppFonts.bold18.copyWith(color: AppColors.background)),
      ),
      body: Obx(() => ListView(
            padding: EdgeInsets.symmetric(vertical: 16.w),
            children: [
              // ── Vault section ───────────────────────────────────────────────
              const _SectionHeader(title: 'Vault'),

              // Export — secret vault only
              if (controller.isSecretVaultActive) ...[
                _SettingsTile(
                  icon: Icons.upload_outlined,
                  title: 'Export Vault',
                  subtitle: 'Save vault as .hpv file to Downloads',
                  onTap: controller.isExporting.value ? null : controller.onExportTapped,
                  trailing: controller.isExporting.value
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
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
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),

              SizedBox(height: 24.w),

              // ── App section ─────────────────────────────────────────────────
              const _SectionHeader(title: 'App'),

              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About',
                subtitle: 'Version info',
                onTap: () {}, // future
              ),
            ],
          )),
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
          color: AppColors.secondary.withOpacity(0.4),
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
                  color: AppColors.secondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 18.w, color: AppColors.secondary),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppFonts.bold14.copyWith(color: AppColors.secondary)),
                    2.verticalSpace,
                    Text(
                      subtitle,
                      style: AppFonts.medium14.copyWith(
                        color: AppColors.secondary.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20.w,
                    color: AppColors.secondary.withOpacity(0.3),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
