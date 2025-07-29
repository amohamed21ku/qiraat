// constants/app_constants.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryColor = Color(0xffa86418);
  static const Color secondaryColor = Color(0xffcc9657);

  // STAGE 1: APPROVAL WORKFLOW STATUSES (English for database)
  static const String INCOMING = 'incoming';
  static const String SECRETARY_REVIEW = 'secretary_review';
  static const String SECRETARY_APPROVED = 'secretary_approved';
  static const String SECRETARY_REJECTED = 'secretary_rejected';
  static const String SECRETARY_EDIT_REQUESTED = 'secretary_edit_requested';
  static const String EDITOR_REVIEW = 'editor_review';
  static const String EDITOR_APPROVED = 'editor_approved';
  static const String EDITOR_REJECTED = 'editor_rejected';
  static const String EDITOR_WEBSITE_RECOMMENDED = 'editor_website_recommended';
  static const String EDITOR_EDIT_REQUESTED = 'editor_edit_requested';
  static const String HEAD_REVIEW = 'head_review';
  static const String STAGE1_APPROVED = 'stage1_approved';
  static const String FINAL_REJECTED = 'final_rejected';
  static const String WEBSITE_APPROVED = 'website_approved';

  // STAGE 2: REVIEWING (Placeholders for future implementation)
  static const String REVIEWERS_ASSIGNED = 'reviewers_assigned';
  static const String UNDER_PEER_REVIEW = 'under_peer_review';
  static const String PEER_REVIEW_COMPLETED = 'peer_review_completed';

  // STAGE 3: PRODUCTION (Placeholders for future implementation)
  static const String LANGUAGE_EDITING = 'language_editing';
  static const String LAYOUT_DESIGN = 'layout_design';
  static const String FINAL_PRODUCTION = 'final_production';
  static const String PUBLISHED = 'published';
  // Strings
  static const String documentDetails = 'تفاصيل المستند';
  static const String reviewAndManage = 'مراجعة وإدارة المستند';
  static const String processing = 'جاري المعالجة...';
  static const String pleaseWait = 'الرجاء الانتظار';

  // Stage 1 Workflow Statuses List
  static const List<String> stage1Statuses = [
    INCOMING,
    SECRETARY_REVIEW,
    SECRETARY_APPROVED,
    SECRETARY_REJECTED,
    SECRETARY_EDIT_REQUESTED,
    EDITOR_REVIEW,
    EDITOR_APPROVED,
    EDITOR_REJECTED,
    EDITOR_WEBSITE_RECOMMENDED,
    EDITOR_EDIT_REQUESTED,
    HEAD_REVIEW,
    STAGE1_APPROVED,
    FINAL_REJECTED,
    WEBSITE_APPROVED,
  ];

  // All workflow statuses
  static const List<String> allWorkflowStatuses = [
    ...stage1Statuses,
    REVIEWERS_ASSIGNED,
    UNDER_PEER_REVIEW,
    PEER_REVIEW_COMPLETED,
    LANGUAGE_EDITING,
    LAYOUT_DESIGN,
    FINAL_PRODUCTION,
    PUBLISHED,
  ];

  // Status Display Names (Arabic for UI)
  static const Map<String, String> statusDisplayNames = {
    INCOMING: 'ملف وارد',
    SECRETARY_REVIEW: 'مراجعة السكرتير',
    SECRETARY_APPROVED: 'موافقة السكرتير',
    SECRETARY_REJECTED: 'رفض السكرتير',
    SECRETARY_EDIT_REQUESTED: 'تعديل مطلوب من السكرتير',
    EDITOR_REVIEW: 'مراجعة مدير التحرير',
    EDITOR_APPROVED: 'موافقة مدير التحرير',
    EDITOR_REJECTED: 'رفض مدير التحرير',
    EDITOR_WEBSITE_RECOMMENDED: 'موصى للموقع',
    EDITOR_EDIT_REQUESTED: 'تعديل مطلوب من مدير التحرير',
    HEAD_REVIEW: 'مراجعة رئيس التحرير',
    STAGE1_APPROVED: 'موافق للمرحلة الثانية',
    FINAL_REJECTED: 'مرفوض نهائياً',
    WEBSITE_APPROVED: 'موافق لنشر الموقع',
    // Stage 2 & 3 placeholders
    REVIEWERS_ASSIGNED: 'تم تعيين المحكمين',
    UNDER_PEER_REVIEW: 'تحت التحكيم',
    PEER_REVIEW_COMPLETED: 'انتهى التحكيم',
    LANGUAGE_EDITING: 'التحرير اللغوي',
    LAYOUT_DESIGN: 'التصميم والإخراج',
    FINAL_PRODUCTION: 'الإنتاج النهائي',
    PUBLISHED: 'منشور',
  };
  // User Positions
  static const String POSITION_SECRETARY = 'سكرتير تحرير';
  static const String POSITION_MANAGING_EDITOR = 'مدير التحرير';
  static const String POSITION_HEAD_EDITOR = 'رئيس التحرير';
  static const String POSITION_REVIEWER = 'محكم';
  static const String POSITION_LANGUAGE_EDITOR = 'محرر لغوي';
  static const String POSITION_LAYOUT_DESIGNER = 'مصمم إخراج';
  static const String POSITION_FINAL_REVIEWER = 'مراجع نهائي';
  static const String POSITION_AUTHOR = 'مؤلف';

  // Action Types for Stage 1
  static const String ACTION_APPROVE = 'approve';
  static const String ACTION_REJECT = 'reject';
  static const String ACTION_REQUEST_EDIT = 'request_edit';
  static const String ACTION_RECOMMEND_WEBSITE = 'recommend_website';
  static const String ACTION_FINAL_APPROVE = 'final_approve';
  static const String ACTION_FINAL_REJECT = 'final_reject';
  static const String ACTION_WEBSITE_APPROVE = 'website_approve';

  // Stage 1 Workflow Progress Steps
  static List<Map<String, dynamic>> getStage1WorkflowSteps() {
    return [
      {
        'status': INCOMING,
        'title': 'استلام المقال',
        'subtitle': 'ملف وارد',
        'icon': Icons.inbox,
        'description': 'تم استلام المقال من المؤلف',
        'responsibleRole': 'السكرتير',
      },
      {
        'status': SECRETARY_REVIEW,
        'title': 'مراجعة السكرتير',
        'subtitle': 'فحص أولي',
        'icon': Icons.assignment_ind,
        'description': 'مراجعة التنسيق والمتطلبات الأساسية',
        'responsibleRole': 'السكرتير',
      },
      {
        'status': EDITOR_REVIEW,
        'title': 'مراجعة مدير التحرير',
        'subtitle': 'تقييم المحتوى',
        'icon': Icons.supervisor_account,
        'description': 'مراجعة الملاءمة والموضوع',
        'responsibleRole': 'مدير التحرير',
      },
      {
        'status': HEAD_REVIEW,
        'title': 'مراجعة رئيس التحرير',
        'subtitle': 'قرار نهائي',
        'icon': Icons.admin_panel_settings,
        'description': 'اتخاذ القرار النهائي للمرحلة الأولى',
        'responsibleRole': 'رئيس التحرير',
      },
      {
        'status': STAGE1_APPROVED,
        'title': 'موافق للمرحلة الثانية',
        'subtitle': 'انتهاء المرحلة الأولى',
        'icon': Icons.check_circle,
        'description': 'تم قبول المقال للمرحلة الثانية (التحكيم)',
        'responsibleRole': 'النظام',
      },
    ];
  }

  // Get next status based on action
  static String getNextStatus(
      String currentStatus, String action, String userPosition) {
    switch (currentStatus) {
      case INCOMING:
        return SECRETARY_REVIEW;

      case SECRETARY_REVIEW:
        switch (action) {
          case ACTION_APPROVE:
            return SECRETARY_APPROVED;
          case ACTION_REJECT:
            return SECRETARY_REJECTED;
          case ACTION_REQUEST_EDIT:
            return SECRETARY_EDIT_REQUESTED;
          default:
            return currentStatus;
        }

      case SECRETARY_APPROVED:
      case SECRETARY_EDIT_REQUESTED:
        return EDITOR_REVIEW;

      case EDITOR_REVIEW:
        switch (action) {
          case ACTION_APPROVE:
            return EDITOR_APPROVED;
          case ACTION_REJECT:
            return EDITOR_REJECTED;
          case ACTION_RECOMMEND_WEBSITE:
            return EDITOR_WEBSITE_RECOMMENDED;
          case ACTION_REQUEST_EDIT:
            return EDITOR_EDIT_REQUESTED;
          default:
            return currentStatus;
        }

      case EDITOR_APPROVED:
      case EDITOR_REJECTED:
      case EDITOR_WEBSITE_RECOMMENDED:
      case EDITOR_EDIT_REQUESTED:
        return HEAD_REVIEW;

      case HEAD_REVIEW:
        switch (action) {
          case ACTION_FINAL_APPROVE:
            return STAGE1_APPROVED;
          case ACTION_FINAL_REJECT:
            return FINAL_REJECTED;
          case ACTION_WEBSITE_APPROVE:
            return WEBSITE_APPROVED;
          default:
            return currentStatus;
        }

      default:
        return currentStatus;
    }
  }

  // Get available actions for user and status
  static List<Map<String, dynamic>> getAvailableActions(
      String status, String userPosition) {
    List<Map<String, dynamic>> actions = [];

    switch (status) {
      case INCOMING:
        if (userPosition == POSITION_SECRETARY) {
          actions.add({
            'action': 'start_review',
            'title': 'بدء المراجعة',
            'description': 'بدء مراجعة الملف',
            'icon': Icons.play_arrow,
            'color': Colors.blue,
            'requiresAttachment': false,
            'requiresComment': false,
          });
        }
        break;

      case SECRETARY_REVIEW:
        if (userPosition == POSITION_SECRETARY) {
          actions.addAll([
            {
              'action': ACTION_APPROVE,
              'title': 'موافقة',
              'description': 'الموافقة على الملف وإرساله لمدير التحرير',
              'icon': Icons.check_circle,
              'color': Colors.green,
              'requiresAttachment': true,
              'requiresComment': true,
            },
            {
              'action': ACTION_REJECT,
              'title': 'رفض',
              'description': 'رفض الملف',
              'icon': Icons.cancel,
              'color': Colors.red,
              'requiresAttachment': true,
              'requiresComment': true,
            },
            {
              'action': ACTION_REQUEST_EDIT,
              'title': 'طلب تعديل',
              'description': 'طلب تعديلات من المؤلف',
              'icon': Icons.edit,
              'color': Colors.orange,
              'requiresAttachment': true,
              'requiresComment': true,
            },
          ]);
        }
        break;

      case EDITOR_REVIEW:
        if (userPosition == POSITION_MANAGING_EDITOR) {
          actions.addAll([
            {
              'action': ACTION_APPROVE,
              'title': 'موافقة',
              'description': 'الموافقة على الملف وإرساله لرئيس التحرير',
              'icon': Icons.check_circle,
              'color': Colors.green,
              'requiresAttachment': true,
              'requiresComment': true,
            },
            {
              'action': ACTION_REJECT,
              'title': 'رفض',
              'description': 'رفض الملف',
              'icon': Icons.cancel,
              'color': Colors.red,
              'requiresAttachment': true,
              'requiresComment': true,
            },
            {
              'action': ACTION_RECOMMEND_WEBSITE,
              'title': 'موصى للموقع',
              'description': 'غير مناسب للمجلة لكن يمكن نشره على الموقع',
              'icon': Icons.web,
              'color': Colors.blue,
              'requiresAttachment': true,
              'requiresComment': true,
            },
            {
              'action': ACTION_REQUEST_EDIT,
              'title': 'طلب تعديل',
              'description': 'طلب تعديلات من المؤلف',
              'icon': Icons.edit,
              'color': Colors.orange,
              'requiresAttachment': true,
              'requiresComment': true,
            },
          ]);
        }
        break;

      case HEAD_REVIEW:
        if (userPosition == POSITION_HEAD_EDITOR) {
          actions.addAll([
            {
              'action': ACTION_FINAL_APPROVE,
              'title': 'الموافقة النهائية',
              'description': 'الموافقة النهائية للانتقال للمرحلة الثانية',
              'icon': Icons.verified,
              'color': Colors.green,
              'requiresAttachment': true,
              'requiresComment': true,
            },
            {
              'action': ACTION_FINAL_REJECT,
              'title': 'الرفض النهائي',
              'description': 'الرفض النهائي للملف',
              'icon': Icons.block,
              'color': Colors.red,
              'requiresAttachment': true,
              'requiresComment': true,
            },
            {
              'action': ACTION_WEBSITE_APPROVE,
              'title': 'موافقة نشر الموقع',
              'description': 'الموافقة على النشر في الموقع فقط',
              'icon': Icons.public,
              'color': Colors.blue,
              'requiresAttachment': true,
              'requiresComment': true,
            },
          ]);
        }
        break;
    }

    return actions;
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

  // // Action Types for Each Status
  // static Map<String, List<String>> getAvailableActions(
  //     String status, String userRole) {
  //   switch (status) {
  //     case 'ملف وارد':
  //       if (userRole == 'سكرتير تحرير') {
  //         return {
  //           'primary': ['مراجعة أولية وإرسال'],
  //           'secondary': ['رفض لعدم اكتمال البيانات']
  //         };
  //       }
  //       break;
  //
  //     case 'مراجعة السكرتير':
  //       if (userRole == 'سكرتير تحرير') {
  //         return {
  //           'primary': ['إرسال لمدير التحرير'],
  //           'secondary': ['طلب تعديل من المؤلف', 'رفض']
  //         };
  //       }
  //       break;
  //
  //     case 'مراجعة مدير التحرير':
  //       if (userRole == 'مدير التحرير') {
  //         return {
  //           'primary': ['إرسال لرئيس التحرير'],
  //           'secondary': ['طلب تعديل', 'رفض', 'إرسال للموقع']
  //         };
  //       }
  //       break;
  //
  //     case 'مراجعة رئيس التحرير':
  //       if (userRole == 'رئيس التحرير') {
  //         return {
  //           'primary': ['قبول وإرسال للتحكيم', 'قبول وإرسال للتحرير اللغوي'],
  //           'secondary': ['طلب تعديل', 'رفض', 'إرسال للموقع']
  //         };
  //       }
  //       break;
  //
  //     case 'الي المحكمين':
  //       if (userRole.contains('محكم')) {
  //         return {
  //           'primary': ['موافقة'],
  //           'secondary': ['طلب تعديل', 'رفض']
  //         };
  //       } else if (userRole == 'مدير التحرير') {
  //         return {
  //           'primary': ['إدارة المحكمين'],
  //           'secondary': ['إنهاء التحكيم']
  //         };
  //       }
  //       break;
  //
  //     case 'تم التحكيم':
  //       if (userRole == 'مدير التحرير') {
  //         return {
  //           'primary': ['إرسال لرئيس التحرير'],
  //           'secondary': ['طلب تعديل من المؤلف', 'رفض']
  //         };
  //       }
  //       break;
  //
  //     case 'مطلوب تعديل من المؤلف':
  //       if (userRole == 'مؤلف') {
  //         return {
  //           'primary': ['رفع النسخة المعدلة'],
  //           'secondary': ['سحب المقال']
  //         };
  //       }
  //       break;
  //
  //     case 'التحرير اللغوي':
  //       if (userRole == 'محرر لغوي') {
  //         return {
  //           'primary': ['إنهاء التحرير اللغوي'],
  //           'secondary': ['طلب توضيح من المؤلف']
  //         };
  //       }
  //       break;
  //
  //     case 'التصميم والإخراج':
  //       if (userRole == 'مصمم إخراج') {
  //         return {
  //           'primary': ['إنهاء التصميم'],
  //           'secondary': ['طلب توضيح']
  //         };
  //       }
  //       break;
  //
  //     case 'المراجعة الأولى للإخراج':
  //       if (userRole == 'مدير التحرير') {
  //         return {
  //           'primary': ['إرسال لرئيس التحرير'],
  //           'secondary': ['إعادة للتصميم']
  //         };
  //       }
  //       break;
  //
  //     case 'مراجعة رئيس التحرير للإخراج':
  //       if (userRole == 'رئيس التحرير') {
  //         return {
  //           'primary': ['إرسال للمراجعة النهائية'],
  //           'secondary': ['إعادة للتصميم', 'تعديلات مطلوبة']
  //         };
  //       }
  //       break;
  //
  //     case 'المراجعة النهائية':
  //       if (userRole == 'مراجع نهائي') {
  //         return {
  //           'primary': ['موافقة نهائية'],
  //           'secondary': ['تعديلات مطلوبة']
  //         };
  //       }
  //       break;
  //
  //     case 'التعديلات النهائية':
  //       if (userRole == 'مصمم إخراج') {
  //         return {
  //           'primary': ['إنهاء التعديلات'],
  //           'secondary': ['طلب توضيح']
  //         };
  //       }
  //       break;
  //   }
  //   return {'primary': [], 'secondary': []};
  // }

  // File Types
  // static const Map<String, String> supportedFileTypes = {
  //   '.pdf': 'application/pdf',
  //   '.doc': 'application/msword',
  //   '.docx':
  //       'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  //   '.txt': 'text/plain',
  //   '.rtf': 'application/rtf',
  //   '.odt': 'application/vnd.oasis.opendocument.text',
  // };
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

  // Status Colors for Stage 1
  static Color getStatusColor(String status) {
    switch (status) {
      case AppConstants.INCOMING:
        return Colors.blue.shade600;
      case AppConstants.SECRETARY_REVIEW:
        return Colors.orange.shade600;
      case AppConstants.SECRETARY_APPROVED:
        return Colors.green.shade500;
      case AppConstants.SECRETARY_REJECTED:
        return Colors.red.shade500;
      case AppConstants.SECRETARY_EDIT_REQUESTED:
        return Colors.amber.shade600;
      case AppConstants.EDITOR_REVIEW:
        return Colors.purple.shade600;
      case AppConstants.EDITOR_APPROVED:
        return Colors.green.shade600;
      case AppConstants.EDITOR_REJECTED:
        return Colors.red.shade600;
      case AppConstants.EDITOR_WEBSITE_RECOMMENDED:
        return Colors.blue.shade500;
      case AppConstants.EDITOR_EDIT_REQUESTED:
        return Colors.amber.shade700;
      case AppConstants.HEAD_REVIEW:
        return Colors.indigo.shade600;
      case AppConstants.STAGE1_APPROVED:
        return Colors.green.shade700;
      case AppConstants.FINAL_REJECTED:
        return Colors.red.shade700;
      case AppConstants.WEBSITE_APPROVED:
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  // Status Icons for Stage 1
  static IconData getStatusIcon(String status) {
    switch (status) {
      case AppConstants.INCOMING:
        return Icons.inbox;
      case AppConstants.SECRETARY_REVIEW:
        return Icons.assignment_ind;
      case AppConstants.SECRETARY_APPROVED:
        return Icons.check_circle_outline;
      case AppConstants.SECRETARY_REJECTED:
        return Icons.cancel_outlined;
      case AppConstants.SECRETARY_EDIT_REQUESTED:
        return Icons.edit_note;
      case AppConstants.EDITOR_REVIEW:
        return Icons.supervisor_account;
      case AppConstants.EDITOR_APPROVED:
        return Icons.verified_user;
      case AppConstants.EDITOR_REJECTED:
        return Icons.do_not_disturb;
      case AppConstants.EDITOR_WEBSITE_RECOMMENDED:
        return Icons.public;
      case AppConstants.EDITOR_EDIT_REQUESTED:
        return Icons.edit;
      case AppConstants.HEAD_REVIEW:
        return Icons.admin_panel_settings;
      case AppConstants.STAGE1_APPROVED:
        return Icons.verified;
      case AppConstants.FINAL_REJECTED:
        return Icons.block;
      case AppConstants.WEBSITE_APPROVED:
        return Icons.web_asset;
      default:
        return Icons.circle;
    }
  }

  // Helper method to get display name
  static String getStatusDisplayName(String status) {
    return AppConstants.statusDisplayNames[status] ?? status;
  }

  // Check if status is in Stage 1
  static bool isStage1Status(String status) {
    return AppConstants.stage1Statuses.contains(status);
  }

  // Check if status is a final state in Stage 1
  static bool isStage1FinalStatus(String status) {
    return [
      AppConstants.STAGE1_APPROVED,
      AppConstants.FINAL_REJECTED,
      AppConstants.WEBSITE_APPROVED,
    ].contains(status);
  }

  // Get stage number for status
  static int getStageNumber(String status) {
    if (AppConstants.stage1Statuses.contains(status)) return 1;
    if ([
      AppConstants.REVIEWERS_ASSIGNED,
      AppConstants.UNDER_PEER_REVIEW,
      AppConstants.PEER_REVIEW_COMPLETED
    ].contains(status)) return 2;
    if ([
      AppConstants.LANGUAGE_EDITING,
      AppConstants.LAYOUT_DESIGN,
      AppConstants.FINAL_PRODUCTION,
      AppConstants.PUBLISHED
    ].contains(status)) return 3;
    return 0;
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
