// pages/document_details_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:ui' as ui;
import 'package:universal_html/html.dart' as html;

import '../../../Classes/current_user_providerr.dart';
import 'Constants/App_Constants.dart';
import 'Services/Document_Services.dart';
import 'Widgets/ActionButtons.dart';
import 'Widgets/DocumentHeader.dart';
import 'Widgets/DocumentInfoCard.dart';
import 'Widgets/LoadingOverlay.dart';
import 'Widgets/senderinfocard.dart';
import 'Widgets/Action_history.dart';
import 'Widgets/ReviewerStatus.dart';
import 'Widgets/statusbar.dart';
import 'models/document_model.dart';

class DocumentDetailsPage extends StatefulWidget {
  final DocumentSnapshot document;

  const DocumentDetailsPage({super.key, required this.document});

  @override
  State<DocumentDetailsPage> createState() => _DocumentDetailsPageState();
}

class _DocumentDetailsPageState extends State<DocumentDetailsPage>
    with TickerProviderStateMixin {
  // Services
  final DocumentService _documentService = DocumentService();

  // Supported file types
  static const Map<String, String> supportedFileTypes = {
    '.pdf': 'application/pdf',
    '.doc': 'application/msword',
    '.docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.txt': 'text/plain',
    '.rtf': 'application/rtf',
    '.odt': 'application/vnd.oasis.opendocument.text',
  };

  // State variables
  bool _isLoading = false;
  DocumentModel? _documentModel;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPosition;

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDocument();
    _getCurrentUserInfo();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    _progressController.forward();
  }

  void _initializeDocument() {
    try {
      _documentModel = DocumentModel.fromFirestore(widget.document);
      setState(() {});
    } catch (e) {
      _showErrorSnackBar('خطأ في تحميل بيانات المستند: $e');
    }
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
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppStyles.backgroundColor,
        body: _documentModel == null ? _buildLoadingState() : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: AppStyles.primaryColor,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
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
                          // Header
                          DocumentHeader(
                            timestamp: _documentModel!.timestamp,
                            onBack: () => Navigator.pop(context),
                            isDesktop: isDesktop,
                          ),

                          // Content
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 80 : 20,
                              vertical: 20,
                            ),
                            child: Column(
                              children: [
                                // Status Progress Bar
                                StatusProgressBar(
                                    status: _documentModel!.status),

                                SizedBox(height: 24),

                                // Document Info Card
                                DocumentInfoCard(
                                  document: _documentModel!,
                                  onViewFile: _handleViewFile,
                                ),

                                // Sender Info Card
                                SenderInfoCard(
                                  document: _documentModel!,
                                  isDesktop: isDesktop,
                                ),

                                // Update your ActionButtonsWidget instantiation in the build method:
                                ActionButtonsWidget(
                                  status: _documentModel!.status,
                                  document: _documentModel!,
                                  onStatusUpdate: _handleStatusUpdate,
                                  onAssignReviewers:
                                      _showReviewerSelectionDialog,
                                  onReviewerApproval:
                                      _showReviewerApprovalDialog,
                                  onAcceptReject: _showAcceptRejectDialog,
                                  onFinalApproval: _showFinalApprovalDialog,
                                  onHeadOfEditorsApproval:
                                      _showHeadOfEditorsApprovalDialog,
                                  onManageReviewers:
                                      _showManageReviewersDialog, // Add this
                                  onAdminStatusChange:
                                      _showAdminStatusChangeDialog, // Add this
                                ),

                                // Reviewers Status (if available)
                                if (_documentModel!.reviewers.isNotEmpty)
                                  ReviewersStatusWidget(
                                    reviewers: _documentModel!.reviewers,
                                  ),

                                // Action History (if available)
                                if (_documentModel!.actionLog.isNotEmpty)
                                  ActionHistoryWidget(
                                    actionLog: _documentModel!.actionLog,
                                  ),

                                SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Loading Overlay
              if (_isLoading) LoadingOverlay(message: 'جاري تحديث المستند...'),
            ],
          );
        },
      ),
    );
  }

