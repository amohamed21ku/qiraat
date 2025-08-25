// lib/utils/arabic_text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArabicTextStyles {
  // Base Arabic text style using local font (without fontFallback)
  static TextStyle arabicTextStyleLocal({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFamily: 'NotoSansArabic',
    );
  }

  // Base Arabic text style using Google Fonts (recommended - has built-in fallback)
  static TextStyle arabicTextStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.notoSansArabic(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Predefined styles using Google Fonts
  static TextStyle heading1({Color? color}) {
    return GoogleFonts.notoSansArabic(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.2,
    );
  }

  static TextStyle heading2({Color? color}) {
    return GoogleFonts.notoSansArabic(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle heading3({Color? color}) {
    return GoogleFonts.notoSansArabic(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle bodyLarge({Color? color}) {
    return GoogleFonts.notoSansArabic(
      fontSize: 16,
      color: color,
      height: 1.5,
    );
  }

  static TextStyle bodyMedium({Color? color}) {
    return GoogleFonts.notoSansArabic(
      fontSize: 14,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle bodySmall({Color? color}) {
    return GoogleFonts.notoSansArabic(
      fontSize: 12,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle caption({Color? color}) {
    return GoogleFonts.notoSansArabic(
      fontSize: 12,
      color: color ?? Colors.grey.shade600,
      height: 1.3,
    );
  }

  static TextStyle button({Color? color}) {
    return GoogleFonts.notoSansArabic(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle cardTitle({Color? color}) {
    return GoogleFonts.notoSansArabic(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle dialogTitle({Color? color}) {
    return GoogleFonts.notoSansArabic(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.2,
    );
  }

  static TextStyle statusText({Color? color}) {
    return GoogleFonts.notoSansArabic(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  // Alternative using local fonts only (if you prefer not to use Google Fonts)
  static TextStyle localHeading1({Color? color}) {
    return TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.2,
      fontFamily: 'NotoSansArabic',
    );
  }

  static TextStyle localHeading2({Color? color}) {
    return TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.3,
      fontFamily: 'NotoSansArabic',
    );
  }

  static TextStyle localBodyMedium({Color? color}) {
    return TextStyle(
      fontSize: 14,
      color: color,
      height: 1.4,
      fontFamily: 'NotoSansArabic',
    );
  }

  static TextStyle localCaption({Color? color}) {
    return TextStyle(
      fontSize: 12,
      color: color ?? Colors.grey.shade600,
      height: 1.3,
      fontFamily: 'NotoSansArabic',
    );
  }
}

// Helper widget for easy Arabic text
class ArabicText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool useLocalFont;

  const ArabicText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.useLocalFont = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseStyle = useLocalFont
        ? TextStyle(fontFamily: 'NotoSansArabic')
        : GoogleFonts.notoSansArabic();

    return Text(
      text,
      style: baseStyle.merge(style),
      textAlign: textAlign ?? TextAlign.right,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: TextDirection.rtl,
    );
  }
}

// Extension for easy text styling (without fontFallback)
extension ArabicTextExtension on Text {
  Text withLocalArabicStyle(TextStyle style) {
    return Text(
      data ?? '',
      style: TextStyle(fontFamily: 'NotoSansArabic').merge(style),
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }
}
