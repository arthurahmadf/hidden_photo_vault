import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/style/app_colors.dart';
import 'package:hidden_photo_vault/app/core/style/app_fonts.dart';
import 'package:hidden_photo_vault/app/data/services/vault_health_service.dart';
import 'package:hidden_photo_vault/app/modules/home/controllers/home_controller.dart';
import 'package:intl/intl.dart';

class VaultHealthView extends StatefulWidget {
  const VaultHealthView({super.key});

  @override
  State<VaultHealthView> createState() => _VaultHealthViewState();
}

class _VaultHealthViewState extends State<VaultHealthView> {
  final service = VaultHealthService();
  final home = Get.find<HomeController>();
  late Future<VaultHealthReport> report;
  bool isRunningAction = false;

  String get vaultId => home.selectedVault.value.id ?? 'public';

  @override
  void initState() {
    super.initState();
    report = service.inspect(vaultId);
  }

  void refresh() => setState(() => report = service.inspect(vaultId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.appBarTitle,
            size: 18.w,
          ),
          onPressed: Get.back,
        ),
        title: Text(
          'Vault Health',
          style: AppFonts.bold18.copyWith(color: AppColors.appBarTitle),
        ),
      ),
      body: FutureBuilder<VaultHealthReport>(
        future: report,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final value = snapshot.data!;
          return ListView(
            padding: EdgeInsets.symmetric(vertical: 16.w),
            children: [
              _HealthInfographic(report: value),
              20.verticalSpace,
              const _SectionHeader(title: 'Storage'),
              _HealthTile(
                icon: Icons.photo_library_outlined,
                title: 'Stored Media',
                subtitle:
                    '${value.activeItems} items · ${_formatBytes(value.activeBytes)}',
                status: 'Protected',
              ),
              _HealthTile(
                icon: value.missingFiles + value.orphanFiles == 0
                    ? Icons.verified_outlined
                    : Icons.warning_amber_rounded,
                title: 'File Integrity',
                subtitle: value.missingFiles + value.orphanFiles == 0
                    ? 'No missing or untracked encrypted files'
                    : '${value.missingFiles} missing · ${value.orphanFiles} orphaned',
                status: value.missingFiles + value.orphanFiles == 0
                    ? 'Healthy'
                    : 'Review',
                statusColor: value.missingFiles + value.orphanFiles == 0
                    ? AppColors.success
                    : AppColors.warning,
              ),
              _HealthTile(
                icon: Icons.cleaning_services_outlined,
                title: 'Temporary Storage',
                subtitle: _formatBytes(value.temporaryBytes),
                status: value.temporaryBytes == 0 ? 'Clean' : 'Available',
              ),
              12.verticalSpace,
              const _SectionHeader(title: 'Security & Recovery'),
              _HealthTile(
                icon: Icons.backup_outlined,
                title: 'Last Backup',
                subtitle: value.lastBackupAt == null
                    ? 'No successful backup recorded'
                    : DateFormat.yMMMd().add_jm().format(value.lastBackupAt!),
                status:
                    value.lastBackupAt == null ? 'Not backed up' : 'Recorded',
                statusColor: value.lastBackupAt == null
                    ? AppColors.warning
                    : AppColors.success,
              ),
              const _HealthTile(
                icon: Icons.enhanced_encryption_outlined,
                title: 'Encryption Format',
                subtitle: 'HVLT authenticated vault container',
                status: 'Version 1',
              ),
              _HealthTile(
                icon: Icons.delete_outline_rounded,
                title: 'Encrypted Trash',
                subtitle: value.trashItems == 0
                    ? 'Trash is empty'
                    : '${value.trashItems} items · removed after 7 days',
                status: '${value.trashItems}',
              ),
              12.verticalSpace,
              const _SectionHeader(title: 'Maintenance'),
              _ActionTile(
                icon: Icons.cleaning_services_outlined,
                title: 'Clean Temporary Storage',
                subtitle: 'Remove temporary and orphaned files',
                enabled: !isRunningAction,
                onTap: _cleanStorage,
              ),
              if (value.trashItems > 0) ...[
                _ActionTile(
                  icon: Icons.restore_rounded,
                  title: 'Restore Trash',
                  subtitle: 'Return all encrypted items to the gallery',
                  enabled: !isRunningAction,
                  onTap: _restoreTrash,
                ),
                _ActionTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Empty Trash Now',
                  subtitle: 'Permanently remove all trashed items',
                  enabled: !isRunningAction,
                  color: AppColors.error,
                  onTap: () => _confirmEmptyTrash(context),
                ),
              ],
              16.verticalSpace,
            ],
          );
        },
      ),
    );
  }

  Future<void> _runAction(Future<String> Function() action) async {
    if (isRunningAction) return;
    setState(() => isRunningAction = true);
    final message = await action();
    if (!mounted) return;
    setState(() {
      isRunningAction = false;
      report = service.inspect(vaultId);
    });
    Get.snackbar(
      'Vault Health',
      message,
      backgroundColor: AppColors.secondary,
      colorText: AppColors.textPrimary,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(16.w),
      borderRadius: 12.r,
    );
  }

  Future<void> _cleanStorage() => _runAction(() async {
        final count = await service.cleanup(vaultId);
        return '$count temporary or orphaned entries removed.';
      });

  Future<void> _restoreTrash() => _runAction(() async {
        final count = await service.restoreTrash(vaultId);
        await home.refreshImages();
        return '$count items restored.';
      });

  Future<void> _confirmEmptyTrash(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Empty Trash?',
          style: AppFonts.bold18.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'These encrypted files will be permanently deleted.',
          style: AppFonts.medium14.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction(() async {
      final count = await service.emptyTrash(vaultId);
      return '$count items permanently deleted.';
    });
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _HealthInfographic extends StatelessWidget {
  final VaultHealthReport report;

  const _HealthInfographic({required this.report});

  int get score {
    var result = 100;
    if (report.lastBackupAt == null) result -= 20;
    result -= (report.missingFiles * 30).clamp(0, 60);
    result -= (report.orphanFiles * 10).clamp(0, 20);
    if (report.temporaryBytes > 100 * 1024 * 1024) result -= 10;
    return result.clamp(0, 100);
  }

  String get label {
    if (score >= 90) return 'Excellent';
    if (score >= 70) return 'Good';
    return 'Needs attention';
  }

  Color get statusColor {
    if (score >= 90) return AppColors.success;
    if (score >= 70) return AppColors.primary;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final checks = <_HealthCheck>[
      _HealthCheck(
        'Files',
        report.missingFiles + report.orphanFiles == 0,
      ),
      _HealthCheck('Backup', report.lastBackupAt != null),
      _HealthCheck('Temp', report.temporaryBytes < 100 * 1024 * 1024),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 112.w,
            height: 112.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 9.w,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.surfaceHigh,
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: AppFonts.bold28.copyWith(
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      'HEALTH',
                      style: AppFonts.medium10.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          20.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.bold18.copyWith(color: AppColors.textPrimary),
                ),
                4.verticalSpace,
                Text(
                  score >= 90
                      ? 'Your vault checks look good.'
                      : 'Review the highlighted checks below.',
                  style: AppFonts.medium12.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                14.verticalSpace,
                ...checks.map((check) => Padding(
                      padding: EdgeInsets.only(bottom: 7.w),
                      child: Row(
                        children: [
                          Icon(
                            check.passed
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            size: 14.w,
                            color: check.passed
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          7.horizontalSpace,
                          Text(
                            check.label,
                            style: AppFonts.medium12.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthCheck {
  final String label;
  final bool passed;

  const _HealthCheck(this.label, this.passed);
}

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

class _HealthTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color? statusColor;

  const _HealthTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
      child: Row(
        children: [
          _TileIcon(icon: icon),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.bold14.copyWith(color: AppColors.textPrimary),
                ),
                2.verticalSpace,
                Text(
                  subtitle,
                  style: AppFonts.medium14.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          10.horizontalSpace,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.w),
            decoration: BoxDecoration(
              color: (statusColor ?? AppColors.primary).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              status,
              style: AppFonts.medium10.copyWith(
                color: statusColor ?? AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final Color? color;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.enabled,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
          child: Row(
            children: [
              _TileIcon(icon: icon, color: color),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.bold14.copyWith(
                        color: color ?? AppColors.textPrimary,
                      ),
                    ),
                    2.verticalSpace,
                    Text(
                      subtitle,
                      style: AppFonts.medium14.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20.w,
                color: color ?? AppColors.iconPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;

  const _TileIcon({required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? AppColors.iconPrimary;
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: foreground.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(icon, size: 18.w, color: foreground),
    );
  }
}
