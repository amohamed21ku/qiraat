// widgets/action_buttons_widget.dart - Stage 1 Approval Workflow
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../Classes/current_user_providerr.dart';

import '../Constants/App_Constants.dart';
import '../models/document_model.dart';

class ActionButtonsWidget extends StatelessWidget {
  final String status;
  final DocumentModel document;
  final Function(String, String?, String?, String?)
      onStatusUpdate; // action, comment, fileUrl, fileName
  final VoidCallback? onAdminStatusChange;

  const ActionButtonsWidget({
    Key? key,
    required this.status,
    required this.document,
    required this.onStatusUpdate,
    this.onAdminStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentUserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;
        return Column(
          children: [
            // Admin Controls for Head Editor and Managing Editor
            if (_isPrivilegedUser(currentUser))
              _buildAdminControls(context, currentUser),

            // Stage 1 Workflow Action Buttons
            _buildStage1ActionButtons(status, currentUser, context),
          ],
        );
      },
    );
  }

  Widget _buildAdminControls(BuildContext context, dynamic currentUser) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.purple.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200, width: 2),
      ),
      child: Column(
        children: [
          // Admin Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'أدوات الإدارة المتقدمة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentUser?.position ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Admin Action Button
          Padding(
            padding: EdgeInsets.all(16),
            child: _buildAdminButton(
              title: 'تغيير الحالة',
              subtitle: 'تغيير حالة المقال إلى أي مرحلة',
              icon: Icons.swap_horiz,
              color: Colors.indigo,
              onPressed: onAdminStatusChange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required MaterialColor color,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.shade50, color.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color.shade600, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color.shade700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color.shade600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStage1ActionButtons(
      String status, dynamic currentUser, BuildContext context) {
    final userPosition = currentUser?.position ?? '';
    final availableActions =
        AppConstants.getAvailableActions(status, userPosition);

    if (availableActions.isEmpty) {
      return _buildWaitingCard(status);
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header showing current stage
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppStyles.getStatusColor(status).withOpacity(0.8),
                  AppStyles.getStatusColor(status),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    AppStyles.getStatusIcon(status),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المرحلة الأولى: الموافقة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        AppStyles.getStatusDisplayName(status),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: _buildActionButtonsList(availableActions, context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtonsList(
      List<Map<String, dynamic>> actions, BuildContext context) {
    List<Widget> buttons = [];

    for (int i = 0; i < actions.length; i++) {
      final action = actions[i];

      if (i == 0) {
        // Primary action - full width
        buttons.add(_buildPrimaryActionButton(action, context));
      } else {
        // Secondary actions - smaller
        buttons.add(SizedBox(height: 12));
        buttons.add(_buildSecondaryActionButton(action, context));
      }
    }

    return buttons;
  }

  Widget _buildPrimaryActionButton(
      Map<String, dynamic> action, BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [action['color'].shade500, action['color'].shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: action['color'].withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showActionDialog(context, action),
        icon: Icon(action['icon'], color: Colors.white, size: 24),
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              action['title'],
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              action['description'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActionButton(
      Map<String, dynamic> action, BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: action['color'].shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showActionDialog(context, action),
        icon: Icon(action['icon'], color: action['color'], size: 18),
        label: Text(
          action['title'],
          style: TextStyle(
            color: action['color'],
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingCard(String status) {
    String message = _getWaitingMessage(status);
    String responsibleRole = _getResponsibleRole(status);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.hourglass_top, color: Colors.orange, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (responsibleRole.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        'المسؤول: $responsibleRole',
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getWaitingMessage(String status) {
    switch (status) {
      case AppConstants.INCOMING:
        return 'في انتظار بدء المراجعة';
      case AppConstants.SECRETARY_APPROVED:
        return 'في انتظار مراجعة مدير التحرير';
      case AppConstants.SECRETARY_REJECTED:
        return 'تم رفض الملف من السكرتير';
      case AppConstants.SECRETARY_EDIT_REQUESTED:
        return 'في انتظار مراجعة مدير التحرير للتعديلات المطلوبة';
      case AppConstants.EDITOR_APPROVED:
      case AppConstants.EDITOR_REJECTED:
      case AppConstants.EDITOR_WEBSITE_RECOMMENDED:
      case AppConstants.EDITOR_EDIT_REQUESTED:
        return 'في انتظار القرار النهائي من رئيس التحرير';
      case AppConstants.STAGE1_APPROVED:
        return 'تمت الموافقة النهائية - جاهز للمرحلة الثانية';
      case AppConstants.FINAL_REJECTED:
        return 'تم الرفض النهائي للملف';
      case AppConstants.WEBSITE_APPROVED:
        return 'تمت الموافقة للنشر على الموقع';
      default:
        return 'في انتظار الإجراء التالي';
    }
  }

  String _getResponsibleRole(String status) {
    switch (status) {
      case AppConstants.INCOMING:
      case AppConstants.SECRETARY_REVIEW:
        return 'سكرتير التحرير';
      case AppConstants.EDITOR_REVIEW:
        return 'مدير التحرير';
      case AppConstants.HEAD_REVIEW:
        return 'رئيس التحرير';
      default:
        return '';
    }
  }

  void _showActionDialog(BuildContext context, Map<String, dynamic> action) {
    showDialog(
      context: context,
      builder: (dialogContext) => ActionWithAttachmentDialog(
        title: action['title'],
        description: action['description'],
        action: action['action'],
        requiresAttachment: action['requiresAttachment'] ?? false,
        requiresComment: action['requiresComment'] ?? false,
        color: action['color'],
        onConfirm: (comment, fileUrl, fileName) {
          Navigator.pop(dialogContext);

          // Get next status based on action
          String nextStatus =
              AppConstants.getNextStatus(status, action['action'], '');

          // Call the onStatusUpdate with the next status
          onStatusUpdate(nextStatus, comment, fileUrl, fileName);
        },
      ),
    );
  }

  bool _isPrivilegedUser(dynamic currentUser) {
    if (currentUser?.position == null) return false;
    return currentUser.position == AppConstants.POSITION_HEAD_EDITOR ||
        currentUser.position == AppConstants.POSITION_MANAGING_EDITOR;
  }
}

// Dialog for Stage 1 actions with attachment support
class ActionWithAttachmentDialog extends StatefulWidget {
  final String title;
  final String description;
  final String action;
  final bool requiresAttachment;
  final bool requiresComment;
  final Color color;
  final Function(String?, String?, String?)
      onConfirm; // comment, fileUrl, fileName

  const ActionWithAttachmentDialog({
    Key? key,
    required this.title,
    required this.description,
    required this.action,
    required this.requiresAttachment,
    required this.requiresComment,
    required this.color,
    required this.onConfirm,
  }) : super(key: key);

  @override
  _ActionWithAttachmentDialogState createState() =>
      _ActionWithAttachmentDialogState();
}

class _ActionWithAttachmentDialogState
    extends State<ActionWithAttachmentDialog> {
  final TextEditingController _commentController = TextEditingController();
  String? _attachedFileUrl;
  String? _attachedFileName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.assignment, color: widget.color, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            widget.description,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment field
          Text('تعليق${widget.requiresComment ? ' (مطلوب)' : ' (اختياري)'}:'),
          SizedBox(height: 8),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'اكتب تعليقك أو مبررات القرار هنا...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            maxLines: 3,
            textAlign: TextAlign.right,
          ),

          // File attachment section
          if (widget.requiresAttachment || widget.action != 'start_review') ...[
            SizedBox(height: 16),
            Text(
                'إرفاق مستند${widget.requiresAttachment ? ' (مطلوب)' : ' (اختياري)'}:'),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: _pickFile,
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child:
                          Icon(Icons.attach_file, color: Colors.grey.shade600),
                    ),
                    Expanded(
                      child: Text(
                        _attachedFileName ??
                            'اختر ملف للإرفاق (تقرير المراجعة)',
                        style: TextStyle(
                          color: _attachedFileName != null
                              ? Colors.black
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    if (_attachedFileName != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _attachedFileName = null;
                            _attachedFileUrl = null;
                          });
                        },
                        icon: Icon(Icons.close, color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.requiresAttachment)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'يجب إرفاق مستند يوضح مبررات القرار ونتائج المراجعة',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validation
            if (widget.requiresComment &&
                _commentController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('الرجاء إدخال تعليق')),
              );
              return;
            }

            if (widget.requiresAttachment && _attachedFileName == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('الرجاء إرفاق مستند')),
              );
              return;
            }

            widget.onConfirm(
              _commentController.text.trim().isEmpty
                  ? null
                  : _commentController.text.trim(),
              _attachedFileUrl,
              _attachedFileName,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            foregroundColor: Colors.white,
          ),
          child: Text('تأكيد'),
        ),
      ],
    );
  }

  void _pickFile() {
    // Placeholder for file picker implementation
    // In a real app, you would use file_picker package
    setState(() {
      _attachedFileName =
          'تقرير_مراجعة_${DateTime.now().millisecondsSinceEpoch}.pdf';
      _attachedFileUrl = 'https://example.com/files/${_attachedFileName}';
    });
  }
}
