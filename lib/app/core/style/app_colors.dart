import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF167B60);
  static const Color primary50 = Color(0xFFF3FFFB);
  static const Color primary100 = Color(0xFFD9FFF3);
  static const Color primary500 = Color(0xFF5CD4AC);
  static const Color primary600 = Color(0xFF47BA94);
  static const Color primary700 = Color(0xFF3A927B);
  static const Color primary800 = Color(0xFF47BA94);
  static const Color primary2 = Color(0xFF256E99);
  static const Color primaryDark = Color(0xFF5E35B1);
  static const Color primaryLight = Color(0xFF4D94FF);
  static const Color gradationEnd = Color.fromARGB(255, 231, 217, 14);
  
  // Secondary Colors
  static const Color secondary = Color(0xFFBDA700);
  static const Color secondary100 = Color(0xFFDDF3FF);
  static const Color secondaryDark = Color(0xFFCC8400);
  static const Color secondaryLight = Color(0xFFFFBF40);

  // Background Colors
  // static const Color background = Color.fromARGB(255, 241, 241, 241);
  static const Color background = Color(0xFFF9F9F9);
  static const Color backgroundAccent = Color.fromARGB(255, 230, 230, 230);
  static const Color backgroundDark = Color(0xFFE0E0E0);
  static const Color backgroundLight = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF999999);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textSubfont = Color(0xFF999999);

  // Icons
  static const Color iconPrimary = Color(0xFF757575);

  // Border Colors
  static const Color border = Color(0xFFE6E6E6);
  static const Color gray3 = Color(0xFFE6E6E6);
  static const Color borderDark = Color(0xFFBDBDBD);

  // MISC
  static const Color neutral4 = Color(0xFFF5F5F5);
  static const Color neutral100 = Color(0xFFEFEFEF);

  // Success, Warning, Error Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFFF3744);

  // Custom AppBar Colors
  static const Color appBarBackground = Colors.white;
  // static const Color appBarBackground = Color.fromARGB(255, 248, 248, 248);
  static const Color appBarTitle = Colors.white;
  static const Color appBarIcon = Colors.black54;

  // Chart Color gae "fl_chart" plugin
  static const Color chartRealization = Colors.green;
  static const Color chartPlan = Colors.lightBlue;

  // Button Colors
  static const Color buttonPrimary = Color(0xFF3A927B);
  static const Color buttonSecondary = secondary;
  static const Color buttonDisabled = Color(0xFFE6E6E6);

  // Menu Colors
  // static const Color menuBackground = primary;
  // static const Color menuIcon = Colors.white;
  // static const Color menuLabel = Colors.white;
  static const Color menuBackground = background;
  static const Color menuBorder = background;
  static const Color menuIcon = primary;
  static const Color menuLabel = primary;
}
