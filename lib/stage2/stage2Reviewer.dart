// pages/Stage2/Stage2ReviewerDetailsPage.dart
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
import '../App_Constants.dart';
import '../Document_Services.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/Action_history.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/senderinfocard.dart';
import '../models/document_model.dart';
import '../models/reviewerModel.dart';

class Stage2ReviewerDetailsPage extends StatefulWidget {
  final DocumentModel document;

  const Stage2ReviewerDetailsPage({Key? key, required this.document})
      : super(key: key);

  @override
  _Stage2ReviewerDetailsPageState createState() =>
      _Stage2ReviewerDetailsPageState();
}

class _Stage2ReviewerDetailsPageState extends State<Stage2ReviewerDetailsPage>
    with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();

  bool _isLoading = false;
  DocumentModel? _document;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPosition;
  ReviewerModel? _currentReviewerInfo;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Review form controllers
  final TextEditingController _reviewCommentController =
      TextEditingController();
  int _selectedRating = 0;
  String _recommendedAction = '';

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

        // Find current reviewer info
        _currentReviewerInfo = _document!.reviewers.firstWhere(
          (reviewer) => reviewer.userId == _currentUserId,
          orElse: () => ReviewerModel(
            userId: _currentUserId!,
            name: _currentUserName!,
            email: currentUser.email,
            position: _currentUserPosition!,
            reviewStatus: 'Not Assigned',
            assignedDate: null,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _reviewCommentController.dispose();
    _strengthsController.dispose(); // Add this
    _weaknessesController.dispose(); // Add this
    _recommendationsController.dispose(); // Add this
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
            Colors.teal.shade600,
            Colors.teal.shade800,
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
                child: Icon(Icons.rate_review, color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التحكيم العلمي',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'المرحلة الثانية - مراجعة وتقييم المقال',
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
          _buildReviewerStatusBar(),
        ],
      ),
    );
  }

  Widget _buildReviewerStatusBar() {
    final status = _currentReviewerInfo?.reviewStatus ?? 'Not Assigned';
    String statusText = '';
    Color statusColor = Colors.white;
    IconData statusIcon = Icons.info;

    switch (status) {
      case 'Pending':
        statusText = 'تم تعيينك كمحكم - ابدأ المراجعة';
        statusColor = Colors.orange.shade100;
        statusIcon = Icons.hourglass_top;
        break;
      case 'In Progress':
        statusText = 'مراجعتك قيد التقدم';
        statusColor = Colors.blue.shade100;
        statusIcon = Icons.rate_review;
        break;
      case 'Completed':
        statusText = 'تم إنهاء المراجعة بنجاح';
        statusColor = Colors.green.shade100;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusText = 'غير مخول للمراجعة';
        statusColor = Colors.red.shade100;
        statusIcon = Icons.block;
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
          Icon(statusIcon, color: Colors.teal.shade800, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة المراجعة',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.teal.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
              ],
            ),
          ),
          if (_currentReviewerInfo?.assignedDate != null)
            Text(
              'تم التعيين: ${_formatDate(_currentReviewerInfo!.assignedDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.teal.shade600,
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
          // Review Guidelines
          _buildReviewGuidelines(),

          // Document Info Card
          _buildDocumentInfoCard(),

          // Sender Info Card
          SenderInfoCard(
            document: _document!,
            isDesktop: isDesktop,
          ),

          // Main Review Panel
          _buildReviewPanel(),

          // Other Reviewers (if any)
          if (_document!.reviewers.length > 1) _buildOtherReviewers(),

          // Previous Actions
          if (_document!.actionLog.isNotEmpty)
            ActionHistoryWidget(actionLog: _document!.actionLog),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildReviewGuidelines() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
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
                  color: Colors.blue.shade500,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'إرشادات التحكيم العلمي',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildGuidelineItem('تقييم الأصالة العلمية والإبداع في الموضوع'),
          _buildGuidelineItem('فحص سلامة المنهجية العلمية المستخدمة'),
          _buildGuidelineItem('مراجعة دقة المراجع والاستشهادات'),
          _buildGuidelineItem('تقييم وضوح العرض والتنظيم المنطقي'),
          _buildGuidelineItem('فحص سلامة اللغة والأسلوب العلمي'),
          _buildGuidelineItem('تقديم ملاحظات بناءة ومقترحات للتحسين'),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue.shade500,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
              ),
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
                    colors: [Colors.teal.shade100, Colors.teal.shade200],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description,
                    color: Colors.teal.shade700, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المستند المطلوب تحكيمه',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'اضغط لعرض أو تحميل الملف للمراجعة',
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
                    'الملف الأصلي للمقال',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ملف المقال المقدم من المؤلف للتحكيم',
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

  Widget _buildReviewPanel() {
    final canReview = _currentReviewerInfo != null &&
        ['Pending', 'In Progress'].contains(_currentReviewerInfo!.reviewStatus);

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
                colors: [Colors.teal.shade500, Colors.teal.shade700],
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
                  child: Icon(Icons.rate_review, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نموذج التحكيم العلمي',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'قم بمراجعة وتقييم المقال علمياً',
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

          // Review Content
          Padding(
            padding: EdgeInsets.all(20),
            child: canReview ? _buildReviewForm() : _buildCompletedReview(),
          ),
        ],
      ),
    );
  }

