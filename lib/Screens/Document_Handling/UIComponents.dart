import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class DocumentComponents {
  static Widget detailRow(String label, String value) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(width: 16),
            Text('$label:'),
          ],
        ),
      ),
    );
  }
}

class StatusProgressBar extends StatelessWidget {
  final String status;

  const StatusProgressBar({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'حالة المستند',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffa86418),
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildHorizontalProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalProgress() {
    // Handle special end states
    if (_isEndState(status)) {
      // For end states, we want to show progress up to the appropriate step
      // and then show the final state card
      return Column(
        children: [
          _buildHorizontalSteps(
              showCompleted: false), // Don't auto-complete everything
          SizedBox(height: 20),
          _buildFinalStateCard(),
        ],
      );
    }

    // Normal workflow
    return _buildHorizontalSteps();
  }

  Widget _buildHorizontalSteps({bool showCompleted = false}) {
    List<StepData> steps = [
      StepData(
        title: 'ملف مرسل',
        icon: Icons.send,
        shortTitle: 'مرسل',
      ),
      StepData(
        title: 'قبول الملف',
        icon: Icons.check_circle_outline,
        shortTitle: 'مقبول',
      ),
      StepData(
        title: 'الي المحكمين',
        icon: Icons.people,
        shortTitle: 'الى المحكمين',
      ),
      StepData(
        title: 'تم التحكيم',
        icon: Icons.rate_review,
        shortTitle: 'تم التحكيم',
      ),
      StepData(
        title: 'موافقة مدير التحرير',
        icon: Icons.approval,
        shortTitle: 'موافقة مدير التحرير',
      ),
      StepData(
        title: 'موافقة رئيس التحرير',
        icon: Icons.gavel,
        shortTitle: 'الموافقة النهائية',
      ),
    ];

    return Column(
      children: [
        // Progress bar with circles and connecting lines
        Container(
          height: 60,
          child: Stack(
            children: [
              // Connecting lines
              Positioned(
                top: 29, // Center of circles (60/2 - 1)
                left: 30,
                right: 30,
                child: Row(
                  children: List.generate(steps.length - 1, (index) {
                    bool isLineCompleted = showCompleted ||
                        (_isStepCompleted(steps[index].title) &&
                            (_isStepCompleted(steps[index + 1].title) ||
                                _isStepActive(steps[index + 1].title)));

                    return Expanded(
                      child: Container(
                        height: 2,
                        color: isLineCompleted
                            ? Color(0xffa86418)
                            : Colors.grey[300],
                      ),
                    );
                  }),
                ),
              ),
              // Progress circles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(steps.length, (index) {
                  StepData step = steps[index];
                  bool isCompleted =
                      showCompleted || _isStepCompleted(step.title);
                  bool isActive = !showCompleted && _isStepActive(step.title);

                  Color stepColor = isCompleted
                      ? Color(0xffa86418)
                      : isActive
                          ? Color(0xffa86418)
                          : Colors.grey;

                  Color bgColor = isCompleted
                      ? Color(0xffa86418)
                      : isActive
                          ? Color(0xffa86418).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1);

                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: stepColor, width: 2),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : step.icon,
                      color: isCompleted ? Colors.white : stepColor,
                      size: 20,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        // Step labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            StepData step = steps[index];
            bool isCompleted = showCompleted || _isStepCompleted(step.title);
            bool isActive = !showCompleted && _isStepActive(step.title);

            Color textColor = isCompleted
                ? Color(0xffa86418)
                : isActive
                    ? Color(0xffa86418)
                    : Colors.grey[600]!;

            return Container(
              width: 50,
              child: Column(
                children: [
                  Text(
                    step.shortTitle,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : isCompleted
                              ? FontWeight.w600
                              : FontWeight.normal,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isActive)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      height: 3,
                      width: 25,
                      decoration: BoxDecoration(
                        color: Color(0xffa86418),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xffa86418).withOpacity(0.4),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  if (isCompleted && !isActive)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      height: 2,
                      width: 20,
                      color: Color(0xffa86418).withOpacity(0.6),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFinalStateCard() {
    Color endColor;
    IconData endIcon;
    String endTitle;
    String endDescription;

    switch (status) {
      case 'موافقة رئيس التحرير':
      case 'تمت الموافقة النهائية':
        endColor = Colors.green;
        endIcon = Icons.verified;
        endTitle = 'تمت الموافقة النهائية';
        endDescription = 'تم قبول المستند من رئيس التحرير - جاهز للنشر';
        break;
      case 'رفض رئيس التحرير':
      case 'تم الرفض':
      case 'تم الرفض النهائي':
        endColor = Colors.red;
        endIcon = Icons.cancel;
        endTitle = 'تم الرفض النهائي';
        endDescription = 'تم رفض المستند نهائياً';
        break;
      case 'مرسل للتعديل من رئيس التحرير':
      case 'مرسل للتعديل':
        endColor = Colors.orange;
        endIcon = Icons.edit;
        endTitle = 'مرسل للتعديل';
        endDescription = 'تم إرسال المستند للمؤلف للتعديل';
        break;
      default:
        endColor = Colors.grey;
        endIcon = Icons.help;
        endTitle = status;
        endDescription = 'حالة غير معروفة';
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: endColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: endColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: endColor,
              shape: BoxShape.circle,
            ),
            child: Icon(endIcon, color: Colors.white, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  endTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: endColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  endDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: endColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isEndState(String status) {
    return [
      'موافقة رئيس التحرير',
      'تمت الموافقة النهائية',
      'رفض رئيس التحرير',
      'تم الرفض',
      'تم الرفض النهائي',
      'مرسل للتعديل من رئيس التحرير',
      'مرسل للتعديل'
    ].contains(status);
  }

  bool _isStepActive(String stepTitle) {
    // No step should be marked as active if the current status is an end state
    if (_isEndState(status)) {
      return false;
    }

    // A step is only active if it's the NEXT step to be completed
    // For example, if status is "الي المحكمين", then "تم التحكيم" would be active
    List<String> statusOrder = [
      'ملف مرسل',
      'قبول الملف',
      'الي المحكمين',
      'تم التحكيم',
      'موافقة مدير التحرير',
      'موافقة رئيس التحرير'
    ];

    int currentIndex = statusOrder.indexOf(status);
    int stepIndex = statusOrder.indexOf(stepTitle);

    // If current status is not in the normal workflow, no step is active
    if (currentIndex == -1) {
      return false;
    }

    // The next step after current status is active
    return stepIndex == currentIndex + 1;
  }

  bool _isStepCompleted(String stepTitle) {
    List<String> statusOrder = [
      'ملف مرسل',
      'قبول الملف',
      'الي المحكمين',
      'تم التحكيم',
      'موافقة مدير التحرير',
      'موافقة رئيس التحرير'
    ];

    int currentIndex = statusOrder.indexOf(status);
    int stepIndex = statusOrder.indexOf(stepTitle);

    // If current status is an end state, mark appropriate steps as completed
    if (_isEndState(status)) {
      switch (status) {
        case 'موافقة رئيس التحرير':
        case 'تمت الموافقة النهائية':
          // All steps are completed for final approval
          return true;
        case 'مرسل للتعديل من رئيس التحرير':
        case 'رفض رئيس التحرير':
          // Steps up to and including Editor Chief approval are completed
          return stepIndex <= 4; // Include "موافقة مدير التحرير"
        case 'مرسل للتعديل':
          // Steps up to and including review completion are completed
          return stepIndex <= 3; // Include "تم التحكيم"
        default:
          return false;
      }
    }

    // For normal workflow: mark step as completed if current status has reached or passed this step
    if (currentIndex == -1) {
      return false; // Unknown status
    }

    // FIXED: Include the current step as completed
    return currentIndex >= stepIndex;
  }
}

class StepData {
  final String title;
  final IconData icon;
  final String shortTitle;

  StepData({
    required this.title,
    required this.icon,
    required this.shortTitle,
  });
}

class ActionHistoryWidget extends StatelessWidget {
  final List<dynamic> actionLog;

  const ActionHistoryWidget(
      {Key? key,
      required this.actionLog,
      required DocumentSnapshot<Object?> document})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (actionLog.isEmpty) {
      return SizedBox.shrink();
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(top: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'سجل الإجراءات',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffa86418),
                ),
              ),
            ),
            const Divider(height: 30, thickness: 1),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: actionLog.length,
              itemBuilder: (context, index) {
                final action = actionLog[actionLog.length -
                    1 -
                    index]; // Reverse order to show newest first
                final DateTime timestamp =
                    (action['timestamp'] as Timestamp).toDate();
                final String formattedDate =
                    DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp);

                // Determine action color based on the action type
                Color actionColor = Color(0xffa86418);
                if (action['action'] == 'تم الرفض') {
                  actionColor = Colors.red;
                } else if (action['action'] == 'موافقة المحكم') {
                  actionColor = Colors.green;
                }

                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${action['action']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: actionColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(':الإجراء'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                              '${action['userName']} (${action['userPosition']})'),
                          const SizedBox(width: 8),
                          Text(':بواسطة'),
                        ],
                      ),
                      if (action['comment'] != null &&
                          action['comment'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  action['comment'],
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(':تعليق'),
                            ],
                          ),
                        ),
                      if (action['reviewers'] != null &&
                          (action['reviewers'] as List).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(':المحكمون'),
                              const SizedBox(height: 4),
                              ...List.generate(
                                (action['reviewers'] as List).length,
                                (i) => Padding(
                                  padding: const EdgeInsets.only(
                                      right: 16.0, top: 4.0),
                                  child: Text('- ${action['reviewers'][i]}'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewersStatusWidget extends StatelessWidget {
  final Map<String, bool> reviewerApprovals;

  const ReviewersStatusWidget({Key? key, required this.reviewerApprovals})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reviewerApprovals.isEmpty) return SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حالة موافقات المحكمين',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xffa86418),
            ),
          ),
          SizedBox(height: 12),
          ...reviewerApprovals.entries.map((entry) {
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    entry.value ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: entry.value ? Colors.green : Colors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    entry.value ? Icons.check_circle : Icons.hourglass_empty,
                    color: entry.value ? Colors.green : Colors.orange,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: entry.value
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                      ),
                    ),
                  ),
                  Text(
                    entry.value ? 'تمت الموافقة' : 'في انتظار الموافقة',
                    style: TextStyle(
                      fontSize: 12,
                      color: entry.value
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
