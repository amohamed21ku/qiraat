// widgets/status_progress_bar.dart
import 'package:flutter/material.dart';
import '../Constants/App_Constants.dart';

class StatusProgressBar extends StatelessWidget {
  final String status;

  const StatusProgressBar({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final steps = _getWorkflowSteps();
    int currentStepIndex = _getCurrentStepIndex(status);

    return Container(
      padding: EdgeInsets.all(24),
      decoration: AppStyles.simpleCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 24),
          _buildProgressSteps(steps, currentStepIndex),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
          child: Icon(Icons.timeline, color: AppStyles.primaryColor, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مسار المقال الأكاديمي',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.primaryColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'المرحلة الحالية: $status',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getWorkflowSteps() {
    return [
      {
        'title': 'استلام المقال',
        'subtitle': 'ملف وارد',
        'icon': Icons.inbox,
        'description': 'تم استلام المقال من المؤلف'
      },
      {
        'title': 'مراجعة السكرتير',
        'subtitle': 'فحص أولي',
        'icon': Icons.assignment_ind,
        'description': 'مراجعة التنسيق والمتطلبات الأساسية'
      },
      {
        'title': 'مراجعة مدير التحرير',
        'subtitle': 'تقييم المحتوى',
        'icon': Icons.supervisor_account,
        'description': 'مراجعة الملاءمة والموضوع'
      },
      {
        'title': 'مراجعة رئيس التحرير',
        'subtitle': 'قرار أولي',
        'icon': Icons.admin_panel_settings,
        'description': 'اتخاذ قرار بالقبول أو الرفض'
      },
      {
        'title': 'التحكيم العلمي',
        'subtitle': 'مراجعة الأقران',
        'icon': Icons.people,
        'description': 'تقييم من قبل المحكمين المتخصصين'
      },
      {
        'title': 'التحرير اللغوي',
        'subtitle': 'تدقيق لغوي',
        'icon': Icons.spellcheck,
        'description': 'مراجعة النحو والأسلوب'
      },
      {
        'title': 'التصميم والإخراج',
        'subtitle': 'التنسيق النهائي',
        'icon': Icons.design_services,
        'description': 'تجهيز التصميم النهائي'
      },
      {
        'title': 'المراجعة النهائية',
        'subtitle': 'فحص الجودة',
        'icon': Icons.fact_check,
        'description': 'مراجعة نهائية للجودة'
      },
      {
        'title': 'الموافقة للنشر',
        'subtitle': 'جاهز للنشر',
        'icon': Icons.publish,
        'description': 'الموافقة النهائية للنشر'
      },
    ];
  }

  Widget _buildProgressSteps(
      List<Map<String, dynamic>> steps, int currentStep) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;
          final isActive = isCompleted || isCurrent;
          final step = steps[index];

          return Row(
            children: [
              Column(
                children: [
                  // Step circle with icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppStyles.primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isCurrent
                            ? AppStyles.secondaryColor
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppStyles.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      step['icon'] as IconData,
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      size: 24,
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
                            color: isActive
                                ? AppStyles.primaryColor
                                : Colors.grey.shade600,
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
                                ? AppStyles.primaryColor.withOpacity(0.8)
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
                    color: index < currentStep
                        ? AppStyles.primaryColor
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

  int _getCurrentStepIndex(String status) {
    // Map status to workflow step index
    switch (status) {
      case 'ملف وارد':
        return 0;
      case 'مراجعة السكرتير':
        return 1;
      case 'مراجعة مدير التحرير':
        return 2;
      case 'مراجعة رئيس التحرير':
        return 3;
      case 'الي المحكمين':
      case 'تم التحكيم':
        return 4;
      case 'التحرير اللغوي':
        return 5;
      case 'التصميم والإخراج':
      case 'المراجعة الأولى للإخراج':
      case 'مراجعة رئيس التحرير للإخراج':
        return 6;
      case 'المراجعة النهائية':
      case 'التعديلات النهائية':
        return 7;
      case 'الموافقة النهائية للنشر':
        return 8;
      case 'مرفوض نهائياً':
      case 'مرفوض لعدم الملاءمة':
      case 'مرسل للموقع':
        return -1; // Special case for rejected/alternative outcomes
      default:
        return 0;
    }
  }
}
