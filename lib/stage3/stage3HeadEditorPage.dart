// pages/Stage3/Stage3HeadEditorPage.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

import '../../Classes/current_user_providerr.dart';
import '../App_Constants.dart';
import '../Document_Services.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/Action_history.dart';
import '../models/document_model.dart';

class Stage3HeadEditorPage extends StatefulWidget {
  final DocumentModel document;

  const Stage3HeadEditorPage({Key? key, required this.document})
      : super(key: key);

  @override
  _Stage3HeadEditorPageState createState() => _Stage3HeadEditorPageState();
}

class _Stage3HeadEditorPageState extends State<Stage3HeadEditorPage>
    with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();

  bool _isLoading = false;
  DocumentModel? _document;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPosition;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
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
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    _buildContent(),
                  ],
                ),
              ),
              if (_isLoading) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade800],
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
                child: Icon(_getHeaderIcon(), color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getHeaderTitle(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _getHeaderSubtitle(),
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
          _buildStatusBar(),
        ],
      ),
    );
  }

  IconData _getHeaderIcon() {
    switch (_document!.status) {
      case AppConstants.STAGE2_APPROVED:
        return Icons.send_to_mobile;
      case AppConstants.HEAD_EDITOR_FIRST_REVIEW:
        return Icons.preview;
      case AppConstants.HEAD_EDITOR_FINAL_APPROVAL:
        return Icons.verified_user;
      default:
        return Icons.admin_panel_settings;
    }
  }

  String _getHeaderTitle() {
    switch (_document!.status) {
      case AppConstants.STAGE2_APPROVED:
        return 'إرسال للإخراج الفني';
      case AppConstants.HEAD_EDITOR_FIRST_REVIEW:
        return 'المراجعة الأولى';
      case AppConstants.HEAD_EDITOR_FINAL_APPROVAL:
        return 'الاعتماد النهائي';
      default:
        return 'مراجعة رئيس التحرير';
    }
  }

  String _getHeaderSubtitle() {
    switch (_document!.status) {
      case AppConstants.STAGE2_APPROVED:
        return 'إرسال المقال للمخرج الفني للتصميم والإخراج';
      case AppConstants.HEAD_EDITOR_FIRST_REVIEW:
        return 'مراجعة الإخراج الفني والموافقة للمراجعة النهائية';
      case AppConstants.HEAD_EDITOR_FINAL_APPROVAL:
        return 'الاعتماد النهائي للمقال للطباعة والنشر';
      default:
        return 'مراجعة واتخاذ القرار المناسب';
    }
  }

  Widget _buildStatusBar() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_document!.status) {
      case AppConstants.STAGE2_APPROVED:
        statusColor = Colors.green;
        statusText = 'جاهز للإرسال للإخراج الفني';
        statusIcon = Icons.send_to_mobile;
        break;
      case AppConstants.HEAD_EDITOR_FIRST_REVIEW:
        statusColor = Colors.orange;
        statusText = 'جاري المراجعة الأولى';
        statusIcon = Icons.preview;
        break;
      case AppConstants.HEAD_EDITOR_FINAL_APPROVAL:
        statusColor = Colors.blue;
        statusText = 'جاهز للاعتماد النهائي';
        statusIcon = Icons.verified_user;
        break;
      default:
        statusColor = Colors.white;
        statusText = 'قيد المراجعة';
        statusIcon = Icons.info;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة المراجعة',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Document Info
          _buildDocumentInfoCard(),

          // Current Stage Content
          _buildCurrentStageContent(),

          // Action History
          if (_document!.actionLog.isNotEmpty)
            ActionHistoryWidget(actionLog: _document!.actionLog),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDocumentInfoCard() {
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade100, Colors.blue.shade200],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description,
                    color: Colors.blue.shade700, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات المقال',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'تفاصيل المقال ومرفقاته',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildFileViewingSection(),
          SizedBox(height: 16),
          _buildDocumentProgress(),
        ],
      ),
    );
  }

  Widget _buildFileViewingSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.grey.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الملف الأصلي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'المقال الأصلي للمراجعة',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _handleViewFile,
                icon: Icon(Icons.visibility, size: 18),
                label: Text('عرض'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _handleDownloadFile,
                icon: Icon(Icons.download, size: 18),
                label: Text('تحميل'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentProgress() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.deepPurple.shade600, size: 20),
              SizedBox(width: 8),
              Text(
                'تقدم المقال',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'المرحلة الثالثة: ${AppStyles.getStatusDisplayName(_document!.status)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.deepPurple.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStageContent() {
    switch (_document!.status) {
      case AppConstants.STAGE2_APPROVED:
        return _buildSendToLayoutDesignerForm();
      case AppConstants.HEAD_EDITOR_FIRST_REVIEW:
        return _buildFirstReviewForm();
      case AppConstants.HEAD_EDITOR_FINAL_APPROVAL:
        return _buildFinalApprovalForm();
      default:
        return _buildGeneralInfoCard();
    }
  }

  Widget _buildSendToLayoutDesignerForm() {
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
                colors: [Colors.green.shade500, Colors.green.shade700],
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
                  child:
                      Icon(Icons.send_to_mobile, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إرسال للإخراج الفني',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'المقال جاهز للإرسال للمخرج الفني',
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

          // Content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green.shade600, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'تم اعتماد المقال من المرحلة الثانية وهو جاهز للإرسال للإخراج الفني',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showSendToLayoutDesignerDialog(),
                    icon: Icon(Icons.send_to_mobile, size: 24),
                    label: Text(
                      'إرسال للمخرج الفني',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstReviewForm() {
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
                colors: [Colors.orange.shade500, Colors.orange.shade700],
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
                  child: Icon(Icons.preview, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المراجعة الأولى للإخراج',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'مراجعة عمل المخرج الفني واتخاذ القرار',
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

          // Content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Layout file info
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.design_services,
                          color: Colors.purple.shade600, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'انتهى المخرج الفني من عمله. يرجى مراجعة الإخراج الفني والموافقة للمراجعة النهائية أو طلب تعديلات.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _viewLayoutFile,
                        icon: Icon(Icons.visibility, size: 16),
                        label: Text('عرض الإخراج'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          foregroundColor: Colors.white,
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          minimumSize: Size(0, 32),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showFirstReviewDialog('send_to_final_review'),
                        icon: Icon(Icons.check_circle, size: 20),
                        label: Text('إرسال للمراجعة النهائية'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showFirstReviewDialog('request_revision'),
                        icon: Icon(Icons.edit, size: 20),
                        label: Text('طلب تعديل الإخراج'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalApprovalForm() {
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
                colors: [Colors.blue.shade500, Colors.blue.shade700],
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
                  child:
                      Icon(Icons.verified_user, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الاعتماد النهائي للنشر',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'القرار النهائي للاعتماد والنشر',
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

          // Content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Final review completed info
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.fact_check,
                          color: Colors.blue.shade600, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'تم إنهاء المراجعة النهائية والتعديلات المطلوبة. المقال جاهز للاعتماد النهائي والنشر.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _viewFinalVersion,
                        icon: Icon(Icons.visibility, size: 16),
                        label: Text('عرض النسخة النهائية'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          minimumSize: Size(0, 32),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Final decision buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showFinalApprovalDialog('approve_for_publication'),
                        icon: Icon(Icons.publish, size: 20),
                        label: Text('اعتماد للنشر النهائي'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showFinalApprovalDialog(
                            'request_final_modifications'),
                        icon: Icon(Icons.edit, size: 20),
                        label: Text('ملاحظات إضافية'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade500,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'معلومات المرحلة الحالية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'المقال في مرحلة: ${AppStyles.getStatusDisplayName(_document!.status)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
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
              CircularProgressIndicator(color: Colors.deepPurple.shade600),
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

  // Action methods
  void _showSendToLayoutDesignerDialog() {
    _showDecisionDialog(
      'إرسال للإخراج الفني',
      'إرسال المقال للمخرج الفني للتصميم والإخراج',
      Colors.green,
      'send_to_layout_designer',
      (comment) => _sendToLayoutDesigner(comment),
    );
  }

  void _showFirstReviewDialog(String decision) {
    String title = decision == 'send_to_final_review'
        ? 'إرسال للمراجعة النهائية'
        : 'طلب تعديل الإخراج';
    String description = decision == 'send_to_final_review'
        ? 'الموافقة على الإخراج الفني وإرساله للمراجعة النهائية'
        : 'طلب تعديلات على الإخراج الفني من المخرج';
    Color color =
        decision == 'send_to_final_review' ? Colors.green : Colors.orange;

    _showDecisionDialog(
      title,
      description,
      color,
      decision,
      (comment) => _submitFirstReview(decision, comment),
    );
  }

  void _showFinalApprovalDialog(String decision) {
    String title = decision == 'approve_for_publication'
        ? 'اعتماد للنشر النهائي'
        : 'ملاحظات إضافية';
    String description = decision == 'approve_for_publication'
        ? 'اعتماد المقال للطباعة والنشر النهائي'
        : 'إرسال ملاحظات إضافية للمخرج الفني';
    Color color =
        decision == 'approve_for_publication' ? Colors.green : Colors.orange;

    _showDecisionDialog(
      title,
      description,
      color,
      decision,
      (comment) => _submitFinalApproval(decision, comment),
    );
  }

  void _showDecisionDialog(
    String title,
    String description,
    Color color,
    String decision,
    Function(String) onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => HeadEditorDecisionDialog(
        title: title,
        description: description,
        color: color,
        decision: decision,
        onConfirm: onConfirm,
      ),
    );
  }

  Future<void> _sendToLayoutDesigner(String comment) async {
    setState(() => _isLoading = true);

    try {
      await _documentService.sendToLayoutDesigner(
        _document!.id,
        _currentUserId!,
        _currentUserName!,
        _currentUserPosition!,
        comment,
      );

      _showSuccessSnackBar('تم إرسال المقال للمخرج الفني بنجاح');
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('خطأ في إرسال المقال: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitFirstReview(String decision, String comment) async {
    setState(() => _isLoading = true);

    try {
      await _documentService.submitHeadEditorFirstReview(
        _document!.id,
        _currentUserId!,
        _currentUserName!,
        decision,
        comment,
      );

      String message = decision == 'send_to_final_review'
          ? 'تم إرسال المقال للمراجعة النهائية بنجاح'
          : 'تم طلب تعديل الإخراج الفني بنجاح';

      _showSuccessSnackBar(message);
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('خطأ في اتخاذ القرار: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitFinalApproval(String decision, String comment) async {
    setState(() => _isLoading = true);

    try {
      await _documentService.submitHeadEditorFinalApproval(
        _document!.id,
        _currentUserId!,
        _currentUserName!,
        decision,
        comment,
      );

      String message = decision == 'approve_for_publication'
          ? 'تم اعتماد المقال للنشر النهائي بنجاح'
          : 'تم إرسال الملاحظات الإضافية بنجاح';

      _showSuccessSnackBar(message);
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('خطأ في اتخاذ القرار: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _viewLayoutFile() async {
    _showSuccessSnackBar('تم فتح ملف الإخراج الفني');
  }

  Future<void> _viewFinalVersion() async {
    _showSuccessSnackBar('تم فتح النسخة النهائية');
  }

  // File handling methods
  Future<void> _handleViewFile() async {
    if (_document?.documentUrl == null || _document!.documentUrl!.isEmpty) {
      _showErrorSnackBar('رابط الملف غير متوفر');
      return;
    }

    try {
      if (kIsWeb) {
        html.window.open(_document!.documentUrl!, '_blank');
        _showSuccessSnackBar('تم فتح الملف في تبويب جديد');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في فتح الملف: ${e.toString()}');
    }
  }

  Future<void> _handleDownloadFile() async {
    if (_document?.documentUrl == null || _document!.documentUrl!.isEmpty) {
      _showErrorSnackBar('رابط الملف غير متوفر');
      return;
    }

    try {
      if (kIsWeb) {
        final html.AnchorElement anchor =
            html.AnchorElement(href: _document!.documentUrl!)
              ..download = 'original_article.pdf'
              ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);

        _showSuccessSnackBar('تم بدء تنزيل الملف الأصلي');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في تحميل الملف: ${e.toString()}');
    }
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
}

// Decision Dialog for Head Editor
class HeadEditorDecisionDialog extends StatefulWidget {
  final String title;
  final String description;
  final Color color;
  final String decision;
  final Function(String) onConfirm;

  const HeadEditorDecisionDialog({
    Key? key,
    required this.title,
    required this.description,
    required this.color,
    required this.decision,
    required this.onConfirm,
  }) : super(key: key);

  @override
  _HeadEditorDecisionDialogState createState() =>
      _HeadEditorDecisionDialogState();
}

class _HeadEditorDecisionDialogState extends State<HeadEditorDecisionDialog> {
  final TextEditingController _commentController = TextEditingController();
  bool _isCommentValid = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _commentController.removeListener(_onTextChanged);
    _commentController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isCommentValid = _commentController.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: AlertDialog(
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
                  child: Icon(
                    _getDialogIcon(),
                    color: widget.color,
                    size: 20,
                  ),
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
            Text('تعليقك (مطلوب):'),
            SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: _getHintText(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 4,
              textAlign: TextAlign.right,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _isCommentValid
                ? () {
                    Navigator.pop(context);
                    widget.onConfirm(_commentController.text.trim());
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
            ),
            child: Text('تأكيد القرار'),
          ),
        ],
      ),
    );
  }

  IconData _getDialogIcon() {
    switch (widget.decision) {
      case 'send_to_layout_designer':
        return Icons.send_to_mobile;
      case 'send_to_final_review':
        return Icons.fact_check;
      case 'approve_for_publication':
        return Icons.publish;
      case 'request_revision':
      case 'request_final_modifications':
        return Icons.edit;
      default:
        return Icons.info;
    }
  }

  String _getHintText() {
    switch (widget.decision) {
      case 'send_to_layout_designer':
        return 'تعليقاتك حول إرسال المقال للإخراج الفني...';
      case 'send_to_final_review':
        return 'تعليقاتك حول الموافقة على الإخراج...';
      case 'approve_for_publication':
        return 'تعليقاتك حول الاعتماد النهائي للنشر...';
      case 'request_revision':
        return 'ملاحظاتك على الإخراج الفني للتعديل...';
      case 'request_final_modifications':
        return 'ملاحظاتك الإضافية للمخرج الفني...';
      default:
        return 'اكتب تعليقك هنا...';
    }
  }
}
