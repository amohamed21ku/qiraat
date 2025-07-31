// pages/Stage2/Stage2HeadEditorDetailsPage.dart - Updated to allow Editor Chief access and better reviewer selection
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

import '../../Classes/current_user_providerr.dart';
import '../Screens/Document_Handling/DocumentDetails/Constants/App_Constants.dart';
import '../Screens/Document_Handling/DocumentDetails/Services/Document_Services.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/Action_history.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/ImprovedReviewerSelector.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/senderinfocard.dart';
import '../Screens/Document_Handling/DocumentDetails/models/document_model.dart';
import '../Screens/Document_Handling/DocumentDetails/models/reviewerModel.dart';

class Stage2HeadEditorDetailsPage extends StatefulWidget {
  final DocumentModel document;

  const Stage2HeadEditorDetailsPage({Key? key, required this.document})
      : super(key: key);

  @override
  _Stage2HeadEditorDetailsPageState createState() =>
      _Stage2HeadEditorDetailsPageState();
}

class _Stage2HeadEditorDetailsPageState
    extends State<Stage2HeadEditorDetailsPage> with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();

  bool _isLoading = false;
  DocumentModel? _document;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPosition;
  List<Map<String, dynamic>> _availableReviewers = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _initializeAnimations();
    _getCurrentUserInfo();
    _loadAvailableReviewers();
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

  Future<void> _loadAvailableReviewers() async {
    try {
      print('Loading available reviewers...');
      final reviewers = await _documentService.getAvailableReviewers();
      setState(() {
        _availableReviewers = reviewers;
      });
      print('Loaded ${reviewers.length} reviewers successfully');

      // Debug print each reviewer
      for (var reviewer in reviewers) {
        print(
            'Reviewer: ${reviewer['name']} - ${reviewer['position']} - Email: ${reviewer['email']}');
      }
    } catch (e) {
      print('Error loading reviewers: $e');
      // Show error to user
      if (mounted) {
        _showErrorSnackBar('خطأ في تحميل قائمة المحكمين: $e');
      }
    }
  }

  bool _isHeadEditor() {
    return _currentUserPosition == AppConstants.POSITION_HEAD_EDITOR;
  }

  bool _isEditorChief() {
    return _currentUserPosition == AppConstants.POSITION_EDITOR_CHIEF ||
        _currentUserPosition == AppConstants.POSITION_MANAGING_EDITOR ||
        _currentUserPosition == 'مدير التحرير';
  }

  bool _canTakeAction() {
    return _isHeadEditor() || _isEditorChief();
  }

  Color _getThemeColor() {
    if (_isEditorChief()) {
      return Color(0xffa86418);
    }
    return Colors.indigo.shade600;
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
          colors: _isEditorChief()
              ? [Color(0xffa86418), Color(0xffcc9657)]
              : [Colors.indigo.shade600, Colors.indigo.shade800],
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
                child: Icon(
                  _isEditorChief()
                      ? Icons.supervisor_account
                      : Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditorChief()
                          ? 'إدارة التحكيم العلمي'
                          : 'إدارة التحكيم العلمي',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isEditorChief()
                          ? 'المرحلة الثانية - تنسيق وإشراف المحكمين'
                          : 'المرحلة الثانية - تعيين المحكمين والمراجعة',
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
          _buildStage2StatusBar(),
        ],
      ),
    );
  }

  Widget _buildStage2StatusBar() {
    final status = _document!.status;
    String statusText = '';
    Color statusColor = Colors.white;
    IconData statusIcon = Icons.info;

    switch (status) {
      case AppConstants.STAGE1_APPROVED:
        statusText = 'جاهز لتعيين المحكمين';
        statusColor = Colors.green.shade100;
        statusIcon = Icons.assignment_ind;
        break;
      case AppConstants.REVIEWERS_ASSIGNED:
        statusText = 'تم تعيين المحكمين - في انتظار بدء التحكيم';
        statusColor = Colors.blue.shade100;
        statusIcon = Icons.people;
        break;
      case AppConstants.UNDER_PEER_REVIEW:
        statusText = 'قيد التحكيم العلمي';
        statusColor = Colors.orange.shade100;
        statusIcon = Icons.rate_review;
        break;
      case AppConstants.PEER_REVIEW_COMPLETED:
        statusText = 'انتهى التحكيم - جاهز للمراجعة النهائية';
        statusColor = Colors.purple.shade100;
        statusIcon = Icons.check_circle;
        break;
      case AppConstants.HEAD_REVIEW_STAGE2:
        statusText = 'قيد المراجعة النهائية من رئيس التحرير';
        statusColor = Colors.indigo.shade100;
        statusIcon = Icons.admin_panel_settings;
        break;
      default:
        statusText = AppStyles.getStatusDisplayName(status);
        statusColor = Colors.green.shade100;
        statusIcon = Icons.verified;
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
          Icon(statusIcon, color: _getThemeColor(), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة التحكيم',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getThemeColor().withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getThemeColor(),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(_document!.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: _getThemeColor().withOpacity(0.8),
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
          // Stage 1 Summary
          _buildStage1Summary(),

          // Document Info Card
          _buildDocumentInfoCard(),

          // Sender Info Card
          SenderInfoCard(
            document: _document!,
            isDesktop: isDesktop,
          ),

          // Main Action Panel based on status
          _buildMainActionPanel(),

          // Current Reviewers (if any)
          if (_document!.reviewers.isNotEmpty) _buildCurrentReviewers(),

          // Previous Actions
          if (_document!.actionLog.isNotEmpty)
            ActionHistoryWidget(actionLog: _document!.actionLog),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStage1Summary() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade500,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.check_circle, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اجتاز المرحلة الأولى بنجاح',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  'تم قبول المقال من قبل رئيس التحرير للانتقال للتحكيم العلمي',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
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
                      'الملف المقدم للتحكيم العلمي',
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
          // File viewing section
          _buildFileViewingSection(),
        ],
      ),
    );
  }

  Widget _buildFileViewingSection() {
    if (_document!.documentUrl != null && _document!.documentUrl!.isNotEmpty) {
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
                    'ملف المقال المقدم من المؤلف',
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
    } else {
      return Container(
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
      );
    }
  }

  Widget _buildMainActionPanel() {
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
                colors: _isEditorChief()
                    ? [Color(0xffa86418), Color(0xffcc9657)]
                    : [Colors.indigo.shade500, Colors.indigo.shade700],
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
                  child: Icon(_getActionPanelIcon(),
                      color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getActionPanelTitle(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _getActionPanelSubtitle(),
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
            child: _canTakeAction()
                ? _buildActionContent()
                : _buildUnauthorizedMessage(),
          ),
        ],
      ),
    );
  }

  String _getActionPanelTitle() {
    switch (_document!.status) {
      case AppConstants.STAGE1_APPROVED:
        return 'تعيين المحكمين';
      case AppConstants.REVIEWERS_ASSIGNED:
        return 'إدارة التحكيم';
      case AppConstants.UNDER_PEER_REVIEW:
        return 'متابعة التحكيم';
      case AppConstants.PEER_REVIEW_COMPLETED:
      case AppConstants.HEAD_REVIEW_STAGE2:
        return 'المراجعة النهائية للتحكيم';
      default:
        return 'إدارة المرحلة الثانية';
    }
  }

  String _getActionPanelSubtitle() {
    switch (_document!.status) {
      case AppConstants.STAGE1_APPROVED:
        return 'اختر المحكمين المناسبين للمقال';
      case AppConstants.REVIEWERS_ASSIGNED:
        return 'تم تعيين المحكمين - بدء التحكيم';
      case AppConstants.UNDER_PEER_REVIEW:
        return 'المحكمون يراجعون المقال حالياً';
      case AppConstants.PEER_REVIEW_COMPLETED:
      case AppConstants.HEAD_REVIEW_STAGE2:
        return 'مراجعة نتائج التحكيم واتخاذ القرار';
      default:
        return 'إدارة سير العمل';
    }
  }

  IconData _getActionPanelIcon() {
    switch (_document!.status) {
      case AppConstants.STAGE1_APPROVED:
        return Icons.assignment_ind;
      case AppConstants.REVIEWERS_ASSIGNED:
      case AppConstants.UNDER_PEER_REVIEW:
        return Icons.people;
      case AppConstants.PEER_REVIEW_COMPLETED:
      case AppConstants.HEAD_REVIEW_STAGE2:
        return _isEditorChief()
            ? Icons.supervisor_account
            : Icons.admin_panel_settings;
      default:
        return Icons.settings;
    }
  }

  Widget _buildActionContent() {
    switch (_document!.status) {
      case AppConstants.STAGE1_APPROVED:
        return _buildReviewerAssignmentPanel();
      case AppConstants.REVIEWERS_ASSIGNED:
        return _buildStartReviewPanel();
      case AppConstants.UNDER_PEER_REVIEW:
        return _buildReviewMonitoringPanel();
      case AppConstants.PEER_REVIEW_COMPLETED:
      case AppConstants.HEAD_REVIEW_STAGE2:
        return _buildFinalDecisionPanel();
      default:
        return _buildCompletedPanel();
    }
  }

  Widget _buildReviewerAssignmentPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.assignment_ind, color: Colors.blue.shade600, size: 48),
              SizedBox(height: 16),
              Text(
                'تعيين المحكمين',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'اختر المحكمين المتخصصين المناسبين لهذا المقال',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _showAdvancedReviewerSelectionDialog(),
          icon: Icon(Icons.people_alt, size: 24),
          label: Text(
            'اختيار المحكمين',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getThemeColor(),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartReviewPanel() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.green.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.play_arrow, color: Colors.green.shade600, size: 48),
              SizedBox(height: 16),
              Text(
                'بدء عملية التحكيم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'تم تعيين المحكمين. ابدأ عملية التحكيم الآن',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _startReviewProcess(),
          icon: Icon(Icons.play_arrow, size: 24),
          label: Text(
            'بدء التحكيم',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewMonitoringPanel() {
    final completedReviews = _document!.reviewers
        .where((reviewer) => reviewer.reviewStatus == 'Completed')
        .length;
    final totalReviewers = _document!.reviewers.length;
    final progressPercentage =
        totalReviewers > 0 ? completedReviews / totalReviewers : 0.0;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade50, Colors.orange.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review,
                      color: Colors.orange.shade600, size: 32),
                  SizedBox(width: 12),
                  Text(
                    'التحكيم قيد التنفيذ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'تقدم التحكيم: $completedReviews من $totalReviewers',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              LinearProgressIndicator(
                value: progressPercentage,
                backgroundColor: Colors.orange.shade200,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
                minHeight: 8,
              ),
              SizedBox(height: 12),
              Text(
                '${(progressPercentage * 100).round()}% مكتمل',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange.shade600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Text(
          'المحكمون يراجعون المقال حالياً. ستتمكن من اتخاذ القرار النهائي عند انتهاء جميع المحكمين.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFinalDecisionPanel() {
    return Column(
      children: [
        // Review Summary
        Container(
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
                  Icon(Icons.assessment,
                      color: Colors.purple.shade600, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'ملخص نتائج التحكيم',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildReviewSummary(),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Decision Options
        Text(
          'القرارات المتاحة:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _getThemeColor(),
          ),
        ),

        SizedBox(height: 16),

        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: _buildFinalActionButton(
                title: 'الموافقة للمرحلة الثالثة',
                subtitle: 'إرسال للتحرير اللغوي والإخراج',
                icon: Icons.verified,
                color: Colors.green,
                onPressed: () => _showFinalActionDialog('stage3_approve'),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFinalActionButton(
                    title: 'طلب تعديل',
                    subtitle: 'يحتاج تعديلات محددة',
                    icon: Icons.edit,
                    color: Colors.orange,
                    onPressed: () => _showFinalActionDialog('edit_request'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildFinalActionButton(
                    title: 'رفض',
                    subtitle: 'رفض بناءً على التحكيم',
                    icon: Icons.cancel,
                    color: Colors.red,
                    onPressed: () => _showFinalActionDialog('reject'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildFinalActionButton(
                title: 'موافقة نشر الموقع',
                subtitle: 'نشر على الموقع فقط',
                icon: Icons.public,
                color: Colors.blue,
                onPressed: () => _showFinalActionDialog('website_approve'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewSummary() {
    final completedReviews = _document!.reviewers
        .where((reviewer) => reviewer.reviewStatus == 'Completed')
        .toList();

    if (completedReviews.isEmpty) {
      return Text(
        'لا توجد مراجعات مكتملة بعد',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      );
    }

    return Column(
      children: completedReviews.map((reviewer) {
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green,
                    child: Text(
                      reviewer.name[0],
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reviewer.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          reviewer.position,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'مكتمل',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (reviewer.comment != null && reviewer.comment!.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  reviewer.comment!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
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

  Widget _buildCompletedPanel() {
    String message = '';
    String description = '';
    IconData icon = Icons.info;
    Color color = Colors.grey;

    switch (_document!.status) {
      case AppConstants.STAGE2_APPROVED:
        message = 'تمت الموافقة للمرحلة الثالثة';
        description = 'تم قبول المقال للانتقال للتحرير اللغوي والإخراج';
        icon = Icons.verified;
        color = Colors.green;
        break;
      case AppConstants.STAGE2_REJECTED:
        message = 'تم رفض المقال';
        description = 'تم رفض المقال بناءً على نتائج التحكيم';
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case AppConstants.STAGE2_WEBSITE_APPROVED:
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
        ],
      ),
    );
  }

  Widget _buildCurrentReviewers() {
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
              Icon(Icons.people, color: _getThemeColor(), size: 24),
              SizedBox(width: 12),
              Text(
                'المحكمون المعينون',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getThemeColor(),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ..._document!.reviewers
              .map((reviewer) => _buildReviewerCard(reviewer)),
        ],
      ),
    );
  }

  Widget _buildReviewerCard(ReviewerModel reviewer) {
    Color statusColor = _getReviewStatusColor(reviewer.reviewStatus);
    IconData statusIcon = _getReviewStatusIcon(reviewer.reviewStatus);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: statusColor,
            child: Text(
              reviewer.name[0],
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reviewer.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  reviewer.position,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (reviewer.assignedDate != null)
                  Text(
                    'تم التعيين: ${_formatDate(reviewer.assignedDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getReviewStatusDisplayName(reviewer.reviewStatus),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthorizedMessage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.withOpacity(0.1), Colors.grey.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.lock, color: Colors.grey, size: 48),
          SizedBox(height: 16),
          Text(
            'غير مخول',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'يمكن لرئيس التحرير ومدير التحرير فقط إدارة عملية التحكيم',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.withOpacity(0.8),
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
              CircularProgressIndicator(color: _getThemeColor()),
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

  // Helper methods
  Color _getReviewStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getReviewStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_top;
      case 'In Progress':
        return Icons.rate_review;
      case 'Completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _getReviewStatusDisplayName(String status) {
    switch (status) {
      case 'Pending':
        return 'في الانتظار';
      case 'In Progress':
        return 'قيد المراجعة';
      case 'Completed':
        return 'مكتمل';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAdvancedReviewerSelectionDialog() {
    // Debug print to check available reviewers
    print(
        'Showing reviewer dialog with ${_availableReviewers.length} reviewers');

    if (_availableReviewers.isEmpty) {
      // Show error if no reviewers available
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('لا توجد محكمين متاحين'),
          content: Text(
              'لم يتم العثور على محكمين في النظام. تأكد من إضافة محكمين أولاً.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('موافق'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ImprovedReviewerSelectionDialog(
        availableReviewers: _availableReviewers,
        themeColor: _getThemeColor(),
        userRole: _isEditorChief() ? 'مدير التحرير' : 'رئيس التحرير',
        onReviewersSelected: (selectedReviewers) {
          print('Selected ${selectedReviewers.length} reviewers');
          _assignReviewers(selectedReviewers);
        },
      ),
    );
  }

  Future<void> _assignReviewers(
      List<Map<String, dynamic>> selectedReviewers) async {
    setState(() => _isLoading = true);

    try {
      await _documentService.assignReviewersToDocument(
        _document!.id,
        selectedReviewers,
        _currentUserId!,
        _currentUserName!,
        _currentUserPosition!,
      );

      await _refreshDocument();
      _showSuccessSnackBar('تم تعيين المحكمين بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في تعيين المحكمين: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startReviewProcess() async {
    setState(() => _isLoading = true);

    try {
      await _documentService.updateDocumentStatus(
        _document!.id,
        AppConstants.UNDER_PEER_REVIEW,
        'بدء عملية التحكيم العلمي',
        _currentUserId!,
        _currentUserName!,
        _currentUserPosition!,
      );

      await _refreshDocument();
      _showSuccessSnackBar('تم بدء عملية التحكيم بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في بدء التحكيم: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFinalActionDialog(String action) {
    String title = '';
    String description = '';
    Color color = Colors.blue;

    switch (action) {
      case 'stage3_approve':
        title = 'الموافقة للمرحلة الثالثة';
        description = 'سيتم قبول المقال للانتقال للتحرير اللغوي والإخراج';
        color = Colors.green;
        break;
      case 'edit_request':
        title = 'طلب تعديل';
        description =
            'سيتم طلب تعديلات محددة من المؤلف بناءً على ملاحظات المحكمين';
        color = Colors.orange;
        break;
      case 'reject':
        title = 'رفض المقال';
        description = 'سيتم رفض المقال بناءً على نتائج التحكيم';
        color = Colors.red;
        break;
      case 'website_approve':
        title = 'موافقة نشر الموقع';
        description = 'سيتم الموافقة على نشر المقال على الموقع الإلكتروني فقط';
        color = Colors.blue;
        break;
    }

    showDialog(
      context: context,
      builder: (context) => Stage2ActionDialog(
        title: title,
        description: description,
        color: color,
        isEditRequest: action == 'edit_request',
        reviewSummary: _buildReviewSummaryText(),
        onConfirm: (comment, fileUrl, fileName, editRequirements) =>
            _processFinalAction(
                action, comment, fileUrl, fileName, editRequirements),
      ),
    );
  }

  String _buildReviewSummaryText() {
    final completedReviews = _document!.reviewers
        .where((reviewer) => reviewer.reviewStatus == 'Completed')
        .toList();

    if (completedReviews.isEmpty) {
      return 'لا توجد مراجعات مكتملة';
    }

    String summary = 'ملخص آراء المحكمين:\n\n';
    for (int i = 0; i < completedReviews.length; i++) {
      final reviewer = completedReviews[i];
      summary += '${i + 1}. ${reviewer.name} (${reviewer.position}):\n';
      if (reviewer.comment != null && reviewer.comment!.isNotEmpty) {
        summary += '${reviewer.comment}\n\n';
      } else {
        summary += 'لا يوجد تعليق\n\n';
      }
    }

    return summary;
  }

  Future<void> _processFinalAction(String action, String comment,
      String? fileUrl, String? fileName, String? editRequirements) async {
    setState(() => _isLoading = true);

    try {
      String nextStatus = '';
      switch (action) {
        case 'stage3_approve':
          nextStatus = AppConstants.STAGE2_APPROVED;
          break;
        case 'edit_request':
          nextStatus = AppConstants.STAGE2_EDIT_REQUESTED;
          break;
        case 'reject':
          nextStatus = AppConstants.STAGE2_REJECTED;
          break;
        case 'website_approve':
          nextStatus = AppConstants.STAGE2_WEBSITE_APPROVED;
          break;
      }

      final additionalData = <String, dynamic>{};
      if (editRequirements != null && editRequirements.isNotEmpty) {
        additionalData['editRequirements'] = editRequirements;
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
        additionalData: additionalData,
      );

      await _refreshDocument();
      _showSuccessSnackBar('تم اتخاذ القرار بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في اتخاذ القرار: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // File handling methods (similar to Stage1 pages)
  Future<void> _handleViewFile() async {
    if (_document?.documentUrl == null || _document!.documentUrl!.isEmpty) {
      _showErrorSnackBar('رابط الملف غير متوفر');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        html.window.open(_document!.documentUrl!, '_blank');
        _showSuccessSnackBar('تم فتح الملف في تبويب جديد');
      } else {
        // Handle mobile file viewing
        _showSuccessSnackBar('سيتم إضافة عرض الملفات على الهاتف قريباً');
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
        final html.AnchorElement anchor =
            html.AnchorElement(href: _document!.documentUrl!)
              ..download = 'document.pdf'
              ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);

        _showSuccessSnackBar('تم بدء تنزيل الملف');
      } else {
        // Handle mobile file download
        _showSuccessSnackBar('سيتم إضافة تحميل الملفات على الهاتف قريباً');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في تحميل الملف: ${e.toString()}');
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

// Advanced Reviewer Selection Dialog - styled like EditorChef_TaskPage.dart
class AdvancedReviewerSelectionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableReviewers;
  final Color themeColor;
  final String userRole;
  final Function(List<Map<String, dynamic>>) onReviewersSelected;

  const AdvancedReviewerSelectionDialog({
    Key? key,
    required this.availableReviewers,
    required this.themeColor,
    required this.userRole,
    required this.onReviewersSelected,
  }) : super(key: key);

  @override
  _AdvancedReviewerSelectionDialogState createState() =>
      _AdvancedReviewerSelectionDialogState();
}

class _AdvancedReviewerSelectionDialogState
    extends State<AdvancedReviewerSelectionDialog> {
  List<Map<String, dynamic>> selectedReviewers = [];
  String searchQuery = '';
  String selectedSpecialization = 'الكل';
  List<String> specializations = ['الكل'];

  @override
  void initState() {
    super.initState();
    _extractSpecializations();
  }

  void _extractSpecializations() {
    Set<String> specs = {'الكل'};
    for (var reviewer in widget.availableReviewers) {
      if (reviewer['specialization'] != null) {
        specs.add(reviewer['specialization']);
      }
    }
    setState(() {
      specializations = specs.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredReviewers = widget.availableReviewers.where((reviewer) {
      bool matchesSearch =
          reviewer['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
              reviewer['position']
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              (reviewer['specialization']
                      ?.toLowerCase()
                      .contains(searchQuery.toLowerCase()) ??
                  false);

      bool matchesSpecialization = selectedSpecialization == 'الكل' ||
          reviewer['specialization'] == selectedSpecialization;

      return matchesSearch && matchesSpecialization;
    }).toList();

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.themeColor,
                      widget.themeColor.withOpacity(0.8)
                    ],
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
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(Icons.people_alt, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اختيار المحكمين',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${widget.userRole} - المرحلة الثانية',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'تم اختيار: ${selectedReviewers.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filters Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'البحث عن محكم (الاسم، المنصب، التخصص)...',
                        prefixIcon:
                            Icon(Icons.search, color: widget.themeColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: widget.themeColor),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),

                    // Specialization filter
                    Row(
                      children: [
                        Text(
                          'التخصص:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: specializations.map((spec) {
                                bool isSelected =
                                    selectedSpecialization == spec;
                                return Container(
                                  margin: EdgeInsets.only(left: 8),
                                  child: InkWell(
                                    onTap: () => setState(
                                        () => selectedSpecialization = spec),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? widget.themeColor
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected
                                              ? widget.themeColor
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        spec,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Results count
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: widget.themeColor, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'النتائج: ${filteredReviewers.length} محكم',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    if (selectedReviewers.isNotEmpty)
                      InkWell(
                        onTap: () => setState(() => selectedReviewers.clear()),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.clear, color: Colors.red, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'مسح الكل',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Reviewers list
              Expanded(
                child: filteredReviewers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredReviewers.length,
                        itemBuilder: (context, index) {
                          final reviewer = filteredReviewers[index];
                          final isSelected = selectedReviewers
                              .any((r) => r['id'] == reviewer['id']);

                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? widget.themeColor
                                    : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: widget.themeColor.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    selectedReviewers.add(reviewer);
                                  } else {
                                    selectedReviewers.removeWhere(
                                        (r) => r['id'] == reviewer['id']);
                                  }
                                });
                              },
                              activeColor: widget.themeColor,
                              checkColor: Colors.white,
                              secondary: CircleAvatar(
                                backgroundColor: isSelected
                                    ? widget.themeColor
                                    : Colors.grey.shade400,
                                child: Text(
                                  reviewer['name'][0],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                reviewer['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? widget.themeColor
                                      : Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reviewer['position'],
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (reviewer['specialization'] != null) ...[
                                    SizedBox(height: 4),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? widget.themeColor.withOpacity(0.1)
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        reviewer['specialization'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected
                                              ? widget.themeColor
                                              : Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                          );
                        },
                      ),
              ),

              // Footer
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('إلغاء'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: selectedReviewers.isNotEmpty
                            ? () {
                                Navigator.pop(context);
                                widget.onReviewersSelected(selectedReviewers);
                              }
                            : null,
                        icon: Icon(Icons.assignment_ind, size: 20),
                        label: Text(
                          'تعيين ${selectedReviewers.length} محكم',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.themeColor,
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
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'لم يتم العثور على محكمين يطابقون معايير البحث',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Stage2 Action Dialog (keeping the existing one from the original code)
class Stage2ActionDialog extends StatefulWidget {
  final String title;
  final String description;
  final Color color;
  final bool isEditRequest;
  final String reviewSummary;
  final Function(String, String?, String?, String?) onConfirm;

  const Stage2ActionDialog({
    Key? key,
    required this.title,
    required this.description,
    required this.color,
    this.isEditRequest = false,
    required this.reviewSummary,
    required this.onConfirm,
  }) : super(key: key);

  @override
  _Stage2ActionDialogState createState() => _Stage2ActionDialogState();
}

class _Stage2ActionDialogState extends State<Stage2ActionDialog> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _editRequirementsController =
      TextEditingController();
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
                  child: Icon(Icons.admin_panel_settings,
                      color: widget.color, size: 20),
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Review Summary
              ExpansionTile(
                title: Text('ملخص آراء المحكمين'),
                leading: Icon(Icons.assessment, color: widget.color),
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.reviewSummary,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Comment field
              Text('قرارك وتبريراته (مطلوب):'),
              SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'اكتب قرارك النهائي بناءً على نتائج التحكيم...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 4,
                textAlign: TextAlign.right,
              ),

              // Edit requirements (only for edit requests)
              if (widget.isEditRequest) ...[
                SizedBox(height: 16),
                Text('متطلبات التعديل المحددة (مطلوب):'),
                SizedBox(height: 8),
                TextField(
                  controller: _editRequirementsController,
                  decoration: InputDecoration(
                    hintText: 'حدد بالضبط ما يحتاج إلى تعديل...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 3,
                  textAlign: TextAlign.right,
                ),
              ],

              SizedBox(height: 16),

              // File attachment (optional)
              Text('إرفاق تقرير نهائي (اختياري):'),
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.attach_file,
                                color: Colors.grey.shade600),
                      ),
                      Expanded(
                        child: Text(
                          _attachedFileName ??
                              'اختر ملف للإرفاق (التقرير النهائي)',
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
            ],
          ),
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
                      widget.isEditRequest
                          ? _editRequirementsController.text.trim()
                          : null,
                    );
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

  bool _canConfirm() {
    bool hasComment = _commentController.text.trim().isNotEmpty;
    bool hasEditRequirements = !widget.isEditRequest ||
        _editRequirementsController.text.trim().isNotEmpty;
    return hasComment && hasEditRequirements && !_isUploading;
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
      final String fileName = 'stage2_reports/${timestamp}_${file.name}';

      Reference ref = storage.ref().child(fileName);

      if (kIsWeb) {
        if (file.bytes != null) {
          UploadTask uploadTask = ref.putData(
            file.bytes!,
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
