// pages/Stage1/Stage1HeadEditorDetailsPage.dart - Updated with comprehensive file handling
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
import 'package:qiraat/Widgets/documentInfoSection.dart';

import '../../Classes/current_user_providerr.dart';
import '../App_Constants.dart';
import '../Document_Services.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/Action_history.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/senderinfocard.dart';
import '../Widgets/Stage1TimeLine.dart';
import '../models/document_model.dart';

class Stage1HeadEditorDetailsPage extends StatefulWidget {
  final DocumentModel document;

  const Stage1HeadEditorDetailsPage({Key? key, required this.document})
      : super(key: key);

  @override
  _Stage1HeadEditorDetailsPageState createState() =>
      _Stage1HeadEditorDetailsPageState();
}

class _Stage1HeadEditorDetailsPageState
    extends State<Stage1HeadEditorDetailsPage> with TickerProviderStateMixin {
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

    // Initialize controllers
    _commentController = TextEditingController();
    _finalCommentController = TextEditingController();
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

// Update your dispose method:
  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    _finalCommentController.dispose(); // Add this line
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
            Colors.indigo.shade600,
            Colors.indigo.shade800,
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
                child: Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مراجعة رئيس التحرير',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'المرحلة الأولى - القرار النهائي',
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
          _buildHeadEditorStatusBar(),
        ],
      ),
    );
  }

  Widget _buildHeadEditorStatusBar() {
    final status = _document!.status;
    String statusText = '';
    Color statusColor = Colors.white;
    IconData statusIcon = Icons.info;

    switch (status) {
      case AppConstants.EDITOR_APPROVED:
        statusText = 'تم قبوله من مدير التحرير - جاهز للقرار النهائي';
        statusColor = Colors.green.shade100;
        statusIcon = Icons.check_circle;
        break;
      case AppConstants.EDITOR_REJECTED:
        statusText = 'تم رفضه من مدير التحرير - يمكن إعادة المراجعة';
        statusColor = Colors.red.shade100;
        statusIcon = Icons.cancel;
        break;
      case AppConstants.EDITOR_WEBSITE_RECOMMENDED:
        statusText = 'موصى للموقع من مدير التحرير - للمراجعة النهائية';
        statusColor = Colors.blue.shade100;
        statusIcon = Icons.web;
        break;
      case AppConstants.EDITOR_EDIT_REQUESTED:
        statusText = 'طلب تعديل من مدير التحرير - للمراجعة النهائية';
        statusColor = Colors.orange.shade100;
        statusIcon = Icons.edit;
        break;
      case AppConstants.HEAD_REVIEW:
        statusText = 'قيد المراجعة من رئيس التحرير';
        statusColor = Colors.indigo.shade100;
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
          Icon(statusIcon, color: Colors.indigo.shade800, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة المراجعة',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.indigo.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(_document!.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.indigo.shade600,
            ),
          ),
        ],
      ),
    );
  }

// Add this import at the top of your Stage1HeadEditorDetailsPage.dart file:

// Replace your existing _buildContent method with this:
  Widget _buildContent(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 20,
        vertical: 20,
      ),
      child: Column(
        children: [
          // Stage 1 Decision Timeline - Now using the separate widget
          Stage1DecisionTimeline(
            document: _document!,
            onViewAttachedFile: _handleViewAttachedFile,
            formatDate: _formatDate,
          ),

          // Document Info Card with View File
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

          // Head Editor Action Panel
          _buildHeadEditorActionPanel(),

          // Previous Actions
          if (_document!.actionLog.isNotEmpty)
            ActionHistoryWidget(actionLog: _document!.actionLog),

          SizedBox(height: 40),
        ],
      ),
    );
  }

