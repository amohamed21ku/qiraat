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
import '../App_Constants.dart';
import '../Document_Services.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/Action_history.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/ImprovedReviewerSelector.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/senderinfocard.dart';
import '../models/document_model.dart';
import '../models/reviewerModel.dart';

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
    return _currentUserPosition == AppConstants.POSITION_MANAGING_EDITOR ||
        _currentUserPosition == 'مدير التحرير';
  }

  bool _canTakeAction() {
    // Head Editor can always take action
    if (_isHeadEditor()) return true;

    // Chef/Managing Editor can take action in specific statuses
    if (_isEditorChief() ||
        _currentUserPosition == AppConstants.POSITION_MANAGING_EDITOR) {
      return [
        AppConstants.LANGUAGE_EDITOR_COMPLETED,
        AppConstants.CHEF_REVIEW_LANGUAGE_EDIT,
        AppConstants
            .HEAD_REVIEW_STAGE2, // When language editing is approved and comes back to head
      ].contains(_document!.status);
    }

    return false;
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
// Enhanced Review Display Components for stage2HeadEditor.dart
// Add these methods to your Stage2HeadEditorDetailsPage class

  Widget _buildDetailedReviewSummary() {
    final completedReviews = _document!.reviewers
        .where((reviewer) => reviewer.reviewStatus == 'Completed')
        .toList();

    if (completedReviews.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange.shade600),
            SizedBox(width: 12),
            Text(
              'لا توجد مراجعات مكتملة بعد',
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Statistics
        _buildReviewStatistics(completedReviews),

        SizedBox(height: 20),

        // Individual Review Details
        Text(
          'تفاصيل المراجعات الفردية:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.purple.shade700,
          ),
        ),
        SizedBox(height: 12),

        ...completedReviews
            .map((reviewer) => _buildDetailedReviewCard(reviewer)),

        SizedBox(height: 20),

        // Recommendation Summary
        _buildRecommendationSummary(completedReviews),
      ],
    );
  }

  Widget _buildReviewStatistics(List<ReviewerModel> completedReviews) {
    // Calculate statistics
    final ratings = completedReviews
        .where((r) => r.rating != null && r.rating! > 0)
        .map((r) => r.rating!.toDouble())
        .toList();

    final averageRating = ratings.isNotEmpty
        ? ratings.reduce((a, b) => a + b) / ratings.length
        : 0.0;

    // Count recommendations
    final recommendations = <String, int>{
      'accept': 0,
      'minor_revision': 0,
      'major_revision': 0,
      'reject': 0,
    };

    for (var reviewer in completedReviews) {
      final rec = reviewer.recommendation ?? 'unknown';
      if (recommendations.containsKey(rec)) {
        recommendations[rec] = recommendations[rec]! + 1;
      }
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.indigo.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.indigo.shade600, size: 24),
              SizedBox(width: 12),
              Text(
                'إحصائيات المراجعة الشاملة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Rating Statistics
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'متوسط التقييم',
                  '${averageRating.toStringAsFixed(1)}/5',
                  Icons.star,
                  Colors.amber,
                  subtitle: _getRatingDescription(averageRating.round()),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'عدد المراجعات',
                  '${completedReviews.length}',
                  Icons.people,
                  Colors.blue,
                  subtitle: 'من أصل ${_document!.reviewers.length} محكمين',
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Visual Rating Distribution
          Text(
            'توزيع التقييمات:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
            ),
          ),
          SizedBox(height: 8),
          _buildRatingDistribution(ratings),

          SizedBox(height: 16),

          // Recommendation Distribution
          Text(
            'توزيع التوصيات:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
            ),
          ),
          SizedBox(height: 8),
          _buildRecommendationDistribution(recommendations),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color,
      {String? subtitle}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingDistribution(List<double> ratings) {
    Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var rating in ratings) {
      distribution[rating.round()] = distribution[rating.round()]! + 1;
    }

    final maxCount = distribution.values.reduce((a, b) => a > b ? a : b);

    return Row(
      children: [1, 2, 3, 4, 5].map((star) {
        final count = distribution[star]!;
        final percentage = maxCount > 0 ? count / maxCount : 0.0;

        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Container(
                  height: 40,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: (percentage * 40),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.7),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 12),
                    Text('$star', style: TextStyle(fontSize: 10)),
                  ],
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendationDistribution(Map<String, int> recommendations) {
    final colors = {
      'accept': Colors.green,
      'minor_revision': Colors.blue,
      'major_revision': Colors.orange,
      'reject': Colors.red,
    };

    final labels = {
      'accept': 'قبول',
      'minor_revision': 'تعديل طفيف',
      'major_revision': 'تعديل كبير',
      'reject': 'رفض',
    };

    return Row(
      children: recommendations.entries.map((entry) {
        final count = entry.value;
        final color = colors[entry.key]!;
        final label = labels[entry.key]!;

        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2),
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailedReviewCard(ReviewerModel reviewer) {
    final rating = reviewer.rating ?? 0;
    final recommendation = reviewer.recommendation ?? '';

    Color recommendationColor = _getRecommendationColor(recommendation);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: recommendationColor.withOpacity(0.3)),
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
          // Reviewer Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: recommendationColor,
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
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      reviewer.position,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (reviewer.submittedDate != null)
                      Text(
                        'تاريخ الإرسال: ${_formatDate(reviewer.submittedDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: recommendationColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getRecommendationText(recommendation),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Rating Display
          Row(
            children: [
              Text(
                'التقييم: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              ...List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
              SizedBox(width: 8),
              Text(
                '($rating/5)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
              Spacer(),
              Text(
                _getRatingDescription(rating),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Comments Section
          if (reviewer.comment != null && reviewer.comment!.isNotEmpty) ...[
            Container(
              width: double.infinity,
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
                      Icon(Icons.comment,
                          color: Colors.grey.shade600, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'تعليقات المحكم:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    reviewer.comment!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Additional Review Details
          if (reviewer.strengths != null ||
              reviewer.weaknesses != null ||
              reviewer.recommendations != null)
            _buildAdditionalReviewDetails(reviewer),

          // Attached Files
          if (reviewer.attachedFileUrl != null &&
              reviewer.attachedFileUrl!.isNotEmpty)
            _buildAttachedFileSection(reviewer),
        ],
      ),
    );
  }

  Widget _buildAdditionalReviewDetails(ReviewerModel reviewer) {
    return Container(
      margin: EdgeInsets.only(top: 16),
      child: Column(
        children: [
          if (reviewer.strengths != null && reviewer.strengths!.isNotEmpty)
            _buildReviewDetailSection(
              'نقاط القوة',
              reviewer.strengths!,
              Icons.thumb_up,
              Colors.green,
            ),
          if (reviewer.weaknesses != null && reviewer.weaknesses!.isNotEmpty)
            _buildReviewDetailSection(
              'نقاط الضعف',
              reviewer.weaknesses!,
              Icons.thumb_down,
              Colors.red,
            ),
          if (reviewer.recommendations != null &&
              reviewer.recommendations!.isNotEmpty)
            _buildReviewDetailSection(
              'توصيات التحسين',
              reviewer.recommendations!,
              Icons.lightbulb,
              Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildReviewDetailSection(
      String title, String content, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachedFileSection(ReviewerModel reviewer) {
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file, color: Colors.blue.shade600, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تقرير التحكيم المرفق',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                if (reviewer.attachedFileName != null)
                  Text(
                    reviewer.attachedFileName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _downloadReviewerFile(reviewer.attachedFileUrl!),
            icon: Icon(Icons.download, size: 16),
            label: Text('تحميل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size(0, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSummary(List<ReviewerModel> completedReviews) {
    final recommendations = <String, List<ReviewerModel>>{
      'accept': [],
      'minor_revision': [],
      'major_revision': [],
      'reject': [],
    };

    for (var reviewer in completedReviews) {
      final rec = reviewer.recommendation ?? 'unknown';
      if (recommendations.containsKey(rec)) {
        recommendations[rec]!.add(reviewer);
      }
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.purple.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: Colors.purple.shade600, size: 24),
              SizedBox(width: 12),
              Text(
                'ملخص التوصيات النهائية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...recommendations.entries
              .where((entry) => entry.value.isNotEmpty)
              .map((entry) {
            final recommendation = entry.key;
            final reviewers = entry.value;
            final color = _getRecommendationColor(recommendation);

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getRecommendationText(recommendation),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '${reviewers.length} محكم',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'المحكمون: ${reviewers.map((r) => r.name).join(', ')}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

// Helper methods
  Color _getRecommendationColor(String recommendation) {
    switch (recommendation) {
      case 'accept':
        return Colors.green;
      case 'minor_revision':
        return Colors.blue;
      case 'major_revision':
        return Colors.orange;
      case 'reject':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRecommendationText(String recommendation) {
    switch (recommendation) {
      case 'accept':
        return 'قبول للنشر';
      case 'minor_revision':
        return 'تعديلات طفيفة';
      case 'major_revision':
        return 'تعديلات كبيرة';
      case 'reject':
        return 'رفض النشر';
      default:
        return 'غير محدد';
    }
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'ضعيف جداً';
      case 2:
        return 'ضعيف';
      case 3:
        return 'متوسط';
      case 4:
        return 'جيد';
      case 5:
        return 'ممتاز';
      default:
        return 'غير مقيم';
    }
  }

  Future<void> _downloadReviewerFile(String fileUrl) async {
    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        final html.AnchorElement anchor = html.AnchorElement(href: fileUrl)
          ..download = 'reviewer_report.pdf'
          ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);

        _showSuccessSnackBar('تم بدء تنزيل تقرير المحكم');
      } else {
        _showSuccessSnackBar('سيتم إضافة تحميل الملفات على الهاتف قريباً');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في تحميل الملف: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
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
      case AppConstants.CHEF_REVIEW_LANGUAGE_EDIT:
        return 'القرار النهائي بعد التدقيق اللغوي';
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
      case AppConstants.CHEF_REVIEW_LANGUAGE_EDIT:
        return 'اتخاذ القرار النهائي بعد اكتمال التدقيق اللغوي';
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

// Update the _buildFinalDecisionPanel method in stage2HeadEditor.dart
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
                  Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showDetailedReviewAnalysis(),
                    icon: Icon(Icons.analytics, size: 16),
                    label: Text('عرض التفاصيل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildSimpleReviewSummary(),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Decision Options based on status and user role
        if (_document!.status == AppConstants.LANGUAGE_EDITOR_COMPLETED &&
            (_isEditorChief() ||
                _currentUserPosition ==
                    AppConstants.POSITION_MANAGING_EDITOR)) ...[
          // Chef Editor reviewing completed language editing
          _buildChefLanguageReviewDecisions(),
        ] else if (_document!.status ==
                AppConstants.CHEF_REVIEW_LANGUAGE_EDIT &&
            (_isEditorChief() ||
                _currentUserPosition ==
                    AppConstants.POSITION_MANAGING_EDITOR)) ...[
          // Chef Editor making decision on language editing
          _buildChefLanguageReviewDecisions(),
        ] else if (_document!.status == AppConstants.PEER_REVIEW_COMPLETED ||
            _document!.status == AppConstants.HEAD_REVIEW_STAGE2) ...[
          // Head Editor decisions (including after chef approval of language editing)
          _buildHeadEditorDecisions(),
        ],
      ],
    );
  }

  // Widget _buildFinalDecisionPanel() {
  //   return Column(
  //     children: [
  //       // Review Summary
  //       Container(
  //         padding: EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(
  //             colors: [Colors.purple.shade50, Colors.purple.shade100],
  //           ),
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(color: Colors.purple.shade200),
  //         ),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Row(
  //               children: [
  //                 Icon(Icons.assessment,
  //                     color: Colors.purple.shade600, size: 24),
  //                 SizedBox(width: 12),
  //                 Text(
  //                   'ملخص نتائج التحكيم',
  //                   style: TextStyle(
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.purple.shade700,
  //                   ),
  //                 ),
  //                 Spacer(),
  //                 ElevatedButton.icon(
  //                   onPressed: () => _showSimpleReviewSummary(),
  //                   icon: Icon(Icons.analytics, size: 16),
  //                   label: Text('عرض التفاصيل'),
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: Colors.purple.shade600,
  //                     foregroundColor: Colors.white,
  //                     padding:
  //                         EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             SizedBox(height: 16),
  //             _buildSimpleReviewSummary(),
  //           ],
  //         ),
  //       ),
  //
  //       SizedBox(height: 24),
  //
  //       // Decision Options based on status
  //       if (_document!.status == AppConstants.PEER_REVIEW_COMPLETED ||
  //           _document!.status == AppConstants.HEAD_REVIEW_STAGE2) ...[
  //         Text(
  //           'القرارات المتاحة:',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: _getThemeColor(),
  //           ),
  //         ),
  //         SizedBox(height: 16),
  //
  //         // Primary option: Send to Language Editor
  //         SizedBox(
  //           width: double.infinity,
  //           child: _buildFinalActionButton(
  //             title: 'إرسال للتدقيق اللغوي',
  //             subtitle: 'إرسال للمدقق اللغوي قبل القرار النهائي',
  //             icon: Icons.spellcheck,
  //             color: Colors.blue,
  //             onPressed: () =>
  //                 _showFinalActionDialog('send_to_language_editor'),
  //           ),
  //         ),
  //
  //         SizedBox(height: 12),
  //
  //         // Alternative options
  //         Row(
  //           children: [
  //             Expanded(
  //               child: _buildFinalActionButton(
  //                 title: 'رفض مباشر',
  //                 subtitle: 'رفض بدون تدقيق لغوي',
  //                 icon: Icons.cancel,
  //                 color: Colors.red,
  //                 onPressed: () => _showFinalActionDialog('reject'),
  //               ),
  //             ),
  //             SizedBox(width: 12),
  //             Expanded(
  //               child: _buildFinalActionButton(
  //                 title: 'نشر الموقع',
  //                 subtitle: 'موافقة للموقع فقط',
  //                 icon: Icons.public,
  //                 color: Colors.orange,
  //                 onPressed: () => _showFinalActionDialog('website_approve'),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ] else if (_document!.status ==
  //               AppConstants.CHEF_REVIEW_LANGUAGE_EDIT &&
  //           (_isEditorChief() ||
  //               _currentUserPosition ==
  //                   AppConstants.POSITION_MANAGING_EDITOR)) ...[
  //         // Chef review of language editing
  //         Container(
  //           padding: EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               colors: [Colors.purple.shade50, Colors.purple.shade100],
  //             ),
  //             borderRadius: BorderRadius.circular(12),
  //             border: Border.all(color: Colors.purple.shade200),
  //           ),
  //           child: Column(
  //             children: [
  //               Row(
  //                 children: [
  //                   Icon(Icons.spellcheck,
  //                       color: Colors.purple.shade600, size: 24),
  //                   SizedBox(width: 12),
  //                   Expanded(
  //                     child: Text(
  //                       'مراجعة التدقيق اللغوي',
  //                       style: TextStyle(
  //                         fontSize: 16,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.purple.shade700,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               SizedBox(height: 8),
  //               Text(
  //                 'راجع عمل المدقق اللغوي واتخذ قرارك',
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   color: Colors.purple.shade600,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //
  //         SizedBox(height: 16),
  //
  //         Text(
  //           'قرارات مراجعة التدقيق اللغوي:',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: _getThemeColor(),
  //           ),
  //         ),
  //
  //         SizedBox(height: 16),
  //
  //         // Chef decisions for language editing
  //         Column(
  //           children: [
  //             SizedBox(
  //               width: double.infinity,
  //               child: _buildFinalActionButton(
  //                 title: 'الموافقة على التدقيق',
  //                 subtitle: 'إرسال لرئيس التحرير للقرار النهائي',
  //                 icon: Icons.check_circle,
  //                 color: Colors.green,
  //                 onPressed: () => _showChefLanguageReviewDialog('approve'),
  //               ),
  //             ),
  //             SizedBox(height: 12),
  //             SizedBox(
  //               width: double.infinity,
  //               child: _buildFinalActionButton(
  //                 title: 'إعادة للتدقيق',
  //                 subtitle: 'إرجاع للمدقق اللغوي للتحسين',
  //                 icon: Icons.replay,
  //                 color: Colors.orange,
  //                 onPressed: () => _showChefLanguageReviewDialog('reject'),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ] else if (_document!.status == AppConstants.HEAD_REVIEW_STAGE2 &&
  //           _document!.languageEditingApproved == true) ...[
  //         // Head editor final decision after language editing approval
  //         Container(
  //           padding: EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               colors: [Colors.green.shade50, Colors.green.shade100],
  //             ),
  //             borderRadius: BorderRadius.circular(12),
  //             border: Border.all(color: Colors.green.shade200),
  //           ),
  //           child: Column(
  //             children: [
  //               Row(
  //                 children: [
  //                   Icon(Icons.check_circle,
  //                       color: Colors.green.shade600, size: 24),
  //                   SizedBox(width: 12),
  //                   Expanded(
  //                     child: Text(
  //                       'اكتمل التدقيق اللغوي - القرار النهائي',
  //                       style: TextStyle(
  //                         fontSize: 16,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.green.shade700,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               SizedBox(height: 8),
  //               Text(
  //                 'تم اعتماد التدقيق اللغوي من مدير التحرير. اتخذ قرارك النهائي.',
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   color: Colors.green.shade600,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //
  //         SizedBox(height: 16),
  //
  //         Text(
  //           'القرارات النهائية:',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: _getThemeColor(),
  //           ),
  //         ),
  //
  //         SizedBox(height: 16),
  //
  //         Column(
  //           children: [
  //             SizedBox(
  //               width: double.infinity,
  //               child: _buildFinalActionButton(
  //                 title: 'الموافقة للمرحلة الثالثة',
  //                 subtitle: 'إرسال للإنتاج النهائي',
  //                 icon: Icons.verified,
  //                 color: Colors.green,
  //                 onPressed: () => _showFinalActionDialog('stage3_approve'),
  //               ),
  //             ),
  //             SizedBox(height: 12),
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: _buildFinalActionButton(
  //                     title: 'طلب تعديل',
  //                     subtitle: 'يحتاج تعديلات إضافية',
  //                     icon: Icons.edit,
  //                     color: Colors.orange,
  //                     onPressed: () => _showFinalActionDialog('edit_request'),
  //                   ),
  //                 ),
  //                 SizedBox(width: 12),
  //                 Expanded(
  //                   child: _buildFinalActionButton(
  //                     title: 'رفض',
  //                     subtitle: 'رفض نهائي',
  //                     icon: Icons.cancel,
  //                     color: Colors.red,
  //                     onPressed: () => _showFinalActionDialog('reject'),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             SizedBox(height: 12),
  //             SizedBox(
  //               width: double.infinity,
  //               child: _buildFinalActionButton(
  //                 title: 'نشر الموقع',
  //                 subtitle: 'موافقة للموقع فقط',
  //                 icon: Icons.public,
  //                 color: Colors.blue,
  //                 onPressed: () => _showFinalActionDialog('website_approve'),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ],
  //   );
  // }

// 3. Add new method for Chef Editor language review decisions
  Widget _buildChefLanguageReviewDecisions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xffa86418).withOpacity(0.1),
                Color(0xffa86418).withOpacity(0.05)
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xffa86418).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.supervisor_account,
                      color: Color(0xffa86418), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'مراجعة التدقيق اللغوي',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xffa86418),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'راجع عمل المدقق اللغوي واتخذ قرارك',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xffa86418).withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        Text(
          'قرارات مراجعة التدقيق اللغوي:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _getThemeColor(),
          ),
        ),

        SizedBox(height: 16),

        // Chef decisions for language editing
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: _buildFinalActionButton(
                title: 'الموافقة على التدقيق',
                subtitle: 'إرسال لرئيس التحرير للقرار النهائي',
                icon: Icons.check_circle,
                color: Colors.green,
                onPressed: () => _showChefLanguageReviewDialog('approve'),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildFinalActionButton(
                title: 'إعادة للتدقيق',
                subtitle: 'إرجاع للمدقق اللغوي للتحسين',
                icon: Icons.replay,
                color: Colors.orange,
                onPressed: () => _showChefLanguageReviewDialog('reject'),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildFinalActionButton(
                title: 'طلب تعديل من المؤلف',
                subtitle: 'إرجاع للمؤلف للتعديل',
                icon: Icons.edit,
                color: Colors.blue,
                onPressed: () => _showFinalActionDialog('edit_request'),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildFinalActionButton(
                title: 'نشر الموقع',
                subtitle: 'موافقة للموقع فقط',
                icon: Icons.public,
                color: Colors.indigo,
                onPressed: () => _showFinalActionDialog('website_approve'),
              ),
            ),
          ],
        ),
      ],
    );
  }

// 4. Add new method for Head Editor decisions (enhanced)
  Widget _buildHeadEditorDecisions() {
    bool languageEditingCompleted = _document!.languageEditingApproved == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (languageEditingCompleted) ...[
          // After language editing is approved by chef
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
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade600, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'اكتمل التدقيق اللغوي - القرار النهائي',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'تم اعتماد التدقيق اللغوي من مدير التحرير. اتخذ قرارك النهائي.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          Text(
            'القرارات النهائية:',
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
                  subtitle: 'إرسال للإنتاج النهائي',
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
                      subtitle: 'يحتاج تعديلات إضافية',
                      icon: Icons.edit,
                      color: Colors.orange,
                      onPressed: () => _showFinalActionDialog('edit_request'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildFinalActionButton(
                      title: 'رفض',
                      subtitle: 'رفض نهائي',
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
                  title: 'نشر الموقع',
                  subtitle: 'موافقة للموقع فقط',
                  icon: Icons.public,
                  color: Colors.blue,
                  onPressed: () => _showFinalActionDialog('website_approve'),
                ),
              ),
            ],
          ),
        ] else ...[
          // Before language editing or initial review completed
          Text(
            'القرارات المتاحة:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getThemeColor(),
            ),
          ),
          SizedBox(height: 16),

          // Primary option: Send to Language Editor
          SizedBox(
            width: double.infinity,
            child: _buildFinalActionButton(
              title: 'إرسال للتدقيق اللغوي',
              subtitle: 'إرسال للمدقق اللغوي قبل القرار النهائي',
              icon: Icons.spellcheck,
              color: Colors.blue,
              onPressed: () =>
                  _showFinalActionDialog('send_to_language_editor'),
            ),
          ),

          SizedBox(height: 12),

          // Alternative options
          Row(
            children: [
              Expanded(
                child: _buildFinalActionButton(
                  title: 'رفض مباشر',
                  subtitle: 'رفض بدون تدقيق لغوي',
                  icon: Icons.cancel,
                  color: Colors.red,
                  onPressed: () => _showFinalActionDialog('reject'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFinalActionButton(
                  title: 'نشر الموقع',
                  subtitle: 'موافقة للموقع فقط',
                  icon: Icons.public,
                  color: Colors.orange,
                  onPressed: () => _showFinalActionDialog('website_approve'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

// 5. Add method to show detailed review analysis (for clicking on action log items)
  void _showDetailedReviewAnalysis() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade600, Colors.purple.shade800],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'التحليل المفصل لنتائج التحكيم',
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
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: _buildDetailedReviewSummary(),
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
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('إغلاق'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChefLanguageReviewDialog(String decision) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: decision == 'approve'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      decision == 'approve' ? Icons.check_circle : Icons.replay,
                      color:
                          decision == 'approve' ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      decision == 'approve'
                          ? 'الموافقة على التدقيق اللغوي'
                          : 'إعادة للتدقيق اللغوي',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                decision == 'approve'
                    ? 'سيتم إرسال المقال لرئيس التحرير للقرار النهائي'
                    : 'سيتم إعادة المقال للمدقق اللغوي للتحسين',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'تعليقاتك (مطلوب)',
                  hintText: 'اكتب تعليقاتك هنا...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
                onChanged: (value) => _chefComment = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: (_chefComment?.trim().isNotEmpty ?? false)
                  ? () {
                      Navigator.pop(context);
                      _processChefLanguageReviewDecision(
                          decision, _chefComment!);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    decision == 'approve' ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }

  String? _chefComment;

  Future<void> _processChefLanguageReviewDecision(
      String decision, String comment) async {
    setState(() => _isLoading = true);

    try {
      await _documentService.submitChefEditorLanguageReview(
        _document!.id,
        _currentUserId!,
        _currentUserName!,
        decision,
        comment,
      );

      await _refreshDocument();

      String message = decision == 'approve'
          ? 'تم اعتماد التدقيق اللغوي وإرساله لرئيس التحرير'
          : 'تم إعادة المقال للتدقيق اللغوي';

      _showSuccessSnackBar(message);
    } catch (e) {
      _showErrorSnackBar('خطأ في معالجة القرار: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

// Simple review summary that works within the main class
  Widget _buildSimpleReviewSummary() {
    final completedReviews = _document!.reviewers
        .where((reviewer) => reviewer.reviewStatus == 'Completed')
        .toList();

    if (completedReviews.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange.shade600),
            SizedBox(width: 12),
            Text(
              'لا توجد مراجعات مكتملة بعد',
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

    // Calculate basic statistics
    final ratings = completedReviews
        .where((r) => r.rating != null && r.rating! > 0)
        .map((r) => r.rating!.toDouble())
        .toList();

    final averageRating = ratings.isNotEmpty
        ? ratings.reduce((a, b) => a + b) / ratings.length
        : 0.0;

    final recommendations = <String, int>{
      'accept': 0,
      'minor_revision': 0,
      'major_revision': 0,
      'reject': 0,
    };

    for (var reviewer in completedReviews) {
      final rec = reviewer.recommendation ?? 'unknown';
      if (recommendations.containsKey(rec)) {
        recommendations[rec] = recommendations[rec]! + 1;
      }
    }

    return Column(
      children: [
        // Statistics Row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '${averageRating.toStringAsFixed(1)}/5',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    Text(
                      'متوسط التقييم',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '${completedReviews.length}/${_document!.reviewers.length}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      'مراجعات مكتملة',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        // Recommendations Summary
        Row(
          children: [
            if (recommendations['accept']! > 0)
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'قبول: ${recommendations['accept']}',
                    style:
                        TextStyle(fontSize: 11, color: Colors.green.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (recommendations['minor_revision']! > 0) ...[
              if (recommendations['accept']! > 0) SizedBox(width: 4),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'تعديل طفيف: ${recommendations['minor_revision']}',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            if (recommendations['major_revision']! > 0) ...[
              if (recommendations['accept']! > 0 ||
                  recommendations['minor_revision']! > 0)
                SizedBox(width: 4),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'تعديل كبير: ${recommendations['major_revision']}',
                    style:
                        TextStyle(fontSize: 11, color: Colors.orange.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            if (recommendations['reject']! > 0) ...[
              if (recommendations.values
                  .any((v) => v > 0 && recommendations['reject'] != v))
                SizedBox(width: 4),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'رفض: ${recommendations['reject']}',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),

        SizedBox(height: 12),

        // Individual reviews preview
        Column(
          children: completedReviews.take(2).map((reviewer) {
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        _getRecommendationColor(reviewer.recommendation ?? ''),
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
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (reviewer.comment != null &&
                            reviewer.comment!.isNotEmpty)
                          Text(
                            reviewer.comment!.length > 50
                                ? '${reviewer.comment!.substring(0, 50)}...'
                                : reviewer.comment!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (reviewer.rating != null)
                    Row(
                      children: List.generate(
                          reviewer.rating!,
                          (index) =>
                              Icon(Icons.star, color: Colors.amber, size: 12)),
                    ),
                ],
              ),
            );
          }).toList(),
        ),

        if (completedReviews.length > 2)
          Text(
            'و ${completedReviews.length - 2} مراجعات أخرى...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  void _showSimpleReviewSummary() {
    final completedReviews = _document!.reviewers
        .where((reviewer) => reviewer.reviewStatus == 'Completed')
        .toList();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.analytics, color: Colors.purple.shade600),
              SizedBox(width: 12),
              Text('تفاصيل نتائج التحكيم'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: completedReviews.map((reviewer) {
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
                        // Reviewer Header
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getRecommendationColor(
                                  reviewer.recommendation ?? ''),
                              child: Text(
                                reviewer.name[0],
                                style: TextStyle(color: Colors.white),
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
                                      fontSize: 16,
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
                            if (reviewer.rating != null)
                              Row(
                                children: List.generate(
                                    reviewer.rating!,
                                    (index) => Icon(Icons.star,
                                        color: Colors.amber, size: 16)),
                              ),
                          ],
                        ),

                        // Recommendation Badge
                        if (reviewer.recommendation != null) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getRecommendationColor(
                                  reviewer.recommendation!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getRecommendationText(reviewer.recommendation!),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],

                        // Comments
                        if (reviewer.comment != null &&
                            reviewer.comment!.isNotEmpty) ...[
                          SizedBox(height: 12),
                          Text(
                            'التعليقات:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            reviewer.comment!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],

                        // Attached Files Section
                        if (reviewer.attachedFileUrl != null &&
                            reviewer.attachedFileUrl!.isNotEmpty) ...[
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.attach_file,
                                    color: Colors.blue.shade600, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'تقرير التحكيم المرفق',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      if (reviewer.attachedFileName != null)
                                        Text(
                                          reviewer.attachedFileName!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // View Button
                                    InkWell(
                                      onTap: () => _viewReviewerFile(
                                          reviewer.attachedFileUrl!),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade600,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.visibility,
                                                color: Colors.white, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              'عرض',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    // Download Button
                                    InkWell(
                                      onTap: () => _downloadReviewerFile(
                                          reviewer.attachedFileUrl!),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade600,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.download,
                                                color: Colors.white, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              'تحميل',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

// Add this method if it doesn't exist already
  Future<void> _viewReviewerFile(String fileUrl) async {
    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        html.window.open(fileUrl, '_blank');
        _showSuccessSnackBar('تم فتح تقرير المحكم في تبويب جديد');
      } else {
        _showSuccessSnackBar('سيتم إضافة عرض الملفات على الهاتف قريباً');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في فتح الملف: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
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
      case 'send_to_language_editor':
        title = 'إرسال للتدقيق اللغوي';
        description =
            'سيتم إرسال المقال للمدقق اللغوي للمراجعة اللغوية والأسلوبية';
        color = Colors.blue;
        break;
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

// Update the _processFinalAction method in stage2HeadEditor.dart

  Future<void> _processFinalAction(String action, String comment,
      String? fileUrl, String? fileName, String? editRequirements) async {
    setState(() => _isLoading = true);

    try {
      String nextStatus = '';
      Map<String, dynamic> additionalData = {};

      switch (action) {
        case 'send_to_language_editor':
          nextStatus = AppConstants.LANGUAGE_EDITING_STAGE2;
          additionalData = {
            'languageEditingAssignedDate': FieldValue.serverTimestamp(),
            'languageEditingAssignedBy': _currentUserName,
            'languageEditingAssignedById': _currentUserId,
            'sentToLanguageEditorDate': FieldValue.serverTimestamp(),
          };
          break;
        case 'stage3_approve':
          nextStatus = AppConstants.STAGE2_APPROVED;
          additionalData = {
            'stage2ApprovedDate': FieldValue.serverTimestamp(),
            'finalDecision': 'approved_for_stage3',
          };
          break;
        case 'edit_request':
          nextStatus = AppConstants.STAGE2_EDIT_REQUESTED;
          if (editRequirements != null && editRequirements.isNotEmpty) {
            additionalData['editRequirements'] = editRequirements;
          }
          additionalData['editRequestedDate'] = FieldValue.serverTimestamp();
          break;
        case 'reject':
          nextStatus = AppConstants.STAGE2_REJECTED;
          additionalData = {
            'rejectedDate': FieldValue.serverTimestamp(),
            'finalDecision': 'rejected',
          };
          break;
        case 'website_approve':
          nextStatus = AppConstants.STAGE2_WEBSITE_APPROVED;
          additionalData = {
            'websiteApprovedDate': FieldValue.serverTimestamp(),
            'finalDecision': 'approved_for_website',
          };
          break;
      }

      // Add common metadata
      additionalData.addAll({
        'decisionMadeBy': _currentUserName,
        'decisionMadeById': _currentUserId,
        'decisionMadeByPosition': _currentUserPosition,
        'decisionDate': FieldValue.serverTimestamp(),
      });

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

      // Show appropriate success message
      String successMessage = '';
      switch (action) {
        case 'send_to_language_editor':
          successMessage = 'تم إرسال المقال للتدقيق اللغوي بنجاح';
          break;
        case 'stage3_approve':
          successMessage = 'تم قبول المقال للمرحلة الثالثة بنجاح';
          break;
        case 'edit_request':
          successMessage = 'تم طلب التعديل بنجاح';
          break;
        case 'reject':
          successMessage = 'تم رفض المقال بنجاح';
          break;
        case 'website_approve':
          successMessage = 'تم قبول المقال لنشر الموقع بنجاح';
          break;
        default:
          successMessage = 'تم اتخاذ القرار بنجاح';
      }

      _showSuccessSnackBar(successMessage);
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

// Complete and working DetailedReviewDialog
class DetailedReviewDialog extends StatefulWidget {
  final DocumentModel document;

  const DetailedReviewDialog({
    Key? key,
    required this.document,
  }) : super(key: key);

  @override
  _DetailedReviewDialogState createState() => _DetailedReviewDialogState();
}

class _DetailedReviewDialogState extends State<DetailedReviewDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade600, Colors.purple.shade800],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'التحليل المفصل لنتائج التحكيم',
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

              // Tabs
              Container(
                color: Colors.purple.shade50,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.purple.shade700,
                  unselectedLabelColor: Colors.purple.shade400,
                  indicatorColor: Colors.purple.shade600,
                  tabs: [
                    Tab(text: 'الإحصائيات'),
                    Tab(text: 'المراجعات الفردية'),
                    Tab(text: 'التوصيات'),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatisticsTab(),
                    _buildIndividualReviewsTab(),
                    _buildRecommendationsTab(),
                  ],
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
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('إغلاق'),
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

  Widget _buildStatisticsTab() {
    final completedReviews = widget.document.reviewers
        .where((reviewer) => reviewer.reviewStatus == 'Completed')
        .toList();

    if (completedReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'لا توجد مراجعات مكتملة بعد',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate statistics
    final ratings = completedReviews
        .where((r) => r.rating != null && r.rating! > 0)
        .map((r) => r.rating!.toDouble())
        .toList();

    final averageRating = ratings.isNotEmpty
        ? ratings.reduce((a, b) => a + b) / ratings.length
        : 0.0;

    final recommendations = <String, int>{
      'accept': 0,
      'minor_revision': 0,
      'major_revision': 0,
      'reject': 0,
    };

    for (var reviewer in completedReviews) {
      final rec = reviewer.recommendation ?? 'unknown';
      if (recommendations.containsKey(rec)) {
        recommendations[rec] = recommendations[rec]! + 1;
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Statistics
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade50, Colors.indigo.shade100],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإحصائيات العامة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'متوسط التقييم',
                        '${averageRating.toStringAsFixed(1)}/5',
                        Icons.star,
                        Colors.amber,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'عدد المراجعات',
                        '${completedReviews.length}',
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Rating Distribution
                Text(
                  'توزيع التقييمات:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
                SizedBox(height: 8),
                _buildRatingDistribution(ratings),

                SizedBox(height: 16),

                // Recommendation Distribution
                Text(
                  'توزيع التوصيات:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
                SizedBox(height: 8),
                _buildRecommendationDistribution(recommendations),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualReviewsTab() {
    final completedReviews = widget.document.reviewers
        .where((reviewer) => reviewer.reviewStatus == 'Completed')
        .toList();

    if (completedReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined,
                size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'لا توجد مراجعات مكتملة',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: completedReviews.length,
      itemBuilder: (context, index) {
        return _buildReviewerCard(completedReviews[index]);
      },
    );
  }

  Widget _buildRecommendationsTab() {
    final completedReviews = widget.document.reviewers
        .where((reviewer) => reviewer.reviewStatus == 'Completed')
        .toList();

    if (completedReviews.isEmpty) {
      return Center(
        child: Text(
          'لا توجد توصيات متاحة',
          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
        ),
      );
    }

    final recommendations = <String, List<ReviewerModel>>{
      'accept': [],
      'minor_revision': [],
      'major_revision': [],
      'reject': [],
    };

    for (var reviewer in completedReviews) {
      final rec = reviewer.recommendation ?? 'unknown';
      if (recommendations.containsKey(rec)) {
        recommendations[rec]!.add(reviewer);
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص التوصيات النهائية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          SizedBox(height: 16),
          ...recommendations.entries
              .where((entry) => entry.value.isNotEmpty)
              .map((entry) {
            final recommendation = entry.key;
            final reviewers = entry.value;
            final color = _getRecommendationColor(recommendation);

            return Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getRecommendationText(recommendation),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '${reviewers.length} محكم',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'المحكمون: ${reviewers.map((r) => r.name).join(', ')}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution(List<double> ratings) {
    Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var rating in ratings) {
      distribution[rating.round()] = distribution[rating.round()]! + 1;
    }

    final maxCount = distribution.values.isNotEmpty
        ? distribution.values.reduce((a, b) => a > b ? a : b)
        : 1;

    return Row(
      children: [1, 2, 3, 4, 5].map((star) {
        final count = distribution[star]!;
        final percentage = maxCount > 0 ? count / maxCount : 0.0;

        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Container(
                  height: 40,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: (percentage * 40),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.7),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 12),
                    Text('$star', style: TextStyle(fontSize: 10)),
                  ],
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendationDistribution(Map<String, int> recommendations) {
    final colors = {
      'accept': Colors.green,
      'minor_revision': Colors.blue,
      'major_revision': Colors.orange,
      'reject': Colors.red,
    };

    final labels = {
      'accept': 'قبول',
      'minor_revision': 'تعديل طفيف',
      'major_revision': 'تعديل كبير',
      'reject': 'رفض',
    };

    return Row(
      children: recommendations.entries.map((entry) {
        final count = entry.value;
        final color = colors[entry.key]!;
        final label = labels[entry.key]!;

        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2),
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewerCard(ReviewerModel reviewer) {
    final rating = reviewer.rating ?? 0;
    final recommendation = reviewer.recommendation ?? '';

    Color recommendationColor = _getRecommendationColor(recommendation);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: recommendationColor.withOpacity(0.3)),
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
          // Reviewer Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: recommendationColor,
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
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      reviewer.position,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (reviewer.submittedDate != null)
                      Text(
                        'تاريخ الإرسال: ${_formatDate(reviewer.submittedDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: recommendationColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getRecommendationText(recommendation),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Rating Display
          Row(
            children: [
              Text(
                'التقييم: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              ...List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
              SizedBox(width: 8),
              Text(
                '($rating/5)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Comments Section
          if (reviewer.comment != null && reviewer.comment!.isNotEmpty) ...[
            Container(
              width: double.infinity,
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
                      Icon(Icons.comment,
                          color: Colors.grey.shade600, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'تعليقات المحكم:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    reviewer.comment!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Attached Files
          if (reviewer.attachedFileUrl != null &&
              reviewer.attachedFileUrl!.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file,
                      color: Colors.blue.shade600, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تقرير التحكيم المرفق',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        if (reviewer.attachedFileName != null)
                          Text(
                            reviewer.attachedFileName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _downloadFile(reviewer.attachedFileUrl!),
                    icon: Icon(Icons.download, size: 16),
                    label: Text('تحميل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size(0, 32),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getRecommendationColor(String recommendation) {
    switch (recommendation) {
      case 'accept':
        return Colors.green;
      case 'minor_revision':
        return Colors.blue;
      case 'major_revision':
        return Colors.orange;
      case 'reject':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRecommendationText(String recommendation) {
    switch (recommendation) {
      case 'accept':
        return 'قبول للنشر';
      case 'minor_revision':
        return 'تعديلات طفيفة';
      case 'major_revision':
        return 'تعديلات كبيرة';
      case 'reject':
        return 'رفض النشر';
      default:
        return 'غير محدد';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _downloadFile(String fileUrl) {
    // Implement file download logic
    if (kIsWeb) {
      html.window.open(fileUrl, '_blank');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
