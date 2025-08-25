// constants/app_constants.dart - Updated with complete Stage 2 workflow and Editor Chief position
import 'package:flutter/material.dart';

import 'models/document_model.dart';
// constants/app_constants.dart - Updated with complete Stage 3 workflow

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

  // STAGE 2: PEER REVIEW WORKFLOW STATUSES
  static const String REVIEWERS_ASSIGNED = 'reviewers_assigned';
  static const String UNDER_PEER_REVIEW = 'under_peer_review';
  static const String PEER_REVIEW_COMPLETED = 'peer_review_completed';
  static const String HEAD_REVIEW_STAGE2 = 'head_review_stage2';
  static const String LANGUAGE_EDITING_STAGE2 = 'language_editing_stage2';
  static const String LANGUAGE_EDITOR_COMPLETED = 'language_editor_completed';
  static const String CHEF_REVIEW_LANGUAGE_EDIT = 'chef_review_language_edit';
  static const String STAGE2_APPROVED = 'stage2_approved';
  static const String STAGE2_REJECTED = 'stage2_rejected';
  static const String STAGE2_EDIT_REQUESTED = 'stage2_edit_requested';
  static const String STAGE2_WEBSITE_APPROVED = 'stage2_website_approved';

  // STAGE 3: PRODUCTION WORKFLOW STATUSES
  static const String LAYOUT_DESIGN_STAGE3 = 'layout_design_stage3';
  static const String LAYOUT_DESIGN_COMPLETED = 'layout_design_completed';
  static const String MANAGING_EDITOR_REVIEW_LAYOUT =
      'managing_editor_review_layout';
  static const String HEAD_EDITOR_FIRST_REVIEW = 'head_editor_first_review';
  static const String LAYOUT_REVISION_REQUESTED = 'layout_revision_requested';
  static const String FINAL_REVIEW_STAGE = 'final_review_stage';
  static const String FINAL_REVIEW_COMPLETED = 'final_review_completed';
  static const String FINAL_MODIFICATIONS = 'final_modifications';
  static const String MANAGING_EDITOR_FINAL_CHECK =
      'managing_editor_final_check';
  static const String HEAD_EDITOR_FINAL_APPROVAL = 'head_editor_final_approval';
  static const String PUBLISHED = 'published';

  // Strings
  static const String documentDetails = 'تفاصيل المستند';
  static const String reviewAndManage = 'مراجعة وإدارة المستند';
  static const String processing = 'جاري المعالجة...';
  static const String pleaseWait = 'الرجاء الانتظار';

  // Get next status based on action for Stage 1
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

  // Stage 2 Workflow Statuses List
  static const List<String> stage2Statuses = [
    STAGE1_APPROVED,
    REVIEWERS_ASSIGNED,
    UNDER_PEER_REVIEW,
    PEER_REVIEW_COMPLETED,
    HEAD_REVIEW_STAGE2,
    LANGUAGE_EDITING_STAGE2,
    LANGUAGE_EDITOR_COMPLETED,
    CHEF_REVIEW_LANGUAGE_EDIT,
    STAGE2_APPROVED,
    STAGE2_REJECTED,
    STAGE2_EDIT_REQUESTED,
    STAGE2_WEBSITE_APPROVED,
  ];

  // Stage 3 Workflow Statuses List
  static const List<String> stage3Statuses = [
    STAGE2_APPROVED,
    LAYOUT_DESIGN_STAGE3,
    LAYOUT_DESIGN_COMPLETED,
    MANAGING_EDITOR_REVIEW_LAYOUT,
    HEAD_EDITOR_FIRST_REVIEW,
    LAYOUT_REVISION_REQUESTED,
    FINAL_REVIEW_STAGE,
    FINAL_REVIEW_COMPLETED,
    FINAL_MODIFICATIONS,
    MANAGING_EDITOR_FINAL_CHECK,
    HEAD_EDITOR_FINAL_APPROVAL,
    PUBLISHED,
  ];

  // All workflow statuses
  static const List<String> allWorkflowStatuses = [
    ...stage1Statuses,
    ...stage2Statuses,
    ...stage3Statuses,
  ];

  // Status Display Names (Arabic for UI)
  static const Map<String, String> statusDisplayNames = {
    // Stage 1
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

    // Stage 2
    REVIEWERS_ASSIGNED: 'تم تعيين المحكمين',
    UNDER_PEER_REVIEW: 'تحت التحكيم العلمي',
    PEER_REVIEW_COMPLETED: 'انتهى التحكيم العلمي',
    HEAD_REVIEW_STAGE2: 'مراجعة رئيس التحرير للتحكيم',
    LANGUAGE_EDITING_STAGE2: 'التدقيق اللغوي',
    LANGUAGE_EDITOR_COMPLETED: 'انتهى التدقيق اللغوي',
    CHEF_REVIEW_LANGUAGE_EDIT: 'مراجعة مدير التحرير للتدقيق',
    STAGE2_APPROVED: 'موافق للمرحلة الثالثة',
    STAGE2_REJECTED: 'مرفوض بعد التحكيم',
    STAGE2_EDIT_REQUESTED: 'تعديل مطلوب بناءً على التحكيم',
    STAGE2_WEBSITE_APPROVED: 'موافق لنشر الموقع بعد التحكيم',

    // Stage 3
    LAYOUT_DESIGN_STAGE3: 'الإخراج الفني والتصميم',
    LAYOUT_DESIGN_COMPLETED: 'انتهاء الإخراج الفني',
    MANAGING_EDITOR_REVIEW_LAYOUT: 'مراجعة مدير التحرير للإخراج',
    HEAD_EDITOR_FIRST_REVIEW: 'المراجعة الأولى لرئيس التحرير',
    LAYOUT_REVISION_REQUESTED: 'مطلوب تعديل الإخراج',
    FINAL_REVIEW_STAGE: 'المراجعة النهائية',
    FINAL_REVIEW_COMPLETED: 'انتهاء المراجعة النهائية',
    FINAL_MODIFICATIONS: 'التعديلات النهائية',
    MANAGING_EDITOR_FINAL_CHECK: 'التحقق النهائي من مدير التحرير',
    HEAD_EDITOR_FINAL_APPROVAL: 'الاعتماد النهائي',
    PUBLISHED: 'منشور',
  };

  // User Positions
  static const String POSITION_SECRETARY = 'سكرتير تحرير';
  static const String POSITION_MANAGING_EDITOR = 'مدير التحرير';

  static const String POSITION_HEAD_EDITOR = 'رئيس التحرير';
  static const String POSITION_REVIEWER = 'محكم';
  static const String POSITION_LANGUAGE_EDITOR = 'المدقق اللغوي';
  static const String POSITION_LAYOUT_DESIGNER = 'الاخراج الفني والتصميم';
  static const String POSITION_FINAL_REVIEWER = 'مراجع نهائي';
  static const String POSITION_AUTHOR = 'مؤلف';

  // Reviewer specializations
  static const String REVIEWER_POLITICAL = 'محكم سياسي';
  static const String REVIEWER_ECONOMIC = 'محكم اقتصادي';
  static const String REVIEWER_SOCIAL = 'محكم اجتماعي';
  static const String REVIEWER_GENERAL = 'محكم عام';

  // Action Types for Stage 1
  static const String ACTION_APPROVE = 'approve';
  static const String ACTION_REJECT = 'reject';
  static const String ACTION_REQUEST_EDIT = 'request_edit';
  static const String ACTION_RECOMMEND_WEBSITE = 'recommend_website';
  static const String ACTION_FINAL_APPROVE = 'final_approve';
  static const String ACTION_FINAL_REJECT = 'final_reject';
  static const String ACTION_WEBSITE_APPROVE = 'website_approve';

  // Action Types for Stage 2
  static const String ACTION_ASSIGN_REVIEWERS = 'assign_reviewers';
  static const String ACTION_START_REVIEW = 'start_review';
  static const String ACTION_SUBMIT_REVIEW = 'submit_review';
  static const String ACTION_COMPLETE_REVIEW = 'complete_review';
  static const String ACTION_STAGE2_APPROVE = 'stage2_approve';
  static const String ACTION_STAGE2_REJECT = 'stage2_reject';
  static const String ACTION_STAGE2_EDIT_REQUEST = 'stage2_edit_request';
  static const String ACTION_STAGE2_WEBSITE_APPROVE = 'stage2_website_approve';
  static const String ACTION_SEND_TO_LANGUAGE_EDITOR =
      'send_to_language_editor';
  static const String ACTION_COMPLETE_LANGUAGE_EDITING =
      'complete_language_editing';
  static const String ACTION_CHEF_APPROVE_LANGUAGE_EDIT =
      'chef_approve_language_edit';
  static const String ACTION_CHEF_REJECT_LANGUAGE_EDIT =
      'chef_reject_language_edit';

  // Action Types for Stage 3
  static const String ACTION_SEND_TO_LAYOUT_DESIGNER =
      'send_to_layout_designer';
  static const String ACTION_COMPLETE_LAYOUT_DESIGN = 'complete_layout_design';
  static const String ACTION_APPROVE_LAYOUT = 'approve_layout';
  static const String ACTION_REQUEST_LAYOUT_REVISION =
      'request_layout_revision';
  static const String ACTION_SEND_TO_FINAL_REVIEWER = 'send_to_final_reviewer';
  static const String ACTION_COMPLETE_FINAL_REVIEW = 'complete_final_review';
  static const String ACTION_COMPLETE_FINAL_MODIFICATIONS =
      'complete_final_modifications';
  static const String ACTION_FINAL_APPROVE_FOR_PUBLICATION =
      'final_approve_for_publication';
  static const String ACTION_REQUEST_FINAL_MODIFICATIONS =
      'request_final_modifications';

  // Reviewer Status
  static const String REVIEWER_STATUS_PENDING = 'Pending';
  static const String REVIEWER_STATUS_IN_PROGRESS = 'In Progress';
  static const String REVIEWER_STATUS_COMPLETED = 'Completed';
  static const String REVIEWER_STATUS_DECLINED = 'Declined';

  // Review Recommendations
  static const String REVIEW_RECOMMENDATION_ACCEPT = 'accept';
  static const String REVIEW_RECOMMENDATION_MINOR_REVISION = 'minor_revision';
  static const String REVIEW_RECOMMENDATION_MAJOR_REVISION = 'major_revision';
  static const String REVIEW_RECOMMENDATION_REJECT = 'reject';

  // Stage 3 Workflow Progress Steps
  static List<Map<String, dynamic>> getStage3WorkflowSteps() {
    return [
      {
        'status': STAGE2_APPROVED,
        'title': 'جاهز للإخراج الفني',
        'subtitle': 'اعتماد المرحلة الثانية',
        'icon': Icons.verified,
        'description': 'تم اعتماد المقال من المرحلة الثانية',
        'responsibleRole': 'النظام',
      },
      {
        'status': LAYOUT_DESIGN_STAGE3,
        'title': 'الإخراج الفني والتصميم',
        'subtitle': 'تنسيق وإخراج المقال',
        'icon': Icons.design_services,
        'description': 'المخرج الفني يقوم بعمليات التنسيق والإخراج',
        'responsibleRole': 'المخرج الفني',
      },
      {
        'status': LAYOUT_DESIGN_COMPLETED,
        'title': 'انتهاء الإخراج الفني',
        'subtitle': 'اكتمال التصميم والإخراج',
        'icon': Icons.check_circle_outline,
        'description': 'انتهاء المخرج الفني من عمله',
        'responsibleRole': 'النظام',
      },
      {
        'status': MANAGING_EDITOR_REVIEW_LAYOUT,
        'title': 'مراجعة مدير التحرير',
        'subtitle': 'مراجعة الإخراج الفني',
        'icon': Icons.supervisor_account,
        'description': 'مدير التحرير يراجع الإخراج',
        'responsibleRole': 'مدير التحرير',
      },
      {
        'status': HEAD_EDITOR_FIRST_REVIEW,
        'title': 'المراجعة الأولى لرئيس التحرير',
        'subtitle': 'مراجعة أولى للإخراج',
        'icon': Icons.admin_panel_settings,
        'description': 'رئيس التحرير يراجع الإخراج',
        'responsibleRole': 'رئيس التحرير',
      },
      {
        'status': FINAL_REVIEW_STAGE,
        'title': 'المراجعة النهائية',
        'subtitle': 'مراجعة نهائية متخصصة',
        'icon': Icons.fact_check,
        'description': 'المراجع النهائي يسجل الملاحظات',
        'responsibleRole': 'المراجع النهائي',
      },
      {
        'status': FINAL_MODIFICATIONS,
        'title': 'التعديلات النهائية',
        'subtitle': 'تطبيق الملاحظات النهائية',
        'icon': Icons.edit,
        'description': 'المخرج الفني ينفذ التعديلات النهائية',
        'responsibleRole': 'المخرج الفني',
      },
      {
        'status': HEAD_EDITOR_FINAL_APPROVAL,
        'title': 'الاعتماد النهائي',
        'subtitle': 'اعتماد للطباعة والنشر',
        'icon': Icons.verified_user,
        'description': 'رئيس التحرير يعتمد للنشر النهائي',
        'responsibleRole': 'رئيس التحرير',
      },
      {
        'status': PUBLISHED,
        'title': 'منشور',
        'subtitle': 'تم النشر النهائي',
        'icon': Icons.publish,
        'description': 'تم نشر المقال نهائياً',
        'responsibleRole': 'النظام',
      },
    ];
  }

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

  // Updated Stage 2 Workflow Progress Steps
  static List<Map<String, dynamic>> getStage2WorkflowSteps() {
    return [
      {
        'status': STAGE1_APPROVED,
        'title': 'جاهز لتعيين المحكمين',
        'subtitle': 'انتهاء المرحلة الأولى',
        'icon': Icons.verified,
        'description': 'المقال جاهز لتعيين المحكمين',
        'responsibleRole': 'رئيس التحرير',
      },
      {
        'status': REVIEWERS_ASSIGNED,
        'title': 'تم تعيين المحكمين',
        'subtitle': 'اختيار المحكمين المتخصصين',
        'icon': Icons.people,
        'description': 'تم تعيين المحكمين المتخصصين للمقال',
        'responsibleRole': 'رئيس التحرير',
      },
      {
        'status': UNDER_PEER_REVIEW,
        'title': 'تحت التحكيم العلمي',
        'subtitle': 'مراجعة المحكمين',
        'icon': Icons.rate_review,
        'description': 'المحكمون يراجعون المقال علمياً',
        'responsibleRole': 'المحكمون',
      },
      {
        'status': PEER_REVIEW_COMPLETED,
        'title': 'انتهى التحكيم العلمي',
        'subtitle': 'اكتمال المراجعات',
        'icon': Icons.check_circle,
        'description': 'انتهى جميع المحكمين من مراجعة المقال',
        'responsibleRole': 'النظام',
      },
      {
        'status': HEAD_REVIEW_STAGE2,
        'title': 'مراجعة رئيس التحرير',
        'subtitle': 'مراجعة نتائج التحكيم',
        'icon': Icons.admin_panel_settings,
        'description': 'مراجعة نتائج التحكيم',
        'responsibleRole': 'رئيس التحرير',
      },
      {
        'status': LANGUAGE_EDITING_STAGE2,
        'title': 'التدقيق اللغوي',
        'subtitle': 'مراجعة لغوية وأسلوبية',
        'icon': Icons.spellcheck,
        'description': 'المدقق اللغوي يراجع اللغة والأسلوب',
        'responsibleRole': 'المدقق اللغوي',
      },
      {
        'status': LANGUAGE_EDITOR_COMPLETED,
        'title': 'انتهى التدقيق اللغوي',
        'subtitle': 'اكتمال المراجعة اللغوية',
        'icon': Icons.check_circle_outline,
        'description': 'انتهاء المراجعة اللغوية',
        'responsibleRole': 'النظام',
      },
      {
        'status': CHEF_REVIEW_LANGUAGE_EDIT,
        'title': 'مراجعة مدير التحرير',
        'subtitle': 'الموافقة على التدقيق اللغوي',
        'icon': Icons.supervisor_account,
        'description': 'مدير التحرير يراجع التدقيق اللغوي',
        'responsibleRole': 'مدير التحرير',
      },
    ];
  }

  // Get available actions for Stage 3
  static List<Map<String, dynamic>> getAvailableActions(
      String status, String userPosition) {
    List<Map<String, dynamic>> actions = [];

    // Stage 1 and Stage 2 actions (existing code)
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

      // Stage 2 actions
      case STAGE1_APPROVED:
        if (userPosition == POSITION_HEAD_EDITOR ||
            userPosition == POSITION_MANAGING_EDITOR) {
          actions.add({
            'action': ACTION_ASSIGN_REVIEWERS,
            'title': 'تعيين المحكمين',
            'description': 'اختيار وتعيين المحكمين المتخصصين',
            'icon': Icons.people,
            'color': Colors.blue,
            'requiresAttachment': false,
            'requiresComment': true,
          });
        }
        break;

      case REVIEWERS_ASSIGNED:
        if (userPosition == POSITION_HEAD_EDITOR ||
            userPosition == POSITION_MANAGING_EDITOR) {
          actions.add({
            'action': ACTION_START_REVIEW,
            'title': 'بدء التحكيم',
            'description': 'بدء عملية التحكيم العلمي',
            'icon': Icons.play_arrow,
            'color': Colors.green,
            'requiresAttachment': false,
            'requiresComment': true,
          });
        }
        break;

      case UNDER_PEER_REVIEW:
        if (userPosition.contains('محكم') ||
            userPosition == POSITION_REVIEWER) {
          actions.add({
            'action': ACTION_SUBMIT_REVIEW,
            'title': 'إرسال التحكيم',
            'description': 'إرسال تقييم التحكيم النهائي',
            'icon': Icons.send,
            'color': Colors.blue,
            'requiresAttachment': true,
            'requiresComment': true,
          });
        }
        break;

      case PEER_REVIEW_COMPLETED:
      case HEAD_REVIEW_STAGE2:
        if (userPosition == POSITION_HEAD_EDITOR ||
            userPosition == POSITION_MANAGING_EDITOR) {
          actions.addAll([
            {
              'action': ACTION_SEND_TO_LANGUAGE_EDITOR,
              'title': 'إرسال للتدقيق اللغوي',
              'description': 'إرسال للمدقق اللغوي للمراجعة اللغوية',
              'icon': Icons.spellcheck,
              'color': Colors.blue,
              'requiresAttachment': false,
              'requiresComment': true,
            },
            {
              'action': ACTION_STAGE2_APPROVE,
              'title': 'الموافقة للمرحلة الثالثة',
              'description': 'الموافقة للانتقال للإخراج الفني',
              'icon': Icons.verified,
              'color': Colors.green,
              'requiresAttachment': true,
              'requiresComment': true,
            },
            {
              'action': ACTION_STAGE2_REJECT,
              'title': 'رفض بعد التحكيم',
              'description': 'رفض المقال بناءً على نتائج التحكيم',
              'icon': Icons.cancel,
              'color': Colors.red,
              'requiresAttachment': true,
              'requiresComment': true,
            },
            {
              'action': ACTION_STAGE2_EDIT_REQUEST,
              'title': 'طلب تعديل',
              'description': 'طلب تعديلات بناءً على ملاحظات المحكمين',
              'icon': Icons.edit,
              'color': Colors.orange,
              'requiresAttachment': true,
              'requiresComment': true,
            },
            {
              'action': ACTION_STAGE2_WEBSITE_APPROVE,
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

      case LANGUAGE_EDITING_STAGE2:
        if (userPosition == POSITION_LANGUAGE_EDITOR) {
          actions.add({
            'action': ACTION_COMPLETE_LANGUAGE_EDITING,
            'title': 'إنهاء التدقيق اللغوي',
            'description': 'إرسال المقال بعد التدقيق اللغوي',
            'icon': Icons.send,
            'color': Colors.green,
            'requiresAttachment': true,
            'requiresComment': true,
          });
        }
        break;

      case CHEF_REVIEW_LANGUAGE_EDIT:
        if (userPosition == POSITION_MANAGING_EDITOR) {
          actions.addAll([
            {
              'action': ACTION_CHEF_APPROVE_LANGUAGE_EDIT,
              'title': 'الموافقة على التدقيق',
              'description':
                  'الموافقة على التدقيق اللغوي وإرساله لرئيس التحرير',
              'icon': Icons.check_circle,
              'color': Colors.green,
              'requiresAttachment': false,
              'requiresComment': true,
            },
            {
              'action': ACTION_CHEF_REJECT_LANGUAGE_EDIT,
              'title': 'إعادة للتدقيق',
              'description': 'إعادة المقال للمدقق اللغوي للمراجعة',
              'icon': Icons.edit,
              'color': Colors.orange,
              'requiresAttachment': false,
              'requiresComment': true,
            },
          ]);
        }
        break;

      // NEW STAGE 3 ACTIONS
      case STAGE2_APPROVED:
        if (userPosition == POSITION_HEAD_EDITOR ||
            userPosition == POSITION_MANAGING_EDITOR) {
          actions.add({
            'action': ACTION_SEND_TO_LAYOUT_DESIGNER,
            'title': 'إرسال للإخراج الفني',
            'description': 'إرسال المقال للمخرج الفني للتصميم والإخراج',
            'icon': Icons.design_services,
            'color': Colors.purple,
            'requiresAttachment': false,
            'requiresComment': true,
          });
        }
        break;

      case LAYOUT_DESIGN_STAGE3:
        if (userPosition == POSITION_LAYOUT_DESIGNER) {
          actions.add({
            'action': ACTION_COMPLETE_LAYOUT_DESIGN,
            'title': 'إنهاء الإخراج الفني',
            'description': 'إرسال المقال بعد انتهاء التصميم والإخراج',
            'icon': Icons.send,
            'color': Colors.green,
            'requiresAttachment': true,
            'requiresComment': true,
          });
        }
        break;

      case LAYOUT_DESIGN_COMPLETED:
      case MANAGING_EDITOR_REVIEW_LAYOUT:
        if (userPosition == POSITION_MANAGING_EDITOR) {
          actions.addAll([
            {
              'action': ACTION_APPROVE_LAYOUT,
              'title': 'الموافقة على الإخراج',
              'description': 'الموافقة على الإخراج وإرساله لرئيس التحرير',
              'icon': Icons.check_circle,
              'color': Colors.green,
              'requiresAttachment': false,
              'requiresComment': true,
            },
            {
              'action': ACTION_REQUEST_LAYOUT_REVISION,
              'title': 'طلب تعديل الإخراج',
              'description': 'طلب تعديلات على الإخراج الفني',
              'icon': Icons.edit,
              'color': Colors.orange,
              'requiresAttachment': false,
              'requiresComment': true,
            },
          ]);
        }
        break;

      case HEAD_EDITOR_FIRST_REVIEW:
        if (userPosition == POSITION_HEAD_EDITOR) {
          actions.addAll([
            {
              'action': ACTION_SEND_TO_FINAL_REVIEWER,
              'title': 'إرسال للمراجعة النهائية',
              'description': 'إرسال للمراجع النهائي',
              'icon': Icons.fact_check,
              'color': Colors.blue,
              'requiresAttachment': false,
              'requiresComment': true,
            },
            {
              'action': ACTION_REQUEST_LAYOUT_REVISION,
              'title': 'طلب تعديل الإخراج',
              'description': 'إعادة للمخرج الفني لتعديل الإخراج',
              'icon': Icons.edit,
              'color': Colors.orange,
              'requiresAttachment': false,
              'requiresComment': true,
            },
          ]);
        }
        break;

      case FINAL_REVIEW_STAGE:
        if (userPosition == POSITION_FINAL_REVIEWER) {
          actions.add({
            'action': ACTION_COMPLETE_FINAL_REVIEW,
            'title': 'إنهاء المراجعة النهائية',
            'description': 'إرسال الملاحظات النهائية للإخراج',
            'icon': Icons.send,
            'color': Colors.green,
            'requiresAttachment': true,
            'requiresComment': true,
          });
        }
        break;

      case FINAL_REVIEW_COMPLETED:
      case FINAL_MODIFICATIONS:
        if (userPosition == POSITION_LAYOUT_DESIGNER) {
          actions.add({
            'action': ACTION_COMPLETE_FINAL_MODIFICATIONS,
            'title': 'إنهاء التعديلات النهائية',
            'description': 'إرسال المقال بعد التعديلات النهائية',
            'icon': Icons.send,
            'color': Colors.green,
            'requiresAttachment': true,
            'requiresComment': true,
          });
        }
        break;

      case MANAGING_EDITOR_FINAL_CHECK:
        if (userPosition == POSITION_MANAGING_EDITOR) {
          actions.addAll([
            {
              'action': ACTION_APPROVE_LAYOUT,
              'title': 'تأكيد الإنجاز',
              'description': 'تأكيد إنجاز جميع التعديلات وإرساله لرئيس التحرير',
              'icon': Icons.check_circle,
              'color': Colors.green,
              'requiresAttachment': false,
              'requiresComment': true,
            },
            {
              'action': ACTION_REQUEST_FINAL_MODIFICATIONS,
              'title': 'إعادة للتعديل',
              'description': 'إعادة للمخرج الفني لتعديلات إضافية',
              'icon': Icons.edit,
              'color': Colors.orange,
              'requiresAttachment': false,
              'requiresComment': true,
            },
          ]);
        }
        break;

      case HEAD_EDITOR_FINAL_APPROVAL:
        if (userPosition == POSITION_HEAD_EDITOR) {
          actions.addAll([
            {
              'action': ACTION_FINAL_APPROVE_FOR_PUBLICATION,
              'title': 'اعتماد للنشر النهائي',
              'description': 'اعتماد المقال للطباعة والنشر النهائي',
              'icon': Icons.publish,
              'color': Colors.green,
              'requiresAttachment': false,
              'requiresComment': true,
            },
            {
              'action': ACTION_REQUEST_FINAL_MODIFICATIONS,
              'title': 'ملاحظات إضافية',
              'description': 'إرسال ملاحظات إضافية للمخرج الفني',
              'icon': Icons.edit,
              'color': Colors.orange,
              'requiresAttachment': false,
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

  // User Roles (Extended with new Stage 3 positions)
  static const List<String> userRoles = [
    POSITION_SECRETARY,
    POSITION_MANAGING_EDITOR,
    POSITION_HEAD_EDITOR,
    POSITION_REVIEWER,
    REVIEWER_POLITICAL,
    REVIEWER_ECONOMIC,
    REVIEWER_SOCIAL,
    REVIEWER_GENERAL,
    POSITION_LANGUAGE_EDITOR,
    POSITION_LAYOUT_DESIGNER,
    POSITION_FINAL_REVIEWER,
    POSITION_AUTHOR,
  ];

  // Reviewer specialization types
  static const List<String> reviewerSpecializations = [
    'سياسي',
    'اقتصادي',
    'اجتماعي',
    'عام',
  ];

  // Review criteria for evaluation
  static const List<Map<String, String>> reviewCriteria = [
    {
      'key': 'originality',
      'title': 'الأصالة العلمية',
      'description': 'مدى جدة البحث وإضافته للمعرفة',
    },
    {
      'key': 'methodology',
      'title': 'المنهجية',
      'description': 'سلامة المنهج المستخدم في البحث',
    },
    {
      'key': 'references',
      'title': 'المراجع والاستشهادات',
      'description': 'دقة وحداثة المراجع المستخدمة',
    },
    {
      'key': 'clarity',
      'title': 'وضوح العرض',
      'description': 'وضوح الأسلوب والتنظيم المنطقي',
    },
    {
      'key': 'language',
      'title': 'سلامة اللغة',
      'description': 'سلامة اللغة والأسلوب العلمي',
    },
  ];

  // Minimum and maximum number of reviewers per document
  static const int MIN_REVIEWERS_PER_DOCUMENT = 2;
  static const int MAX_REVIEWERS_PER_DOCUMENT = 4;

  // Review timeline constants (in days)
  static const int REVIEW_DEADLINE_DAYS = 14;
  static const int REVIEW_REMINDER_DAYS = 7;
  static const int REVIEW_OVERDUE_DAYS = 21;

  // Stage 3 timeline constants (in days)
  static const int LAYOUT_DESIGN_DEADLINE_DAYS = 7;
  static const int FINAL_REVIEW_DEADLINE_DAYS = 3;
  static const int FINAL_MODIFICATIONS_DEADLINE_DAYS = 3;
}

// Constants/Style.dart - Updated with Stage 3 styles
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

  // Status Colors - Updated to include all stages
  static Color getStatusColor(String status) {
    // Stage 1 Colors
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
        // Check Stage 2 and Stage 3
        if (AppConstants.stage2Statuses.contains(status)) {
          return getStage2StatusColor(status);
        } else if (AppConstants.stage3Statuses.contains(status)) {
          return getStage3StatusColor(status);
        }
        return Colors.grey.shade600;
    }
  }

  // Status Colors for Stage 2
  static Color getStage2StatusColor(String status) {
    switch (status) {
      case AppConstants.REVIEWERS_ASSIGNED:
        return Colors.blue.shade600;
      case AppConstants.UNDER_PEER_REVIEW:
        return Colors.orange.shade600;
      case AppConstants.PEER_REVIEW_COMPLETED:
        return Colors.purple.shade600;
      case AppConstants.HEAD_REVIEW_STAGE2:
        return Colors.indigo.shade600;
      case AppConstants.LANGUAGE_EDITING_STAGE2:
        return Colors.green.shade600;
      case AppConstants.LANGUAGE_EDITOR_COMPLETED:
        return Colors.green.shade700;
      case AppConstants.CHEF_REVIEW_LANGUAGE_EDIT:
        return Colors.teal.shade600;
      case AppConstants.STAGE2_APPROVED:
        return Colors.green.shade700;
      case AppConstants.STAGE2_REJECTED:
        return Colors.red.shade700;
      case AppConstants.STAGE2_EDIT_REQUESTED:
        return Colors.amber.shade700;
      case AppConstants.STAGE2_WEBSITE_APPROVED:
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  // NEW: Status Colors for Stage 3
  static Color getStage3StatusColor(String status) {
    switch (status) {
      case AppConstants.STAGE2_APPROVED:
        return Colors.green.shade700; // Ready for layout
      case AppConstants.LAYOUT_DESIGN_STAGE3:
        return Colors.purple.shade600; // In layout design
      case AppConstants.LAYOUT_DESIGN_COMPLETED:
        return Colors.purple.shade700; // Layout completed
      case AppConstants.MANAGING_EDITOR_REVIEW_LAYOUT:
        return Colors.indigo.shade600; // Managing editor review
      case AppConstants.HEAD_EDITOR_FIRST_REVIEW:
        return Colors.indigo.shade700; // Head editor first review
      case AppConstants.LAYOUT_REVISION_REQUESTED:
        return Colors.orange.shade600; // Layout revision needed
      case AppConstants.FINAL_REVIEW_STAGE:
        return Colors.blue.shade600; // Final review
      case AppConstants.FINAL_REVIEW_COMPLETED:
        return Colors.blue.shade700; // Final review completed
      case AppConstants.FINAL_MODIFICATIONS:
        return Colors.deepOrange.shade600; // Final modifications
      case AppConstants.MANAGING_EDITOR_FINAL_CHECK:
        return Colors.teal.shade600; // Managing editor final check
      case AppConstants.HEAD_EDITOR_FINAL_APPROVAL:
        return Colors.deepPurple.shade600; // Head editor final approval
      case AppConstants.PUBLISHED:
        return Colors.green.shade800; // Published
      default:
        return Colors.grey.shade600;
    }
  }

  // Status Icons - Updated to include all stages
  static IconData getStatusIcon(String status) {
    // Stage 1 Icons
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
        // Check Stage 2 and Stage 3
        if (AppConstants.stage2Statuses.contains(status)) {
          return getStage2StatusIcon(status);
        } else if (AppConstants.stage3Statuses.contains(status)) {
          return getStage3StatusIcon(status);
        }
        return Icons.circle;
    }
  }

  // Status Icons for Stage 2
  static IconData getStage2StatusIcon(String status) {
    switch (status) {
      case AppConstants.REVIEWERS_ASSIGNED:
        return Icons.people;
      case AppConstants.UNDER_PEER_REVIEW:
        return Icons.rate_review;
      case AppConstants.PEER_REVIEW_COMPLETED:
        return Icons.check_circle;
      case AppConstants.HEAD_REVIEW_STAGE2:
        return Icons.admin_panel_settings;
      case AppConstants.LANGUAGE_EDITING_STAGE2:
        return Icons.spellcheck;
      case AppConstants.LANGUAGE_EDITOR_COMPLETED:
        return Icons.check_circle_outline;
      case AppConstants.CHEF_REVIEW_LANGUAGE_EDIT:
        return Icons.supervisor_account;
      case AppConstants.STAGE2_APPROVED:
        return Icons.verified;
      case AppConstants.STAGE2_REJECTED:
        return Icons.cancel;
      case AppConstants.STAGE2_EDIT_REQUESTED:
        return Icons.edit;
      case AppConstants.STAGE2_WEBSITE_APPROVED:
        return Icons.public;
      default:
        return Icons.circle;
    }
  }

  // NEW: Status Icons for Stage 3
  static IconData getStage3StatusIcon(String status) {
    switch (status) {
      case AppConstants.STAGE2_APPROVED:
        return Icons.verified; // Ready for layout
      case AppConstants.LAYOUT_DESIGN_STAGE3:
        return Icons.design_services; // In layout design
      case AppConstants.LAYOUT_DESIGN_COMPLETED:
        return Icons.check_circle_outline; // Layout completed
      case AppConstants.MANAGING_EDITOR_REVIEW_LAYOUT:
        return Icons.supervisor_account; // Managing editor review
      case AppConstants.HEAD_EDITOR_FIRST_REVIEW:
        return Icons.admin_panel_settings; // Head editor first review
      case AppConstants.LAYOUT_REVISION_REQUESTED:
        return Icons.edit; // Layout revision needed
      case AppConstants.FINAL_REVIEW_STAGE:
        return Icons.fact_check; // Final review
      case AppConstants.FINAL_REVIEW_COMPLETED:
        return Icons.check_circle; // Final review completed
      case AppConstants.FINAL_MODIFICATIONS:
        return Icons.build; // Final modifications
      case AppConstants.MANAGING_EDITOR_FINAL_CHECK:
        return Icons.verified_user; // Managing editor final check
      case AppConstants.HEAD_EDITOR_FINAL_APPROVAL:
        return Icons.approval; // Head editor final approval
      case AppConstants.PUBLISHED:
        return Icons.publish; // Published
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

  // Check if status is in Stage 2
  static bool isStage2Status(String status) {
    return AppConstants.stage2Statuses.contains(status);
  }

  // NEW: Check if status is in Stage 3
  static bool isStage3Status(String status) {
    return AppConstants.stage3Statuses.contains(status);
  }

  // Check if status is a final state in Stage 1
  static bool isStage1FinalStatus(String status) {
    return [
      AppConstants.STAGE1_APPROVED,
      AppConstants.FINAL_REJECTED,
      AppConstants.WEBSITE_APPROVED,
    ].contains(status);
  }

  // Check if status is a final state in Stage 2
  static bool isStage2FinalStatus(String status) {
    return [
      AppConstants.STAGE2_APPROVED,
      AppConstants.STAGE2_REJECTED,
      AppConstants.STAGE2_EDIT_REQUESTED,
      AppConstants.STAGE2_WEBSITE_APPROVED,
    ].contains(status);
  }

  // NEW: Check if status is a final state in Stage 3
  static bool isStage3FinalStatus(String status) {
    return [
      AppConstants.PUBLISHED,
    ].contains(status);
  }

  // Get stage number for status
  static int getStageNumber(String status) {
    if (AppConstants.stage1Statuses.contains(status)) return 1;
    if (AppConstants.stage2Statuses.contains(status)) return 2;
    if (AppConstants.stage3Statuses.contains(status)) return 3;
    return 0;
  }

  // NEW: Get Stage 3 progress
  Map<String, dynamic> getStage3Progress(DocumentModel document) {
    final steps = AppConstants.getStage3WorkflowSteps();
    int currentStepIndex = -1;

    for (int i = 0; i < steps.length; i++) {
      if (steps[i]['status'] == document.status) {
        currentStepIndex = i;
        break;
      }
    }

    if (currentStepIndex == -1) {
      if (AppStyles.isStage3FinalStatus(document.status)) {
        currentStepIndex = steps.length;
      }
    }

    double progressPercentage =
        currentStepIndex >= 0 ? (currentStepIndex + 1) / steps.length : 0.0;

    return {
      'currentStepIndex': currentStepIndex,
      'totalSteps': steps.length,
      'progressPercentage': progressPercentage,
      'isCompleted': AppStyles.isStage3FinalStatus(document.status),
      'currentStep': currentStepIndex >= 0 && currentStepIndex < steps.length
          ? steps[currentStepIndex]
          : null,
    };
  }

  Map<String, dynamic> getStage2Progress(DocumentModel document) {
    final steps = AppConstants.getStage2WorkflowSteps();
    int currentStepIndex = -1;

    for (int i = 0; i < steps.length; i++) {
      if (steps[i]['status'] == document.status) {
        currentStepIndex = i;
        break;
      }
    }

    if (currentStepIndex == -1) {
      if (AppStyles.isStage2FinalStatus(document.status)) {
        currentStepIndex = steps.length;
      }
    }

    double progressPercentage =
        currentStepIndex >= 0 ? (currentStepIndex + 1) / steps.length : 0.0;

    return {
      'currentStepIndex': currentStepIndex,
      'totalSteps': steps.length,
      'progressPercentage': progressPercentage,
      'isCompleted': AppStyles.isStage2FinalStatus(document.status),
      'currentStep': currentStepIndex >= 0 && currentStepIndex < steps.length
          ? steps[currentStepIndex]
          : null,
    };
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