// Add this new method to handle viewing attached files from the timeline:
  Future<void> _handleViewAttachedFile(String fileUrl) async {
    if (fileUrl.isEmpty) {
      _showErrorSnackBar('رابط الملف غير متوفر');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        await _openInNewTab(fileUrl);
      } else {
        await _handleMobileAttachedFileView(fileUrl);
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في فتح الملف: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

// Add this helper method for mobile attached file viewing:
  Future<void> _handleMobileAttachedFileView(String fileUrl) async {
    try {
      // For mobile, we'll download and open the attached file
      final String fileName = _getFileNameFromUrl(fileUrl);
      final String fileExtension = _getFileExtensionFromUrl(fileUrl);

      if (!supportedFileTypes.containsKey(fileExtension)) {
        throw Exception('نوع الملف غير مدعوم');
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
          _showWarningSnackBar('لا يوجد تطبيق مناسب لفتح هذا النوع من الملفات');
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
      throw Exception('خطأ في فتح الملف: ${e.toString()}');
    }
  }

// Add these helper methods to extract filename from URL:
  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
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

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'attached_file_$timestamp.pdf';
  }

  String _getFileExtensionFromUrl(String url) {
    try {
      String urlPath = Uri.parse(url).path;
      String extension = path.extension(urlPath).toLowerCase();
      if (extension.isNotEmpty && supportedFileTypes.containsKey(extension)) {
        return extension;
      }
      return '.pdf';
    } catch (e) {
      return '.pdf';
    }
  }

  Widget _buildHeadEditorActionPanel() {
    final canTakeAction =
        _currentUserPosition == AppConstants.POSITION_HEAD_EDITOR &&
            [
              AppConstants.EDITOR_APPROVED,
              AppConstants.EDITOR_REJECTED,
              AppConstants.EDITOR_WEBSITE_RECOMMENDED,
              AppConstants.EDITOR_EDIT_REQUESTED,
              AppConstants.HEAD_REVIEW
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
                colors: [Colors.indigo.shade500, Colors.indigo.shade700],
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
                  child: Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إجراءات رئيس التحرير',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'القرار النهائي للمرحلة الأولى',
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
                ? _buildHeadEditorActions()
                : _buildFinalStatusMessage(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadEditorActions() {
    if ([
      AppConstants.EDITOR_APPROVED,
      AppConstants.EDITOR_REJECTED,
      AppConstants.EDITOR_WEBSITE_RECOMMENDED,
      AppConstants.EDITOR_EDIT_REQUESTED
    ].contains(_document!.status)) {
      return _buildStartHeadReviewAction();
    } else {
      return _buildFinalDecisionActions();
    }
  }

  Widget _buildStartHeadReviewAction() {
    String actionText = _document!.status == AppConstants.EDITOR_REJECTED
        ? 'مراجعة المقال المرفوض'
        : 'بدء المراجعة النهائية';
    String descriptionText = _document!.status == AppConstants.EDITOR_REJECTED
        ? 'يمكنك مراجعة هذا المقال رغم رفض مدير التحرير واتخاذ قرار مستقل'
        : 'انقر للبدء في المراجعة النهائية واتخاذ القرار';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _document!.status == AppConstants.EDITOR_REJECTED
                  ? [Colors.orange.shade50, Colors.orange.shade100]
                  : [Colors.blue.shade50, Colors.blue.shade100],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _document!.status == AppConstants.EDITOR_REJECTED
                  ? Colors.orange.shade200
                  : Colors.blue.shade200,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.play_arrow,
                  color: _document!.status == AppConstants.EDITOR_REJECTED
                      ? Colors.orange.shade600
                      : Colors.blue.shade600,
                  size: 48),
              SizedBox(height: 16),
              Text(
                actionText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _document!.status == AppConstants.EDITOR_REJECTED
                      ? Colors.orange.shade700
                      : Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                descriptionText,
                style: TextStyle(
                  fontSize: 14,
                  color: _document!.status == AppConstants.EDITOR_REJECTED
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
            onPressed: () => _startHeadReview(),
            icon: Icon(Icons.play_arrow, size: 24),
            label: Text(
              'بدء المراجعة النهائية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _document!.status == AppConstants.EDITOR_REJECTED
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

// Replace the _buildFinalDecisionActions method with this inline version:

  Widget _buildFinalDecisionActions() {
    return Column(
      children: [
        // Decision Guidelines
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade50, Colors.indigo.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.indigo.shade600, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'معايير القرار النهائي',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildGuidelineItem('مراجعة قرارات السكرتير ومدير التحرير'),
              _buildGuidelineItem('تقييم الجودة العلمية الشاملة'),
              _buildGuidelineItem('تحديد الملاءمة للمجلة أو الموقع'),
              _buildGuidelineItem('اتخاذ القرار النهائي للمرحلة الأولى'),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Inline Final Decision Form
        _buildInlineFinalDecisionForm(),
      ],
    );
  }

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

  // ADD THIS MISSING METHOD:
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

// Add these new variables to your class state (if not already added for the editor actions):
// Add to _Stage1EditorDetailsPageState class
  late TextEditingController _finalCommentController;
  late TextEditingController _commentController; // Missing - add this

  String? _finalAttachedFileName;
  String? _finalAttachedFileUrl;
  bool _isFinalUploading = false;
  String? _selectedFinalAction;

// Add this new method:
  Widget _buildInlineFinalDecisionForm() {
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
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.gavel, color: Colors.indigo.shade600, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'القرار النهائي',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Comment Field
          Text(
            'مبررات القرار النهائي (مطلوب):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _finalCommentController,
            decoration: InputDecoration(
              hintText: 'اكتب مبررات وتفاصيل القرار النهائي هنا...',
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
                borderSide: BorderSide(color: Colors.indigo.shade400, width: 2),
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
            'إرفاق تقرير القرار (اختياري):',
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
              onTap: _isFinalUploading ? null : _pickFinalFile,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isFinalUploading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.attach_file,
                              color: Colors.indigo.shade600, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _finalAttachedFileName ?? 'اختر ملف للإرفاق',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _finalAttachedFileName != null
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                            ),
                          ),
                          if (_finalAttachedFileName == null)
                            Text(
                              'يمكنك إرفاق تقرير يوضح تفاصيل ومبررات القرار (PDF, DOC, DOCX)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_finalAttachedFileName != null && !_isFinalUploading)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _finalAttachedFileName = null;
                            _finalAttachedFileUrl = null;
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
            'اختر القرار النهائي:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 12),

          // Final Decision Buttons
          Column(
            children: [
              // Final Approve Button (Full Width)
              SizedBox(
                width: double.infinity,
                child: _buildInlineFinalActionButton(
                  action: 'final_approve',
                  title: 'الموافقة النهائية للمرحلة الثانية',
                  subtitle: 'المقال مؤهل للانتقال للتحكيم العلمي',
                  icon: Icons.verified,
                  color: Colors.green,
                  isFullWidth: true,
                ),
              ),
              SizedBox(height: 12),
              // Reject and Website Approve (Side by Side)
              Row(
                children: [
                  Expanded(
                    child: _buildInlineFinalActionButton(
                      action: 'final_reject',
                      title: 'الرفض النهائي',
                      subtitle: 'رفض المقال نهائياً',
                      icon: Icons.block,
                      color: Colors.red,
                      isFullWidth: false,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildInlineFinalActionButton(
                      action: 'website_approve',
                      title: 'موافقة نشر الموقع',
                      subtitle: 'نشر على الموقع فقط',
                      icon: Icons.public,
                      color: Colors.blue,
                      isFullWidth: false,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 20),

          // Submit Button
          if (_selectedFinalAction != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canSubmitFinalAction() ? _submitFinalAction : null,
                icon: Icon(Icons.send, size: 20),
                label: Text(
                  'تنفيذ القرار النهائي',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getFinalActionColor(_selectedFinalAction!),
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

// Helper method for final action buttons:
  Widget _buildInlineFinalActionButton({
    required String action,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isFullWidth,
  }) {
    bool isSelected = _selectedFinalAction == action;

    return Container(
      height: isFullWidth ? 110 : 100,
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
            _selectedFinalAction = action;
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
                size: isFullWidth ? 32 : 28,
                color: isSelected ? color : Colors.grey.shade600,
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: isFullWidth ? 14 : 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isFullWidth ? 12 : 10,
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

// Helper methods for final actions:
  bool _canSubmitFinalAction() {
    return _finalCommentController.text.trim().isNotEmpty &&
        _selectedFinalAction != null &&
        !_isFinalUploading;
  }

  Color _getFinalActionColor(String action) {
    switch (action) {
      case 'final_approve':
        return Colors.green;
      case 'final_reject':
        return Colors.red;
      case 'website_approve':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _submitFinalAction() {
    if (_canSubmitFinalAction()) {
      _processFinalAction(
        _selectedFinalAction!,
        _finalCommentController.text.trim(),
        _finalAttachedFileUrl,
        _finalAttachedFileName,
      );
    }
  }

// File picker method for final actions:
  Future<void> _pickFinalFile() async {
    setState(() => _isFinalUploading = true);

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
            _finalAttachedFileName = fileName;
            _finalAttachedFileUrl = uploadResult;
          });
          _showSuccessSnackBar('تم رفع الملف بنجاح: $fileName');
        } else {
          throw Exception('فشل في رفع الملف');
        }
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في رفع الملف: $e');
    } finally {
      setState(() => _isFinalUploading = false);
    }
  }

// Remove or comment out these methods since they're no longer needed:
// - _showFinalActionDialog
// - Any dialog-related methods for final actions
  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.indigo.shade400,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.indigo.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalActionButton({
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
          padding: EdgeInsets.all(16),
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
              textAlign: TextAlign.center,
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

  Widget _buildFinalStatusMessage() {
    if (!AppStyles.isStage1FinalStatus(_document!.status)) {
      return _buildWaitingMessage();
    }

    final status = _document!.status;
    String message = '';
    String description = '';
    IconData icon = Icons.info;
    Color color = Colors.grey;

    switch (status) {
      case AppConstants.STAGE1_APPROVED:
        message = 'تمت الموافقة النهائية';
        description =
            'تم قبول المقال للانتقال للمرحلة الثانية (التحكيم العلمي)';
        icon = Icons.verified;
        color = Colors.green;
        break;
      case AppConstants.FINAL_REJECTED:
        message = 'تم الرفض النهائي';
        description = 'تم رفض المقال نهائياً من رئيس التحرير';
        icon = Icons.block;
        color = Colors.red;
        break;
      case AppConstants.WEBSITE_APPROVED:
        message = 'موافقة نشر الموقع';
        description = 'تمت الموافقة على نشر المقال على الموقع الإلكتروني فقط';
        icon = Icons.public;
        color = Colors.blue;
        break;
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
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 20,
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
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: color, size: 16),
                SizedBox(width: 8),
                Text(
                  'المرحلة الأولى مكتملة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingMessage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.hourglass_top, color: Colors.blue, size: 32),
          ),
          SizedBox(height: 16),
          Text(
            'في انتظار الإجراء',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'يجب أن يقوم رئيس التحرير بمراجعة المقال واتخاذ القرار النهائي',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.withOpacity(0.8),
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

  void _startHeadReview() async {
    setState(() => _isLoading = true);

    try {
      await _documentService.updateDocumentStatus(
        _document!.id,
        AppConstants.HEAD_REVIEW,
        _document!.status == AppConstants.EDITOR_REJECTED
            ? 'بدء المراجعة النهائية للمقال المرفوض من مدير التحرير'
            : 'بدء المراجعة النهائية من رئيس التحرير',
        _currentUserId!,
        _currentUserName!,
        _currentUserPosition!,
      );

      await _refreshDocument();
      _showSuccessSnackBar('تم بدء المراجعة النهائية بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في بدء المراجعة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processFinalAction(
      String action, String comment, String? fileUrl, String? fileName) async {
    setState(() => _isLoading = true);

    try {
      String nextStatus = '';
      switch (action) {
        case 'final_approve':
          nextStatus = AppConstants.STAGE1_APPROVED;
          break;
        case 'final_reject':
          nextStatus = AppConstants.FINAL_REJECTED;
          break;
        case 'website_approve':
          nextStatus = AppConstants.WEBSITE_APPROVED;
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
      _showSuccessSnackBar('تم اتخاذ القرار النهائي بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في اتخاذ القرار: $e');
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
