// To parse this JSON data, do
//
//     final pageLog = pageLogFromJson(jsonString);

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

part 'page_log_model.g.dart';

List<PageLog> pageLogFromJson(String str) => List<PageLog>.from(json.decode(str).map((x) => PageLog.fromJson(x)));

String pageLogToJson(List<PageLog> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

@HiveType(typeId: 12)
class PageLog {
  @HiveField(0)
  String? pageId;
  @HiveField(1)
  int? userId;
  @HiveField(2)
  DateTime? openedAt;

  PageLog({
    this.pageId,
    this.userId,
    this.openedAt,
  });

  factory PageLog.fromJson(Map<String, dynamic> json) => PageLog(
        pageId: json["page_id"],
        userId: json["user_id"],
        openedAt: json["opened_at"] == null ? null : DateTime.parse(json["opened_at"]),
      );

  Map<String, dynamic> toJson() => {
        "page_id": pageId,
        "user_id": userId,
        "opened_at": openedAt?.toIso8601String(),
      };
}
