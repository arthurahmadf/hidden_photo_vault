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

  AppSetting({
    this.gridItemCount = 4,
    this.preferTaggedView = true,
    this.exportDir = "/storage/emulated/0/Download",
  });

  AppSetting copyWith({
    int? gridItemCount,
    bool? preferTaggedView,
    String? exportDir,
  }) =>
      AppSetting(
        gridItemCount: gridItemCount ?? this.gridItemCount,
        preferTaggedView: preferTaggedView ?? this.preferTaggedView,
        exportDir: exportDir ?? this.exportDir,
      );
}
