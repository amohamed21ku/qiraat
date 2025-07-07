import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:qiraat/Classes/current_user_providerr.dart';
import 'package:qiraat/Screens/Document_Handling/UIComponents.dart';
import 'package:qiraat/Widgets/Components.dart';
import 'dart:ui' as ui;
import 'package:path/path.dart' as path;

class DocumentDetailsPage extends StatefulWidget {
  final DocumentSnapshot document;

  const DocumentDetailsPage({super.key, required this.document});

  @override
  State<DocumentDetailsPage> createState() => _DocumentDetailsPageState();
}

class _DocumentDetailsPageState extends State<DocumentDetailsPage>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  List<String> selectedReviewers = [];
  bool isCurrentUserReviewer = false;
  bool hasCurrentUserApproved = false;
  Map<String, String> reviewerStatuses = {};
  String? currentUserId;
  String? currentUserName;
  String? currentUserEmail;

  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Define the theme colors
  final Color primaryColor = const Color(0xffa86418);
  final Color secondaryColor = const Color(0xffcc9657);

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

  @override
  void initState() {
    super.initState();
    _getCurrentUserInfo();
    _checkIfUserIsReviewer();
    _loadReviewerStatuses();

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

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  // Get file extension from document data or URL fallback
  String _getFileExtension(Map<String, dynamic> documentData, String? url) {
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

      if (url != null) {
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

  IconData _getFileTypeIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.txt':
        return Icons.text_snippet;
      case '.rtf':
        return Icons.article;
      case '.odt':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file;
    }
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

  Future<void> _viewFile(String url, Map<String, dynamic> documentData) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String fileExtension = _getFileExtension(documentData, url);

      if (!supportedFileTypes.containsKey(fileExtension)) {
        throw Exception(
            'نوع الملف غير مدعوم: ${_getFileTypeDisplayName(documentData, fileExtension)}');
      }

      String fileName;
      if (documentData.containsKey('originalFileName')) {
        fileName = documentData['originalFileName'] ??
            'document_${widget.document.id}$fileExtension';
      } else {
        fileName = 'document_${widget.document.id}$fileExtension';
      }

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDocDir.path}/$fileName';

      double downloadProgress = 0.0;

      await Dio().download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress = received / total;
            debugPrint(
                'Download progress: ${(downloadProgress * 100).toStringAsFixed(0)}%');
          }
        },
      );

      setState(() {
        _isLoading = false;
      });

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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

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

      _showErrorSnackBar(errorMessage,
          action: SnackBarAction(
            label: 'إعادة المحاولة',
            textColor: Colors.white,
            onPressed: () => _viewFile(url, documentData),
          ));
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

  void _showErrorSnackBar(String message, {SnackBarAction? action}) {
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
        duration: Duration(seconds: 5),
        action: action,
      ),
    );
  }

  Widget _buildDocumentInfoWidget() {
    final data = widget.document.data() as Map<String, dynamic>;
    final String? documentUrl = data['documentUrl'];

    if (documentUrl == null) {
      return Container(
        padding: EdgeInsets.all(20),
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade50, Colors.red.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.error_outline, color: Colors.red, size: 32),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مشكلة في الملف',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'رابط المستند غير متوفر',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final String fileExtension = _getFileExtension(data, documentUrl);
    final String fileTypeName = _getFileTypeDisplayName(data, fileExtension);
    final IconData fileIcon = _getFileTypeIcon(fileExtension);

    String? originalFileName = data['originalFileName'] as String?;
    int? fileSize = data['fileSize'] as int?;

    return Container(
      padding: EdgeInsets.all(24),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.2)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  fileIcon,
                  color: primaryColor,
                  size: 32,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نوع المستند',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      fileTypeName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    if (originalFileName != null) ...[
                      SizedBox(height: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          originalFileName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (fileSize != null) ...[
                      SizedBox(height: 6),
                      Text(
                        formatFileSize(fileSize),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _viewFile(documentUrl, data),
                  icon: Icon(Icons.visibility, color: Colors.white, size: 20),
                  label: Text(
                    'عرض الملف',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
    );
  }

  String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _getCurrentUserInfo() async {
    final currentUserProvider =
        Provider.of<CurrentUserProvider>(context, listen: false);
    final currentUser = currentUserProvider.currentUser;

    if (currentUser != null) {
      setState(() {
        currentUserId = currentUser.id ?? currentUser.email;
        currentUserName = currentUser.name;
        currentUserEmail = currentUser.email;
      });
    }
  }

  void _loadReviewerStatuses() {
    final data = widget.document.data() as Map<String, dynamic>;
    final reviewers = data['reviewers'] as List<dynamic>? ?? [];

    Map<String, String> statuses = {};
    for (var reviewer in reviewers) {
      if (reviewer is Map<String, dynamic>) {
        final userId = reviewer['userId'] ?? reviewer['id'] ?? '';
        final name = reviewer['name'] ?? reviewer['fullName'] ?? '';
        final status = reviewer['review_status'] ?? 'Pending';

        String key = userId.isNotEmpty ? userId : name;
        if (key.isNotEmpty) {
          statuses[key] = status;
        }
      } else if (reviewer is String) {
        statuses[reviewer] = 'Pending';
      }
    }

    setState(() {
      reviewerStatuses = statuses;
    });
  }

  bool _isCurrentUserReviewer(dynamic reviewer) {
    if (currentUserId == null || currentUserId!.isEmpty) {
      return false;
    }

    try {
      if (reviewer is Map<String, dynamic>) {
        final reviewerUserId = reviewer['userId'] ?? reviewer['id'] ?? '';
        if (reviewerUserId.isNotEmpty && reviewerUserId == currentUserId) {
          return true;
        }

        final reviewerEmail = reviewer['email'] ?? '';
        if (reviewerEmail.isNotEmpty &&
            (reviewerEmail == currentUserId ||
                reviewerEmail == currentUserEmail)) {
          return true;
        }

        final reviewerName = reviewer['name'] ?? reviewer['fullName'] ?? '';
        if (reviewerName.isNotEmpty &&
            currentUserName != null &&
            reviewerName.toLowerCase().trim() ==
                currentUserName!.toLowerCase().trim()) {
          return true;
        }
      } else if (reviewer is String) {
        if (reviewer == currentUserId ||
            reviewer == currentUserName ||
            reviewer == currentUserEmail) {
          return true;
        }
      }
    } catch (e) {
      print('Error checking if current user is reviewer: $e');
    }

    return false;
  }

  void _checkIfUserIsReviewer() async {
    if (currentUserId == null || currentUserId!.isEmpty) {
      return;
    }

    final data = widget.document.data() as Map<String, dynamic>;
    final reviewers = data['reviewers'] as List<dynamic>? ?? [];

    final currentUserProvider =
        Provider.of<CurrentUserProvider>(context, listen: false);
    final currentUser = currentUserProvider.currentUser;

    if (currentUser != null) {
      for (var reviewer in reviewers) {
        if (_isCurrentUserReviewer(reviewer)) {
          String reviewStatus = 'Pending';

          if (reviewer is Map<String, dynamic>) {
            reviewStatus = reviewer['review_status'] ?? 'Pending';
          }

          setState(() {
            isCurrentUserReviewer = true;
            hasCurrentUserApproved = reviewStatus == "Approved";
          });
          break;
        }
      }
    }
  }

  bool _canAssignReviewers(String? position) {
    return position == 'رئيس التحرير' || position == 'مدير التحرير';
  }

  bool _canFinalApprove(String? position) {
    return position == 'مدير التحرير' || position == 'رئيس التحرير';
  }

  Future<Map<String, int>> _getReviewerWorkload() async {
    Map<String, int> workload = {};

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('sent_documents')
          .where('status', isEqualTo: 'الي المحكمين')
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final List<dynamic> reviewers = data['reviewers'] ?? [];

        for (var reviewer in reviewers) {
          String reviewerId = '';
          if (reviewer is Map<String, dynamic>) {
            reviewerId = reviewer['userId'] ?? reviewer['id'] ?? '';
          }

          if (reviewerId.isNotEmpty) {
            workload[reviewerId] = (workload[reviewerId] ?? 0) + 1;
          }
        }
      }
    } catch (e) {
      print('Error getting reviewer workload: $e');
    }

    return workload;
  }

  void _showReviewerAssignmentDialog() async {
    final currentUserProvider =
        Provider.of<CurrentUserProvider>(context, listen: false);
    final currentUser = currentUserProvider.currentUser;

    if (!_canAssignReviewers(currentUser?.position)) {
      _showErrorSnackBar('غير مسموح لك بتعيين المحكمين');
      return;
    }

    String selectedReviewerType = 'جميع الأنواع';
    List<String> reviewerTypes = [
      'جميع الأنواع',
      'سياسي',
      'اقتصادي',
      'اجتماعي'
    ];
    List<String> selectedReviewers = [];
    Map<String, int> reviewerWorkload = await _getReviewerWorkload();

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
                      // Modern Header
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [secondaryColor, primaryColor],
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
                                  Text(
                                    'تعيين المحكمين',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'اختر المحكمين المناسبين لمراجعة المستند',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Document Info Card
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
                                        color: primaryColor, size: 24),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'ملف: ${(widget.document.data() as Map<String, dynamic>)['fullName'] ?? 'غير معروف'}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Color(0xff2d3748),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),

                              // Filter Section
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 0,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تصفية حسب نوع التحكيم',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: primaryColor,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey.shade50,
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedReviewerType,
                                          isExpanded: true,
                                          icon: Icon(Icons.arrow_drop_down,
                                              color: primaryColor),
                                          items: reviewerTypes.map((type) {
                                            return DropdownMenuItem(
                                              value: type,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    type == 'جميع الأنواع'
                                                        ? Icons.all_inclusive
                                                        : type == 'سياسي'
                                                            ? Icons
                                                                .account_balance
                                                            : type == 'اقتصادي'
                                                                ? Icons
                                                                    .trending_up
                                                                : Icons.people,
                                                    color: primaryColor,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    type == 'جميع الأنواع'
                                                        ? type
                                                        : 'محكم $type',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                            );
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
                                      ),
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
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryColor.withOpacity(0.1),
                                        primaryColor.withOpacity(0.05)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: primaryColor.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: primaryColor, size: 24),
                                      SizedBox(width: 12),
                                      Text(
                                        'تم اختيار ${selectedReviewers.length} محكم',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(height: 16),

                              // Reviewers List
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.grey.shade50,
                                  ),
                                  child: StreamBuilder<QuerySnapshot>(
                                    stream: selectedReviewerType ==
                                            'جميع الأنواع'
                                        ? FirebaseFirestore.instance
                                            .collection('users')
                                            .where('position', whereIn: [
                                            'محكم سياسي',
                                            'محكم اقتصادي',
                                            'محكم اجتماعي'
                                          ]).snapshots()
                                        : FirebaseFirestore.instance
                                            .collection('users')
                                            .where('position',
                                                isEqualTo:
                                                    'محكم $selectedReviewerType')
                                            .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return _buildErrorState(
                                            'خطأ في تحميل المحكمين',
                                            snapshot.error.toString());
                                      }

                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return _buildLoadingState(
                                            'جاري تحميل المحكمين...');
                                      }

                                      final reviewers =
                                          snapshot.data?.docs ?? [];

                                      if (reviewers.isEmpty) {
                                        return _buildEmptyState(
                                            selectedReviewerType ==
                                                    'جميع الأنواع'
                                                ? 'لا يوجد محكمين في النظام'
                                                : 'لا يوجد محكمين من نوع: محكم $selectedReviewerType');
                                      }

                                      return ListView.builder(
                                        padding: EdgeInsets.all(12),
                                        itemCount: reviewers.length,
                                        itemBuilder: (context, index) {
                                          final reviewer = reviewers[index];
                                          final data = reviewer.data()
                                              as Map<String, dynamic>;
                                          final reviewerName =
                                              data['fullName'] ?? 'غير معروف';
                                          final reviewerEmail =
                                              data['email'] ?? '';
                                          final reviewerPosition =
                                              data['position'] ?? '';
                                          final reviewerId = reviewer.id;
                                          final workloadCount =
                                              reviewerWorkload[reviewerId] ?? 0;
                                          final isSelected = selectedReviewers
                                              .contains(reviewerId);

                                          String reviewerType = '';
                                          IconData reviewerIcon = Icons.person;
                                          Color typeColor = Colors.grey;

                                          if (reviewerPosition
                                              .contains('سياسي')) {
                                            reviewerType = 'سياسي';
                                            reviewerIcon =
                                                Icons.account_balance;
                                            typeColor = Colors.blue;
                                          } else if (reviewerPosition
                                              .contains('اقتصادي')) {
                                            reviewerType = 'اقتصادي';
                                            reviewerIcon = Icons.trending_up;
                                            typeColor = Colors.green;
                                          } else if (reviewerPosition
                                              .contains('اجتماعي')) {
                                            reviewerType = 'اجتماعي';
                                            reviewerIcon = Icons.people;
                                            typeColor = Colors.purple;
                                          }

                                          return Container(
                                            margin: EdgeInsets.only(bottom: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isSelected
                                                    ? primaryColor
                                                    : Colors.grey.shade200,
                                                width: isSelected ? 2 : 1,
                                              ),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: primaryColor
                                                            .withOpacity(0.2),
                                                        spreadRadius: 0,
                                                        blurRadius: 10,
                                                        offset: Offset(0, 4),
                                                      ),
                                                    ]
                                                  : [
                                                      BoxShadow(
                                                        color: Colors.grey
                                                            .withOpacity(0.1),
                                                        spreadRadius: 0,
                                                        blurRadius: 5,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    if (isSelected) {
                                                      selectedReviewers
                                                          .remove(reviewerId);
                                                    } else {
                                                      selectedReviewers
                                                          .add(reviewerId);
                                                    }
                                                  });
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Padding(
                                                  padding: EdgeInsets.all(16),
                                                  child: Row(
                                                    children: [
                                                      // Workload Indicator
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 12,
                                                                vertical: 8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: workloadCount >
                                                                  3
                                                              ? Colors.red
                                                                  .withOpacity(
                                                                      0.1)
                                                              : workloadCount >
                                                                      1
                                                                  ? Colors
                                                                      .orange
                                                                      .withOpacity(
                                                                          0.1)
                                                                  : Colors.green
                                                                      .withOpacity(
                                                                          0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          border: Border.all(
                                                            color: workloadCount >
                                                                    3
                                                                ? Colors.red
                                                                : workloadCount >
                                                                        1
                                                                    ? Colors
                                                                        .orange
                                                                    : Colors
                                                                        .green,
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            Text(
                                                              '$workloadCount',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 18,
                                                                color: workloadCount >
                                                                        3
                                                                    ? Colors.red
                                                                    : workloadCount >
                                                                            1
                                                                        ? Colors
                                                                            .orange
                                                                        : Colors
                                                                            .green,
                                                              ),
                                                            ),
                                                            Text(
                                                              'ملف',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color: workloadCount >
                                                                        3
                                                                    ? Colors.red
                                                                    : workloadCount >
                                                                            1
                                                                        ? Colors
                                                                            .orange
                                                                        : Colors
                                                                            .green,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(width: 16),

                                                      // Reviewer Info
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              reviewerName,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                                color: Color(
                                                                    0xff2d3748),
                                                              ),
                                                            ),
                                                            SizedBox(height: 6),
                                                            if (reviewerEmail
                                                                .isNotEmpty)
                                                              Text(
                                                                reviewerEmail,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade600,
                                                                ),
                                                              ),
                                                            SizedBox(height: 8),
                                                            Container(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: typeColor
                                                                    .withOpacity(
                                                                        0.1),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                              child: Text(
                                                                'محكم $reviewerType',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      typeColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(width: 16),

                                                      // Type Icon
                                                      Container(
                                                        padding:
                                                            EdgeInsets.all(12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: typeColor
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Icon(
                                                            reviewerIcon,
                                                            color: typeColor,
                                                            size: 20),
                                                      ),
                                                      SizedBox(width: 16),

                                                      // Checkbox
                                                      Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isSelected
                                                              ? primaryColor
                                                              : Colors
                                                                  .transparent,
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? primaryColor
                                                                : Colors.grey
                                                                    .shade400,
                                                            width: 2,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: isSelected
                                                            ? Icon(Icons.check,
                                                                color: Colors
                                                                    .white,
                                                                size: 16)
                                                            : null,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: selectedReviewers.isEmpty
                                            ? null
                                            : LinearGradient(
                                                colors: [
                                                  primaryColor,
                                                  secondaryColor
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: selectedReviewers.isEmpty
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: primaryColor
                                                      .withOpacity(0.3),
                                                  spreadRadius: 0,
                                                  blurRadius: 10,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: selectedReviewers.isEmpty
                                            ? null
                                            : () async {
                                                Navigator.pop(context);
                                                String assignmentType =
                                                    selectedReviewerType ==
                                                            'جميع الأنواع'
                                                        ? 'مختلط'
                                                        : selectedReviewerType;
                                                await _assignReviewersToDocument(
                                                    selectedReviewers,
                                                    assignmentType);
                                              },
                                        icon: Icon(
                                          Icons.assignment_ind,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        label: Text(
                                          'تعيين المحكمين (${selectedReviewers.length})',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              selectedReviewers.isEmpty
                                                  ? Colors.grey.shade400
                                                  : Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(
                                            color: Colors.grey.shade400),
                                      ),
                                      child: Text(
                                        'إلغاء',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
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

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.error_outline, color: Colors.red, size: 48),
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 12, color: Colors.red.shade400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.people_outline,
                color: Colors.grey.shade400, size: 48),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Continue with rest of the methods... (due to length, I'll continue in the next part)

  Future<void> _assignReviewersToDocument(
      List<String> reviewerIds, String reviewerType) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserProvider =
          Provider.of<CurrentUserProvider>(context, listen: false);
      final currentUser = currentUserProvider.currentUser;

      if (reviewerIds.isEmpty) {
        throw Exception('لم يتم اختيار أي محكمين');
      }

      List<Map<String, dynamic>> reviewers = [];
      for (String reviewerId in reviewerIds) {
        try {
          DocumentSnapshot reviewerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(reviewerId)
              .get();

          if (reviewerDoc.exists) {
            final reviewerData = reviewerDoc.data() as Map<String, dynamic>;
            reviewers.add({
              'userId': reviewerId,
              'name': reviewerData['fullName'] ?? 'غير معروف',
              'email': reviewerData['email'] ?? '',
              'position': reviewerData['position'] ?? '',
              'review_status': 'Pending',
              'assigned_date': Timestamp.now(),
            });
          }
        } catch (e) {
          print('Error fetching reviewer $reviewerId: $e');
        }
      }

      if (reviewers.isEmpty) {
        throw Exception('لم يتم العثور على بيانات المحكمين');
      }

      await FirebaseFirestore.instance
          .collection('sent_documents')
          .doc(widget.document.id)
          .update({
        'status': 'الي المحكمين',
        'reviewers': reviewers,
        'reviewer_type': reviewerType,
        'assigned_by': currentUser?.name ?? 'غير معروف',
        'assigned_by_id': currentUser?.id ?? '',
        'assigned_date': FieldValue.serverTimestamp(),
      });

      Map<String, dynamic> actionLogEntry = {
        'action': 'الي المحكمين',
        'userName': currentUser?.name ?? 'غير معروف',
        'performedById': currentUser?.id ?? '',
        'userPosition': currentUser?.position ?? 'غير معروف',
        'reviewers': reviewers,
        'reviewerType': reviewerType,
        'timestamp': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('sent_documents')
          .doc(widget.document.id)
          .update({
        'actionLog': FieldValue.arrayUnion([actionLogEntry]),
      });

      setState(() {
        _isLoading = false;
      });

      _showSuccessSnackBar('تم تعيين ${reviewers.length} محكم بنجاح');

      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DocumentDetailsPage(document: widget.document),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar('خطأ في تعيين المحكمين: ${e.toString()}');
    }
  }

  Future<void> _updateDocumentStatus(String newStatus, String? comment) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserProvider =
          Provider.of<CurrentUserProvider>(context, listen: false);
      final currentUser = currentUserProvider.currentUser;

      final docRef = FirebaseFirestore.instance
          .collection('sent_documents')
          .doc(widget.document.id);

      final actionLog = {
        'timestamp': Timestamp.now(),
        'action': newStatus,
        'userName': currentUser?.name,
        'userPosition': currentUser?.position,
        'userId': currentUser?.id ?? currentUser?.email,
        'comment': comment,
      };

      if (newStatus == 'موافقة المحكم') {
        final data = widget.document.data() as Map<String, dynamic>;
        List<dynamic> reviewers = List.from(data['reviewers'] ?? []);

        bool reviewerFound = false;
        for (int i = 0; i < reviewers.length; i++) {
          if (reviewers[i] is String) {
            if (reviewers[i] == currentUser?.name ||
                reviewers[i] == currentUserId) {
              reviewers[i] = {
                'userId': currentUserId ?? '',
                'name': currentUser?.name ?? reviewers[i],
                'email': currentUser?.email ?? '',
                'review_status': 'Approved',
                'comment': comment,
                'approved_date': Timestamp.now(),
              };
              reviewerFound = true;
              break;
            }
          } else if (reviewers[i] is Map<String, dynamic>) {
            final reviewerUserId =
                reviewers[i]['userId'] ?? reviewers[i]['id'] ?? '';
            final reviewerEmail = reviewers[i]['email'] ?? '';
            final reviewerName = reviewers[i]['name'] ?? '';

            bool isCurrentUser = false;
            if (reviewerUserId.isNotEmpty && reviewerUserId == currentUserId) {
              isCurrentUser = true;
            } else if (reviewerEmail.isNotEmpty &&
                reviewerEmail == currentUserId) {
              isCurrentUser = true;
            } else if (reviewerName.isNotEmpty &&
                reviewerName == currentUser?.name) {
              isCurrentUser = true;
            }

            if (isCurrentUser) {
              reviewers[i]['review_status'] = 'Approved';
              reviewers[i]['comment'] = comment;
              reviewers[i]['approved_date'] = Timestamp.now();
              if (reviewerUserId.isEmpty) {
                reviewers[i]['userId'] = currentUserId ?? '';
              }
              reviewerFound = true;
              break;
            }
          }
        }

        if (!reviewerFound) {
          throw Exception(
              'لم يتم العثور على المحكم في قائمة المحكمين المعينين');
        }

        bool allApproved = true;
        for (var reviewer in reviewers) {
          String status = '';
          if (reviewer is String) {
            status = 'Pending';
            allApproved = false;
            break;
          } else if (reviewer is Map<String, dynamic>) {
            status = reviewer['review_status'] ?? 'Pending';
            if (status != 'Approved') {
              allApproved = false;
              break;
            }
          }
        }

        if (allApproved) {
          await docRef.update({
            'status': 'تم التحكيم',
            'reviewers': reviewers,
            'all_approved_date': FieldValue.serverTimestamp(),
            'actionLog': FieldValue.arrayUnion([actionLog]),
          });
        } else {
          await docRef.update({
            'reviewers': reviewers,
            'actionLog': FieldValue.arrayUnion([actionLog]),
          });
        }
      } else {
        await docRef.update({
          'status': newStatus,
          'actionLog': FieldValue.arrayUnion([actionLog]),
        });
      }

      setState(() {
        _isLoading = false;
      });

      _showSuccessSnackBar('تم تحديث حالة المستند بنجاح');

      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DocumentDetailsPage(document: widget.document),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحديث حالة المستند: $e');
    }
  }

  Future<void> _showReviewerApprovalDialog() async {
    final TextEditingController commentController = TextEditingController();

    return showDialog<void>(
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
                        colors: [Colors.green.shade400, Colors.green.shade600],
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
                          child: Icon(Icons.rate_review,
                              color: Colors.white, size: 28),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تقييم المستند',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'أدخل تعليقك وتقييمك للمستند',
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
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'التعليق (مطلوب)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2d3748),
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'اكتب تعليقك وتقييمك هنا...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                            maxLines: 4,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade400,
                                      Colors.green.shade600
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      spreadRadius: 0,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    if (commentController.text.trim().isEmpty) {
                                      _showErrorSnackBar('الرجاء إدخال تعليق');
                                      return;
                                    }
                                    Navigator.of(context).pop();

                                    await _updateDocumentStatus('موافقة المحكم',
                                        commentController.text);

                                    setState(() {
                                      hasCurrentUserApproved = true;
                                      final currentUserProvider =
                                          Provider.of<CurrentUserProvider>(
                                              context,
                                              listen: false);
                                      final currentUser =
                                          currentUserProvider.currentUser;
                                      if (currentUser != null &&
                                          currentUserId != null) {
                                        reviewerStatuses[currentUserId!] =
                                            'Approved';
                                      }
                                    });
                                  },
                                  icon: Icon(Icons.check, color: Colors.white),
                                  label: Text(
                                    'موافقة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade400),
                                ),
                                child: Text(
                                  'إلغاء',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
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
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAcceptRejectDialog() async {
    final TextEditingController commentController = TextEditingController();

    return showDialog<void>(
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
                        colors: [primaryColor, secondaryColor],
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
                          child:
                              Icon(Icons.gavel, color: Colors.white, size: 28),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'اختر الإجراء',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'هل تريد قبول أو رفض هذا المستند؟',
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
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تعليق (اختياري)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2d3748),
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'اكتب تعليقك هنا...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                            maxLines: 3,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade400,
                                      Colors.green.shade600
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      spreadRadius: 0,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _updateDocumentStatus(
                                        'قبول الملف', commentController.text);
                                  },
                                  icon: Icon(Icons.check_circle,
                                      color: Colors.white),
                                  label: Text(
                                    'قبول',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.shade400,
                                      Colors.red.shade600
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      spreadRadius: 0,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _updateDocumentStatus(
                                        'تم الرفض', commentController.text);
                                  },
                                  icon: Icon(Icons.cancel, color: Colors.white),
                                  label: Text(
                                    'رفض',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
            ),
          ),
        );
      },
    );
  }

// Updated _showFinalApprovalDialog method in DocumentDetails.dart
// Replace the existing method with this updated version

  Future<void> _showFinalApprovalDialog() async {
    final TextEditingController commentController = TextEditingController();

    return showDialog<void>(
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
                        colors: [Colors.blue.shade600, Colors.purple.shade600],
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
                          child: Icon(Icons.verified,
                              color: Colors.white, size: 28),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'موافقة مدير التحرير',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'اختر الإجراء المناسب بعد مراجعة تعليقات المحكمين',
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
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تعليق (اختياري)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2d3748),
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'أضف تعليقك على القرار...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                            maxLines: 3,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Buttons Grid
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade500,
                                          Colors.green.shade700
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          spreadRadius: 0,
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        // Updated: Send to Head of Editors instead of final approval
                                        _updateDocumentStatus(
                                            'موافقة مدير التحرير',
                                            commentController.text);
                                      },
                                      icon:
                                          Icon(Icons.send, color: Colors.white),
                                      label: Text(
                                        'إرسال لرئيس التحرير',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange.shade400,
                                          Colors.orange.shade600
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.3),
                                          spreadRadius: 0,
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _updateDocumentStatus('مرسل للتعديل',
                                            commentController.text);
                                      },
                                      icon:
                                          Icon(Icons.edit, color: Colors.white),
                                      label: Text(
                                        'إرسال للتعديل',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.red.shade400,
                                          Colors.red.shade600
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          spreadRadius: 0,
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _updateDocumentStatus(
                                            'تم الرفض النهائي',
                                            commentController.text);
                                      },
                                      icon: Icon(Icons.block,
                                          color: Colors.white),
                                      label: Text(
                                        'رفض نهائي',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: BorderSide(
                                          color: Colors.grey.shade400),
                                    ),
                                    child: Text(
                                      'إلغاء',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

  Future<void> _showHeadOfEditorsApprovalDialog() async {
    final TextEditingController commentController = TextEditingController();

    return showDialog<void>(
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
                          Colors.purple.shade600,
                          Colors.indigo.shade600
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
                          child: Icon(Icons.verified_user,
                              color: Colors.white, size: 28),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'موافقة رئيس التحرير',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'الموافقة النهائية على المستند',
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
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تعليق (اختياري)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2d3748),
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'أضف تعليقك على القرار النهائي...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                            maxLines: 3,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Buttons Grid
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade500,
                                          Colors.green.shade700
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          spreadRadius: 0,
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _updateDocumentStatus(
                                            'موافقة رئيس التحرير',
                                            commentController.text);
                                      },
                                      icon: Icon(Icons.check_circle,
                                          color: Colors.white),
                                      label: Text(
                                        'موافقة نهائية',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange.shade400,
                                          Colors.orange.shade600
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.3),
                                          spreadRadius: 0,
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _updateDocumentStatus(
                                            'مرسل للتعديل من رئيس التحرير',
                                            commentController.text);
                                      },
                                      icon:
                                          Icon(Icons.edit, color: Colors.white),
                                      label: Text(
                                        'إرسال للتعديل',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.red.shade400,
                                          Colors.red.shade600
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          spreadRadius: 0,
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _updateDocumentStatus(
                                            'رفض رئيس التحرير',
                                            commentController.text);
                                      },
                                      icon: Icon(Icons.block,
                                          color: Colors.white),
                                      label: Text(
                                        'رفض نهائي',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: BorderSide(
                                          color: Colors.grey.shade400),
                                    ),
                                    child: Text(
                                      'إلغاء',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

// Updated _buildActionButtons method for DocumentDetails.dart
// Replace the existing _buildActionButtons method with this updated version
  Widget _buildActionButtons(String status) {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context);
    final currentUser = currentUserProvider.currentUser;
    final canAssignReviewers = _canAssignReviewers(currentUser?.position);
    final canFinalApprove = _canFinalApprove(currentUser?.position);
    final isHeadOfEditors = currentUser?.position == 'رئيس التحرير';
    final isEditorChief = currentUser?.position == 'مدير التحرير';

    if (status == 'ملف مرسل') {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _showAcceptRejectDialog,
          icon: Icon(Icons.assignment_turned_in, color: Colors.white, size: 24),
          label: Text(
            'قبول / رفض الملف',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
    } else if (status == 'قبول الملف' && canAssignReviewers) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade500, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _showReviewerAssignmentDialog,
          icon: Icon(Icons.person_add, color: Colors.white, size: 24),
          label: Text(
            'تعيين المحكمين',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
    } else if (status == 'الي المحكمين' &&
        isCurrentUserReviewer &&
        !hasCurrentUserApproved) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade500, Colors.green.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _showReviewerApprovalDialog,
          icon: Icon(Icons.thumb_up, color: Colors.white, size: 24),
          label: Text(
            'الموافقة والتعليق',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
    } else if (status == 'الي المحكمين' &&
        isCurrentUserReviewer &&
        hasCurrentUserApproved) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 20),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade300, width: 2),
        ),
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
    } else if (status == 'تم التحكيم' && isEditorChief && !isHeadOfEditors) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade500, Colors.purple.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _showFinalApprovalDialog,
          icon: Icon(Icons.send, color: Colors.white, size: 24),
          label: Text(
            'موافقة مدير التحرير',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
    } else if (status == 'موافقة مدير التحرير' && isHeadOfEditors) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade500, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _showHeadOfEditorsApprovalDialog,
          icon: Icon(Icons.verified_user, color: Colors.white, size: 24),
          label: Text(
            'الموافقة النهائية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
    } else if (status == 'موافقة مدير التحرير' && !isHeadOfEditors) {
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
                'بانتظار الموافقة النهائية من رئيس التحرير',
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
    } else if (status == 'موافقة رئيس التحرير') {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 20),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade300, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.verified, color: Colors.green, size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'تمت الموافقة النهائية - جاهز للنشر',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'تم التحكيم' && !canFinalApprove) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 20),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade300, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.hourglass_top, color: Colors.blue, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'بانتظار موافقة مدير التحرير',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'مرسل للتعديل من رئيس التحرير' ||
        status == 'مرسل للتعديل') {
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit, color: Colors.orange, size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'تم إرسال المستند للتعديل',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'رفض رئيس التحرير' || status == 'تم الرفض النهائي') {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 20),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade50, Colors.red.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade300, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.cancel, color: Colors.red, size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'تم رفض المستند نهائياً',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildReviewersStatusWidget() {
    final data = widget.document.data() as Map<String, dynamic>;
    final reviewers = data['reviewers'] as List<dynamic>? ?? [];

    if (reviewers.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(24),
      margin: EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
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
                    colors: [
                      primaryColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.2)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.people_alt, color: primaryColor, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حالة المحكمين',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'تتبع تقدم المراجعة',
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
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${reviewers.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: reviewers.length,
            itemBuilder: (context, index) {
              final reviewer = reviewers[index];

              String reviewerName = 'غير معروف';
              String reviewerEmail = '';
              String reviewStatus = 'Pending';
              String reviewerId = '';
              String comment = '';
              String position = '';

              if (reviewer is String) {
                reviewerName = reviewer;
                reviewStatus = 'Pending';
              } else if (reviewer is Map<String, dynamic>) {
                reviewerId = reviewer['userId'] ?? reviewer['id'] ?? '';
                reviewerName =
                    reviewer['name'] ?? reviewer['fullName'] ?? 'غير معروف';
                reviewerEmail = reviewer['email'] ?? '';
                reviewStatus = reviewer['review_status'] ?? 'Pending';
                comment = reviewer['comment'] ?? '';
                position = reviewer['position'] ?? '';
              }

              final Color statusColor =
                  reviewStatus == 'Approved' ? Colors.green : Colors.orange;
              final IconData statusIcon = reviewStatus == 'Approved'
                  ? Icons.check_circle
                  : Icons.schedule;
              final String statusText = reviewStatus == 'Approved'
                  ? 'تمت الموافقة'
                  : 'في انتظار المراجعة';

              // Get reviewer type for styling
              String reviewerType = '';
              Color typeColor = Colors.grey;
              IconData typeIcon = Icons.person;

              if (position.contains('سياسي')) {
                reviewerType = 'سياسي';
                typeColor = Colors.blue;
                typeIcon = Icons.account_balance;
              } else if (position.contains('اقتصادي')) {
                reviewerType = 'اقتصادي';
                typeColor = Colors.green;
                typeIcon = Icons.trending_up;
              } else if (position.contains('اجتماعي')) {
                reviewerType = 'اجتماعي';
                typeColor = Colors.purple;
                typeIcon = Icons.people;
              }

              return Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      statusColor.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: statusColor.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                Icon(statusIcon, color: statusColor, size: 24),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reviewerName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xff2d3748),
                                  ),
                                ),
                                SizedBox(height: 4),
                                if (reviewerEmail.isNotEmpty)
                                  Text(
                                    reviewerEmail,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (position.isNotEmpty) ...[
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: typeColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(typeIcon,
                                                size: 12, color: typeColor),
                                            SizedBox(width: 4),
                                            Text(
                                              'محكم $reviewerType',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: typeColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                    ],
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
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
                      if (comment.isNotEmpty && reviewStatus == 'Approved') ...[
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade50,
                                Colors.green.shade100
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.comment,
                                      color: Colors.green.shade600, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'تعليق المحكم:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                comment,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green.shade800,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionHistory() {
    final Map<String, dynamic> data =
        widget.document.data() as Map<String, dynamic>;
    final List<dynamic> actionLog = data['actionLog'] ?? [];

    if (actionLog.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(24),
      margin: EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.history, color: Colors.blue.shade700, size: 24),
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
          ),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: actionLog.length,
            itemBuilder: (context, index) {
              final action = actionLog[actionLog.length - 1 - index];

              DateTime timestamp;
              if (action['timestamp'] is Timestamp) {
                timestamp = (action['timestamp'] as Timestamp).toDate();
              } else if (action['timestamp'] is DateTime) {
                timestamp = action['timestamp'];
              } else {
                timestamp = DateTime.now();
              }

              final String formattedDate =
                  DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp);

              Color actionColor = primaryColor;
              IconData actionIcon = Icons.info;

              if (action['action'] == 'تم الرفض' ||
                  action['action'] == 'تم الرفض النهائي') {
                actionColor = Colors.red;
                actionIcon = Icons.cancel;
              } else if (action['action'] == 'موافقة المحكم' ||
                  action['action'] == 'تمت الموافقة النهائية') {
                actionColor = Colors.green;
                actionIcon = Icons.check_circle;
              } else if (action['action'] == 'مرسل للتعديل') {
                actionColor = Colors.orange;
                actionIcon = Icons.edit;
              } else if (action['action'] == 'الي المحكمين') {
                actionColor = Colors.blue;
                actionIcon = Icons.people;
              } else if (action['action'] == 'قبول الملف') {
                actionColor = Colors.green;
                actionIcon = Icons.check;
              }

              String performedBy = action['performedBy']?.toString() ??
                  action['userName']?.toString() ??
                  'مجهول';
              String performedByPosition =
                  action['performedByPosition']?.toString() ??
                      action['userPosition']?.toString() ??
                      'منصب غير معروف';

              return Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      actionColor.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: actionColor.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: actionColor.withOpacity(0.1),
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
                              color: actionColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:
                                Icon(actionIcon, color: actionColor, size: 20),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${action['action']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: actionColor,
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
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person,
                                    size: 16, color: Colors.grey.shade600),
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
                                    '$performedBy ($performedByPosition)',
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
                            if (action['comment'] != null &&
                                action['comment'].toString().isNotEmpty) ...[
                              SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.comment,
                                      size: 16, color: Colors.grey.shade600),
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
                                      action['comment'],
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
                            if (action['reviewers'] != null &&
                                (action['reviewers'] as List).isNotEmpty) ...[
                              SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.people,
                                      size: 16, color: Colors.grey.shade600),
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
                                      children: List.generate(
                                        (action['reviewers'] as List).length,
                                        (i) {
                                          final reviewer =
                                              (action['reviewers'] as List)[i];
                                          String reviewerName = 'غير معروف';

                                          if (reviewer
                                              is Map<String, dynamic>) {
                                            reviewerName =
                                                reviewer['name'] ?? 'غير معروف';
                                          } else if (reviewer is String) {
                                            reviewerName = reviewer;
                                          }

                                          return Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  actionColor.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              reviewerName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: actionColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.document.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'غير معروف';
    final DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
    final String formattedDate =
        DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xfff8f9fa),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 1024;
              bool isTablet = constraints.maxWidth > 768;

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
                              // Modern Header
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 80 : 20,
                                  vertical: isDesktop ? 40 : 20,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      secondaryColor,
                                      primaryColor,
                                      Color(0xff8b5a2b),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.arrow_back,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ),
                                        SizedBox(width: 20),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'تفاصيل المستند',
                                                style: TextStyle(
                                                  fontSize: isDesktop ? 32 : 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'مراجعة وإدارة المستند',
                                                style: TextStyle(
                                                  fontSize: isDesktop ? 18 : 16,
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                    Container(
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time,
                                              color: Colors.white, size: 20),
                                          SizedBox(width: 12),
                                          Text(
                                            'تاريخ الإرسال: $formattedDate',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 80 : 20,
                                  vertical: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Status Progress Bar
                                    StatusProgressBar(status: status),
                                    SizedBox(height: 24),

                                    // Document Info Widget
                                    _buildDocumentInfoWidget(),

                                    // Sender Information Card
                                    Container(
                                      padding: EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 20,
                                            offset: Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.blue.shade100,
                                                      Colors.blue.shade200
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(Icons.person,
                                                    color: Colors.blue.shade700,
                                                    size: 24),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'بيانات المرسل',
                                                      style: TextStyle(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .blue.shade700,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      'معلومات الشخص الذي أرسل المستند',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 20),
                                          _buildSenderInfoGrid(data, isDesktop),
                                        ],
                                      ),
                                    ),

                                    // Action Buttons
                                    _buildActionButtons(status),

                                    // Reviewers Status Widget
                                    _buildReviewersStatusWidget(),

                                    // Action History
                                    _buildActionHistory(),

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
                  if (_isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.7),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
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
                              CircularProgressIndicator(
                                color: primaryColor,
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'جاري المعالجة...',
                                style: TextStyle(
                                  color: Color(0xff2d3748),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'الرجاء الانتظار',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSenderInfoGrid(Map<String, dynamic> data, bool isDesktop) {
    final List<Map<String, String>> infoItems = [
      {
        'label': 'الاسم الكامل',
        'value': data['fullName'] ?? 'غير متوفر',
        'icon': 'person'
      },
      {
        'label': 'البريد الإلكتروني',
        'value': data['email'] ?? 'غير متوفر',
        'icon': 'email'
      },
      {'label': 'حول', 'value': data['about'] ?? 'غير متوفر', 'icon': 'info'},
      {
        'label': 'التعليم',
        'value': data['education'] ?? 'غير متوفر',
        'icon': 'school'
      },
      {
        'label': 'الحالة',
        'value': data['status'] ?? 'غير متوفر',
        'icon': 'status'
      },
      {
        'label': 'المنصب',
        'value': data['position'] ?? 'غير متوفر',
        'icon': 'work'
      },
    ];

    if (isDesktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 4,
        ),
        itemCount: infoItems.length,
        itemBuilder: (context, index) {
          return _buildInfoCard(infoItems[index]);
        },
      );
    } else {
      return Column(
        children: infoItems
            .map((item) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _buildInfoCard(item),
                ))
            .toList(),
      );
    }
  }

  Widget _buildInfoCard(Map<String, String> item) {
    IconData icon = Icons.info;
    Color iconColor = Colors.grey.shade600;

    switch (item['icon']) {
      case 'person':
        icon = Icons.person;
        iconColor = Colors.blue.shade600;
        break;
      case 'email':
        icon = Icons.email;
        iconColor = Colors.green.shade600;
        break;
      case 'info':
        icon = Icons.info;
        iconColor = Colors.orange.shade600;
        break;
      case 'school':
        icon = Icons.school;
        iconColor = Colors.purple.shade600;
        break;
      case 'status':
        icon = Icons.check_circle;
        iconColor = Colors.red.shade600;
        break;
      case 'work':
        icon = Icons.work;
        iconColor = Colors.indigo.shade600;
        break;
    }

    return Container(
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
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  item['value']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xff2d3748),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
