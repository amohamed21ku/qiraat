// pages/Stage1/Stage1SecretaryDetailsPage.dart - Updated with comprehensive file handling
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

import '../../Classes/current_user_providerr.dart';
import '../Screens/Document_Handling/DocumentDetails/Constants/App_Constants.dart';
import '../Screens/Document_Handling/DocumentDetails/Services/Document_Services.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/Action_history.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/senderinfocard.dart';
import '../Screens/Document_Handling/DocumentDetails/models/document_model.dart';

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

          // Sender Info Card
          SenderInfoCard(
            document: _document!,
            isDesktop: isDesktop,
          ),

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
                        'مراجعة التنسيق والمتطلبات الأساسية',
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
      return _buildReviewActions();
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

  Widget _buildReviewActions() {
    return Column(
      children: [
        // Guidelines Box
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
                    'معايير المراجعة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildGuidelineItem('فحص اكتمال البيانات الأساسية'),
              _buildGuidelineItem('التأكد من صحة التنسيق'),
              _buildGuidelineItem('مراجعة المتطلبات الشكلية'),
              _buildGuidelineItem('التحقق من سلامة الملف'),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'موافقة',
                icon: Icons.check_circle,
                color: Colors.green,
                onPressed: () => _showActionDialog('approve'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: 'رفض',
                icon: Icons.cancel,
                color: Colors.red,
                onPressed: () => _showActionDialog('reject'),
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            title: 'طلب تعديل',
            icon: Icons.edit,
            color: Colors.orange,
            onPressed: () => _showActionDialog('edit'),
          ),
        ),
      ],
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.orange.shade400,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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

  void _showActionDialog(String action) {
    String title = '';
    String description = '';
    Color color = Colors.blue;

    switch (action) {
      case 'approve':
        title = 'موافقة على المقال';
        description = 'سيتم إرسال المقال لمدير التحرير للمراجعة';
        color = Colors.green;
        break;
      case 'reject':
        title = 'رفض المقال';
        description = 'سيتم رفض المقال وإشعار المؤلف';
        color = Colors.red;
        break;
      case 'edit':
        title = 'طلب تعديل';
        description = 'سيتم طلب تعديلات من المؤلف';
        color = Colors.orange;
        break;
    }

    showDialog(
      context: context,
      builder: (context) => ActionDialog(
        title: title,
        description: description,
        color: color,
        onConfirm: (comment, fileUrl, fileName) =>
            _processAction(action, comment, fileUrl, fileName),
      ),
    );
  }

  Future<void> _processAction(
      String action, String comment, String? fileUrl, String? fileName) async {
    setState(() => _isLoading = true);

    try {
      String nextStatus = '';
      switch (action) {
        case 'approve':
          nextStatus = AppConstants.SECRETARY_APPROVED;
          break;
        case 'reject':
          nextStatus = AppConstants.SECRETARY_REJECTED;
          break;
        case 'edit':
          nextStatus = AppConstants.SECRETARY_EDIT_REQUESTED;
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

// 1. Secretary Action Dialog - Updated
class ActionDialog extends StatefulWidget {
  final String title;
  final String description;
  final Color color;
  final Function(String, String?, String?) onConfirm;

  const ActionDialog({
    Key? key,
    required this.title,
    required this.description,
    required this.color,
    required this.onConfirm,
  }) : super(key: key);

  @override
  _ActionDialogState createState() => _ActionDialogState();
}

class _ActionDialogState extends State<ActionDialog> {
  final TextEditingController _commentController = TextEditingController();
  String? _attachedFileName;
  String? _attachedFileUrl;
  bool _isUploading = false;

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
            Text('تعليق (مطلوب):'),
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

            SizedBox(height: 16),

            // File attachment (optional)
            Text('إرفاق تقرير (اختياري):'),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: _isUploading ? null : _pickFile,
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: _isUploading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.attach_file,
                              color: Colors.grey.shade600),
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
                    if (_attachedFileName != null && !_isUploading)
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
            SizedBox(height: 8),
            Text(
              'يمكنك إرفاق تقرير يوضح نتائج المراجعة ومبررات القرار (اختياري)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _canConfirm()
                ? () {
                    Navigator.pop(context);
                    widget.onConfirm(
                      _commentController.text.trim(),
                      _attachedFileUrl,
                      _attachedFileName,
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
            ),
            child: Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  bool _canConfirm() {
    return _commentController.text.trim().isNotEmpty && !_isUploading;
  }

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
        } else {
          throw Exception('فشل في رفع الملف');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في رفع الملف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<String?> _uploadFileToFirebaseStorage(PlatformFile file) async {
    try {
      final FirebaseStorage storage = FirebaseStorage.instance;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'secretary_reports/${timestamp}_${file.name}';

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
}
