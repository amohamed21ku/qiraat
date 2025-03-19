import 'package:flutter/material.dart';

Widget detailRow(String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 16),
          ),
        ),
        SizedBox(width: 16),
        SizedBox(
          width: 120,
          child: Text(
            ':$title',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xffa86418),
              fontSize: 16,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

// ============= Status Bar =====================
Widget buildStatusProgressBar(String status) {
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

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    children: List.generate(displaySteps.length - 1, (index) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          color: index < currentIndex
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
                  children: List.generate(displaySteps.length, (index) {
                    bool isActive = index <= currentIndex;
                    bool isLast = index == displaySteps.length - 1;
                    bool isFirst = index == 0;

                    // Choose icon and color based on the step and status
                    IconData? iconData;
                    Color stepColor;

                    if (isLast && isActive) {
                      if (isApproved) {
                        iconData = Icons.check;
                        stepColor = Colors.green;
                      } else if (isRejected) {
                        iconData = Icons.close;
                        stepColor = Colors.red;
                      } else if (isReturnedForEdit) {
                        iconData = Icons.question_mark;
                        stepColor = Colors.grey;
                      } else {
                        // For the placeholder final step when inactive
                        iconData = null;
                        stepColor = Colors.grey.shade300;
                      }
                    } else if (isFirst || isActive) {
                      // Always show check mark for first step and active steps
                      iconData = Icons.check;
                      stepColor =
                          isActive ? Color(0xffa86418) : Colors.grey.shade300;
                    } else {
                      // Inactive steps (except first)
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
              children: List.generate(displaySteps.length, (index) {
                bool isLast = index == displaySteps.length - 1;
                String displayText = displaySteps[index];

                // For the last step, display the actual final status if not active yet
                if (isLast && currentIndex < index) {
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
                        color: index <= currentIndex
                            ? Color(0xffa86418)
                            : Colors.grey.shade300,
                      ),
                      const SizedBox(height: 4),
                      // Status text
                      Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: index == currentIndex
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: index == currentIndex
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
  );
}
// =================== Action Button ===============
