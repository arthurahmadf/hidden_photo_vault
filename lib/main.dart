import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/core/services/data_service.dart';
import 'app/core/services/flavor/flavor_banner.dart';
import 'app/core/services/flavor/flavor_service.dart';
import 'app/core/style/app_theme.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DataService.init();
  await initializeDateFormatting('id_ID', null);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  const flavorString = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  final flavor = FlavorService.fromString(flavorString);
  FlavorService(
    flavor: flavor,
    name: FlavorService.getFlavorName(flavor),
    apiBaseUrl: FlavorService.getBaseUrl(flavor),
  );
  runApp(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (context, child) {
        return FlavorBanner(
          flavor: flavor.name,
          child: GetMaterialApp(
            title: "mY Gallery",
            initialRoute: AppPages.INITIAL,
            locale: const Locale('id', 'ID'),
            fallbackLocale: const Locale('id', 'ID'),
            getPages: AppPages.routes,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.lightTheme,
            defaultTransition: Transition.rightToLeft,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('id', 'ID'),
            ],
          ),
        );
      },
    ),
  );
}
