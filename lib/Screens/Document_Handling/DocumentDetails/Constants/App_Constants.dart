// constants/app_constants.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryColor = Color(0xffa86418);
  static const Color secondaryColor = Color(0xffcc9657);

  // Strings
  static const String documentDetails = 'تفاصيل المستند';
  static const String reviewAndManage = 'مراجعة وإدارة المستند';
  static const String processing = 'جاري المعالجة...';
  static const String pleaseWait = 'الرجاء الانتظار';

  static const List<String> workflowStatuses = [
    'ملف وارد', // Incoming File
    'مراجعة السكرتير', // Secretary Review
    'مراجعة مدير التحرير', // Managing Editor Review
    'مراجعة رئيس التحرير', // Editor-in-Chief Review
    'الي المحكمين', // To Reviewers
    'تم التحكيم', // Review Completed
    'مطلوب تعديل من المؤلف', // Author Revision Required
    'التحرير اللغوي', // Language Editing
    'التصميم والإخراج', // Layout and Design
    'المراجعة الأولى للإخراج', // First Layout Review
    'مراجعة رئيس التحرير للإخراج', // Editor-in-Chief Layout Review
    'المراجعة النهائية', // Final Review
    'التعديلات النهائية', // Final Revisions
    'الموافقة النهائية للنشر', // Final Approval for Publication
    'مرفوض نهائياً', // Finally Rejected
    'مرفوض لعدم الملاءمة', // Rejected for Inappropriateness
    'مرسل للموقع', // Sent to Website
  ];

  // User Roles
  static const List<String> userRoles = [
    'سكرتير تحرير', // Editorial Secretary
    'مدير التحرير', // Managing Editor
    'رئيس التحرير', // Editor-in-Chief
    'محكم سياسي', // Political Reviewer
    'محكم اقتصادي', // Economic Reviewer
    'محكم اجتماعي', // Social Reviewer
    'محرر لغوي', // Language Editor
    'مصمم إخراج', // Layout Designer
    'مراجع نهائي', // Final Reviewer
    'مؤلف', // Author
  ];

  // Reviewer Types
  static const List<String> reviewerTypes = [
    'جميع الأنواع',
    'سياسي',
    'اقتصادي',
    'اجتماعي',
  ];

  // Action Types for Each Status
  static Map<String, List<String>> getAvailableActions(
      String status, String userRole) {
    switch (status) {
      case 'ملف وارد':
        if (userRole == 'سكرتير تحرير') {
          return {
            'primary': ['مراجعة أولية وإرسال'],
            'secondary': ['رفض لعدم اكتمال البيانات']
          };
        }
        break;

      case 'مراجعة السكرتير':
        if (userRole == 'سكرتير تحرير') {
          return {
            'primary': ['إرسال لمدير التحرير'],
            'secondary': ['طلب تعديل من المؤلف', 'رفض']
          };
        }
        break;

      case 'مراجعة مدير التحرير':
        if (userRole == 'مدير التحرير') {
          return {
            'primary': ['إرسال لرئيس التحرير'],
            'secondary': ['طلب تعديل', 'رفض', 'إرسال للموقع']
          };
        }
        break;

      case 'مراجعة رئيس التحرير':
        if (userRole == 'رئيس التحرير') {
          return {
            'primary': ['قبول وإرسال للتحكيم', 'قبول وإرسال للتحرير اللغوي'],
            'secondary': ['طلب تعديل', 'رفض', 'إرسال للموقع']
          };
        }
        break;

      case 'الي المحكمين':
        if (userRole.contains('محكم')) {
          return {
            'primary': ['موافقة'],
            'secondary': ['طلب تعديل', 'رفض']
          };
        } else if (userRole == 'مدير التحرير') {
          return {
            'primary': ['إدارة المحكمين'],
            'secondary': ['إنهاء التحكيم']
          };
        }
        break;

      case 'تم التحكيم':
        if (userRole == 'مدير التحرير') {
          return {
            'primary': ['إرسال لرئيس التحرير'],
            'secondary': ['طلب تعديل من المؤلف', 'رفض']
          };
        }
        break;

      case 'مطلوب تعديل من المؤلف':
        if (userRole == 'مؤلف') {
          return {
            'primary': ['رفع النسخة المعدلة'],
            'secondary': ['سحب المقال']
          };
        }
        break;

      case 'التحرير اللغوي':
        if (userRole == 'محرر لغوي') {
          return {
            'primary': ['إنهاء التحرير اللغوي'],
            'secondary': ['طلب توضيح من المؤلف']
          };
        }
        break;

      case 'التصميم والإخراج':
        if (userRole == 'مصمم إخراج') {
          return {
            'primary': ['إنهاء التصميم'],
            'secondary': ['طلب توضيح']
          };
        }
        break;

      case 'المراجعة الأولى للإخراج':
        if (userRole == 'مدير التحرير') {
          return {
            'primary': ['إرسال لرئيس التحرير'],
            'secondary': ['إعادة للتصميم']
          };
        }
        break;

      case 'مراجعة رئيس التحرير للإخراج':
        if (userRole == 'رئيس التحرير') {
          return {
            'primary': ['إرسال للمراجعة النهائية'],
            'secondary': ['إعادة للتصميم', 'تعديلات مطلوبة']
          };
        }
        break;

      case 'المراجعة النهائية':
        if (userRole == 'مراجع نهائي') {
          return {
            'primary': ['موافقة نهائية'],
            'secondary': ['تعديلات مطلوبة']
          };
        }
        break;

      case 'التعديلات النهائية':
        if (userRole == 'مصمم إخراج') {
          return {
            'primary': ['إنهاء التعديلات'],
            'secondary': ['طلب توضيح']
          };
        }
        break;
    }
    return {'primary': [], 'secondary': []};
  }

  // File Types
  static const Map<String, String> supportedFileTypes = {
    '.pdf': 'application/pdf',
    '.doc': 'application/msword',
    '.docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.txt': 'text/plain',
    '.rtf': 'application/rtf',
    '.odt': 'application/vnd.oasis.opendocument.text',
  };
}