// Enhanced Reviewer Form - Update your _buildReviewForm method in stage2Reviewer.dart

  Widget _buildReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating Section
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'التقييم العام للمقال:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRating = index + 1),
                    child: Container(
                      margin: EdgeInsets.only(left: 8),
                      child: Icon(
                        _selectedRating > index
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 8),
              Text(
                _getRatingDescription(_selectedRating),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Recommendation Section
        Container(
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
                'التوصية النهائية:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 12),
              ...['accept', 'minor_revision', 'major_revision', 'reject']
                  .map((action) {
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _recommendedAction == action
                        ? Colors.blue.shade100
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _recommendedAction == action
                          ? Colors.blue.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: RadioListTile<String>(
                    title: Text(
                      _getRecommendationText(action),
                      style: TextStyle(
                        fontWeight: _recommendedAction == action
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      _getRecommendationDescription(action),
                      style: TextStyle(fontSize: 12),
                    ),
                    value: action,
                    groupValue: _recommendedAction,
                    onChanged: (value) =>
                        setState(() => _recommendedAction = value!),
                    activeColor: Colors.blue.shade600,
                  ),
                );
              }),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Comments Section - Simplified
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.comment, color: Colors.orange.shade600, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'تعليقات التحكيم العامة (مطلوب):',
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
                'اكتب تقييمك الشامل للمقال، ملاحظاتك، ومقترحاتك للتحسين',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade600,
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _reviewCommentController,
                decoration: InputDecoration(
                  hintText:
                      'تعليقاتك الشاملة على المقال، تقييمك العام، ملاحظاتك، ومقترحاتك للتحسين...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.orange.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.orange, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 8,
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Action Buttons
        if (_currentReviewerInfo!.reviewStatus == 'Pending')
          _buildStartReviewButton()
        else
          _buildSubmitReviewButtons(),
      ],
    );
  }

  bool _canSubmitSimpleReview() {
    return _selectedRating > 0 &&
        _recommendedAction.isNotEmpty &&
        _reviewCommentController.text.trim().isNotEmpty;
  }

  String _getRecommendationDescription(String action) {
    switch (action) {
      case 'accept':
        return 'المقال جاهز للنشر بدون تعديلات';
      case 'minor_revision':
        return 'تعديلات طفيفة مطلوبة قبل النشر';
      case 'major_revision':
        return 'تعديلات كبيرة مطلوبة وإعادة مراجعة';
      case 'reject':
        return 'المقال غير مناسب للنشر';
      default:
        return '';
    }
  }

// Update the submission dialog call:
  void _showSimpleSubmitReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleReviewSubmissionDialog(
        rating: _selectedRating,
        recommendation: _recommendedAction,
        comment: _reviewCommentController.text.trim(),
        onConfirm: (reviewData, fileUrl, fileName) =>
            _submitSimpleReview(reviewData, fileUrl, fileName),
      ),
    );
  }

  Future<void> _submitDetailedReview(Map<String, dynamic> reviewData,
      String? fileUrl, String? fileName) async {
    setState(() => _isLoading = true);

    try {
      final detailedReviewData = {
        ...reviewData,
        'attachedFileUrl': fileUrl,
        'attachedFileName': fileName,
        'submittedAt': DateTime.now().toIso8601String(),
      };

      // Use the existing submitReviewerReview method for now
      await _documentService.submitReviewerReview(
        _document!.id,
        _currentUserId!,
        detailedReviewData,
        _currentUserName!,
      );

      await _refreshDocument();
      _showSuccessSnackBar('تم إرسال التحكيم المفصل بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في إرسال التحكيم: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDetailedDraft() async {
    setState(() => _isLoading = true);

    try {
      final draftData = {
        'rating': _selectedRating,
        'recommendation': _recommendedAction,
        'comment': _reviewCommentController.text.trim(),
        'strengths': _strengthsController.text.trim(),
        'weaknesses': _weaknessesController.text.trim(),
        'recommendations': _recommendationsController.text.trim(),
        'savedAt': DateTime.now().toIso8601String(),
      };

      await _documentService.savereviewDraft(
        _document!.id,
        _currentUserId!,
        draftData,
      );

      _showSuccessSnackBar('تم حفظ المراجعة المفصلة كمسودة');
    } catch (e) {
      _showErrorSnackBar('خطأ في حفظ المسودة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSubmitReviewButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canSubmitSimpleReview()
                ? () => _showSimpleSubmitReviewDialog()
                : null,
            icon: Icon(Icons.send, size: 24),
            label: Text(
              'إرسال التحكيم',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _saveSimpleDraft(),
            icon: Icon(Icons.save, size: 24),
            label: Text(
              'حفظ كمسودة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.teal.shade600,
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

// Simplified submission method:
  Future<void> _submitSimpleReview(Map<String, dynamic> reviewData,
      String? fileUrl, String? fileName) async {
    setState(() => _isLoading = true);

    try {
      final simpleReviewData = {
        ...reviewData,
        'attachedFileUrl': fileUrl,
        'attachedFileName': fileName,
        'submittedAt': DateTime.now().toIso8601String(),
      };

      await _documentService.submitReviewerReview(
        _document!.id,
        _currentUserId!,
        simpleReviewData,
        _currentUserName!,
      );

      await _refreshDocument();
      _showSuccessSnackBar('تم إرسال التحكيم بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في إرسال التحكيم: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

// Simplified draft saving:
  Future<void> _saveSimpleDraft() async {
    setState(() => _isLoading = true);

    try {
      final draftData = {
        'rating': _selectedRating,
        'recommendation': _recommendedAction,
        'comment': _reviewCommentController.text.trim(),
        'savedAt': DateTime.now().toIso8601String(),
      };

      await _documentService.savereviewDraft(
        _document!.id,
        _currentUserId!,
        draftData,
      );

      _showSuccessSnackBar('تم حفظ المراجعة كمسودة');
    } catch (e) {
      _showErrorSnackBar('خطأ في حفظ المسودة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStartReviewButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _startReview(),
        icon: Icon(Icons.play_arrow, size: 24),
        label: Text(
          'بدء المراجعة المفصلة',
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
    );
  }

// Add these controller declarations at the top of your class
  final TextEditingController _strengthsController = TextEditingController();
  final TextEditingController _weaknessesController = TextEditingController();
  final TextEditingController _recommendationsController =
      TextEditingController();

  Widget _buildCompletedReview() {
    if (_currentReviewerInfo == null ||
        _currentReviewerInfo!.reviewStatus != 'Completed') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.block, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'غير مخول للمراجعة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'لم يتم تعيينك كمحكم لهذا المقال',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text(
                'تم إنهاء المراجعة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_currentReviewerInfo!.comment != null &&
              _currentReviewerInfo!.comment!.isNotEmpty) ...[
            Text(
              'تعليقاتك:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                _currentReviewerInfo!.comment!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
          SizedBox(height: 16),
          Text(
            'شكراً لك على مساهمتك في عملية التحكيم العلمي',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherReviewers() {
    final otherReviewers = _document!.reviewers
        .where((reviewer) => reviewer.userId != _currentUserId)
        .toList();

    if (otherReviewers.isEmpty) return SizedBox.shrink();

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
              Icon(Icons.people, color: Colors.teal.shade600, size: 24),
              SizedBox(width: 12),
              Text(
                'المحكمون الآخرون',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...otherReviewers
              .map((reviewer) => _buildOtherReviewerCard(reviewer)),
        ],
      ),
    );
  }

  Widget _buildOtherReviewerCard(ReviewerModel reviewer) {
    Color statusColor = _getReviewStatusColor(reviewer.reviewStatus);

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
            radius: 20,
            backgroundColor: statusColor,
            child: Text(
              reviewer.name[0],
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
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
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _getReviewStatusDisplayName(reviewer.reviewStatus),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
              CircularProgressIndicator(color: Colors.teal.shade600),
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
  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'ضعيف جداً - يحتاج إعادة كتابة شاملة';
      case 2:
        return 'ضعيف - يحتاج تحسينات كبيرة';
      case 3:
        return 'متوسط - يحتاج تحسينات متوسطة';
      case 4:
        return 'جيد - يحتاج تحسينات طفيفة';
      case 5:
        return 'ممتاز - جاهز للنشر';
      default:
        return 'اختر تقييماً';
    }
  }

  String _getRecommendationText(String action) {
    switch (action) {
      case 'accept':
        return 'قبول للنشر بدون تعديل';
      case 'minor_revision':
        return 'قبول مع تعديلات طفيفة';
      case 'major_revision':
        return 'إعادة مراجعة مع تعديلات كبيرة';
      case 'reject':
        return 'رفض النشر';
      default:
        return '';
    }
  }

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

  bool _canSubmitReview() {
    return _selectedRating > 0 &&
        _recommendedAction.isNotEmpty &&
        _reviewCommentController.text.trim().isNotEmpty;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Action methods
  Future<void> _startReview() async {
    setState(() => _isLoading = true);

    try {
      await _documentService.updateReviewerStatusSecure(
        _document!.id,
        _currentUserId!,
        'In Progress',
        'بدء مراجعة المقال',
        _currentUserName!,
      );

      await _refreshDocument();
      _showSuccessSnackBar('تم بدء المراجعة بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في بدء المراجعة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAsDraft() async {
    if (_reviewCommentController.text.trim().isEmpty) {
      _showErrorSnackBar('يرجى إدخال تعليقات المراجعة أولاً');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final draftData = {
        'rating': _selectedRating,
        'recommendation': _recommendedAction,
        'comment': _reviewCommentController.text.trim(),
        'savedAt': DateTime.now().toIso8601String(),
      };

      await _documentService.savereviewDraft(
        _document!.id,
        _currentUserId!,
        draftData,
      );

      _showSuccessSnackBar('تم حفظ المراجعة كمسودة');
    } catch (e) {
      _showErrorSnackBar('خطأ في حفظ المسودة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReview(
      String comment, String? fileUrl, String? fileName) async {
    setState(() => _isLoading = true);

    try {
      final reviewData = {
        'rating': _selectedRating,
        'recommendation': _recommendedAction,
        'comment': comment,
        'attachedFileUrl': fileUrl,
        'attachedFileName': fileName,
        'submittedAt': DateTime.now().toIso8601String(),
      };

      await _documentService.submitReviewerReview(
        _document!.id,
        _currentUserId!,
        reviewData,
        _currentUserName!,
      );

      await _refreshDocument();
      _showSuccessSnackBar('تم إرسال التحكيم بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في إرسال التحكيم: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
        html.window.open(_document!.documentUrl!, '_blank');
        _showSuccessSnackBar('تم فتح الملف في تبويب جديد');
      } else {
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
              ..download = 'article_for_review.pdf'
              ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);

        _showSuccessSnackBar('تم بدء تنزيل الملف');
      } else {
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
          // Update current reviewer info
          _currentReviewerInfo = _document!.reviewers.firstWhere(
            (reviewer) => reviewer.userId == _currentUserId,
            orElse: () => _currentReviewerInfo!,
          );
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

// Simplified Review Submission Dialog
class SimpleReviewSubmissionDialog extends StatefulWidget {
  final int rating;
  final String recommendation;
  final String comment;
  final Function(Map<String, dynamic>, String?, String?) onConfirm;

  const SimpleReviewSubmissionDialog({
    Key? key,
    required this.rating,
    required this.recommendation,
    required this.comment,
    required this.onConfirm,
  }) : super(key: key);

  @override
  _SimpleReviewSubmissionDialogState createState() =>
      _SimpleReviewSubmissionDialogState();
}

class _SimpleReviewSubmissionDialogState
    extends State<SimpleReviewSubmissionDialog> {
  final TextEditingController _finalCommentController = TextEditingController();
  String? _attachedFileName;
  String? _attachedFileUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _finalCommentController.text = widget.comment;
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
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.send, color: Colors.teal, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'إرسال التحكيم النهائي',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'مراجعة نهائية لتحكيمك قبل الإرسال',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Review Summary
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملخص تحكيمك:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                    SizedBox(height: 12),

                    // Rating
                    Row(
                      children: [
                        Text('التقييم: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...List.generate(
                            5,
                            (index) => Icon(
                                  index < widget.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                )),
                        Text(' (${widget.rating}/5)'),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Recommendation
                    Row(
                      children: [
                        Text('التوصية: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_getRecommendationText(widget.recommendation)),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Final comment
              Text('التعليقات النهائية:'),
              SizedBox(height: 8),
              TextField(
                controller: _finalCommentController,
                decoration: InputDecoration(
                  hintText: 'تعديل أو إضافة تعليقات نهائية...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 4,
                textAlign: TextAlign.right,
              ),

              SizedBox(height: 16),

              // File attachment
              Text('إرفاق تقرير التحكيم (اختياري):'),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
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
                            : Icon(Icons.attach_file, color: Colors.grey[600]),
                      ),
                      Expanded(
                        child: Text(
                          _attachedFileName ??
                              'اختر ملف للإرفاق (تقرير التحكيم)',
                          style: TextStyle(
                            color: _attachedFileName != null
                                ? Colors.black
                                : Colors.grey[600],
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
                    final reviewData = {
                      'rating': widget.rating,
                      'recommendation': widget.recommendation,
                      'comment': _finalCommentController.text.trim(),
                    };
                    widget.onConfirm(
                        reviewData, _attachedFileUrl, _attachedFileName);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: Text('إرسال التحكيم'),
          ),
        ],
      ),
    );
  }

  String _getRecommendationText(String action) {
    switch (action) {
      case 'accept':
        return 'قبول للنشر';
      case 'minor_revision':
        return 'تعديلات طفيفة';
      case 'major_revision':
        return 'تعديلات كبيرة';
      case 'reject':
        return 'رفض النشر';
      default:
        return '';
    }
  }

  bool _canConfirm() {
    return _finalCommentController.text.trim().isNotEmpty && !_isUploading;
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
      final String fileName = 'reviewer_reports/${timestamp}_${file.name}';

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
