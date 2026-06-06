import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  // Font Family Reference
  static TextStyle _fontFamily({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = const Color(0xFF000000),
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.w,
    );
  }

  // Components
  static TextStyle buttonStyle = semibold14;

  // ARABIC
  static TextStyle _fontFamilyAmiri({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = const Color(0xFF000000),
  }) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.w,
    );
  }

  static TextStyle _fontFamilyLateef({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = const Color(0xFF000000),
  }) {
    return GoogleFonts.lateef(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.w,
    );
  }

  static TextStyle _fontFamilyPoppins({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = const Color(0xFF000000),
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.w,
    );
  }

  // ARABIC FONT
  static TextStyle boldAmiriQuran16 = _fontFamilyAmiri(fontSize: 16.sp, fontWeight: FontWeight.w700);
  static TextStyle boldAmiriQuran12 = _fontFamilyAmiri(fontSize: 12.sp, fontWeight: FontWeight.w700);
  static TextStyle boldLateef16 = _fontFamilyLateef(fontSize: 16.sp, fontWeight: FontWeight.w700);
  static TextStyle boldLateef12 = _fontFamilyLateef(fontSize: 12.sp, fontWeight: FontWeight.w700);
  static TextStyle semiboldLateef96 = _fontFamilyLateef(fontSize: 96.sp, fontWeight: FontWeight.w600);
  static TextStyle lightLateef28 = _fontFamilyLateef(fontSize: 28.sp, fontWeight: FontWeight.w300);
  static TextStyle lightLateef30 = _fontFamilyLateef(fontSize: 30.sp, fontWeight: FontWeight.w300);
  static TextStyle lightLateef32 = _fontFamilyLateef(fontSize: 32.sp, fontWeight: FontWeight.w300);
  static TextStyle regularLateef24 = _fontFamilyLateef(fontSize: 24.sp, fontWeight: FontWeight.w400);

  // Poppins
  static TextStyle regularPoppins8 = _fontFamilyPoppins(fontSize: 8.sp, fontWeight: FontWeight.w400);
  static TextStyle mediumPoppins12 = _fontFamilyPoppins(fontSize: 12.sp, fontWeight: FontWeight.w500);
  static TextStyle boldPoppins20 = _fontFamilyPoppins(fontSize: 20.sp, fontWeight: FontWeight.w700);

  // Font Light
  static TextStyle light2 = _fontFamily(fontSize: 2.sp, fontWeight: FontWeight.w300);
  static TextStyle light4 = _fontFamily(fontSize: 4.sp, fontWeight: FontWeight.w300);
  static TextStyle light6 = _fontFamily(fontSize: 6.sp, fontWeight: FontWeight.w300);
  static TextStyle light8 = _fontFamily(fontSize: 8.sp, fontWeight: FontWeight.w300);
  static TextStyle light10 = _fontFamily(fontSize: 10.sp, fontWeight: FontWeight.w300);
  static TextStyle light12 = _fontFamily(fontSize: 12.sp, fontWeight: FontWeight.w300);
  static TextStyle light14 = _fontFamily(fontSize: 14.sp, fontWeight: FontWeight.w300);
  static TextStyle light16 = _fontFamily(fontSize: 16.sp, fontWeight: FontWeight.w300);
  static TextStyle light18 = _fontFamily(fontSize: 18.sp, fontWeight: FontWeight.w300);
  static TextStyle light20 = _fontFamily(fontSize: 20.sp, fontWeight: FontWeight.w300);
  static TextStyle light24 = _fontFamily(fontSize: 24.sp, fontWeight: FontWeight.w300);
  static TextStyle light32 = _fontFamily(fontSize: 32.sp, fontWeight: FontWeight.w300);
  static TextStyle light40 = _fontFamily(fontSize: 40.sp, fontWeight: FontWeight.w300);

  // Font Regular
  static TextStyle regular2 = _fontFamily(fontSize: 2.sp, fontWeight: FontWeight.w400);
  static TextStyle regular4 = _fontFamily(fontSize: 4.sp, fontWeight: FontWeight.w400);
  static TextStyle regular6 = _fontFamily(fontSize: 6.sp, fontWeight: FontWeight.w400);
  static TextStyle regular8 = _fontFamily(fontSize: 8.sp, fontWeight: FontWeight.w400);
  static TextStyle regular9 = _fontFamily(fontSize: 9.sp, fontWeight: FontWeight.w400);
  static TextStyle regular10 = _fontFamily(fontSize: 10.sp, fontWeight: FontWeight.w400);
  static TextStyle regular11 = _fontFamily(fontSize: 11.sp, fontWeight: FontWeight.w400);
  static TextStyle regular12 = _fontFamily(fontSize: 12.sp, fontWeight: FontWeight.w400);
  static TextStyle regular13 = _fontFamily(fontSize: 13.sp, fontWeight: FontWeight.w400);
  static TextStyle regular14 = _fontFamily(fontSize: 14.sp, fontWeight: FontWeight.w400);
  static TextStyle regular15 = _fontFamily(fontSize: 15.sp, fontWeight: FontWeight.w400);
  static TextStyle regular16 = _fontFamily(fontSize: 16.sp, fontWeight: FontWeight.w400);
  static TextStyle regular18 = _fontFamily(fontSize: 18.sp, fontWeight: FontWeight.w400);
  static TextStyle regular20 = _fontFamily(fontSize: 20.sp, fontWeight: FontWeight.w400);
  static TextStyle regular24 = _fontFamily(fontSize: 24.sp, fontWeight: FontWeight.w400);
  static TextStyle regular32 = _fontFamily(fontSize: 32.sp, fontWeight: FontWeight.w400);
  static TextStyle regular40 = _fontFamily(fontSize: 40.sp, fontWeight: FontWeight.w400);

  // Font Medium
  static TextStyle medium2 = _fontFamily(fontSize: 2.sp, fontWeight: FontWeight.w500);
  static TextStyle medium4 = _fontFamily(fontSize: 4.sp, fontWeight: FontWeight.w500);
  static TextStyle medium6 = _fontFamily(fontSize: 6.sp, fontWeight: FontWeight.w500);
  static TextStyle medium8 = _fontFamily(fontSize: 8.sp, fontWeight: FontWeight.w500);
  static TextStyle medium10 = _fontFamily(fontSize: 10.sp, fontWeight: FontWeight.w500);
  static TextStyle medium11 = _fontFamily(fontSize: 11.sp, fontWeight: FontWeight.w500);
  static TextStyle medium12 = _fontFamily(fontSize: 12.sp, fontWeight: FontWeight.w500);
  static TextStyle medium13 = _fontFamily(fontSize: 13.sp, fontWeight: FontWeight.w500);
  static TextStyle medium14 = _fontFamily(fontSize: 14.sp, fontWeight: FontWeight.w500);
  static TextStyle medium16 = _fontFamily(fontSize: 16.sp, fontWeight: FontWeight.w500);
  static TextStyle medium18 = _fontFamily(fontSize: 18.sp, fontWeight: FontWeight.w500);
  static TextStyle medium20 = _fontFamily(fontSize: 20.sp, fontWeight: FontWeight.w500);
  static TextStyle medium22 = _fontFamily(fontSize: 22.sp, fontWeight: FontWeight.w500);
  static TextStyle medium24 = _fontFamily(fontSize: 24.sp, fontWeight: FontWeight.w500);
  static TextStyle medium32 = _fontFamily(fontSize: 32.sp, fontWeight: FontWeight.w500);
  static TextStyle medium40 = _fontFamily(fontSize: 40.sp, fontWeight: FontWeight.w500);

  // Font Semibold
  static TextStyle semibold2 = _fontFamily(fontSize: 2.sp, fontWeight: FontWeight.w600);
  static TextStyle semibold4 = _fontFamily(fontSize: 4.sp, fontWeight: FontWeight.w600);
  static TextStyle semibold6 = _fontFamily(fontSize: 6.sp, fontWeight: FontWeight.w600);
  static TextStyle semibold8 = _fontFamily(fontSize: 8.sp, fontWeight: FontWeight.w600);
  static TextStyle semibold9 = _fontFamily(fontSize: 9.sp, fontWeight: FontWeight.w600);
  static TextStyle semibold10 = _fontFamily(fontSize: 10.sp, fontWeight: FontWeight.w600);
  static TextStyle semibold11 = _fontFamily(fontSize: 11.sp, fontWeight: FontWeight.w600);
  static TextStyle semibold12 = _fontFamily(fontSize: 12.sp, fontWeight: FontWeight.w600);
  static TextStyle semibold13 = _fontFamily(fontSize: 13.sp, fontWeight: FontWeight.w600);
  static TextStyle semibold14 = _fontFamily(fontSize: 14.sp, fontWeight: FontWeight.w600);
  static TextStyle semibold16 = _fontFamily(fontSize: 16.sp, fontWeight: FontWeight.w600);
  static TextStyle semibold18 = _fontFamily(fontSize: 18.sp, fontWeight: FontWeight.w600);
  static TextStyle semibold20 = _fontFamily(fontSize: 20.sp, fontWeight: FontWeight.w600);
  static TextStyle semibold24 = _fontFamily(fontSize: 24.sp, fontWeight: FontWeight.w600);
  static TextStyle semibold32 = _fontFamily(fontSize: 32.sp, fontWeight: FontWeight.w600);
  static TextStyle semibold40 = _fontFamily(fontSize: 40.sp, fontWeight: FontWeight.w600);

  // Font Bold
  static TextStyle bold2 = _fontFamily(fontSize: 2.sp, fontWeight: FontWeight.w700);
  static TextStyle bold4 = _fontFamily(fontSize: 4.sp, fontWeight: FontWeight.w700);
  static TextStyle bold6 = _fontFamily(fontSize: 6.sp, fontWeight: FontWeight.w700);
  static TextStyle bold8 = _fontFamily(fontSize: 8.sp, fontWeight: FontWeight.w700);
  static TextStyle bold10 = _fontFamily(fontSize: 10.sp, fontWeight: FontWeight.w700);
  static TextStyle bold11 = _fontFamily(fontSize: 11.sp, fontWeight: FontWeight.w700);
  static TextStyle bold12 = _fontFamily(fontSize: 12.sp, fontWeight: FontWeight.w700);
  static TextStyle bold14 = _fontFamily(fontSize: 14.sp, fontWeight: FontWeight.w700);
  static TextStyle bold15 = _fontFamily(fontSize: 15.sp, fontWeight: FontWeight.w700);
  static TextStyle bold16 = _fontFamily(fontSize: 16.sp, fontWeight: FontWeight.w700);
  static TextStyle bold18 = _fontFamily(fontSize: 18.sp, fontWeight: FontWeight.w700);
  static TextStyle bold20 = _fontFamily(fontSize: 20.sp, fontWeight: FontWeight.w700);
  static TextStyle bold22 = _fontFamily(fontSize: 22.sp, fontWeight: FontWeight.w700);
  static TextStyle bold24 = _fontFamily(fontSize: 24.sp, fontWeight: FontWeight.w700);
  static TextStyle bold28 = _fontFamily(fontSize: 28.sp, fontWeight: FontWeight.w700);
  static TextStyle bold30 = _fontFamily(fontSize: 30.sp, fontWeight: FontWeight.w700);
  static TextStyle bold32 = _fontFamily(fontSize: 32.sp, fontWeight: FontWeight.w700);
  static TextStyle bold34 = _fontFamily(fontSize: 34.sp, fontWeight: FontWeight.w700);
  static TextStyle bold40 = _fontFamily(fontSize: 40.sp, fontWeight: FontWeight.w700);

  // Font Bold
  static TextStyle extraBold2 = _fontFamily(fontSize: 2.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold4 = _fontFamily(fontSize: 4.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold6 = _fontFamily(fontSize: 6.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold8 = _fontFamily(fontSize: 8.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold10 = _fontFamily(fontSize: 10.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold11 = _fontFamily(fontSize: 11.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold12 = _fontFamily(fontSize: 12.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold14 = _fontFamily(fontSize: 14.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold15 = _fontFamily(fontSize: 15.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold16 = _fontFamily(fontSize: 16.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold18 = _fontFamily(fontSize: 18.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold20 = _fontFamily(fontSize: 20.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold22 = _fontFamily(fontSize: 22.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold24 = _fontFamily(fontSize: 24.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold28 = _fontFamily(fontSize: 28.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold30 = _fontFamily(fontSize: 30.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold32 = _fontFamily(fontSize: 32.sp, fontWeight: FontWeight.w900);
  static TextStyle extraBold40 = _fontFamily(fontSize: 40.sp, fontWeight: FontWeight.w900);
}
