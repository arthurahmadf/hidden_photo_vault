// To parse this JSON data, do
//
//     final vault = vaultFromJson(jsonString);

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

part 'vault_model.g.dart';

Vault vaultFromJson(String str) => Vault.fromJson(json.decode(str));

String vaultToJson(Vault data) => json.encode(data.toJson());

@HiveType(typeId: 3)
class Vault {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;
  @HiveField(2)
  String? pinHash;
  @HiveField(3)
  DateTime? createdAt;

  Vault({
    this.id,
    this.name,
    this.pinHash,
    this.createdAt,
  });

  Vault copyWith({
    String? id,
    String? name,
    String? pinHash,
    DateTime? createdAt,
  }) =>
      Vault(
        id: id ?? this.id,
        name: name ?? this.name,
        pinHash: pinHash ?? this.pinHash,
        createdAt: createdAt ?? this.createdAt,
      );

  factory Vault.fromJson(Map<String, dynamic> json) => Vault(
        id: json["id"],
        name: json["name"],
        pinHash: json["pinHash"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "pinHash": pinHash,
        "createdAt": createdAt?.toIso8601String(),
      };
}
