// widgets/action_buttons_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../Classes/current_user_providerr.dart';

import '../Constants/App_Constants.dart';
import '../Services/Document_Services.dart';
import '../models/document_model.dart';

class ActionButtonsWidget extends StatelessWidget {
  final String status;
  final DocumentModel document;
  final Function(String, String?) onStatusUpdate;
  final VoidCallback? onAssignReviewers;
  final VoidCallback? onReviewerApproval;
  final VoidCallback? onAcceptReject;
  final VoidCallback? onFinalApproval;
  final VoidCallback? onHeadOfEditorsApproval;
  final VoidCallback? onManageReviewers; // New callback for reviewer management
  final VoidCallback?
      onAdminStatusChange; // New callback for admin status change

  const ActionButtonsWidget({
    Key? key,
    required this.status,
    required this.document,
    required this.onStatusUpdate,
    this.onAssignReviewers,
    this.onReviewerApproval,
    this.onAcceptReject,
    this.onFinalApproval,
    this.onHeadOfEditorsApproval,
    this.onManageReviewers,
    this.onAdminStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentUserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;
        return Column(
          children: [
            // Admin Controls (show first for privileged users)
            if (_isPrivilegedUser(currentUser))
              _buildAdminControls(context, currentUser),

            // Regular workflow buttons
            _buildButtonForStatus(status, currentUser, context),
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

          // Admin Action Buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildAdminButton(
                        title: 'تغيير الحالة',
                        subtitle: 'تغيير حالة المستند إلى أي مرحلة',
                        icon: Icons.swap_horiz,
                        color: Colors.indigo,
                        onPressed: onAdminStatusChange,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildAdminButton(
                        title: 'إدارة المحكمين',
                        subtitle: 'إضافة أو حذف أو تعديل المحكمين',
                        icon: Icons.people_outline,
                        color: Colors.teal,
                        onPressed: onManageReviewers,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildAdminButton(
                        title: 'إعادة تعيين المحكمين',
                        subtitle: 'مسح جميع المحكمين وإعادة التعيين',
                        icon: Icons.refresh,
                        color: Colors.orange,
                        onPressed: () => _showResetReviewersDialog(context),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildAdminButton(
                        title: 'إلغاء التحكيم',
                        subtitle: 'إلغاء عملية التحكيم والعودة لمرحلة سابقة',
                        icon: Icons.cancel_outlined,
                        color: Colors.red,
                        onPressed: () => _showCancelReviewDialog(context),
                      ),
                    ),
                  ],
                ),

                // Emergency Override Section
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emergency,
                          color: Colors.red.shade600, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'هذه الأدوات متاحة فقط لرئيس ومدير التحرير لضمان مرونة إدارة سير العمل',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                SizedBox(width: 8),
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

  void _showResetReviewersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إعادة تعيين المحكمين'),
        content: Text(
          'هل أنت متأكد من رغبتك في مسح جميع المحكمين المعيّنين حالياً؟\n\nسيتم:\n• إزالة جميع المحكمين الحاليين\n• مسح جميع التعليقات والموافقات\n• إعادة الملف لمرحلة "قبول الملف"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onStatusUpdate(
                  'قبول الملف', 'إعادة تعيين المحكمين من قبل الإدارة');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('تأكيد الإعادة'),
          ),
        ],
      ),
    );
  }

  void _showCancelReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إلغاء التحكيم'),
        content: Text(
          'هل تريد إلغاء عملية التحكيم والعودة إلى مرحلة سابقة؟\n\nيمكنك اختيار المرحلة المناسبة للعودة إليها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showBackStageDialog(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('اختيار مرحلة'),
          ),
        ],
      ),
    );
  }

  void _showBackStageDialog(BuildContext context) {
    final stages = [
      {'key': 'ملف مرسل', 'title': 'ملف مرسل (المرحلة الأولى)'},
      {'key': 'قبول الملف', 'title': 'قبول الملف'},
      {'key': 'الي المحكمين', 'title': 'إلى المحكمين'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اختيار المرحلة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: stages
              .map((stage) => ListTile(
                    title: Text(stage['title']!),
                    onTap: () {
                      Navigator.pop(context);
                      onStatusUpdate(stage['key']!,
                          'إعادة إلى مرحلة سابقة من قبل الإدارة');
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildButtonForStatus(
      String status, dynamic currentUser, BuildContext context) {
    final canAssignReviewers =
        PermissionService.canAssignReviewers(currentUser?.position);
    final canFinalApprove =
        PermissionService.canFinalApprove(currentUser?.position);
    final isHeadOfEditors =
        PermissionService.isHeadOfEditors(currentUser?.position);
    final isEditorChief =
        PermissionService.isEditorChief(currentUser?.position);

    // Check if current user is a reviewer
    final isCurrentUserReviewer = _isCurrentUserReviewer(currentUser);
    final hasCurrentUserApproved = _hasCurrentUserApproved(currentUser);

    switch (status) {
      case 'ملف مرسل':
        return _buildAcceptRejectButton();

      case 'قبول الملف':
        if (canAssignReviewers) {
          return Column(
            children: [
              _buildAssignReviewersButton(),
              // Show option to directly approve without reviewers for privileged users
              if (_isPrivilegedUser(currentUser)) SizedBox(height: 12),
              if (_isPrivilegedUser(currentUser)) _buildDirectApprovalButton(),
            ],
          );
        }
        break;

      case 'الي المحكمين':
        return Column(
          children: [
            if (isCurrentUserReviewer && !hasCurrentUserApproved)
              _buildReviewerApprovalButton(),
            if (isCurrentUserReviewer && hasCurrentUserApproved)
              _buildAlreadyApprovedCard(),

            // Show reviewer management for privileged users
            if (_isPrivilegedUser(currentUser)) SizedBox(height: 12),
            if (_isPrivilegedUser(currentUser)) _buildReviewerManagementCard(),
          ],
        );

      case 'تم التحكيم':
        if (isEditorChief && !isHeadOfEditors) {
          return _buildFinalApprovalButton();
        } else if (!canFinalApprove) {
          return _buildWaitingForApprovalCard('بانتظار موافقة مدير التحرير');
        }
        break;

      case 'موافقة مدير التحرير':
        if (isHeadOfEditors) {
          return _buildHeadOfEditorsApprovalButton();
        } else {
          return _buildWaitingForApprovalCard(
              'بانتظار الموافقة النهائية من رئيس التحرير');
        }
        break;

      case 'موافقة رئيس التحرير':
        return _buildCompletedCard(
            'تمت الموافقة النهائية - جاهز للنشر', Colors.green);

      case 'مرسل للتعديل':
      case 'مرسل للتعديل من رئيس التحرير':
        return _buildCompletedCard('تم إرسال المستند للتعديل', Colors.orange);

      case 'تم الرفض':
      case 'تم الرفض النهائي':
      case 'رفض رئيس التحرير':
        return _buildCompletedCard('تم رفض المستند نهائياً', Colors.red);
    }

    return SizedBox.shrink();
  }

  Widget _buildDirectApprovalButton() {
    return Container(
      width: double.infinity,
      decoration: AppStyles.gradientButtonDecoration(
        Colors.green.shade400,
        Colors.green.shade600,
      ),
      child: ElevatedButton.icon(
        onPressed: () =>
            onStatusUpdate('موافقة مدير التحرير', 'موافقة مباشرة بدون تحكيم'),
        icon: Icon(Icons.fast_forward, color: Colors.white, size: 24),
        label: Text(
          'موافقة مباشرة (بدون تحكيم)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: AppStyles.transparentButtonStyle.copyWith(
          padding:
              MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 16)),
        ),
      ),
    );
  }

  Widget _buildReviewerManagementCard() {
    final reviewerCount = document.reviewers.length;
    final approvedCount =
        document.reviewers.where((r) => r.reviewStatus == 'Approved').length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.people, color: Colors.blue.shade600, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة المحكمين',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      'العدد: $reviewerCount • وافق: $approvedCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onManageReviewers,
                  icon: Icon(Icons.edit, size: 16),
                  label: Text('تعديل المحكمين', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      onStatusUpdate('تم التحكيم', 'إنهاء التحكيم إدارياً'),
                  icon: Icon(Icons.check_circle, size: 16),
                  label: Text('إنهاء التحكيم', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Check if user is privileged (head of editors or editor chief)
  bool _isPrivilegedUser(dynamic currentUser) {
    if (currentUser?.position == null) return false;
    return currentUser.position == 'رئيس التحرير' ||
        currentUser.position == 'مدير التحرير';
  }

  Widget _buildAcceptRejectButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 20),
      decoration: AppStyles.gradientButtonDecoration(
        AppStyles.primaryColor,
        AppStyles.secondaryColor,
      ),
      child: ElevatedButton.icon(
        onPressed: onAcceptReject,
        icon: Icon(Icons.assignment_turned_in, color: Colors.white, size: 24),
        label: Text(
          'قبول / رفض الملف',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: AppStyles.transparentButtonStyle.copyWith(
          padding:
              MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 20)),
        ),
      ),
    );
  }

  Widget _buildAssignReviewersButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 20),
      decoration: AppStyles.gradientButtonDecoration(
        Colors.blue.shade500,
        Colors.blue.shade700,
      ),
      child: ElevatedButton.icon(
        onPressed: onAssignReviewers,
        icon: Icon(Icons.person_add, color: Colors.white, size: 24),
        label: Text(
          'تعيين المحكمين',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: AppStyles.transparentButtonStyle.copyWith(
          padding:
              MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 20)),
        ),
      ),
    );
  }

  Widget _buildReviewerApprovalButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 20),
      decoration: AppStyles.gradientButtonDecoration(
        Colors.green.shade500,
        Colors.green.shade700,
      ),
      child: ElevatedButton.icon(
        onPressed: onReviewerApproval,
        icon: Icon(Icons.thumb_up, color: Colors.white, size: 24),
        label: Text(
          'الموافقة والتعليق',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: AppStyles.transparentButtonStyle.copyWith(
          padding:
              MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 20)),
        ),
      ),
    );
  }

  Widget _buildFinalApprovalButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 20),
      decoration: AppStyles.gradientButtonDecoration(
        Colors.purple.shade500,
        Colors.purple.shade700,
      ),
      child: ElevatedButton.icon(
        onPressed: onFinalApproval,
        icon: Icon(Icons.send, color: Colors.white, size: 24),
        label: Text(
          'موافقة مدير التحرير',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: AppStyles.transparentButtonStyle.copyWith(
          padding:
              MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 20)),
        ),
      ),
    );
  }

  Widget _buildHeadOfEditorsApprovalButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 20),
      decoration: AppStyles.gradientButtonDecoration(
        Colors.indigo.shade500,
        Colors.purple.shade600,
      ),
      child: ElevatedButton.icon(
        onPressed: onHeadOfEditorsApproval,
        icon: Icon(Icons.verified_user, color: Colors.white, size: 24),
        label: Text(
          'الموافقة النهائية',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: AppStyles.transparentButtonStyle.copyWith(
          padding:
              MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 20)),
        ),
      ),
    );
  }

  Widget _buildAlreadyApprovedCard() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: AppStyles.successCardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.check_circle, color: Colors.green, size: 24),
          ),
          SizedBox(width: 12),
          Text(
            'تمت موافقتك على المستند',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForApprovalCard(String message) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: AppStyles.warningCardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.hourglass_top, color: Colors.orange, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(String message, MaterialColor color) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.shade50, color.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade300, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForColor(color),
              color: color,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.shade700,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get appropriate icon based on color
  IconData _getIconForColor(MaterialColor color) {
    if (color == Colors.green) {
      return Icons.verified;
    } else if (color == Colors.orange) {
      return Icons.edit;
    } else if (color == Colors.red) {
      return Icons.cancel;
    } else {
      return Icons.info;
    }
  }

  bool _isCurrentUserReviewer(dynamic currentUser) {
    if (currentUser == null) return false;

    for (var reviewer in document.reviewers) {
      if (reviewer.userId == currentUser.id ||
          reviewer.email == currentUser.email ||
          reviewer.name == currentUser.name) {
        return true;
      }
    }
    return false;
  }

  bool _hasCurrentUserApproved(dynamic currentUser) {
    if (currentUser == null) return false;

    for (var reviewer in document.reviewers) {
      if ((reviewer.userId == currentUser.id ||
              reviewer.email == currentUser.email ||
              reviewer.name == currentUser.name) &&
          reviewer.reviewStatus == 'Approved') {
        return true;
      }
    }
    return false;
  }
}
