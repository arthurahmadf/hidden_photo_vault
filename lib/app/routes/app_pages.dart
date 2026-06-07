import 'package:get/get.dart';

import '../modules/form_add_media/bindings/form_add_media_binding.dart';
import '../modules/form_add_media/views/form_add_media_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/media_viewer/bindings/media_viewer_binding.dart';
import '../modules/media_viewer/views/media_viewer_view.dart';
import '../modules/splashscreen/bindings/splashscreen_binding.dart';
import '../modules/splashscreen/views/splashscreen_view.dart';
import '../modules/vault/bindings/vault_binding.dart';
import '../modules/vault/views/vault_view.dart';

// ignore_for_file: constant_identifier_names

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASHSCREEN;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.SPLASHSCREEN,
      page: () => const SplashscreenView(),
      binding: SplashscreenBinding(),
    ),
    GetPage(
      name: _Paths.FORM_ADD_MEDIA,
      page: () => const FormAddMediaView(),
      binding: FormAddMediaBinding(),
    ),
    GetPage(
      name: _Paths.MEDIA_VIEWER,
      page: () => const MediaViewerView(),
      binding: MediaViewerBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.VAULT,
      page: () => const VaultView(),
      binding: VaultBinding(),
    ),
  ];
}
