import 'package:hive_flutter/hive_flutter.dart';

part 'app_setting_model.g.dart';

@HiveType(typeId: 5)
class AppSetting {
  @HiveField(0)
  int? gridItemCount;
  @HiveField(1)
  bool preferTaggedView;
  @HiveField(2)
  String exportDir;
  @HiveField(3)
  DateTime? lastBackupAt;

  AppSetting({
    this.gridItemCount = 4,
    this.preferTaggedView = true,
    this.exportDir = "/storage/emulated/0/Download",
    this.lastBackupAt,
  });

  AppSetting copyWith({
    int? gridItemCount,
    bool? preferTaggedView,
    String? exportDir,
    DateTime? lastBackupAt,
  }) =>
      AppSetting(
        gridItemCount: gridItemCount ?? this.gridItemCount,
        preferTaggedView: preferTaggedView ?? this.preferTaggedView,
        exportDir: exportDir ?? this.exportDir,
        lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      );
}
