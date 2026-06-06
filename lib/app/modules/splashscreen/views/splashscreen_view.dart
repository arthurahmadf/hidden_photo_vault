import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/consts/app_icons.dart';

import '../controllers/splashscreen_controller.dart';

class SplashscreenView extends GetView<SplashscreenController> {
  const SplashscreenView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(AppIcons.app_logo),
      ),
    );
  }
}