// Replace your existing _handleViewFile method with this updated version
  Future<void> _handleViewFile() async {
    if (_documentModel?.documentUrl == null ||
        _documentModel!.documentUrl!.isEmpty) {
      _showErrorSnackBar('رابط الملف غير متوفر');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final documentData = _buildDocumentDataMap();

      if (kIsWeb) {
        // Web platform handling
        await _handleWebFileView(documentData);
      } else {
        // Mobile platform handling
        String fileExtension =
            _getFileExtension(documentData, _documentModel!.documentUrl!);

        if (!supportedFileTypes.containsKey(fileExtension)) {
          throw Exception(
              'نوع الملف غير مدعوم: ${_getFileTypeDisplayName(documentData, fileExtension)}');
        }

        await _handleMobileFileView(documentData, fileExtension);
      }
    } catch (e) {
      String errorMessage = _getErrorMessage(e);
      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

// Enhanced web file viewing with multiple options
  Future<void> _handleWebFileView(Map<String, dynamic> documentData) async {
    try {
      final String fileUrl = _documentModel!.documentUrl!;
      final String fileExtension = _getFileExtension(documentData, fileUrl);
      final String fileName = _getFileName(documentData, fileUrl);

      if (!supportedFileTypes.containsKey(fileExtension)) {
        throw Exception(
            'نوع الملف غير مدعوم: ${_getFileTypeDisplayName(documentData, fileExtension)}');
      }

      // Show options dialog for web users
      _showWebViewOptionsDialog(fileUrl, fileName, fileExtension, documentData);
    } catch (e) {
      throw Exception('فشل في تجهيز الملف للعرض: $e');
    }
  }

// Show dialog with viewing options for web users
  void _showWebViewOptionsDialog(String fileUrl, String fileName,
      String fileExtension, Map<String, dynamic> documentData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.description, color: AppStyles.primaryColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'خيارات عرض الملف',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 20),
                _buildWebViewOption(
                  icon: Icons.open_in_new,
                  title: 'فتح في تبويب جديد',
                  subtitle: 'فتح الملف في تبويب منفصل',
                  onTap: () async {
                    Navigator.pop(context);
                    await _openInNewTab(fileUrl);
                  },
                ),
                SizedBox(height: 12),
                _buildWebViewOption(
                  icon: Icons.download,
                  title: 'تنزيل الملف',
                  subtitle: 'حفظ الملف على جهازك',
                  onTap: () async {
                    Navigator.pop(context);
                    await _downloadFileWeb(fileUrl, fileName, documentData);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebViewOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppStyles.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppStyles.primaryColor, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

// Open file in new tab
  Future<void> _openInNewTab(String fileUrl) async {
    try {
      html.window.open(fileUrl, '_blank');
      _showSuccessSnackBar('تم فتح الملف في تبويب جديد');
    } catch (e) {
      _showErrorSnackBar('فشل في فتح الملف في تبويب جديد');
    }
  }

// Download file to user's device
  Future<void> _downloadFileWeb(String fileUrl, String fileName,
      Map<String, dynamic> documentData) async {
    try {
      setState(() => _isLoading = true);

      // Method 1: Direct download using anchor element
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

      // Method 2: Download with Dio and create blob
      final dio = Dio();
      final response = await dio.get(
        fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;
        final fileExtension = _getFileExtension(documentData, fileUrl);
        final mimeType =
            supportedFileTypes[fileExtension] ?? 'application/octet-stream';

        // Create blob and download
        final blob = html.Blob([bytes], mimeType);
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);

        final html.AnchorElement anchor = html.AnchorElement(href: blobUrl)
          ..download = fileName
          ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);

        // Clean up blob URL
        html.Url.revokeObjectUrl(blobUrl);

        _showSuccessSnackBar('تم تنزيل الملف بنجاح: $fileName');
      } else {
        throw Exception('فشل في تنزيل الملف: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('فشل في تنزيل الملف: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

// Mobile file handling method (add this if missing)
  Future<void> _handleMobileFileView(
      Map<String, dynamic> documentData, String fileExtension) async {
    String fileName;
    if (documentData.containsKey('originalFileName') &&
        documentData['originalFileName'] != null) {
      fileName = documentData['originalFileName'];
    } else {
      fileName = 'document_${_documentModel!.id}$fileExtension';
    }

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String filePath = '${appDocDir.path}/$fileName';

    await Dio().download(
      _documentModel!.documentUrl!,
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

    final int fileSize = await file.length();
    if (fileSize == 0) {
      throw Exception('الملف فارغ أو تالف');
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
            'لا يوجد تطبيق مناسب لفتح هذا النوع من الملفات\nالرجاء تثبيت تطبيق مناسب لـ ${_getFileTypeDisplayName(documentData, fileExtension)}');
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

// Helper method to get filename
  String _getFileName(Map<String, dynamic> documentData, String url) {
    if (documentData.containsKey('originalFileName') &&
        documentData['originalFileName'] != null &&
        documentData['originalFileName'].toString().isNotEmpty) {
      return documentData['originalFileName'];
    }

    // Try to get filename from URL
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final lastSegment = segments.last;
        if (lastSegment.contains('.')) {
          return lastSegment;
        }
      }
    } catch (e) {
      // Continue to fallback
    }

    // Fallback filename
    final fileExtension = _getFileExtension(documentData, url);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'document_$timestamp$fileExtension';
  }

// Helper method to get error message
  String _getErrorMessage(dynamic e) {
    String errorMessage = 'حدث خطأ أثناء فتح الملف';

    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'انتهت مهلة الاتصال. تحقق من اتصال الإنترنت';
          break;
        case DioExceptionType.badResponse:
          errorMessage = 'خطأ في الخادم: ${e.response?.statusCode}';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'خطأ في الاتصال. تحقق من اتصال الإنترنت';
          break;
        default:
          errorMessage = 'فشل في تنزيل الملف';
      }
    } else if (e is Exception) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    return errorMessage;
  }

  // Helper methods for file handling
  Map<String, dynamic> _buildDocumentDataMap() {
    return {
      'documentType': _documentModel?.documentType,
      'documentTypeName': _documentModel?.documentTypeName,
      'originalFileName': _documentModel?.originalFileName,
      'fileSize': _documentModel?.fileSize,
    };
  }

  String _getFileExtension(Map<String, dynamic> documentData, String url) {
    try {
      if (documentData.containsKey('documentType')) {
        String? docType = documentData['documentType'] as String?;
        if (docType != null &&
            docType.isNotEmpty &&
            supportedFileTypes.containsKey(docType)) {
          return docType;
        }
      }

      if (documentData.containsKey('originalFileName')) {
        String? originalFileName = documentData['originalFileName'] as String?;
        if (originalFileName != null) {
          String extension = path.extension(originalFileName).toLowerCase();
          if (extension.isNotEmpty &&
              supportedFileTypes.containsKey(extension)) {
            return extension;
          }
        }
      }

      String urlPath = Uri.parse(url).path;
      String extension = path.extension(urlPath).toLowerCase();
      if (extension.isNotEmpty && supportedFileTypes.containsKey(extension)) {
        return extension;
      }

      Uri uri = Uri.parse(url);
      if (uri.queryParameters.containsKey('type')) {
        String type = uri.queryParameters['type']!.toLowerCase();
        switch (type) {
          case 'pdf':
            return '.pdf';
          case 'doc':
            return '.doc';
          case 'docx':
            return '.docx';
          case 'txt':
            return '.txt';
          case 'rtf':
            return '.rtf';
          case 'odt':
            return '.odt';
        }
      }
      return '.pdf';
    } catch (e) {
      debugPrint('Error extracting file extension: $e');
      return '.pdf';
    }
  }

  String _getFileTypeDisplayName(
      Map<String, dynamic> documentData, String extension) {
    if (documentData.containsKey('documentTypeName')) {
      String? typeName = documentData['documentTypeName'] as String?;
      if (typeName != null && typeName.isNotEmpty) {
        return typeName;
      }
    }
    return _getFileTypeName(extension);
  }

  String _getFileTypeName(String extension) {
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

  Future<void> _handleStatusUpdate(String newStatus, String? comment) async {
    if (_currentUserId == null ||
        _currentUserName == null ||
        _currentUserPosition == null) {
      _showErrorSnackBar('خطأ في بيانات المستخدم الحالي');
      return;
    }

    _setLoading(true);

    try {
      await _documentService.updateDocumentStatus(
        _documentModel!.id,
        newStatus,
        comment,
        _currentUserId!,
        _currentUserName!,
        _currentUserPosition!,
      );

      // Refresh document data
      await _refreshDocumentData();

      _showSuccessSnackBar('تم تحديث حالة المستند بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في تحديث حالة المستند: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _refreshDocumentData() async {
    try {
      final refreshedDoc = await FirebaseFirestore.instance
          .collection('sent_documents')
          .doc(_documentModel!.id)
          .get();

      if (refreshedDoc.exists) {
        setState(() {
          _documentModel = DocumentModel.fromFirestore(refreshedDoc);
        });
      }
    } catch (e) {
      print('Error refreshing document data: $e');
    }
  }

  // Dialog Methods
  void _showReviewerAssignmentDialog() {
    _showReviewerSelectionDialog();
  }

  void _showReviewerApprovalDialog() {
    _showCommentDialog(
      title: 'موافقة المحكم',
      subtitle: 'أدخل تعليقك على المستند',
      primaryAction: 'موافقة',
      onConfirm: (comment) async {
        await _handleStatusUpdate('موافقة المحكم', comment);
      },
      icon: Icons.thumb_up,
      primaryColor: Colors.green,
    );
  }

  void _showAcceptRejectDialog() {
    _showActionDialog(
      title: 'قبول أو رفض الملف',
      subtitle: 'اختر الإجراء المناسب',
      actions: [
        DialogAction(
          title: 'قبول الملف',
          onPressed: (comment) => _handleStatusUpdate('قبول الملف', comment),
          color: Colors.green,
          icon: Icons.check_circle,
        ),
        DialogAction(
          title: 'رفض الملف',
          onPressed: (comment) => _handleStatusUpdate('تم الرفض', comment),
          color: Colors.red,
          icon: Icons.cancel,
        ),
      ],
      icon: Icons.gavel,
    );
  }

  void _showFinalApprovalDialog() {
    _showActionDialog(
      title: 'موافقة مدير التحرير',
      subtitle: 'اختر الإجراء المناسب بعد مراجعة تعليقات المحكمين',
      actions: [
        DialogAction(
          title: 'إرسال لرئيس التحرير',
          onPressed: (comment) =>
              _handleStatusUpdate('موافقة مدير التحرير', comment),
          color: Colors.green,
          icon: Icons.send,
        ),
        DialogAction(
          title: 'إرسال للتعديل',
          onPressed: (comment) => _handleStatusUpdate('مرسل للتعديل', comment),
          color: Colors.orange,
          icon: Icons.edit,
        ),
        DialogAction(
          title: 'رفض نهائي',
          onPressed: (comment) =>
              _handleStatusUpdate('تم الرفض النهائي', comment),
          color: Colors.red,
          icon: Icons.block,
        ),
      ],
      icon: Icons.approval,
    );
  }

  void _showHeadOfEditorsApprovalDialog() {
    _showActionDialog(
      title: 'موافقة رئيس التحرير',
      subtitle: 'الموافقة النهائية على المستند',
      actions: [
        DialogAction(
          title: 'موافقة نهائية',
          onPressed: (comment) =>
              _handleStatusUpdate('موافقة رئيس التحرير', comment),
          color: Colors.green,
          icon: Icons.verified,
        ),
        DialogAction(
          title: 'إرسال للتعديل',
          onPressed: (comment) =>
              _handleStatusUpdate('مرسل للتعديل من رئيس التحرير', comment),
          color: Colors.orange,
          icon: Icons.edit,
        ),
        DialogAction(
          title: 'رفض نهائي',
          onPressed: (comment) =>
              _handleStatusUpdate('رفض رئيس التحرير', comment),
          color: Colors.red,
          icon: Icons.block,
        ),
      ],
      icon: Icons.verified_user,
    );
  }

  // Reviewer Selection Dialog
  void _showReviewerSelectionDialog() async {
    String selectedReviewerType = 'جميع الأنواع';
    List<String> selectedReviewers = [];
    Map<String, int> reviewerWorkload =
        await _documentService.getReviewerWorkload();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 0,
                        blurRadius: 30,
                        offset: Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppStyles.secondaryColor,
                              AppStyles.primaryColor
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.people_alt,
                                  color: Colors.white, size: 28),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('تعيين المحكمين',
                                      style: AppStyles.headerStyle
                                          .copyWith(fontSize: 24)),
                                  SizedBox(height: 4),
                                  Text(
                                      'اختر المحكمين المناسبين لمراجعة المستند',
                                      style: AppStyles.subHeaderStyle),
                                ],
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
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Document Info
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.description,
                                        color: AppStyles.primaryColor,
                                        size: 24),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                          'ملف: ${_documentModel!.fullName}',
                                          style: AppStyles.bodyTextStyle
                                              .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16)),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 20),

                              // Filter Section
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: AppStyles.simpleCardDecoration,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('تصفية حسب نوع التحكيم',
                                        style: AppStyles.cardTitleStyle
                                            .copyWith(
                                                fontSize: 18,
                                                color: AppStyles.primaryColor)),
                                    SizedBox(height: 16),
                                    DropdownButton<String>(
                                      value: selectedReviewerType,
                                      isExpanded: true,
                                      items: AppConstants.reviewerTypes
                                          .map((type) {
                                        return DropdownMenuItem(
                                            value: type,
                                            child: Text(type == 'جميع الأنواع'
                                                ? type
                                                : 'محكم $type'));
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            selectedReviewerType = value;
                                            selectedReviewers.clear();
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 20),

                              // Selected Count
                              if (selectedReviewers.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color:
                                        AppStyles.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppStyles.primaryColor
                                            .withOpacity(0.3)),
                                  ),
                                  child: Text(
                                      'تم اختيار ${selectedReviewers.length} محكم',
                                      style: AppStyles.bodyTextStyle.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppStyles.primaryColor)),
                                ),

                              SizedBox(height: 16),

                              // Reviewers List
                              Expanded(
                                child: StreamBuilder<QuerySnapshot>(
                                  stream:
                                      _getReviewersStream(selectedReviewerType),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return Center(
                                          child: Text('خطأ في تحميل المحكمين'));
                                    }

                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    }

                                    final reviewers = snapshot.data?.docs ?? [];

                                    if (reviewers.isEmpty) {
                                      return Center(
                                          child: Text('لا يوجد محكمين متاحين'));
                                    }

                                    return ListView.builder(
                                      itemCount: reviewers.length,
                                      itemBuilder: (context, index) {
                                        final reviewer = reviewers[index];
                                        final data = reviewer.data()
                                            as Map<String, dynamic>;
                                        final reviewerId = reviewer.id;
                                        final reviewerName =
                                            data['fullName'] ?? 'غير معروف';
                                        final isSelected = selectedReviewers
                                            .contains(reviewerId);

                                        return Card(
                                          child: CheckboxListTile(
                                            title: Text(reviewerName),
                                            subtitle:
                                                Text(data['position'] ?? ''),
                                            value: isSelected,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (value == true) {
                                                  selectedReviewers
                                                      .add(reviewerId);
                                                } else {
                                                  selectedReviewers
                                                      .remove(reviewerId);
                                                }
                                              });
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),

                              SizedBox(height: 20),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: selectedReviewers.isEmpty
                                          ? null
                                          : () => _assignReviewers(
                                              selectedReviewers,
                                              selectedReviewerType,
                                              context),
                                      style: AppStyles.primaryButtonStyle,
                                      child: Text(
                                          'تعيين المحكمين (${selectedReviewers.length})'),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: AppStyles.secondaryButtonStyle,
                                      child: Text('إلغاء'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getReviewersStream(String selectedReviewerType) {
    if (selectedReviewerType == 'جميع الأنواع') {
      return FirebaseFirestore.instance.collection('users').where('position',
          whereIn: ['محكم سياسي', 'محكم اقتصادي', 'محكم اجتماعي']).snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('users')
          .where('position', isEqualTo: 'محكم $selectedReviewerType')
          .snapshots();
    }
  }

  Future<void> _assignReviewers(List<String> reviewerIds, String reviewerType,
      BuildContext dialogContext) async {
    Navigator.pop(dialogContext);
    _setLoading(true);

    try {
      await _documentService.assignReviewers(
        _documentModel!.id,
        reviewerIds,
        reviewerType == 'جميع الأنواع' ? 'مختلط' : reviewerType,
        _currentUserName!,
        _currentUserId!,
      );

      await _refreshDocumentData();
      _showSuccessSnackBar('تم تعيين ${reviewerIds.length} محكم بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في تعيين المحكمين: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Dialog Helper Methods
  void _showCommentDialog({
    required String title,
    required String subtitle,
    required String primaryAction,
    required Function(String) onConfirm,
    required IconData icon,
    required MaterialColor primaryColor,
  }) {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 500,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 0,
                    blurRadius: 30,
                    offset: Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor.shade400, primaryColor.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: Colors.white, size: 28),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              SizedBox(height: 4),
                              Text(subtitle,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تعليق (مطلوب)',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff2d3748))),
                        SizedBox(height: 12),
                        TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'اكتب تعليقك هنا...',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: EdgeInsets.all(16),
                          ),
                          maxLines: 4,
                          textAlign: TextAlign.right,
                        ),
                        SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (commentController.text.trim().isEmpty) {
                                    _showErrorSnackBar('الرجاء إدخال تعليق');
                                    return;
                                  }
                                  Navigator.of(context).pop();
                                  await onConfirm(commentController.text);
                                },
                                style: AppStyles.primaryButtonStyle,
                                child: Text(primaryAction),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: AppStyles.secondaryButtonStyle,
                                child: Text('إلغاء'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showActionDialog({
    required String title,
    required String subtitle,
    required List<DialogAction> actions,
    required IconData icon,
  }) {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 600,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 0,
                    blurRadius: 30,
                    offset: Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppStyles.primaryColor,
                          AppStyles.secondaryColor
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: Colors.white, size: 28),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              SizedBox(height: 4),
                              Text(subtitle,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9))),
                            ],
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
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تعليق (اختياري)',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff2d3748))),
                        SizedBox(height: 12),
                        TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'اكتب تعليقك هنا...',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: EdgeInsets.all(16),
                          ),
                          maxLines: 3,
                          textAlign: TextAlign.right,
                        ),
                        SizedBox(height: 24),

                        // Action Buttons
                        _buildActionButtons(actions, commentController),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
      List<DialogAction> actions, TextEditingController commentController) {
    List<Widget> buttons = [];

    for (int i = 0; i < actions.length; i += 2) {
      List<Widget> rowButtons = [];

      for (int j = i; j < i + 2 && j < actions.length; j++) {
        final action = actions[j];
        rowButtons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await action.onPressed(commentController.text);
              },
              icon: Icon(action.icon, color: Colors.white),
              label: Text(action.title,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: action.color,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        );

        if (j < i + 1 && j + 1 < actions.length) {
          rowButtons.add(SizedBox(width: 12));
        }
      }

      buttons.add(Row(children: rowButtons));

      if (i + 2 < actions.length) {
        buttons.add(SizedBox(height: 12));
      }
    }

    // Add cancel button
    buttons.add(SizedBox(height: 12));
    buttons.add(
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: AppStyles.secondaryButtonStyle,
              child: Text('إلغاء'),
            ),
          ),
        ],
      ),
    );

    return Column(children: buttons);
  }

  // Utility Methods
  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
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
        duration: Duration(seconds: 2),
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
        duration: Duration(seconds: 4),
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
        duration: Duration(seconds: 4),
      ),
    );
  }

  // Additional methods to add to your DocumentDetailsPage class

