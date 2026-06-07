import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/consts/app_icons.dart';
import 'package:hidden_photo_vault/app/core/style/app_fonts.dart';

import '../controllers/splashscreen_controller.dart';

class SplashscreenView extends GetView<SplashscreenController> {
  const SplashscreenView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: 1.sw,
        height: 1.sh,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppIcons.app_logo),
            12.verticalSpace,
            Text(
              "mY Gallery",
              style: AppFonts.bold18,
            )
          ],
        ),
      ),
    );
  }
}
