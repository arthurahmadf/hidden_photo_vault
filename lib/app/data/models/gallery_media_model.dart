// To parse this JSON data, do
//
//     final galleryImage = galleryImageFromJson(jsonString);

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

part 'gallery_media_model.g.dart';

GalleryMedia galleryImageFromJson(String str) => GalleryMedia.fromJson(json.decode(str));

String galleryImageToJson(GalleryMedia data) => json.encode(data.toJson());

@HiveType(typeId: 4)
class GalleryMedia {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? filePath;
  @HiveField(2)
  String? thumbPath;
  @HiveField(3)
  String? originalName;
  @HiveField(4)
  String? mimeType;
  @HiveField(5)
  int? fileSize;
  @HiveField(6)
  DateTime? importedAt;
  @HiveField(7)
  String? vaultId;
  @HiveField(8)
  String? tag;
  @HiveField(9)
  int? durationMs;
  @HiveField(10)
  int? width;
  @HiveField(11)
  int? height;

  GalleryMedia({
    this.id,
    this.filePath,
    this.thumbPath,
    this.originalName,
    this.mimeType,
    this.fileSize,
    this.importedAt,
    this.vaultId,
    this.tag,
    this.durationMs,
    this.width,
    this.height,
  });

  bool get isVideo => mimeType?.toLowerCase().startsWith('video/') ?? false;

  bool get isGif => mimeType?.toLowerCase() == 'image/gif';

  GalleryMedia copyWith({
    String? id,
    String? filePath,
    String? thumbPath,
    String? originalName,
    String? mimeType,
    int? fileSize,
    DateTime? importedAt,
    String? vaultId,
    String? tag,
    int? durationMs,
    int? width,
    int? height,
  }) =>
      GalleryMedia(
        id: id ?? this.id,
        filePath: filePath ?? this.filePath,
        thumbPath: thumbPath ?? this.thumbPath,
        originalName: originalName ?? this.originalName,
        mimeType: mimeType ?? this.mimeType,
        fileSize: fileSize ?? this.fileSize,
        importedAt: importedAt ?? this.importedAt,
        vaultId: vaultId ?? this.vaultId,
        tag: tag ?? this.tag,
        durationMs: durationMs ?? this.durationMs,
        width: width ?? this.width,
        height: height ?? this.height,
      );

  factory GalleryMedia.fromJson(Map<String, dynamic> json) => GalleryMedia(
        id: json["id"],
        filePath: json["filePath"],
        thumbPath: json["thumbPath"],
        originalName: json["originalName"],
        mimeType: json["mimeType"],
        fileSize: json["fileSize"],
        importedAt: json["importedAt"] == null ? null : DateTime.parse(json["importedAt"]),
        vaultId: json["vaultId"],
        tag: json["tag"],
        durationMs: json["durationMs"],
        width: json["width"],
        height: json["height"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "filePath": filePath,
        "thumbPath": thumbPath,
        "originalName": originalName,
        "mimeType": mimeType,
        "fileSize": fileSize,
        "importedAt": importedAt?.toIso8601String(),
        "vaultId": vaultId,
        "tag": tag,
        "durationMs": durationMs,
        "width": width,
        "height": height,
      };
}
