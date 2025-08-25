// pages/Stage1/Stage1EditorDetailsPage.dart - Updated with comprehensive file handling
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'package:path/path.dart' as path;
import 'package:qiraat/Widgets/SecreterReportSection.dart';
import 'package:qiraat/Widgets/documentInfoSection.dart';

import '../../Classes/current_user_providerr.dart';
import '../App_Constants.dart';
import '../Document_Services.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/Action_history.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/senderinfocard.dart';
import '../models/document_model.dart';

class Stage1EditorDetailsPage extends StatefulWidget {
  final DocumentModel document;

  const Stage1EditorDetailsPage({Key? key, required this.document})
      : super(key: key);

  @override
  _Stage1EditorDetailsPageState createState() =>
      _Stage1EditorDetailsPageState();
}

class _Stage1EditorDetailsPageState extends State<Stage1EditorDetailsPage>
    with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();

  // ADD THESE NEW VARIABLES FOR INLINE FORM:
  late TextEditingController _commentController;
  String? _attachedFileName;
  String? _attachedFileUrl;
  bool _isUploading = false;
  String? _selectedAction;

  bool _isLoading = false;
  DocumentModel? _document;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPosition;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // File handling constants
  static const Map<String, String> supportedFileTypes = {
    '.pdf': 'application/pdf',
    '.doc': 'application/msword',
    '.docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.txt': 'text/plain',
    '.rtf': 'application/rtf',
    '.odt': 'application/vnd.oasis.opendocument.text',
  };

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _commentController = TextEditingController();
    _initializeAnimations();
    _getCurrentUserInfo();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  Future<void> _getCurrentUserInfo() async {
    final currentUserProvider =
        Provider.of<CurrentUserProvider>(context, listen: false);
    final currentUser = currentUserProvider.currentUser;

    if (currentUser != null) {
      setState(() {
        _currentUserId = currentUser.id ?? currentUser.email;
        _currentUserName = currentUser.name;
        _currentUserPosition = currentUser.position;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppStyles.backgroundColor,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 1024;

              return Stack(
                children: [
                  SingleChildScrollView(
                    child: AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(isDesktop),
                              _buildContent(isDesktop),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isLoading) _buildLoadingOverlay(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade500,
            Colors.purple.shade700,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.supervisor_account,
                    color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مراجعة مدير التحرير',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'المرحلة الأولى - تقييم المحتوى والملاءمة',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildEditorStatusBar(),
        ],
      ),
    );
  }

  Widget _buildEditorStatusBar() {
    final status = _document!.status;
    String statusText = '';
    Color statusColor = Colors.white;
    IconData statusIcon = Icons.info;

    switch (status) {
      case AppConstants.SECRETARY_APPROVED:
        statusText = 'تم قبوله من السكرتير - جاهز للمراجعة';
        statusColor = Colors.green.shade100;
        statusIcon = Icons.check_circle;
        break;
      case AppConstants.SECRETARY_REJECTED:
        statusText = 'تم رفضه من السكرتير - يمكن إعادة المراجعة';
        statusColor = Colors.red.shade100;
        statusIcon = Icons.cancel;
        break;
      case AppConstants.SECRETARY_EDIT_REQUESTED:
        statusText = 'طلب تعديل من السكرتير - للمراجعة';
        statusColor = Colors.orange.shade100;
        statusIcon = Icons.edit;
        break;
      case AppConstants.EDITOR_REVIEW:
        statusText = 'قيد المراجعة من مدير التحرير';
        statusColor = Colors.purple.shade100;
        statusIcon = Icons.rate_review;
        break;
      default:
        statusText = AppStyles.getStatusDisplayName(status);
        statusColor = Colors.green.shade100;
        statusIcon = Icons.check_circle;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: Colors.purple.shade800, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة المراجعة',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(_document!.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.purple.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 20,
        vertical: 20,
      ),
      child: Column(
        children: [
          // Secretary Decision Summary
          _buildSecretaryDecisionSummary(),

          // Document Info Card with File Viewing
          documentInfo(
            fileName: _getFileName(),
            FileTypeDisplayName: _getFileTypeDisplayName(),
            handleViewFile: _handleViewFile,
            handleDownloadFile: _handleDownloadFile,
            document: _document,
          ),

          // Sender Info Card
          SenderInfoCard(
            document: _document!,
            isDesktop: isDesktop,
          ),

          // Editor Action Panel
          _buildEditorActionPanel(),

          // Previous Actions
          if (_document!.actionLog.isNotEmpty)
            ActionHistoryWidget(actionLog: _document!.actionLog),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSecretaryDecisionSummary() {
    final lastSecretaryAction = _document!.actionLog
        .where(
            (action) => action.userPosition == AppConstants.POSITION_SECRETARY)
        .toList()
        .lastOrNull;

    if (lastSecretaryAction == null) return SizedBox.shrink();

    return Secreterreportsection(
        lastSecretaryAction: lastSecretaryAction,
        handleViewFile: _handleViewFile);
  }

  Widget _buildEditorActionPanel() {
    // Updated to include SECRETARY_REJECTED
    final canTakeAction =
        _currentUserPosition == AppConstants.POSITION_MANAGING_EDITOR &&
            [
              AppConstants.SECRETARY_APPROVED,
              AppConstants.SECRETARY_REJECTED, // Added this
              AppConstants.SECRETARY_EDIT_REQUESTED,
              AppConstants.EDITOR_REVIEW
            ].contains(_document!.status);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
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
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
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
                  child: Icon(Icons.supervisor_account,
                      color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إجراءات مدير التحرير',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'تقييم المحتوى والملاءمة العلمية',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Content
          Padding(
            padding: EdgeInsets.all(20),
            child:
                canTakeAction ? _buildEditorActions() : _buildWaitingMessage(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorActions() {
    if ([
      AppConstants.SECRETARY_APPROVED,
      AppConstants.SECRETARY_REJECTED,
      AppConstants.SECRETARY_EDIT_REQUESTED
    ].contains(_document!.status)) {
      return _buildStartEditorReviewAction();
    } else {
      return _buildEditorReviewActions();
    }
  }

  Widget _buildStartEditorReviewAction() {
    String actionText = _document!.status == AppConstants.SECRETARY_REJECTED
        ? 'مراجعة المقال المرفوض'
        : 'بدء المراجعة';
    String descriptionText =
        _document!.status == AppConstants.SECRETARY_REJECTED
            ? 'يمكنك مراجعة هذا المقال رغم رفض السكرتير واتخاذ قرار مستقل'
            : 'انقر للبدء في مراجعة هذا المقال كمدير تحرير';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _document!.status == AppConstants.SECRETARY_REJECTED
                  ? [Colors.orange.shade50, Colors.orange.shade100]
                  : [Colors.blue.shade50, Colors.blue.shade100],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _document!.status == AppConstants.SECRETARY_REJECTED
                  ? Colors.orange.shade200
                  : Colors.blue.shade200,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.play_arrow,
                  color: _document!.status == AppConstants.SECRETARY_REJECTED
                      ? Colors.orange.shade600
                      : Colors.blue.shade600,
                  size: 48),
              SizedBox(height: 16),
              Text(
                actionText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _document!.status == AppConstants.SECRETARY_REJECTED
                      ? Colors.orange.shade700
                      : Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                descriptionText,
                style: TextStyle(
                  fontSize: 14,
                  color: _document!.status == AppConstants.SECRETARY_REJECTED
                      ? Colors.orange.shade600
                      : Colors.blue.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startEditorReview(),
            icon: Icon(Icons.play_arrow, size: 24),
            label: Text(
              'بدء المراجعة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _document!.status == AppConstants.SECRETARY_REJECTED
                      ? Colors.orange.shade600
                      : Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Replace the _buildEditorReviewActions method with this inline version:

  Widget _buildEditorReviewActions() {
    return Column(
      children: [
        // Guidelines Box
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade50, Colors.purple.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.purple.shade600, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'معايير المراجعة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildGuidelineItem('تقييم الأهمية العلمية للموضوع'),
              _buildGuidelineItem('مراجعة الملاءمة لنطاق المجلة'),
              _buildGuidelineItem('فحص جودة المحتوى العلمي'),
              _buildGuidelineItem('تحديد إمكانية النشر أو التوجيه للموقع'),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Inline Action Form
        _buildInlineActionForm(),
      ],
    );
  }

// Add this new method:
  Widget _buildInlineActionForm() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.rate_review,
                    color: Colors.purple.shade600, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'قرار المراجعة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Comment Field
          Text(
            'تعليق التقييم (مطلوب):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'اكتب تقييمك ومبررات القرار هنا...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: EdgeInsets.all(16),
            ),
            maxLines: 4,
            textAlign: TextAlign.right,
          ),

          SizedBox(height: 20),

          // File Attachment Section
          Text(
            'إرفاق تقرير التقييم (اختياري):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: _isUploading ? null : _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isUploading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.attach_file,
                              color: Colors.blue.shade600, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _attachedFileName ?? 'اختر ملف للإرفاق',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _attachedFileName != null
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                            ),
                          ),
                          if (_attachedFileName == null)
                            Text(
                              'يمكنك إرفاق تقرير يوضح نتائج التقييم (PDF, DOC, DOCX)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_attachedFileName != null && !_isUploading)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _attachedFileName = null;
                            _attachedFileUrl = null;
                          });
                        },
                        icon: Icon(Icons.close, color: Colors.red.shade400),
                      ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 24),

          // Action Selection
          Text(
            'اختر القرار:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 12),

          // Action Buttons Grid
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInlineActionButton(
                      action: 'approve',
                      title: 'موافقة',
                      subtitle: 'إرسال لرئيس التحرير',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildInlineActionButton(
                      action: 'reject',
                      title: 'رفض',
                      subtitle: 'رفض المقال',
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInlineActionButton(
                      action: 'website',
                      title: 'للموقع',
                      subtitle: 'مناسب للموقع فقط',
                      icon: Icons.web,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildInlineActionButton(
                      action: 'edit',
                      title: 'طلب تعديل',
                      subtitle: 'يحتاج تعديلات',
                      icon: Icons.edit,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 20),

          // Submit Button
          if (_selectedAction != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canSubmitAction() ? _submitAction : null,
                icon: Icon(Icons.send, size: 20),
                label: Text(
                  'تنفيذ القرار',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getActionColor(_selectedAction!),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

// Add this helper method:
  Widget _buildInlineActionButton({
    required String action,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    bool isSelected = _selectedAction == action;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? color.withOpacity(0.1) : Colors.white,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAction = action;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? color : Colors.grey.shade600,
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? color.withOpacity(0.8)
                      : Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

// Add these helper methods:
  bool _canSubmitAction() {
    return _commentController.text.trim().isNotEmpty &&
        _selectedAction != null &&
        !_isUploading;
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'approve':
        return Colors.green;
      case 'reject':
        return Colors.red;
      case 'website':
        return Colors.blue;
      case 'edit':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _submitAction() {
    if (_canSubmitAction()) {
      _processAction(
        _selectedAction!,
        _commentController.text.trim(),
        _attachedFileUrl,
        _attachedFileName,
      );
    }
  }

  // Add this method to your _Stage1EditorDetailsPageState class:

  Future<String?> _uploadFileToFirebaseStorage(PlatformFile file) async {
    try {
      final FirebaseStorage storage = FirebaseStorage.instance;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'editor_reports/${timestamp}_${file.name}';

      Reference ref = storage.ref().child(fileName);

      if (kIsWeb) {
        // Web upload
        if (file.bytes != null) {
          UploadTask uploadTask = ref.putData(
            file.bytes!,
            SettableMetadata(
                contentType: _getContentType(file.extension ?? '')),
          );

          TaskSnapshot snapshot = await uploadTask;
          return await snapshot.ref.getDownloadURL();
        }
      } else {
        // Mobile upload
        if (file.path != null) {
          File uploadFile = File(file.path!);
          UploadTask uploadTask = ref.putFile(
            uploadFile,
            SettableMetadata(
                contentType: _getContentType(file.extension ?? '')),
          );

          TaskSnapshot snapshot = await uploadTask;
          return await snapshot.ref.getDownloadURL();
        }
      }

      return null;
    } catch (e) {
      print('Error uploading file to Firebase Storage: $e');
      return null;
    }
  }

// Also add this helper method:
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

// File picker method (add this if not already present):
  Future<void> _pickFile() async {
    setState(() => _isUploading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        final file = result.files.single;
        final fileName = file.name;

        // Upload to Firebase Storage
        final uploadResult = await _uploadFileToFirebaseStorage(file);

        if (uploadResult != null) {
          setState(() {
            _attachedFileName = fileName;
            _attachedFileUrl = uploadResult;
          });
          _showSuccessSnackBar('تم رفع الملف بنجاح: $fileName');
        } else {
          throw Exception('فشل في رفع الملف');
        }
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في رفع الملف: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

// Also add this to the dispose method:

// Remove or comment out the _showActionDialog method since it's no longer needed
  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.purple.shade400,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.purple.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingMessage() {
    String message = '';
    String description = '';
    IconData icon = Icons.info;
    Color color = Colors.grey;

    switch (_document!.status) {
      case AppConstants.EDITOR_APPROVED:
        message = 'تمت الموافقة';
        description = 'تم إرسال المقال لرئيس التحرير';
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case AppConstants.EDITOR_REJECTED:
        message = 'تم الرفض';
        description = 'تم رفض المقال من مدير التحرير';
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case AppConstants.EDITOR_WEBSITE_RECOMMENDED:
        message = 'موصى للموقع';
        description = 'تم توصية المقال للنشر على الموقع فقط';
        icon = Icons.web;
        color = Colors.blue;
        break;
      case AppConstants.EDITOR_EDIT_REQUESTED:
        message = 'طلب تعديل';
        description = 'تم طلب تعديلات من المؤلف';
        icon = Icons.edit;
        color = Colors.orange;
        break;
      default:
        message = 'في انتظار الإجراء';
        description = 'يجب أن يقوم مدير التحرير بمراجعة المقال';
        icon = Icons.hourglass_top;
        color = Colors.blue;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppStyles.primaryColor),
              SizedBox(height: 16),
              Text(
                'جاري معالجة الطلب...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // File handling methods
  Future<void> _handleViewFile() async {
    if (_document?.documentUrl == null || _document!.documentUrl!.isEmpty) {
      _showErrorSnackBar('رابط الملف غير متوفر');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        await _openInNewTab(_document!.documentUrl!);
      } else {
        await _handleMobileFileView();
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في فتح الملف: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDownloadFile() async {
    if (_document?.documentUrl == null || _document!.documentUrl!.isEmpty) {
      _showErrorSnackBar('رابط الملف غير متوفر');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        await _downloadFileWeb();
      } else {
        await _handleMobileFileDownload();
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في تحميل الملف: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openInNewTab(String fileUrl) async {
    try {
      html.window.open(fileUrl, '_blank');
      _showSuccessSnackBar('تم فتح الملف في تبويب جديد');
    } catch (e) {
      throw Exception('فشل في فتح الملف في تبويب جديد');
    }
  }

  Future<void> _downloadFileWeb() async {
    try {
      final String fileUrl = _document!.documentUrl!;
      final String fileName = _getFileName();

      // Try direct download first
      try {
        final html.AnchorElement anchor = html.AnchorElement(href: fileUrl)
          ..download = fileName
          ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);

        _showSuccessSnackBar('تم بدء تنزيل الملف: $fileName');
        return;
      } catch (e) {
        // Continue to method 2
      }

      // Fallback method using Dio
      final dio = Dio();
      final response = await dio.get(
        fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;
        final fileExtension = _getFileExtension();
        final mimeType =
            supportedFileTypes[fileExtension] ?? 'application/octet-stream';

        final blob = html.Blob([bytes], mimeType);
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);

        final html.AnchorElement anchor = html.AnchorElement(href: blobUrl)
          ..download = fileName
          ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);

        html.Url.revokeObjectUrl(blobUrl);

        _showSuccessSnackBar('تم تنزيل الملف بنجاح: $fileName');
      } else {
        throw Exception('فشل في تنزيل الملف: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('فشل في تنزيل الملف: ${e.toString()}');
    }
  }

  Future<void> _handleMobileFileView() async {
    final String fileName = _getFileName();
    final String fileExtension = _getFileExtension();

    if (!supportedFileTypes.containsKey(fileExtension)) {
      throw Exception('نوع الملف غير مدعوم: ${_getFileTypeDisplayName()}');
    }

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String filePath = '${appDocDir.path}/$fileName';

    await Dio().download(
      _document!.documentUrl!,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          double progress = received / total;
          debugPrint(
              'Download progress: ${(progress * 100).toStringAsFixed(0)}%');
        }
      },
    );

    final File file = File(filePath);
    if (!await file.exists()) {
      throw Exception('فشل في تنزيل الملف');
    }

    final OpenResult result = await OpenFile.open(
      filePath,
      type: supportedFileTypes[fileExtension],
    );

    switch (result.type) {
      case ResultType.done:
        _showSuccessSnackBar('تم فتح الملف بنجاح');
        break;
      case ResultType.noAppToOpen:
        _showWarningSnackBar(
            'لا يوجد تطبيق مناسب لفتح هذا النوع من الملفات\nالرجاء تثبيت تطبيق مناسب لـ ${_getFileTypeDisplayName()}');
        break;
      case ResultType.permissionDenied:
        _showErrorSnackBar('تم رفض الإذن لفتح الملف');
        break;
      case ResultType.fileNotFound:
        _showErrorSnackBar('لم يتم العثور على الملف');
        break;
      case ResultType.error:
        _showErrorSnackBar('حدث خطأ أثناء فتح الملف: ${result.message}');
        break;
    }
  }

  Future<void> _handleMobileFileDownload() async {
    final String fileName = _getFileName();

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String filePath = '${appDocDir.path}/$fileName';

    await Dio().download(
      _document!.documentUrl!,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          double progress = received / total;
          debugPrint(
              'Download progress: ${(progress * 100).toStringAsFixed(0)}%');
        }
      },
    );

    _showSuccessSnackBar('تم تحميل الملف بنجاح: $fileName');
  }

  // Helper methods
  String _getFileName() {
    try {
      final uri = Uri.parse(_document!.documentUrl ?? '');
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final lastSegment = segments.last;
        if (lastSegment.contains('.')) {
          return Uri.decodeComponent(lastSegment);
        }
      }
    } catch (e) {
      // Continue to fallback
    }

    final fileExtension = _getFileExtension();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'document_$timestamp$fileExtension';
  }

  String _getFileExtension() {
    try {
      String urlPath = Uri.parse(_document!.documentUrl ?? '').path;
      String extension = path.extension(urlPath).toLowerCase();
      if (extension.isNotEmpty && supportedFileTypes.containsKey(extension)) {
        return extension;
      }
      return '.pdf';
    } catch (e) {
      return '.pdf';
    }
  }

  String _getFileTypeDisplayName() {
    final extension = _getFileExtension();
    switch (extension.toLowerCase()) {
      case '.pdf':
        return 'PDF';
      case '.doc':
        return 'Word Document (DOC)';
      case '.docx':
        return 'Word Document (DOCX)';
      case '.txt':
        return 'Text Document';
      case '.rtf':
        return 'Rich Text Format';
      case '.odt':
        return 'OpenDocument Text';
      default:
        return 'Document';
    }
  }

  Color _getDecisionColor(String status) {
    switch (status) {
      case AppConstants.SECRETARY_APPROVED:
        return Colors.green;
      case AppConstants.SECRETARY_REJECTED:
        return Colors.red;
      case AppConstants.SECRETARY_EDIT_REQUESTED:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getDecisionIcon(String status) {
    switch (status) {
      case AppConstants.SECRETARY_APPROVED:
        return Icons.check_circle;
      case AppConstants.SECRETARY_REJECTED:
        return Icons.cancel;
      case AppConstants.SECRETARY_EDIT_REQUESTED:
        return Icons.edit;
      default:
        return Icons.info;
    }
  }

  void _startEditorReview() async {
    setState(() => _isLoading = true);

    try {
      await _documentService.updateDocumentStatus(
        _document!.id,
        AppConstants.EDITOR_REVIEW,
        _document!.status == AppConstants.SECRETARY_REJECTED
            ? 'بدء مراجعة مدير التحرير للمقال المرفوض من السكرتير'
            : 'بدء مراجعة مدير التحرير',
        _currentUserId!,
        _currentUserName!,
        _currentUserPosition!,
      );

      await _refreshDocument();
      _showSuccessSnackBar('تم بدء المراجعة بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في بدء المراجعة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processAction(
      String action, String comment, String? fileUrl, String? fileName) async {
    setState(() => _isLoading = true);

    try {
      String nextStatus = '';
      switch (action) {
        case 'approve':
          nextStatus = AppConstants.EDITOR_APPROVED;
          break;
        case 'reject':
          nextStatus = AppConstants.EDITOR_REJECTED;
          break;
        case 'website':
          nextStatus = AppConstants.EDITOR_WEBSITE_RECOMMENDED;
          break;
        case 'edit':
          nextStatus = AppConstants.EDITOR_EDIT_REQUESTED;
          break;
      }

      await _documentService.updateDocumentStatus(
        _document!.id,
        nextStatus,
        comment,
        _currentUserId!,
        _currentUserName!,
        _currentUserPosition!,
        attachedFileUrl: fileUrl,
        attachedFileName: fileName,
      );

      await _refreshDocument();
      _showSuccessSnackBar('تم تنفيذ الإجراء بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في تنفيذ الإجراء: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshDocument() async {
    try {
      final refreshedDoc = await FirebaseFirestore.instance
          .collection('sent_documents')
          .doc(_document!.id)
          .get();

      if (refreshedDoc.exists) {
        setState(() {
          _document = DocumentModel.fromFirestore(refreshedDoc);
        });
      }
    } catch (e) {
      print('Error refreshing document: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
