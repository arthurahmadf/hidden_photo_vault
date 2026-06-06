// To parse this JSON data, do
//
//     final user = userFromJson(jsonString);

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

part 'user_model.g.dart';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

@HiveType(typeId: 1)
class User {
  @HiveField(0)
  int? id;
  @HiveField(1)
  String? username;
  @HiveField(2)
  String? name;
  @HiveField(3)
  String? email;
  @HiveField(4)
  String? alamat;
  @HiveField(5)
  String? jabatan;
  @HiveField(6)
  String? profilePicture;
  @HiveField(7)
  String? country;

  User({
    this.id,
    this.username,
    this.name,
    this.email,
    this.alamat,
    this.jabatan,
    this.profilePicture,
    this.country,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        username: json["username"],
        name: json["name"],
        email: json["email"],
        alamat: json["alamat"],
        jabatan: json["jabatan"],
        profilePicture: json["profile_picture"],
        country: json["country"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "name": name,
        "email": email,
        "alamat": alamat,
        "jabatan": jabatan,
        "profile_picture": profilePicture,
        "country": country,
      };
}
