// // lib/utils/arabic_text_styles.dart
// import 'package:flutter/material.dart';
//
// class ArabicTextStyles {
//   // Font fallback list for better compatibility
//   static const List<String> arabicFontFallbacks = [
//     'NotoSansArabic',
//     'NotoSansArabicCondensed',
//     'Arial',
//     'Helvetica',
//     'Tahoma',
//     'sans-serif',
//   ];
//
//   // Base Arabic text style with font fallback
//   static TextStyle arabicTextStyle({
//     double fontSize = 14,
//     FontWeight fontWeight = FontWeight.normal,
//     Color? color,
//     double? height,
//     double? letterSpacing,
//   }) {
//     return TextStyle(
//       fontSize: fontSize,
//       fontWeight: fontWeight,
//       color: color,
//       height: height,
//       letterSpacing: letterSpacing,
//       fontFamily: 'NotoSansArabic',
//       fontFallback: arabicFontFallbacks,
//     );
//   }
//
//   // Predefined styles for common use cases
//   static TextStyle heading1({Color? color}) {
//     return arabicTextStyle(
//       fontSize: 28,
//       fontWeight: FontWeight.bold,
//       color: color,
//       height: 1.2,
//     );
//   }
//
//   static TextStyle heading2({Color? color}) {
//     return arabicTextStyle(
//       fontSize: 22,
//       fontWeight: FontWeight.bold,
//       color: color,
//       height: 1.3,
//     );
//   }
//
//   static TextStyle heading3({Color? color}) {
//     return arabicTextStyle(
//       fontSize: 18,
//       fontWeight: FontWeight.w600,
//       color: color,
//       height: 1.3,
//     );
//   }
//
//   static TextStyle bodyLarge({Color? color}) {
//     return arabicTextStyle(
//       fontSize: 16,
//       color: color,
//       height: 1.5,
//     );
//   }
//
//   static TextStyle bodyMedium({Color? color}) {
//     return arabicTextStyle(
//       fontSize: 14,
//       color: color,
//       height: 1.4,
//     );
//   }
//
//   static TextStyle bodySmall({Color? color}) {
//     return arabicTextStyle(
//       fontSize: 12,
//       color: color,
//       height: 1.4,
//     );
//   }
//
//   static TextStyle caption({Color? color}) {
//     return arabicTextStyle(
//       fontSize: 12,
//       color: color ?? Colors.grey.shade600,
//       height: 1.3,
//     );
//   }
//
//   static TextStyle button({Color? color}) {
//     return arabicTextStyle(
//       fontSize: 14,
//       fontWeight: FontWeight.w600,
//       color: color,
//     );
//   }
//
//   // Special styles for specific UI elements
//   static TextStyle cardTitle({Color? color}) {
//     return arabicTextStyle(
//       fontSize: 16,
//       fontWeight: FontWeight.w600,
//       color: color,
//       height: 1.3,
//     );
//   }
//
//   static TextStyle dialogTitle({Color? color}) {
//     return arabicTextStyle(
//       fontSize: 20,
//       fontWeight: FontWeight.bold,
//       color: color,
//       height: 1.2,
//     );
//   }
//
//   static TextStyle statusText({Color? color}) {
//     return arabicTextStyle(
//       fontSize: 14,
//       fontWeight: FontWeight.w500,
//       color: color,
//     );
//   }
//
//   // For condensed text (using condensed font family)
//   static TextStyle condensed({
//     double fontSize = 14,
//     FontWeight fontWeight = FontWeight.normal,
//     Color? color,
//   }) {
//     return TextStyle(
//       fontSize: fontSize,
//       fontWeight: fontWeight,
//       color: color,
//       fontFamily: 'NotoSansArabicCondensed',
//       fontFallback: arabicFontFallbacks,
//     );
//   }
// }
//
// // Extension for easy text styling
// extension ArabicText on Text {
//   Text withArabicStyle(TextStyle style) {
//     return Text(
//       data ?? '',
//       style: style,
//       textAlign: textAlign,
//       textDirection: textDirection,
//       locale: locale,
//       softWrap: softWrap,
//       overflow: overflow,
//       textScaleFactor: textScaler?.scale(1.0) ?? 1.0,
//       maxLines: maxLines,
//       semanticsLabel: semanticsLabel,
//       textWidthBasis: textWidthBasis,
//       textHeightBehavior: textHeightBehavior,
//     );
//   }
// }
