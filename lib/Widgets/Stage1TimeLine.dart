// Create a new file: lib/widgets/Stage1DecisionTimeline.dart

import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../App_Constants.dart';

class Stage1DecisionTimeline extends StatelessWidget {
  final DocumentModel document;
  final Function(String) onViewAttachedFile; // Callback to handle file viewing
  final String Function(DateTime) formatDate; // Callback to format date

  const Stage1DecisionTimeline({
    Key? key,
    required this.document,
    required this.onViewAttachedFile,
    required this.formatDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final secretaryActions = document.actionLog
        .where(
            (action) => action.userPosition == AppConstants.POSITION_SECRETARY)
        .toList();
    final editorActions = document.actionLog
        .where((action) =>
            action.userPosition == AppConstants.POSITION_MANAGING_EDITOR)
        .toList();

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 24),

          // Secretary Decision
          if (secretaryActions.isNotEmpty)
            _buildDecisionStep(
              title: 'قرار السكرتير',
              action: secretaryActions.last,
              icon: Icons.assignment_ind,
              color: Colors.orange,
              isFirst: true,
            ),

          if (secretaryActions.isNotEmpty && editorActions.isNotEmpty)
            _buildConnector(),

          // Editor Decision
          if (editorActions.isNotEmpty)
            _buildDecisionStep(
              title: 'قرار مدير التحرير',
              action: editorActions.last,
              icon: Icons.supervisor_account,
              color: Colors.purple,
              isFirst: false,
            ),

          if (editorActions.isNotEmpty) _buildConnector(),

          // Head Editor Decision (Pending)
          _buildPendingDecisionStep(),
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
              colors: [Colors.indigo.shade100, Colors.indigo.shade200],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.timeline, color: Colors.indigo.shade700, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مسار المراجعة في المرحلة الأولى',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'تسلسل القرارات المتخذة حتى الآن',
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

  Widget _buildDecisionStep({
    required String title,
    required ActionLogModel action,
    required IconData icon,
    required Color color,
    required bool isFirst,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.check, color: Colors.white, size: 20),
            ),
          ],
        ),
        SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  action.action,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff2d3748),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${action.userName} - ${formatDate(action.timestamp)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (action.comment != null && action.comment!.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      action.comment!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                // Enhanced Attached File Section with Clickable Button
                if (action.attachedFileUrl != null &&
                    action.attachedFileUrl!.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.15),
                          color.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.attach_file,
                            size: 16,
                            color: color,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تقرير مرفق',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                              if (action.attachedFileName != null)
                                Text(
                                  action.attachedFileName!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: color.withOpacity(0.8),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () =>
                              onViewAttachedFile(action.attachedFileUrl!),
                          icon: Icon(Icons.visibility, size: 14),
                          label: Text(
                            'عرض',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnector() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 20),
          Container(
            width: 2,
            height: 20,
            color: Colors.grey.shade300,
          ),
          SizedBox(width: 14),
          Icon(Icons.arrow_downward, color: Colors.grey.shade400, size: 16),
        ],
      ),
    );
  }

  Widget _buildPendingDecisionStep() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppStyles.isStage1FinalStatus(document.status)
                    ? Colors.green
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppStyles.isStage1FinalStatus(document.status)
                      ? Colors.green.shade700
                      : Colors.indigo.shade400,
                  width: 3,
                ),
              ),
              child: Icon(
                AppStyles.isStage1FinalStatus(document.status)
                    ? Icons.check
                    : Icons.admin_panel_settings,
                color: AppStyles.isStage1FinalStatus(document.status)
                    ? Colors.white
                    : Colors.indigo.shade600,
                size: 20,
              ),
            ),
          ],
        ),
        SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppStyles.isStage1FinalStatus(document.status)
                    ? [
                        Colors.green.withOpacity(0.1),
                        Colors.green.withOpacity(0.05)
                      ]
                    : [
                        Colors.indigo.withOpacity(0.1),
                        Colors.indigo.withOpacity(0.05)
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppStyles.isStage1FinalStatus(document.status)
                    ? Colors.green.withOpacity(0.3)
                    : Colors.indigo.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: AppStyles.isStage1FinalStatus(document.status)
                          ? Colors.green
                          : Colors.indigo,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'قرار رئيس التحرير',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.isStage1FinalStatus(document.status)
                            ? Colors.green
                            : Colors.indigo,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  AppStyles.isStage1FinalStatus(document.status)
                      ? AppStyles.getStatusDisplayName(document.status)
                      : 'في انتظار القرار النهائي',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff2d3748),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
