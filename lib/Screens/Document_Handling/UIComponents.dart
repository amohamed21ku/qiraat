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
    final standardSteps = [
      'ملف مرسل',
      'قبول الملف',
      'الي المحكمين',
      'تم التحكيم',
    ];

    // Determine final status
    final bool isApproved = status == 'تمت الموافقه';
    final bool isRejected = status == 'تم الرفض';
    final bool isReturnedForEdit = status == 'مرسل للتعديل';

    // Always include all possible final steps
    final List<String> displaySteps = [...standardSteps];

    // Add the appropriate final status or a placeholder if none is active
    if (isApproved) {
      displaySteps.add('تمت الموافقه');
    } else if (isRejected) {
      displaySteps.add('تم الرفض');
    } else if (isReturnedForEdit) {
      displaySteps.add('مرسل للتعديل');
    } else {
      // If no final status is active yet, add a placeholder final step
      displaySteps.add('تمت الموافقه'); // Default to approval as placeholder
    }

    // Calculate current index based on status
    int currentIndex = displaySteps.indexOf(status);
    if (currentIndex == -1) {
      // If status is not in the display steps, assume it's at the latest standard step
      currentIndex = standardSteps.length - 1;
    }

    // Reverse the steps for RTL display
    final displayStepsRTL = displaySteps.reversed.toList();

    // Recalculate current index for RTL
    int currentIndexRTL = displaySteps.length - 1 - currentIndex;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'حالة المستند',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xffa86418),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
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
              children: [
                // Progress indicators
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Connecting lines - positioned behind the circles
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Row(
                        children:
                            List.generate(displayStepsRTL.length - 1, (index) {
                          // For RTL, we need to invert the active condition
                          return Expanded(
                            child: Container(
                              height: 3,
                              color: index < currentIndexRTL
                                  ? Color(0xffa86418)
                                  : Colors.grey.shade300,
                            ),
                          );
                        }),
                      ),
                    ),
                    // Progress circles
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(displayStepsRTL.length, (index) {
                        bool isActive = index <= currentIndexRTL;
                        bool isLast = index == displayStepsRTL.length - 1;
                        bool isFirst = index == 0;

                        // Choose icon and color based on the step and status
                        IconData? iconData;
                        Color stepColor;

                        // For RTL, the first step is the final status
                        if (isFirst && isActive) {
                          if (isApproved) {
                            iconData = Icons.check;
                            stepColor = Colors.green;
                          } else if (isRejected) {
                            iconData = Icons.close;
                            stepColor = Colors.red;
                          } else if (isReturnedForEdit) {
                            iconData = Icons.question_mark;
                            stepColor = Colors.orange;
                          } else {
                            // For the placeholder final step when inactive
                            iconData = null;
                            stepColor = Colors.grey.shade300;
                          }
                        } else if (isLast || isActive) {
                          // Always show check mark for last step (which is the first in RTL) and active steps
                          iconData = Icons.check;
                          stepColor = isActive
                              ? Color(0xffa86418)
                              : Colors.grey.shade300;
                        } else {
                          // Inactive steps (except last)
                          iconData = null;
                          stepColor = Colors.grey.shade300;
                        }

                        return Container(
                          width: 60,
                          height: 24,
                          decoration: BoxDecoration(
                            color: stepColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: stepColor,
                              width: 2,
                            ),
                          ),
                          child: iconData != null
                              ? Icon(iconData, size: 16, color: Colors.white)
                              : null,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Status labels - each aligned with its corresponding circle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(displayStepsRTL.length, (index) {
                    bool isFirst = index == 0;
                    String displayText = displayStepsRTL[index];

                    // For the first step (in RTL), display the actual final status if not active yet
                    if (isFirst && currentIndexRTL < index) {
                      if (isApproved) {
                        displayText = 'تمت الموافقه';
                      } else if (isRejected) {
                        displayText = 'تم الرفض';
                      } else if (isReturnedForEdit) {
                        displayText = 'مرسل للتعديل';
                      } else {
                        displayText =
                            'الحالة النهائية'; // Generic final status text
                      }
                    }

                    return Container(
                      width: 60, // Same width as the circles above
                      child: Column(
                        children: [
                          // Add a small vertical connector
                          Container(
                            width: 2,
                            height: 8,
                            color: index <= currentIndexRTL
                                ? Color(0xffa86418)
                                : Colors.grey.shade300,
                          ),
                          const SizedBox(height: 4),
                          // Status text
                          Text(
                            displayText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: index == currentIndexRTL
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: index == currentIndexRTL
                                  ? Color(0xffa86418)
                                  : Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
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
                  color: entry.value
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
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
      ),
    );
  }
}