// Add these new callback methods to your DocumentDetailsPage class:

  void _showAdminStatusChangeDialog() {
    final List<Map<String, dynamic>> allStatuses = [
      {
        'key': 'ملف مرسل',
        'title': 'ملف مرسل',
        'description': 'المرحلة الأولى - في انتظار المراجعة الأولية',
        'icon': Icons.send,
        'color': Colors.blue,
      },
      {
        'key': 'قبول الملف',
        'title': 'قبول الملف',
        'description': 'تم قبول الملف - جاهز لتعيين المحكمين',
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
      {
        'key': 'الي المحكمين',
        'title': 'إلى المحكمين',
        'description': 'تم تعيين المحكمين - في انتظار المراجعة',
        'icon': Icons.people,
        'color': Colors.orange,
      },
      {
        'key': 'تم التحكيم',
        'title': 'تم التحكيم',
        'description': 'انتهت مرحلة التحكيم - في انتظار موافقة مدير التحرير',
        'icon': Icons.rate_review,
        'color': Colors.purple,
      },
      {
        'key': 'موافقة مدير التحرير',
        'title': 'موافقة مدير التحرير',
        'description': 'وافق مدير التحرير - في انتظار موافقة رئيس التحرير',
        'icon': Icons.approval,
        'color': Colors.indigo,
      },
      {
        'key': 'موافقة رئيس التحرير',
        'title': 'موافقة رئيس التحرير',
        'description': 'الموافقة النهائية - جاهز للنشر',
        'icon': Icons.verified,
        'color': Colors.green,
      },
      {
        'key': 'مرسل للتعديل',
        'title': 'مرسل للتعديل',
        'description': 'تم إرسال الملف للمؤلف للتعديل',
        'icon': Icons.edit,
        'color': Colors.orange,
      },
      {
        'key': 'مرسل للتعديل من رئيس التحرير',
        'title': 'مرسل للتعديل من رئيس التحرير',
        'description': 'رئيس التحرير طلب تعديلات',
        'icon': Icons.edit_note,
        'color': Colors.orange,
      },
      {
        'key': 'تم الرفض',
        'title': 'تم الرفض',
        'description': 'تم رفض الملف',
        'icon': Icons.cancel,
        'color': Colors.red,
      },
      {
        'key': 'تم الرفض النهائي',
        'title': 'تم الرفض النهائي',
        'description': 'رفض نهائي من مدير التحرير',
        'icon': Icons.block,
        'color': Colors.red,
      },
      {
        'key': 'رفض رئيس التحرير',
        'title': 'رفض رئيس التحرير',
        'description': 'رفض نهائي من رئيس التحرير',
        'icon': Icons.cancel_presentation,
        'color': Colors.red,
      },
    ];

    final TextEditingController commentController = TextEditingController();
    String? selectedStatus;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 0,
                        blurRadius: 30,
                        offset: Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade400,
                              Colors.purple.shade600
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.swap_horiz,
                                  color: Colors.white, size: 28),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('تغيير حالة المستند',
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  SizedBox(height: 4),
                                  Text('اختر الحالة الجديدة للمستند',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              Colors.white.withOpacity(0.9))),
                                ],
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
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Current Status Info
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info,
                                        color: AppStyles.primaryColor,
                                        size: 24),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'الحالة الحالية: ${_documentModel!.status}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                          Text(
                                              'ملف: ${_documentModel!.fullName}',
                                              style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 20),

                              // Status Selection
                              Text('اختر الحالة الجديدة:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppStyles.primaryColor)),
                              SizedBox(height: 16),

                              Expanded(
                                child: GridView.builder(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 2.5,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: allStatuses.length,
                                  itemBuilder: (context, index) {
                                    final status = allStatuses[index];
                                    final isSelected =
                                        selectedStatus == status['key'];
                                    final isCurrent =
                                        _documentModel!.status == status['key'];

                                    return InkWell(
                                      onTap: isCurrent
                                          ? null
                                          : () {
                                              setState(() {
                                                selectedStatus = status['key'];
                                              });
                                            },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isCurrent
                                                ? [
                                                    Colors.grey.shade100,
                                                    Colors.grey.shade200
                                                  ]
                                                : isSelected
                                                    ? [
                                                        status['color']
                                                            .shade100,
                                                        status['color'].shade200
                                                      ]
                                                    : [
                                                        Colors.white,
                                                        Colors.grey.shade50
                                                      ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isCurrent
                                                ? Colors.grey.shade400
                                                : isSelected
                                                    ? status['color'].shade400
                                                    : Colors.grey.shade200,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: isCurrent
                                                        ? Colors.grey.shade200
                                                        : status['color']
                                                            .shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    status['icon'],
                                                    color: isCurrent
                                                        ? Colors.grey.shade600
                                                        : status['color']
                                                            .shade600,
                                                    size: 20,
                                                  ),
                                                ),
                                                if (isCurrent) ...[
                                                  SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade300,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      'حالياً',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors
                                                            .grey.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              status['title'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isCurrent
                                                    ? Colors.grey.shade600
                                                    : status['color'].shade700,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              status['description'],
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isCurrent
                                                    ? Colors.grey.shade500
                                                    : status['color'].shade600,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              SizedBox(height: 20),

                              // Comment Field
                              Text('تعليق (مطلوب):',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff2d3748))),
                              SizedBox(height: 12),
                              TextField(
                                controller: commentController,
                                decoration: InputDecoration(
                                  hintText: 'اكتب سبب تغيير الحالة...',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  contentPadding: EdgeInsets.all(16),
                                ),
                                maxLines: 3,
                                textAlign: TextAlign.right,
                              ),

                              SizedBox(height: 20),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: (selectedStatus == null ||
                                              commentController.text
                                                  .trim()
                                                  .isEmpty)
                                          ? null
                                          : () async {
                                              Navigator.pop(context);
                                              await _handleStatusUpdate(
                                                  selectedStatus!,
                                                  commentController.text);
                                            },
                                      style: AppStyles.primaryButtonStyle,
                                      child: Text('تطبيق التغيير'),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: AppStyles.secondaryButtonStyle,
                                      child: Text('إلغاء'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showManageReviewersDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 0,
                        blurRadius: 30,
                        offset: Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.teal.shade400,
                              Colors.teal.shade600
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.people_outline,
                                  color: Colors.white, size: 28),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('إدارة المحكمين',
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  SizedBox(height: 4),
                                  Text(
                                      'إضافة أو حذف أو تعديل المحكمين المعيّنين',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              Colors.white.withOpacity(0.9))),
                                ],
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
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Current Reviewers Section
                              if (_documentModel!.reviewers.isNotEmpty) ...[
                                Text('المحكمون الحاليون:',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppStyles.primaryColor)),
                                SizedBox(height: 16),
                                Container(
                                  height: 200,
                                  child: ListView.builder(
                                    itemCount: _documentModel!.reviewers.length,
                                    itemBuilder: (context, index) {
                                      final reviewer =
                                          _documentModel!.reviewers[index];
                                      return Card(
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                reviewer.reviewStatus ==
                                                        'Approved'
                                                    ? Colors.green
                                                    : Colors.orange,
                                            child: Icon(
                                              reviewer.reviewStatus ==
                                                      'Approved'
                                                  ? Icons.check
                                                  : Icons.schedule,
                                              color: Colors.white,
                                            ),
                                          ),
                                          title: Text(reviewer.name),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(reviewer.position),
                                              Text(
                                                  'حالة: ${reviewer.reviewStatus == 'Approved' ? 'وافق' : 'في الانتظار'}',
                                                  style:
                                                      TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                          trailing: PopupMenuButton(
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: 'remove',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete,
                                                        color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('إزالة المحكم'),
                                                  ],
                                                ),
                                              ),
                                              if (reviewer.reviewStatus !=
                                                  'Approved')
                                                PopupMenuItem(
                                                  value: 'approve',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.check,
                                                          color: Colors.green),
                                                      SizedBox(width: 8),
                                                      Text('موافقة إدارية'),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                            onSelected: (value) async {
                                              if (value == 'remove') {
                                                await _removeReviewer(reviewer);
                                              } else if (value == 'approve') {
                                                await _approveReviewerAdmin(
                                                    reviewer);
                                              }
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 20),
                              ],

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _showReviewerSelectionDialog();
                                      },
                                      icon: Icon(Icons.person_add),
                                      label: Text('إضافة محكمين'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          _documentModel!.reviewers.isEmpty
                                              ? null
                                              : () {
                                                  Navigator.pop(context);
                                                  _showClearAllReviewersDialog();
                                                },
                                      icon: Icon(Icons.clear_all),
                                      label: Text('مسح الكل'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showClearAllReviewersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('مسح جميع المحكمين'),
        content: Text(
          'هل أنت متأكد من رغبتك في إزالة جميع المحكمين المعيّنين؟\n\nسيتم:\n• إزالة جميع المحكمين\n• مسح جميع التعليقات والموافقات\n• تغيير حالة الملف إلى "قبول الملف"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllReviewers();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('تأكيد المسح'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeReviewer(ReviewerModel reviewer) async {
    try {
      _setLoading(true);

      // Update document in Firestore to remove this reviewer
      final updatedReviewers = _documentModel!.reviewers
          .where((r) => r.userId != reviewer.userId)
          .map((r) => r.toMap())
          .toList();

      await FirebaseFirestore.instance
          .collection('sent_documents')
          .doc(_documentModel!.id)
          .update({
        'reviewers': updatedReviewers,
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': _currentUserName,
        'actionLog': FieldValue.arrayUnion([
          {
            'action': 'إزالة محكم',
            'userName': _currentUserName,
            'userPosition': _currentUserPosition,
            'performedById': _currentUserId,
            'timestamp': Timestamp.now(),
            'comment': 'تم إزالة المحكم: ${reviewer.name}',
          }
        ]),
      });

      await _refreshDocumentData();
      _showSuccessSnackBar('تم إزالة المحكم: ${reviewer.name}');
    } catch (e) {
      _showErrorSnackBar('خطأ في إزالة المحكم: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _approveReviewerAdmin(ReviewerModel reviewer) async {
    try {
      _setLoading(true);

      await _documentService.updateReviewerStatus(
        _documentModel!.id,
        reviewer.userId,
        'Approved',
        'موافقة إدارية من ${_currentUserPosition}',
        _currentUserName!,
      );

      await _refreshDocumentData();
      _showSuccessSnackBar('تمت الموافقة الإدارية للمحكم: ${reviewer.name}');
    } catch (e) {
      _showErrorSnackBar('خطأ في الموافقة الإدارية: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _clearAllReviewers() async {
    try {
      _setLoading(true);

      await FirebaseFirestore.instance
          .collection('sent_documents')
          .doc(_documentModel!.id)
          .update({
        'reviewers': [],
        'status': 'قبول الملف',
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': _currentUserName,
        'actionLog': FieldValue.arrayUnion([
          {
            'action': 'مسح جميع المحكمين',
            'userName': _currentUserName,
            'userPosition': _currentUserPosition,
            'performedById': _currentUserId,
            'timestamp': Timestamp.now(),
            'comment': 'تم مسح جميع المحكمين وإعادة الملف لمرحلة قبول الملف',
          }
        ]),
      });

      await _refreshDocumentData();
      _showSuccessSnackBar(
          'تم مسح جميع المحكمين وإعادة الملف لمرحلة قبول الملف');
    } catch (e) {
      _showErrorSnackBar('خطأ في مسح المحكمين: $e');
    } finally {
      _setLoading(false);
    }
  }
}

// Helper class for dialog actions
class DialogAction {
  final String title;
  final Function(String) onPressed;
  final MaterialColor color;
  final IconData icon;

  DialogAction({
    required this.title,
    required this.onPressed,
    required this.color,
    required this.icon,
  });
}
