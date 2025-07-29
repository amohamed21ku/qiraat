// pages/document_details_page.dart - Updated for Stage 1 Approval Workflow
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
                                // Stage and Status Progress Bar
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

                                // Stage 1 Action Buttons
                                ActionButtonsWidget(
                                  status: _documentModel!.status,
                                  document: _documentModel!,
                                  onStatusUpdate: _handleStatusUpdate,
                                  onAdminStatusChange:
                                      _showAdminStatusChangeDialog,
                                ),

                                // Stage 1 Decision Summary (if decisions were made)
                                if (_hasStage1Decisions())
                                  _buildStage1DecisionSummary(),

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

  // Updated status update method for Stage 1 workflow
  Future<void> _handleStatusUpdate(String newStatus, String? comment,
      String? attachedFileUrl, String? attachedFileName) async {
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
        attachedFileUrl: attachedFileUrl,
        attachedFileName: attachedFileName,
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

  bool _hasStage1Decisions() {
    final status = _documentModel!.status;
    return [
      AppConstants.SECRETARY_APPROVED,
      AppConstants.SECRETARY_REJECTED,
      AppConstants.SECRETARY_EDIT_REQUESTED,
      AppConstants.EDITOR_APPROVED,
      AppConstants.EDITOR_REJECTED,
      AppConstants.EDITOR_WEBSITE_RECOMMENDED,
      AppConstants.EDITOR_EDIT_REQUESTED,
      AppConstants.STAGE1_APPROVED,
      AppConstants.FINAL_REJECTED,
      AppConstants.WEBSITE_APPROVED,
    ].contains(status);
  }

  Widget _buildStage1DecisionSummary() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(24),
      decoration: AppStyles.simpleCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade100, Colors.purple.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.account_tree,
                    color: Colors.purple.shade700, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملخص قرارات المرحلة الأولى',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'تسلسل القرارات المتخذة',
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
          _buildDecisionTimeline(),
        ],
      ),
    );
  }

  Widget _buildDecisionTimeline() {
    List<Map<String, dynamic>> decisions = [];
    final actionLog = _documentModel!.actionLog;

    // Extract key decisions from action log
    for (var action in actionLog) {
      String actionType = action.action ?? '';
      if (actionType.contains('موافقة') ||
          actionType.contains('رفض') ||
          actionType.contains('تعديل') ||
          actionType.contains('توصية')) {
        decisions.add({
          'title': actionType,
          'user': action.userName ?? '',
          'position': action.userPosition ?? '',
          'date': action.timestamp,
          'comment': action.comment ?? '',
          'hasAttachment': action.attachedFileUrl != null,
        });
      }
    }

    if (decisions.isEmpty) return SizedBox.shrink();

    return Column(
      children: decisions.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> decision = entry.value;
        bool isLast = index == decisions.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: Colors.purple.shade300,
                  ),
              ],
            ),
            SizedBox(width: 16),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            decision['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ),
                        if (decision['hasAttachment'])
                          Icon(
                            Icons.attach_file,
                            size: 16,
                            color: Colors.purple.shade600,
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${decision['user']} (${decision['position']})',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.purple.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (decision['comment'].isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        decision['comment'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // Admin status change dialog for Stage 1
  void _showAdminStatusChangeDialog() {
    final allStatuses = AppConstants.allWorkflowStatuses;
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
                                  Text(
                                    'تغيير حالة المستند',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'اختر الحالة الجديدة للمستند',
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
                            ),
                          ],
                        ),
                      ),

                      // Content - Status Selection
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
                                            'الحالة الحالية: ${AppStyles.getStatusDisplayName(_documentModel!.status)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'ملف: ${_documentModel!.fullName}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 20),

                              Text(
                                'اختر الحالة الجديدة:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppStyles.primaryColor,
                                ),
                              ),
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
                                    final isSelected = selectedStatus == status;
                                    final isCurrent =
                                        _documentModel!.status == status;
                                    final statusColor =
                                        AppStyles.getStatusColor(status);
                                    final statusIcon =
                                        AppStyles.getStatusIcon(status);
                                    final displayName =
                                        AppStyles.getStatusDisplayName(status);

                                    return InkWell(
                                      onTap: isCurrent
                                          ? null
                                          : () {
                                              setState(() {
                                                selectedStatus = status;
                                              });
                                            },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isCurrent
                                                ? [
                                                    Colors.grey.shade100,
                                                    Colors.grey.shade200
                                                  ]
                                                : isSelected
                                                    ? [
                                                        statusColor
                                                            .withOpacity(0.2),
                                                        statusColor
                                                            .withOpacity(0.1)
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
                                                    ? statusColor
                                                    : Colors.grey.shade200,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              statusIcon,
                                              color: isCurrent
                                                  ? Colors.grey.shade600
                                                  : statusColor,
                                              size: 20,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              displayName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isCurrent
                                                    ? Colors.grey.shade600
                                                    : statusColor,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (isCurrent) ...[
                                              SizedBox(height: 4),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade300,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'حالياً',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              SizedBox(height: 20),

                              // Comment Field
                              Text(
                                'تعليق (مطلوب):',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff2d3748),
                                ),
                              ),
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
                                              await _documentService
                                                  .adminChangeDocumentStatus(
                                                _documentModel!.id,
                                                selectedStatus!,
                                                commentController.text.trim(),
                                                _currentUserId!,
                                                _currentUserName!,
                                                _currentUserPosition!,
                                              );
                                              await _refreshDocumentData();
                                              _showSuccessSnackBar(
                                                  'تم تغيير حالة المستند بنجاح');
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppStyles.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text('تطبيق التغيير'),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppStyles.primaryColor,
                                        side: BorderSide(
                                            color: AppStyles.primaryColor),
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
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

  // Keep existing file handling methods unchanged (same as original)
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
        await _handleWebFileView(documentData);
      } else {
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

  Future<void> _handleWebFileView(Map<String, dynamic> documentData) async {
    try {
      final String fileUrl = _documentModel!.documentUrl!;
      final String fileExtension = _getFileExtension(documentData, fileUrl);
      final String fileName = _getFileName(documentData, fileUrl);

      if (!supportedFileTypes.containsKey(fileExtension)) {
        throw Exception(
            'نوع الملف غير مدعوم: ${_getFileTypeDisplayName(documentData, fileExtension)}');
      }

      _showWebViewOptionsDialog(fileUrl, fileName, fileExtension, documentData);
    } catch (e) {
      throw Exception('فشل في تجهيز الملف للعرض: $e');
    }
  }

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

  Future<void> _openInNewTab(String fileUrl) async {
    try {
      html.window.open(fileUrl, '_blank');
      _showSuccessSnackBar('تم فتح الملف في تبويب جديد');
    } catch (e) {
      _showErrorSnackBar('فشل في فتح الملف في تبويب جديد');
    }
  }

  Future<void> _downloadFileWeb(String fileUrl, String fileName,
      Map<String, dynamic> documentData) async {
    try {
      setState(() => _isLoading = true);

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
      _showErrorSnackBar('فشل في تنزيل الملف: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

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

  // Helper methods (same as original)
  String _getFileName(Map<String, dynamic> documentData, String url) {
    if (documentData.containsKey('originalFileName') &&
        documentData['originalFileName'] != null &&
        documentData['originalFileName'].toString().isNotEmpty) {
      return documentData['originalFileName'];
    }

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

    final fileExtension = _getFileExtension(documentData, url);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'document_$timestamp$fileExtension';
  }

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
}
