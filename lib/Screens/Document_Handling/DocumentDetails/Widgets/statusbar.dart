// widgets/status_progress_bar.dart - Updated for Stage 1 Approval Workflow
import 'package:flutter/material.dart';
import '../Constants/App_Constants.dart';

class StatusProgressBar extends StatelessWidget {
  final String status;

  const StatusProgressBar({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final steps = _getStage1WorkflowSteps();
    int currentStepIndex = _getCurrentStepIndex(status);
    bool isCompleted = AppStyles.isStage1FinalStatus(status);

    return Container(
      padding: EdgeInsets.all(24),
      decoration: AppStyles.simpleCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isCompleted),
          SizedBox(height: 24),
          _buildProgressSteps(steps, currentStepIndex, isCompleted),
          if (isCompleted) ...[
            SizedBox(height: 20),
            _buildCompletionStatus(status),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(bool isCompleted) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppStyles.primaryColor.withOpacity(0.1),
                AppStyles.primaryColor.withOpacity(0.2)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.timeline,
            color: AppStyles.primaryColor,
            size: 24,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المرحلة الأولى: الموافقة',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.primaryColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                isCompleted
                    ? 'تم الانتهاء من المرحلة الأولى'
                    : 'الحالة الحالية: ${AppStyles.getStatusDisplayName(status)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (isCompleted)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'مكتملة',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _getStage1WorkflowSteps() {
    return [
      {
        'title': 'استلام المقال',
        'subtitle': 'ملف وارد',
        'icon': Icons.inbox,
        'description': 'تم استلام المقال من المؤلف',
        'status': AppConstants.INCOMING,
      },
      {
        'title': 'مراجعة السكرتير',
        'subtitle': 'فحص أولي',
        'icon': Icons.assignment_ind,
        'description': 'مراجعة التنسيق والمتطلبات الأساسية',
        'status': AppConstants.SECRETARY_REVIEW,
      },
      {
        'title': 'مراجعة مدير التحرير',
        'subtitle': 'تقييم المحتوى',
        'icon': Icons.supervisor_account,
        'description': 'مراجعة الملاءمة والموضوع',
        'status': AppConstants.EDITOR_REVIEW,
      },
      {
        'title': 'مراجعة رئيس التحرير',
        'subtitle': 'قرار نهائي',
        'icon': Icons.admin_panel_settings,
        'description': 'اتخاذ القرار النهائي للمرحلة الأولى',
        'status': AppConstants.HEAD_REVIEW,
      },
      {
        'title': 'انتهاء المرحلة الأولى',
        'subtitle': 'قرار نهائي',
        'icon': Icons.check_circle,
        'description': 'تم اتخاذ القرار النهائي',
        'status': 'completed',
      },
    ];
  }

  Widget _buildProgressSteps(
      List<Map<String, dynamic>> steps, int currentStep, bool isCompleted) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(steps.length, (index) {
          final isStepCompleted =
              index < currentStep || (isCompleted && index == steps.length - 1);
          final isCurrent = index == currentStep && !isCompleted;
          final isActive = isStepCompleted || isCurrent;
          final step = steps[index];

          Color stepColor;
          if (isStepCompleted) {
            stepColor = Colors.green;
          } else if (isCurrent) {
            stepColor = AppStyles.primaryColor;
          } else {
            stepColor = Colors.grey;
          }

          return Row(
            children: [
              Column(
                children: [
                  // Step circle with icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isActive ? stepColor : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isCurrent
                            ? AppStyles.secondaryColor
                            : isStepCompleted
                                ? Colors.green.shade700
                                : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: stepColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      isStepCompleted ? Icons.check : step['icon'] as IconData,
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      size: isStepCompleted ? 28 : 24,
                    ),
                  ),
                  SizedBox(height: 12),

                  // Step info
                  Container(
                    width: 120,
                    child: Column(
                      children: [
                        Text(
                          step['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.w600,
                            color: isActive ? stepColor : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          step['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive
                                ? stepColor.withOpacity(0.8)
                                : Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (isCurrent) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppStyles.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppStyles.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'المرحلة الحالية',
                              style: TextStyle(
                                fontSize: 8,
                                color: AppStyles.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (isStepCompleted && index < steps.length - 1) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'مكتملة',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Connector line
              if (index < steps.length - 1)
                Container(
                  width: 40,
                  height: 3,
                  margin: EdgeInsets.only(bottom: 80),
                  decoration: BoxDecoration(
                    color: index < currentStep || isCompleted
                        ? Colors.green
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCompletionStatus(String status) {
    Color statusColor = AppStyles.getStatusColor(status);
    IconData statusIcon = AppStyles.getStatusIcon(status);
    String statusMessage = _getCompletionMessage(status);
    String nextStepMessage = _getNextStepMessage(status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نتيجة المرحلة الأولى',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppStyles.getStatusDisplayName(status),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xff2d3748),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (nextStepMessage.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    nextStepMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCompletionMessage(String status) {
    switch (status) {
      case AppConstants.STAGE1_APPROVED:
        return 'تمت الموافقة النهائية على المقال للانتقال للمرحلة الثانية (التحكيم).';
      case AppConstants.FINAL_REJECTED:
        return 'تم رفض المقال نهائياً من قبل رئيس التحرير.';
      case AppConstants.WEBSITE_APPROVED:
        return 'تمت الموافقة على نشر المقال على الموقع الإلكتروني فقط.';
      default:
        return 'تم الانتهاء من المرحلة الأولى.';
    }
  }

  String _getNextStepMessage(String status) {
    switch (status) {
      case AppConstants.STAGE1_APPROVED:
        return 'الخطوة التالية: سيتم الانتقال للمرحلة الثانية (التحكيم العلمي).';
      case AppConstants.FINAL_REJECTED:
        return 'سيتم إشعار المؤلف بقرار الرفض مع توضيح الأسباب.';
      case AppConstants.WEBSITE_APPROVED:
        return 'سيتم التواصل مع المؤلف للحصول على موافقته لنشر المقال على الموقع.';
      default:
        return '';
    }
  }

  int _getCurrentStepIndex(String status) {
    // Map status to workflow step index for Stage 1
    switch (status) {
      case AppConstants.INCOMING:
        return 0;
      case AppConstants.SECRETARY_REVIEW:
        return 1;
      case AppConstants.SECRETARY_APPROVED:
      case AppConstants.SECRETARY_REJECTED:
      case AppConstants.SECRETARY_EDIT_REQUESTED:
        return 2; // Moving to editor review
      case AppConstants.EDITOR_REVIEW:
        return 2;
      case AppConstants.EDITOR_APPROVED:
      case AppConstants.EDITOR_REJECTED:
      case AppConstants.EDITOR_WEBSITE_RECOMMENDED:
      case AppConstants.EDITOR_EDIT_REQUESTED:
        return 3; // Moving to head review
      case AppConstants.HEAD_REVIEW:
        return 3;
      case AppConstants.STAGE1_APPROVED:
      case AppConstants.FINAL_REJECTED:
      case AppConstants.WEBSITE_APPROVED:
        return 4; // Completed
      default:
        return 0;
    }
  }
}
