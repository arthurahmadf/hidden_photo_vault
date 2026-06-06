// To parse this JSON data, do
//
//     final auth = authFromJson(jsonString);

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

part 'auth_model.g.dart';

Auth authFromJson(String str) => Auth.fromJson(json.decode(str));

String authToJson(Auth data) => json.encode(data.toJson());

@HiveType(typeId: 0)
class Auth {
  @HiveField(0)
  String? refresh;
  @HiveField(1)
  String? access;
  @HiveField(2)
  bool stayLoggedIn;

  Auth({
    this.refresh,
    this.access,
    this.stayLoggedIn = true,
  });

  factory Auth.fromJson(Map<String, dynamic> json) => Auth(
        refresh: json["refresh"],
        access: json["access"],
      );

  Map<String, dynamic> toJson() => {
        "refresh": refresh,
        "access": access,
        "stayLoggedIn": stayLoggedIn,
      };
}