// Constants/Style.dart

class AppStyles {
  // Colors
  static const Color primaryColor = Color(0xffa86418);
  static const Color secondaryColor = Color(0xffcc9657);
  static const Color backgroundColor = Color(0xfff8f9fa);
  static const Color textColor = Color(0xff2d3748);

  // Text Styles
  static const TextStyle headerStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle subHeaderStyle = TextStyle(
    fontSize: 16,
    color: Colors.white70,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Color(0xff2d3748),
  );

  static const TextStyle cardSubtitleStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 14,
    color: Color(0xff2d3748),
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelTextStyle = TextStyle(
    fontSize: 12,
    color: Colors.grey,
    fontWeight: FontWeight.w600,
  );

  // Decorations
  static BoxDecoration cardDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.white,
        primaryColor.withOpacity(0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.1),
        spreadRadius: 0,
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
    border: Border.all(color: primaryColor.withOpacity(0.2)),
  );

  static BoxDecoration simpleCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration gradientButtonDecoration(Color color1, Color color2) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [color1, color2],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: color1.withOpacity(0.3),
          spreadRadius: 0,
          blurRadius: 15,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration errorCardDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.red.shade50, Colors.red.shade100],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.red.shade200),
  );

  // Status Colors
  static Color getStatusColor(String status) {
    switch (status) {
      case 'ملف وارد':
        return Colors.blue.shade600;
      case 'مراجعة السكرتير':
        return Colors.orange.shade600;
      case 'مراجعة مدير التحرير':
        return Colors.purple.shade600;
      case 'مراجعة رئيس التحرير':
        return Colors.indigo.shade600;
      case 'الي المحكمين':
        return Colors.teal.shade600;
      case 'تم التحكيم':
        return Colors.green.shade600;
      case 'مطلوب تعديل من المؤلف':
        return Colors.amber.shade600;
      case 'التحرير اللغوي':
        return Colors.cyan.shade600;
      case 'التصميم والإخراج':
        return Colors.deepPurple.shade600;
      case 'المراجعة الأولى للإخراج':
        return Colors.pink.shade600;
      case 'مراجعة رئيس التحرير للإخراج':
        return Colors.indigo.shade700;
      case 'المراجعة النهائية':
        return Colors.brown.shade600;
      case 'التعديلات النهائية':
        return Colors.deepOrange.shade600;
      case 'الموافقة النهائية للنشر':
        return Colors.green.shade700;
      case 'مرفوض نهائياً':
      case 'مرفوض لعدم الملاءمة':
        return Colors.red.shade600;
      case 'مرسل للموقع':
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

// Status Icons
  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'ملف وارد':
        return Icons.inbox;
      case 'مراجعة السكرتير':
        return Icons.assignment_ind;
      case 'مراجعة مدير التحرير':
        return Icons.supervisor_account;
      case 'مراجعة رئيس التحرير':
        return Icons.admin_panel_settings;
      case 'الي المحكمين':
        return Icons.people;
      case 'تم التحكيم':
        return Icons.rate_review;
      case 'مطلوب تعديل من المؤلف':
        return Icons.edit_note;
      case 'التحرير اللغوي':
        return Icons.spellcheck;
      case 'التصميم والإخراج':
        return Icons.design_services;
      case 'المراجعة الأولى للإخراج':
        return Icons.preview;
      case 'مراجعة رئيس التحرير للإخراج':
        return Icons.verified_user;
      case 'المراجعة النهائية':
        return Icons.fact_check;
      case 'التعديلات النهائية':
        return Icons.build;
      case 'الموافقة النهائية للنشر':
        return Icons.publish;
      case 'مرفوض نهائياً':
      case 'مرفوض لعدم الملاءمة':
        return Icons.cancel;
      case 'مرسل للموقع':
        return Icons.web;
      default:
        return Icons.circle;
    }
  }

  static BoxDecoration successCardDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.green.shade50, Colors.green.shade100],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.green.shade200),
  );

  static BoxDecoration warningCardDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.orange.shade50, Colors.orange.shade100],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.orange.shade200),
  );

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: primaryColor,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: primaryColor),
    ),
    elevation: 2,
  );

  static ButtonStyle transparentButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Input Decorations
  static InputDecoration inputDecoration({
    required String hintText,
    String? labelText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon:
          prefixIcon != null ? Icon(prefixIcon, color: primaryColor) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // Spacing
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  // Border Radius
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 20.0;
}
