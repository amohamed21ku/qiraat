// pages/Stage1/Stage1SecretaryDetailsPage.dart - Updated with comprehensive evaluation form
import 'dart:convert';

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

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../Classes/current_user_providerr.dart';
import '../App_Constants.dart';
import '../Document_Services.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/Action_history.dart';
import '../models/document_model.dart';

class Stage1SecretaryDetailsPage extends StatefulWidget {
  final DocumentModel document;

  const Stage1SecretaryDetailsPage({Key? key, required this.document})
      : super(key: key);

  @override
  _Stage1SecretaryDetailsPageState createState() =>
      _Stage1SecretaryDetailsPageState();
}

class _Stage1SecretaryDetailsPageState extends State<Stage1SecretaryDetailsPage>
    with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();

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
            Colors.orange.shade500,
            Colors.orange.shade700,
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
                child:
                    Icon(Icons.assignment_ind, color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مراجعة السكرتير',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'المرحلة الأولى - الفحص الأولي والموافقة',
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
          _buildSecretaryStatusBar(),
        ],
      ),
    );
  }

  Widget _buildSecretaryStatusBar() {
    final status = _document!.status;
    String statusText = '';
    Color statusColor = Colors.white;
    IconData statusIcon = Icons.info;

    switch (status) {
      case AppConstants.INCOMING:
        statusText = 'في انتظار بدء المراجعة';
        statusColor = Colors.blue.shade100;
        statusIcon = Icons.hourglass_top;
        break;
      case AppConstants.SECRETARY_REVIEW:
        statusText = 'قيد المراجعة من السكرتير';
        statusColor = Colors.orange.shade100;
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
          Icon(statusIcon, color: Colors.orange.shade800, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة المراجعة',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(_document!.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade600,
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
          // Document Info Card with File Viewing
          _buildDocumentInfoCard(),

          // Enhanced Sender Info Card with all required information
          _buildCompleteSenderInfoCard(),

          // Secretary Action Panel
          _buildSecretaryActionPanel(),

          // Previous Actions (if any)
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
                      'تفاصيل المستند',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'معلومات الملف المرفق',
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

          // File Information
          if (_document!.documentUrl != null &&
              _document!.documentUrl!.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade50, Colors.grey.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_file,
                          color: Colors.grey.shade600, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'الملف المرفق',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getFileName(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff2d3748),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'نوع الملف: ${_getFileTypeDisplayName()}',
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'لا يوجد ملف مرفق',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompleteSenderInfoCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
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
                colors: [Colors.green.shade400, Colors.green.shade600],
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
                  child: Icon(Icons.person, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات المرسل',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'البيانات الشخصية والأكاديمية',
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
                // Full Name
                _buildInfoRow('الاسم الكامل', _document!.fullName ?? 'غير محدد',
                    Icons.person),

                // Email
                _buildInfoRow('البريد الإلكتروني',
                    _document!.email ?? 'غير محدد', Icons.email),

                // Education
                _buildInfoRow('الدرجة العلمية',
                    _document!.education ?? 'غير محدد', Icons.school),

                // Status
                _buildInfoRow(
                    'الحالة',
                    AppStyles.getStatusDisplayName(_document!.status),
                    Icons.info),

                // About/Research Summary
                if (_document!.about != null && _document!.about!.isNotEmpty)
                  _buildInfoSection('ملخص البحث/عنوان المقال',
                      _document!.about!, Icons.description),

                // Co-authors
                if (_document!.coAuthors != null &&
                    _document!.coAuthors!.isNotEmpty)
                  _buildCoAuthorsSection(),

                // CV Section
                if (_document!.cvUrl != null && _document!.cvUrl!.isNotEmpty)
                  _buildCVSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green.shade600, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.green.shade600, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoAuthorsSection() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.group, color: Colors.green.shade600, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'الكتّاب المشاركون',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Column(
            children: _document!.coAuthors!
                .map((author) => Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline,
                              color: Colors.grey.shade600, size: 16),
                          SizedBox(width: 8),
                          Text(
                            author,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCVSection() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
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
                child: Icon(Icons.description,
                    color: Colors.blue.shade600, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'السيرة الذاتية',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'تم رفع السيرة الذاتية',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _handleViewCV(),
                icon: Icon(Icons.visibility, size: 16),
                label: Text('عرض السيرة الذاتية'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
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

  Widget _buildSecretaryActionPanel() {
    final canTakeAction =
        _currentUserPosition == AppConstants.POSITION_SECRETARY &&
            [AppConstants.INCOMING, AppConstants.SECRETARY_REVIEW]
                .contains(_document!.status);

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
                colors: [Colors.orange.shade400, Colors.orange.shade600],
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
                      Icon(Icons.assignment_ind, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إجراءات السكرتير',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'نموذج التقييم الشامل',
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
            child: canTakeAction
                ? _buildSecretaryActions()
                : _buildWaitingMessage(),
          ),
        ],
      ),
    );
  }

  Widget _buildSecretaryActions() {
    if (_document!.status == AppConstants.INCOMING) {
      return _buildStartReviewAction();
    } else {
      return _buildEvaluationForm();
    }
  }

  Widget _buildStartReviewAction() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.play_arrow, color: Colors.blue.shade600, size: 48),
              SizedBox(height: 16),
              Text(
                'جاهز لبدء المراجعة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'انقر للبدء في مراجعة هذا المقال',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startReview(),
            icon: Icon(Icons.play_arrow, size: 24),
            label: Text(
              'بدء المراجعة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
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

  Widget _buildEvaluationForm() {
    return Column(
      children: [
        // Information Box
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade50, Colors.orange.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade600, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'نموذج التقييم الشامل',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'يرجى تقييم المقال وفقاً للمعايير التالية وإضافة التعليقات المناسبة',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showEvaluationDialog(),
            icon: Icon(Icons.rate_review, size: 20),
            label: Text(
              'بدء التقييم الشامل',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
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

  Widget _buildWaitingMessage() {
    String message = '';
    String description = '';
    IconData icon = Icons.info;
    Color color = Colors.grey;

    switch (_document!.status) {
      case AppConstants.SECRETARY_APPROVED:
        message = 'تمت الموافقة';
        description = 'تم إرسال المقال لمدير التحرير';
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case AppConstants.SECRETARY_REJECTED:
        message = 'تم الرفض';
        description = 'تم رفض المقال من السكرتير';
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case AppConstants.SECRETARY_EDIT_REQUESTED:
        message = 'طلب تعديل';
        description = 'تم طلب تعديلات من المؤلف';
        icon = Icons.edit;
        color = Colors.orange;
        break;
      default:
        message = 'في انتظار الإجراء';
        description = 'يجب أن يقوم السكرتير بمراجعة المقال';
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

  Future<void> _handleViewCV() async {
    if (_document?.cvUrl == null || _document!.cvUrl!.isEmpty) {
      _showErrorSnackBar('رابط السيرة الذاتية غير متوفر');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        await _openInNewTab(_document!.cvUrl!);
      } else {
        await _handleMobileFileView(url: _document!.cvUrl!);
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في فتح السيرة الذاتية: ${e.toString()}');
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

  Future<void> _handleMobileFileView({String? url}) async {
    final String fileUrl = url ?? _document!.documentUrl!;
    final String fileName = _getFileName();
    final String fileExtension = _getFileExtension();

    if (!supportedFileTypes.containsKey(fileExtension)) {
      throw Exception('نوع الملف غير مدعوم: ${_getFileTypeDisplayName()}');
    }

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String filePath = '${appDocDir.path}/$fileName';

    await Dio().download(
      fileUrl,
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

  void _startReview() async {
    setState(() => _isLoading = true);

    try {
      await _documentService.updateDocumentStatus(
        _document!.id,
        AppConstants.SECRETARY_REVIEW,
        'بدء مراجعة السكرتير',
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

  void _showEvaluationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ComprehensiveEvaluationDialog(
        document: _document!,
        onComplete: (evaluationResult) => _processEvaluation(evaluationResult),
      ),
    );
  }

  Future<void> _processEvaluation(Map<String, dynamic> evaluationResult) async {
    setState(() => _isLoading = true);

    try {
      // Generate evaluation report
      String reportContent = _generateEvaluationReport(evaluationResult);

      // Upload report to Firebase Storage
      String? reportUrl = await _uploadEvaluationReport(reportContent);

      // Always send to manager with the evaluation report
      String nextStatus = AppConstants.SECRETARY_APPROVED;

      await _documentService.updateDocumentStatus(
        _document!.id,
        nextStatus,
        evaluationResult['comment'],
        _currentUserId!,
        _currentUserName!,
        _currentUserPosition!,
        attachedFileUrl: reportUrl,
        attachedFileName:
            'تقرير_تقييم_السكرتير_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      await _refreshDocument();
      _showSuccessSnackBar(
          'تم إكمال التقييم وإرسال المقال مع التقرير لمدير التحرير');
    } catch (e) {
      _showErrorSnackBar('خطأ في معالجة التقييم: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateEvaluationReport(Map<String, dynamic> evaluation) {
    String report = '''
نموذج أسئلة – المرحلة الأولى – تقييم مقال

عنوان المقال: ${_document!.about ?? 'غير محدد'}
الزاوية/الموضوع: ${evaluation['topic'] ?? 'غير محدد'}
الباحث ودرجته العلمية: ${_document!.fullName ?? 'غير محدد'} - ${_document!.education ?? 'غير محدد'}
تاريخ استلام المقال: ${_formatDate(_document!.timestamp)}

=== 1. الأصالة والجدة ===

• هل تم نشر المقال سابقاً في أي وسيلة نشر؟
الإجابة: ${evaluation['originalityPublished'] ?? 'غير محدد'}
${evaluation['originalityPublishedComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['originalityPublishedComment']}' : ''}

• هل توجد في المجلة موضوعات مماثلة له؟
الإجابة: ${evaluation['originalitySimilar'] ?? 'غير محدد'}
${evaluation['originalitySimilarComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['originalitySimilarComment']}' : ''}

• هل للمقال قيمة مضافة واضحة؟
الإجابة: ${evaluation['originalityValue'] ?? 'غير محدد'}
${evaluation['originalityValueComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['originalityValueComment']}' : ''}

=== 2. سياسات المجلة ===

• هل يتوافق المقال مع سياسات المجلة وهدفها العام؟
الإجابة: ${evaluation['policyAlignment'] ?? 'غير محدد'}
${evaluation['policyAlignmentComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['policyAlignmentComment']}' : ''}

• هل يتعلق المقال بمجال اهتمام المجلة (مثلاً: إفريقيا جنوب الصحراء)؟
الإجابة: ${evaluation['policyRelevance'] ?? 'غير محدد'}
${evaluation['policyRelevanceComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['policyRelevanceComment']}' : ''}

=== 3. المنهجية العلمية ===

• هل المعلومات والإحصاءات جديدة وحديثة؟
الإجابة: ${evaluation['methodologyData'] ?? 'غير محدد'}
${evaluation['methodologyDataComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['methodologyDataComment']}' : ''}

• هل المصادر أصلية وموثوقة؟
الإجابة: ${evaluation['methodologySources'] ?? 'غير محدد'}
${evaluation['methodologySourcesComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['methodologySourcesComment']}' : ''}

• هل التزم الباحث بأصول المنهجية العلمية؟
الإجابة: ${evaluation['methodologyScientific'] ?? 'غير محدد'}
${evaluation['methodologyScientificComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['methodologyScientificComment']}' : ''}

=== 4. الكتابة والمعالجة ===

• هل معالجة الموضوع متكاملة وعناصره الرئيسة متسقة؟
الإجابة: ${evaluation['writingTreatment'] ?? 'غير محدد'}
${evaluation['writingTreatmentComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['writingTreatmentComment']}' : ''}

• هل لغة الكتابة سليمة والأسلوب مناسب لعموم القراء؟
الإجابة: ${evaluation['writingLanguage'] ?? 'غير محدد'}
${evaluation['writingLanguageComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['writingLanguageComment']}' : ''}

• هل حجم المقال مناسب؟
الإجابة: ${evaluation['writingSize'] ?? 'غير محدد'}
${evaluation['writingSizeComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['writingSizeComment']}' : ''}

=== رأي سكرتير التحرير ===

• ما تقييم سكرتير التحرير للمقال بشكل عام؟
${evaluation['generalEvaluation'] ?? 'غير محدد'}

• هل يحتاج المقال إلى تعديلات؟ ما نوعها؟
${evaluation['modificationsNeeded'] ?? 'غير محدد'}

=== ملاحظات إضافية للمقال ===

• هل الملخص يحتوي على الكلمات المفتاحية الكافية؟
الإجابة: ${evaluation['abstractKeywords'] ?? 'غير محدد'}
${evaluation['abstractKeywordsComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['abstractKeywordsComment']}' : ''}

• هل الاستنتاجات في الملخص قابلة للقياس والتحقق؟
الإجابة: ${evaluation['abstractConclusions'] ?? 'غير محدد'}
${evaluation['abstractConclusionsComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['abstractConclusionsComment']}' : ''}

• هل المقدمة تحتوي على منهج وصياغة إشكالية واضحة؟
الإجابة: ${evaluation['introductionMethodology'] ?? 'غير محدد'}
${evaluation['introductionMethodologyComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['introductionMethodologyComment']}' : ''}

• هل المقدمة تشتمل على إطار مفاهيمي محدد للمفاهيم الأساسية؟
الإجابة: ${evaluation['introductionFramework'] ?? 'غير محدد'}
${evaluation['introductionFrameworkComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['introductionFrameworkComment']}' : ''}

• هل الخاتمة تعرض النتائج بوضوح وتبين حدود الدراسة؟
الإجابة: ${evaluation['conclusionResults'] ?? 'غير محدد'}
${evaluation['conclusionResultsComment']?.isNotEmpty == true ? 'التعليق: ${evaluation['conclusionResultsComment']}' : ''}

=== التعليق العام ===
${evaluation['comment'] ?? 'لا يوجد تعليق'}

=== القرار ===
${_getActionText(evaluation['action'])}

تم إعداد هذا التقرير بواسطة: ${_currentUserName}
التاريخ: ${_formatDate(DateTime.now())}
    ''';

    return report;
  }

  String _getActionText(String action) {
    switch (action) {
      case 'send_to_manager':
        return 'تم إرسال المقال مع تقرير التقييم إلى مدير التحرير للمراجعة';
      default:
        return 'غير محدد';
    }
  }

  Future<String?> _uploadEvaluationReport(String reportContent) async {
    try {
      final FirebaseStorage storage = FirebaseStorage.instance;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName =
          'secretary_evaluation_reports/${timestamp}_evaluation_report.txt';

      Reference ref = storage.ref().child(fileName);

      if (kIsWeb) {
        // Web upload
        final bytes = reportContent.codeUnits;
        UploadTask uploadTask = ref.putData(
          Uint8List.fromList(bytes),
          SettableMetadata(contentType: 'text/plain; charset=utf-8'),
        );

        TaskSnapshot snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      } else {
        // Mobile upload
        final Directory tempDir = await getTemporaryDirectory();
        final String filePath =
            '${tempDir.path}/evaluation_report_$timestamp.txt';
        final File file = File(filePath);
        await file.writeAsString(reportContent,
            encoding: Encoding.getByName('utf-8')!);

        UploadTask uploadTask = ref.putFile(
          file,
          SettableMetadata(contentType: 'text/plain; charset=utf-8'),
        );

        TaskSnapshot snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e) {
      print('Error uploading evaluation report: $e');
      return null;
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

// Updated Comprehensive Evaluation Dialog with PDF report generation
class ComprehensiveEvaluationDialog extends StatefulWidget {
  final DocumentModel document;
  final Function(Map<String, dynamic>) onComplete;

  const ComprehensiveEvaluationDialog({
    Key? key,
    required this.document,
    required this.onComplete,
  }) : super(key: key);

  @override
  _ComprehensiveEvaluationDialogState createState() =>
      _ComprehensiveEvaluationDialogState();
}

class _ComprehensiveEvaluationDialogState
    extends State<ComprehensiveEvaluationDialog> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _generalEvaluationController =
      TextEditingController();
  final TextEditingController _modificationsNeededController =
      TextEditingController();
  final TextEditingController _topicController = TextEditingController();

  // Comment controllers for each question
  final TextEditingController _originalityPublishedCommentController =
      TextEditingController();
  final TextEditingController _originalitySimilarCommentController =
      TextEditingController();
  final TextEditingController _originalityValueCommentController =
      TextEditingController();
  final TextEditingController _policyAlignmentCommentController =
      TextEditingController();
  final TextEditingController _policyRelevanceCommentController =
      TextEditingController();
  final TextEditingController _methodologyDataCommentController =
      TextEditingController();
  final TextEditingController _methodologySourcesCommentController =
      TextEditingController();
  final TextEditingController _methodologyScientificCommentController =
      TextEditingController();
  final TextEditingController _writingTreatmentCommentController =
      TextEditingController();
  final TextEditingController _writingLanguageCommentController =
      TextEditingController();
  final TextEditingController _writingSizeCommentController =
      TextEditingController();
  final TextEditingController _abstractKeywordsCommentController =
      TextEditingController();
  final TextEditingController _abstractConclusionsCommentController =
      TextEditingController();
  final TextEditingController _introductionMethodologyCommentController =
      TextEditingController();
  final TextEditingController _introductionFrameworkCommentController =
      TextEditingController();
  final TextEditingController _conclusionResultsCommentController =
      TextEditingController();

  // Comment visibility state for each question
  Map<String, bool> _commentVisibility = {
    'originalityPublished': false,
    'originalitySimilar': false,
    'originalityValue': false,
    'policyAlignment': false,
    'policyRelevance': false,
    'methodologyData': false,
    'methodologySources': false,
    'methodologyScientific': false,
    'writingTreatment': false,
    'writingLanguage': false,
    'writingSize': false,
    'abstractKeywords': false,
    'abstractConclusions': false,
    'introductionMethodology': false,
    'introductionFramework': false,
    'conclusionResults': false,
  };

  // Evaluation criteria answers - Main Sections
  String? originalityPublished;
  String? originalitySimilar;
  String? originalityValue;
  String? policyAlignment;
  String? policyRelevance;
  String? methodologyData;
  String? methodologySources;
  String? methodologyScientific;
  String? writingTreatment;
  String? writingLanguage;
  String? writingSize;

  // Additional Notes Section
  String? abstractKeywords;
  String? abstractConclusions;
  String? introductionMethodology;
  String? introductionFramework;
  String? conclusionResults;

  bool get isFormValid {
    return originalityPublished != null &&
        originalitySimilar != null &&
        originalityValue != null &&
        policyAlignment != null &&
        policyRelevance != null &&
        methodologyData != null &&
        methodologySources != null &&
        methodologyScientific != null &&
        writingTreatment != null &&
        writingLanguage != null &&
        writingSize != null &&
        abstractKeywords != null &&
        abstractConclusions != null &&
        introductionMethodology != null &&
        introductionFramework != null &&
        conclusionResults != null &&
        _commentController.text.trim().isNotEmpty &&
        _generalEvaluationController.text.trim().isNotEmpty &&
        _modificationsNeededController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Dialog(
        insetPadding: EdgeInsets.all(20),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.rate_review, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'نموذج أسئلة - المرحلة الأولى - تقييم مقال',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Article Basic Info
                        _buildArticleBasicInfoSection(),

                        SizedBox(height: 24),

                        // 1. Originality and Novelty
                        _buildMainSection(
                          '1. الأصالة والجدة',
                          [
                            _buildQuestionItem(
                              'هل تم نشر المقال سابقاً في أي وسيلة نشر؟',
                              originalityPublished,
                              (value) =>
                                  setState(() => originalityPublished = value),
                              'originalityPublished',
                              _originalityPublishedCommentController,
                            ),
                            _buildQuestionItem(
                              'هل توجد في المجلة موضوعات مماثلة له؟',
                              originalitySimilar,
                              (value) =>
                                  setState(() => originalitySimilar = value),
                              'originalitySimilar',
                              _originalitySimilarCommentController,
                            ),
                            _buildQuestionItem(
                              'هل للمقال قيمة مضافة واضحة؟',
                              originalityValue,
                              (value) =>
                                  setState(() => originalityValue = value),
                              'originalityValue',
                              _originalityValueCommentController,
                            ),
                          ],
                        ),

                        // 2. Journal Policies
                        _buildMainSection(
                          '2. سياسات المجلة',
                          [
                            _buildQuestionItem(
                              'هل يتوافق المقال مع سياسات المجلة وهدفها العام؟',
                              policyAlignment,
                              (value) =>
                                  setState(() => policyAlignment = value),
                              'policyAlignment',
                              _policyAlignmentCommentController,
                            ),
                            _buildQuestionItem(
                              'هل يتعلق المقال بمجال اهتمام المجلة (مثلاً: إفريقيا جنوب الصحراء)؟',
                              policyRelevance,
                              (value) =>
                                  setState(() => policyRelevance = value),
                              'policyRelevance',
                              _policyRelevanceCommentController,
                            ),
                          ],
                        ),

                        // 3. Scientific Methodology
                        _buildMainSection(
                          '3. المنهجية العلمية',
                          [
                            _buildQuestionItem(
                              'هل المعلومات والإحصاءات جديدة وحديثة؟',
                              methodologyData,
                              (value) =>
                                  setState(() => methodologyData = value),
                              'methodologyData',
                              _methodologyDataCommentController,
                            ),
                            _buildQuestionItem(
                              'هل المصادر أصلية وموثوقة؟',
                              methodologySources,
                              (value) =>
                                  setState(() => methodologySources = value),
                              'methodologySources',
                              _methodologySourcesCommentController,
                            ),
                            _buildQuestionItem(
                              'هل التزم الباحث بأصول المنهجية العلمية؟',
                              methodologyScientific,
                              (value) =>
                                  setState(() => methodologyScientific = value),
                              'methodologyScientific',
                              _methodologyScientificCommentController,
                            ),
                          ],
                        ),

                        // 4. Writing and Treatment
                        _buildMainSection(
                          '4. الكتابة والمعالجة',
                          [
                            _buildQuestionItem(
                              'هل معالجة الموضوع متكاملة وعناصره الرئيسة متسقة؟',
                              writingTreatment,
                              (value) =>
                                  setState(() => writingTreatment = value),
                              'writingTreatment',
                              _writingTreatmentCommentController,
                            ),
                            _buildQuestionItem(
                              'هل لغة الكتابة سليمة والأسلوب مناسب لعموم القراء؟',
                              writingLanguage,
                              (value) =>
                                  setState(() => writingLanguage = value),
                              'writingLanguage',
                              _writingLanguageCommentController,
                            ),
                            _buildQuestionItem(
                              'هل حجم المقال مناسب؟',
                              writingSize,
                              (value) => setState(() => writingSize = value),
                              'writingSize',
                              _writingSizeCommentController,
                            ),
                          ],
                        ),

                        // Secretary Opinion Section
                        _buildSecretaryOpinionSection(),

                        SizedBox(height: 24),

                        // Additional Notes Section
                        _buildMainSection(
                          'ملاحظات إضافية للمقال',
                          [
                            _buildQuestionItem(
                              'هل الملخص يحتوي على الكلمات المفتاحية الكافية؟',
                              abstractKeywords,
                              (value) =>
                                  setState(() => abstractKeywords = value),
                              'abstractKeywords',
                              _abstractKeywordsCommentController,
                            ),
                            _buildQuestionItem(
                              'هل الاستنتاجات في الملخص قابلة للقياس والتحقق؟',
                              abstractConclusions,
                              (value) =>
                                  setState(() => abstractConclusions = value),
                              'abstractConclusions',
                              _abstractConclusionsCommentController,
                            ),
                            _buildQuestionItem(
                              'هل المقدمة تحتوي على منهج وصياغة إشكالية واضحة؟',
                              introductionMethodology,
                              (value) => setState(
                                  () => introductionMethodology = value),
                              'introductionMethodology',
                              _introductionMethodologyCommentController,
                            ),
                            _buildQuestionItem(
                              'هل المقدمة تشتمل على إطار مفاهيمي محدد للمفاهيم الأساسية؟',
                              introductionFramework,
                              (value) =>
                                  setState(() => introductionFramework = value),
                              'introductionFramework',
                              _introductionFrameworkCommentController,
                            ),
                            _buildQuestionItem(
                              'هل الخاتمة تعرض النتائج بوضوح وتبين حدود الدراسة؟',
                              conclusionResults,
                              (value) =>
                                  setState(() => conclusionResults = value),
                              'conclusionResults',
                              _conclusionResultsCommentController,
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        // General Comment
                        _buildGeneralCommentSection(),

                        SizedBox(height: 24),

                        // Final Decision
                      ],
                    ),
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('إلغاء'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isFormValid ? _submitEvaluation : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('إرسال التقييم'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleBasicInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات أساسية عن المقال',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          SizedBox(height: 12),
          _buildInfoItem('الباحث ودرجته العلمية:',
              '${widget.document.fullName ?? 'غير محدد'} - ${widget.document.education ?? 'غير محدد'}'),
          _buildInfoItem(
              'تاريخ استلام المقال:', _formatDate(widget.document.timestamp)),
          SizedBox(height: 12),
          Text(
            'الزاوية/الموضوع:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade600,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _topicController,
            decoration: InputDecoration(
              hintText: 'اكتب الزاوية أو الموضوع الرئيسي للمقال...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.all(12),
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSection(String title, List<Widget> questions) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
          SizedBox(height: 12),
          ...questions,
        ],
      ),
    );
  }

  Widget _buildQuestionItem(
    String question,
    String? value,
    Function(String) onChanged,
    String commentKey,
    TextEditingController commentController,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _commentVisibility[commentKey] =
                        !(_commentVisibility[commentKey] ?? false);
                  });
                },
                icon: Icon(
                  _commentVisibility[commentKey] == true
                      ? Icons.expand_less
                      : Icons.add_comment,
                  size: 16,
                  color: Colors.orange.shade600,
                ),
                label: Text(
                  _commentVisibility[commentKey] == true
                      ? 'إخفاء'
                      : 'إضافة تعليق',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size(0, 30),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text('نعم', style: TextStyle(fontSize: 13)),
                  value: 'نعم',
                  groupValue: value,
                  onChanged: (val) => onChanged(val!),
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text('لا', style: TextStyle(fontSize: 13)),
                  value: 'لا',
                  groupValue: value,
                  onChanged: (val) => onChanged(val!),
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text('أخرى', style: TextStyle(fontSize: 13)),
                  value: 'أخرى',
                  groupValue: value,
                  onChanged: (val) => onChanged(val!),
                  dense: true,
                ),
              ),
            ],
          ),
          if (_commentVisibility[commentKey] == true) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'اكتب تعليقك هنا...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                maxLines: 2,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecretaryOpinionSection() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'رأي سكرتير التحرير',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'ما تقييم سكرتير التحرير للمقال بشكل عام؟',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _generalEvaluationController,
            decoration: InputDecoration(
              hintText: 'اكتب تقييمك العام للمقال...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.all(12),
            ),
            maxLines: 3,
            textAlign: TextAlign.right,
          ),
          SizedBox(height: 16),
          Text(
            'هل يحتاج المقال إلى تعديلات؟ ما نوعها؟',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _modificationsNeededController,
            decoration: InputDecoration(
              hintText: 'حدد التعديلات المطلوبة إن وجدت...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.all(12),
            ),
            maxLines: 3,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التعليق العام (مطلوب)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: 'اكتب تعليقك العام والتوصيات النهائية...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.all(12),
          ),
          maxLines: 5,
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Future<void> _submitEvaluation() async {
    Map<String, dynamic> result = {
      'topic': _topicController.text.trim(),
      'originalityPublished': originalityPublished,
      'originalityPublishedComment':
          _originalityPublishedCommentController.text.trim(),
      'originalitySimilar': originalitySimilar,
      'originalitySimilarComment':
          _originalitySimilarCommentController.text.trim(),
      'originalityValue': originalityValue,
      'originalityValueComment': _originalityValueCommentController.text.trim(),
      'policyAlignment': policyAlignment,
      'policyAlignmentComment': _policyAlignmentCommentController.text.trim(),
      'policyRelevance': policyRelevance,
      'policyRelevanceComment': _policyRelevanceCommentController.text.trim(),
      'methodologyData': methodologyData,
      'methodologyDataComment': _methodologyDataCommentController.text.trim(),
      'methodologySources': methodologySources,
      'methodologySourcesComment':
          _methodologySourcesCommentController.text.trim(),
      'methodologyScientific': methodologyScientific,
      'methodologyScientificComment':
          _methodologyScientificCommentController.text.trim(),
      'writingTreatment': writingTreatment,
      'writingTreatmentComment': _writingTreatmentCommentController.text.trim(),
      'writingLanguage': writingLanguage,
      'writingLanguageComment': _writingLanguageCommentController.text.trim(),
      'writingSize': writingSize,
      'writingSizeComment': _writingSizeCommentController.text.trim(),
      'generalEvaluation': _generalEvaluationController.text.trim(),
      'modificationsNeeded': _modificationsNeededController.text.trim(),
      'abstractKeywords': abstractKeywords,
      'abstractKeywordsComment': _abstractKeywordsCommentController.text.trim(),
      'abstractConclusions': abstractConclusions,
      'abstractConclusionsComment':
          _abstractConclusionsCommentController.text.trim(),
      'introductionMethodology': introductionMethodology,
      'introductionMethodologyComment':
          _introductionMethodologyCommentController.text.trim(),
      'introductionFramework': introductionFramework,
      'introductionFrameworkComment':
          _introductionFrameworkCommentController.text.trim(),
      'conclusionResults': conclusionResults,
      'conclusionResultsComment':
          _conclusionResultsCommentController.text.trim(),
      'comment': _commentController.text.trim(),
      'action': 'send_to_manager', // الملف سيرسل للمدير في جميع الأحوال
      // Add basic doc info for the PDF header
      'doc_fullName': widget.document.fullName,
      'doc_education': widget.document.education,
      'doc_receivedDate': _formatDate(widget.document.timestamp),
      'generated_at': _formatDate(DateTime.now()),
    };

    // 1) Generate & preview/share the PDF
    final pdfBytes = await _buildPdfReport(result);
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);

    // 2) Return the result to your flow (you can also include pdfBytes if needed)
    Navigator.pop(context);
    widget.onComplete(result);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // =========================
  //      PDF GENERATION
  // =========================

  // NO font assets used here
  Future<Uint8List> _buildPdfReport(Map<String, dynamic> data) async {
    final doc = pw.Document();

    // Use default built-in font (Helvetica). No custom font is loaded.
    final h1 = pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold);
    final h2 = pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold);
    final body = pw.TextStyle(fontSize: 11);

    pw.Widget qaBox(String q, String? a, String notes) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        margin: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('س: $q',
                style: body.copyWith(fontWeight: pw.FontWeight.bold)),
            if (a != null) pw.SizedBox(height: 2),
            if (a != null) pw.Text('الإجابة: $a', style: body),
            if (notes.trim().isNotEmpty) pw.SizedBox(height: 2),
            if (notes.trim().isNotEmpty)
              pw.Text('ملاحظات: $notes', style: body),
          ],
        ),
      );
    }

    final sections = <Map<String, dynamic>>[
      {
        'title': 'الأصالة والجدة',
        'items': [
          {
            'q': 'هل تم نشر المقال سابقاً في أي وسيلة نشر؟',
            'a': data['originalityPublished'],
            'n': data['originalityPublishedComment'] ?? ''
          },
          {
            'q': 'هل توجد في المجلة موضوعات مماثلة له؟',
            'a': data['originalitySimilar'],
            'n': data['originalitySimilarComment'] ?? ''
          },
          {
            'q': 'هل للمقال قيمة مضافة واضحة؟',
            'a': data['originalityValue'],
            'n': data['originalityValueComment'] ?? ''
          },
        ],
      },
      {
        'title': 'سياسات المجلة',
        'items': [
          {
            'q': 'هل يتوافق المقال مع سياسات المجلة وهدفها العام؟',
            'a': data['policyAlignment'],
            'n': data['policyAlignmentComment'] ?? ''
          },
          {
            'q':
                'هل يتعلق المقال بمجال اهتمام المجلة (مثلاً: إفريقيا جنوب الصحراء)؟',
            'a': data['policyRelevance'],
            'n': data['policyRelevanceComment'] ?? ''
          },
        ],
      },
      {
        'title': 'المنهجية العلمية',
        'items': [
          {
            'q': 'هل المعلومات والإحصاءات جديدة وحديثة؟',
            'a': data['methodologyData'],
            'n': data['methodologyDataComment'] ?? ''
          },
          {
            'q': 'هل المصادر أصلية وموثوقة؟',
            'a': data['methodologySources'],
            'n': data['methodologySourcesComment'] ?? ''
          },
          {
            'q': 'هل التزم الباحث بأصول المنهجية العلمية؟',
            'a': data['methodologyScientific'],
            'n': data['methodologyScientificComment'] ?? ''
          },
        ],
      },
      {
        'title': 'الكتابة والمعالجة',
        'items': [
          {
            'q': 'هل معالجة الموضوع متكاملة وعناصره الرئيسة متسقة؟',
            'a': data['writingTreatment'],
            'n': data['writingTreatmentComment'] ?? ''
          },
          {
            'q': 'هل لغة الكتابة سليمة والأسلوب مناسب لعموم القراء؟',
            'a': data['writingLanguage'],
            'n': data['writingLanguageComment'] ?? ''
          },
          {
            'q': 'هل حجم المقال مناسب؟',
            'a': data['writingSize'],
            'n': data['writingSizeComment'] ?? ''
          },
        ],
      },
      {
        'title': 'ملاحظات إضافية للمقال',
        'items': [
          {
            'q': 'هل الملخص يحتوي على الكلمات المفتاحية الكافية؟',
            'a': data['abstractKeywords'],
            'n': data['abstractKeywordsComment'] ?? ''
          },
          {
            'q': 'هل الاستنتاجات في الملخص قابلة للقياس والتحقق؟',
            'a': data['abstractConclusions'],
            'n': data['abstractConclusionsComment'] ?? ''
          },
          {
            'q': 'هل المقدمة تحتوي على منهج وصياغة إشكالية واضحة؟',
            'a': data['introductionMethodology'],
            'n': data['introductionMethodologyComment'] ?? ''
          },
          {
            'q': 'هل المقدمة تشتمل على إطار مفاهيمي محدد للمفاهيم الأساسية؟',
            'a': data['introductionFramework'],
            'n': data['introductionFrameworkComment'] ?? ''
          },
          {
            'q': 'هل الخاتمة تعرض النتائج بوضوح وتبين حدود الدراسة؟',
            'a': data['conclusionResults'],
            'n': data['conclusionResultsComment'] ?? ''
          },
        ],
      },
    ];

    pw.Widget metaGrid(List<List<String>> rows) {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.2),
          1: pw.FlexColumnWidth(2.2),
        },
        children: [
          for (final r in rows)
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(r[0],
                      style: body.copyWith(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(r[1], style: body),
                ),
              ],
            ),
        ],
      );
    }

    pw.Widget boxed(String title, String text) {
      final shown = (text.trim().isEmpty) ? '—' : text.trim();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: h2),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(shown, style: body),
          ),
        ],
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        build: (context) => [
          // Keep RTL direction, even with default font (shaping may not occur)
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text('تقرير تقييم المقال – المرحلة الأولى', style: h1),
                pw.SizedBox(height: 6),
                pw.Divider(),
                pw.SizedBox(height: 6),
                metaGrid([
                  [
                    'الباحث ودرجته العلمية',
                    '${data['doc_fullName'] ?? '—'} - ${data['doc_education'] ?? '—'}'
                  ],
                  ['تاريخ الاستلام', data['doc_receivedDate'] ?? '—'],
                  ['الزاوية/الموضوع', data['topic'] ?? '—'],
                  ['تاريخ إنشاء التقرير', data['generated_at'] ?? '—'],
                ]),
                pw.SizedBox(height: 12),
                for (final s in sections) ...[
                  pw.Text('• ${s['title']}', style: h2),
                  pw.SizedBox(height: 6),
                  ...(s['items'] as List).map<pw.Widget>(
                      (it) => qaBox(it['q'], it['a'], (it['n'] ?? ''))),
                  pw.SizedBox(height: 10),
                ],
                boxed('رأي سكرتير التحرير', data['generalEvaluation'] ?? ''),
                pw.SizedBox(height: 8),
                boxed('التعديلات المطلوبة', data['modificationsNeeded'] ?? ''),
                pw.SizedBox(height: 8),
                boxed('التعليق العام', data['comment'] ?? ''),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('— نهاية التقرير —',
                      style: body.copyWith(color: PdfColors.grey600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }
}

// ======= Keep your DocumentModel as-is in your project =======
// Example shape used above:
// class DocumentModel {
//   final String? fullName;
//   final String? education;
//   final DateTime timestamp;
//   // String? title; // if you have it, you can add it to the PDF
//   DocumentModel({this.fullName, this.education, required this.timestamp});
// }
