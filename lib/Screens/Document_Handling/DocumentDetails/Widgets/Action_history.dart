// widgets/action_history_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import '../Constants/App_Constants.dart';
import '../models/document_model.dart';

class ActionHistoryWidget extends StatelessWidget {
  final List<ActionLogModel> actionLog;

  const ActionHistoryWidget({
    Key? key,
    required this.actionLog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (actionLog.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(24),
      margin: EdgeInsets.only(top: 20),
      decoration: AppStyles.simpleCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 20),
          _buildActionsList(),
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
              colors: [Colors.blue.shade100, Colors.blue.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.history, color: Colors.blue.shade700, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سجل الإجراءات',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'تاريخ جميع الإجراءات المتخذة',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${actionLog.length}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsList() {
    // Reverse the list to show most recent actions first
    final reversedActions = actionLog.reversed.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: reversedActions.length,
      itemBuilder: (context, index) {
        return ActionCard(action: reversedActions[index]);
      },
    );
  }
}

class ActionCard extends StatelessWidget {
  final ActionLogModel action;

  const ActionCard({Key? key, required this.action}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('MMM dd, yyyy - hh:mm a').format(action.timestamp);
    final actionInfo = _getActionInfo(action.action);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            actionInfo['color'].withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: actionInfo['color'].withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: actionInfo['color'].withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: actionInfo['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    actionInfo['icon'],
                    color: actionInfo['color'],
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.action,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: actionInfo['color'],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // File attachment indicator
                if (action.attachedFileUrl != null)
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.attach_file,
                      color: Colors.blue,
                      size: 16,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            _buildActionDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionDetails() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performed by
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey.shade600),
              SizedBox(width: 8),
              Text(
                'بواسطة:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${action.userName} (${action.userPosition})',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xff2d3748),
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: ui.TextDirection.rtl,
                ),
              ),
            ],
          ),

          // Comment
          if (action.comment != null && action.comment!.isNotEmpty) ...[
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.comment, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text(
                  'تعليق:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    action.comment!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff2d3748),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],

          // Attached file
          if (action.attachedFileUrl != null) ...[
            SizedBox(height: 12),
            _buildAttachedFile(),
          ],

          // Reviewers (for reviewer assignment actions)
          if (action.reviewers != null && action.reviewers!.isNotEmpty) ...[
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text(
                  'المحكمون:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: action.reviewers!.map((reviewer) {
                      final actionInfo = _getActionInfo(action.action);
                      return Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: actionInfo['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          reviewer.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: actionInfo['color'],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachedFile() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.05),
            Colors.blue.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getFileIcon(action.attachedFileName ?? ''),
              color: Colors.blue.shade700,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملف مرفق:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  action.attachedFileName ?? 'ملف مرفق',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade500, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _viewAttachedFile(action.attachedFileUrl!),
              icon: Icon(Icons.visibility, color: Colors.white, size: 16),
              label: Text(
                'عرض',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getActionInfo(String actionType) {
    Color actionColor = AppStyles.primaryColor;
    IconData actionIcon = Icons.info;

    if (actionType.contains('رفض') || actionType.contains('الرفض')) {
      actionColor = Colors.red;
      actionIcon = Icons.cancel;
    } else if (actionType.contains('موافقة') ||
        actionType.contains('قبول') ||
        actionType.contains('مرسل') ||
        actionType.contains('تمت')) {
      actionColor = Colors.green;
      actionIcon = Icons.check_circle;
    } else if (actionType.contains('تعديل') || actionType.contains('مطلوب')) {
      actionColor = Colors.orange;
      actionIcon = Icons.edit;
    } else if (actionType.contains('محكمين') || actionType.contains('الي')) {
      actionColor = Colors.blue;
      actionIcon = Icons.people;
    } else if (actionType.contains('مدير التحرير')) {
      actionColor = Colors.purple;
      actionIcon = Icons.approval;
    }

    return {
      'color': actionColor,
      'icon': actionIcon,
    };
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.attach_file;
    }
  }

  void _viewAttachedFile(String fileUrl) {
    // Implement file viewing logic
    // This could open a dialog or navigate to a file viewer
    print('Viewing file: $fileUrl');
  }
}
