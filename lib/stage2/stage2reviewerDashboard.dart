// stage2/Stage2ReviewerDashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qiraat/stage2/stage2Reviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

import '../../Classes/current_user_providerr.dart';
import '../Screens/Document_Handling/DocumentDetails/Services/Document_Services.dart';
import '../Screens/Document_Handling/DocumentDetails/Constants/App_Constants.dart';
import '../Screens/Document_Handling/DocumentDetails/models/document_model.dart';
import '../Screens/Document_Handling/DocumentDetails/models/reviewerModel.dart';

class Stage2ReviewerDashboard extends StatefulWidget {
  @override
  _Stage2ReviewerDashboardState createState() =>
      _Stage2ReviewerDashboardState();
}

class _Stage2ReviewerDashboardState extends State<Stage2ReviewerDashboard>
    with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();

  bool _isLoading = true;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPosition;
  List<DocumentModel> _assignedDocuments = [];
  Map<String, int> _statusCounts = {};

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
      await _loadAssignedDocuments();
    }
  }

  Future<void> _loadAssignedDocuments() async {
    setState(() => _isLoading = true);

    try {
      // Use the secure method to get only documents assigned to this reviewer
      final assignedDocs =
          await _documentService.getDocumentsForReviewer(_currentUserId!);

      // Calculate status counts
      Map<String, int> counts = {
        'pending': 0,
        'in_progress': 0,
        'completed': 0,
        'total': assignedDocs.length,
      };

      for (var doc in assignedDocs) {
        final reviewerData = doc.reviewers.firstWhere(
          (reviewer) => reviewer.userId == _currentUserId,
          orElse: () => ReviewerModel(
            userId: '',
            name: '',
            email: '',
            position: '',
            reviewStatus: AppConstants.REVIEWER_STATUS_PENDING,
            assignedDate: DateTime.now(),
          ),
        );

        switch (reviewerData.reviewStatus) {
          case AppConstants.REVIEWER_STATUS_PENDING:
            counts['pending'] = counts['pending']! + 1;
            break;
          case AppConstants.REVIEWER_STATUS_IN_PROGRESS:
            counts['in_progress'] = counts['in_progress']! + 1;
            break;
          case AppConstants.REVIEWER_STATUS_COMPLETED:
            counts['completed'] = counts['completed']! + 1;
            break;
        }
      }

      setState(() {
        _assignedDocuments = assignedDocs;
        _statusCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading assigned documents: $e');
      setState(() => _isLoading = false);
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
        backgroundColor: Color(0xfff8f9fa),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: _isLoading ? _buildLoadingState() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xff4299e1)),
          SizedBox(height: 20),
          Text(
            'جاري تحميل المهام المخصصة لك...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        _buildStatsCards(),
        Expanded(child: _buildDocumentsList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff4299e1), Color(0xff3182ce)],
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
                      'مرحباً، $_currentUserName',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'لوحة التحكيم العلمي - المرحلة الثانية',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentUserPosition ?? '',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'هذه هي المقالات المخصصة لك للتحكيم العلمي. يرجى مراجعة كل مقال بعناية وتقديم تقييمك المهني.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 14,
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

  Widget _buildStatsCards() {
    final stats = [
      {
        'title': 'المجموع',
        'count': _statusCounts['total'] ?? 0,
        'icon': Icons.assignment,
        'color': Color(0xff4299e1),
      },
      {
        'title': 'في الانتظار',
        'count': _statusCounts['pending'] ?? 0,
        'icon': Icons.hourglass_top,
        'color': Color(0xfff6ad55),
      },
      {
        'title': 'قيد المراجعة',
        'count': _statusCounts['in_progress'] ?? 0,
        'icon': Icons.rate_review,
        'color': Color(0xff4299e1),
      },
      {
        'title': 'مكتملة',
        'count': _statusCounts['completed'] ?? 0,
        'icon': Icons.check_circle,
        'color': Color(0xff48bb78),
      },
    ];

    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: stats
            .map((stat) => Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            stat['icon'] as IconData,
                            color: stat['color'] as Color,
                            size: 24,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '${stat['count']}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: stat['color'] as Color,
                          ),
                        ),
                        Text(
                          stat['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDocumentsList() {
    if (_assignedDocuments.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment, color: Color(0xff4299e1), size: 20),
              SizedBox(width: 8),
              Text(
                'المقالات المخصصة للتحكيم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2d3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _assignedDocuments.length,
              itemBuilder: (context, index) {
                final document = _assignedDocuments[index];
                final reviewerData = document.reviewers.firstWhere(
                  (reviewer) => reviewer.userId == _currentUserId,
                );
                return _buildDocumentCard(document, reviewerData);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(
      DocumentModel document, ReviewerModel reviewerData) {
    Color statusColor = _getStatusColor(reviewerData.reviewStatus);
    IconData statusIcon = _getStatusIcon(reviewerData.reviewStatus);
    String statusText = _getStatusText(reviewerData.reviewStatus);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () => _openDocumentForReview(document, reviewerData),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مقال رقم: ${document.id.substring(0, 8)}...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2d3748),
                          ),
                        ),
                        Text(
                          'تاريخ التعيين: ${_formatDate(reviewerData.assignedDate!)}',
                          style: TextStyle(
                            fontSize: 12,
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.grey.shade600, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'تاريخ الإرسال: ${_formatDate(document.timestamp)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Spacer(),
                    if (reviewerData.reviewStatus ==
                        AppConstants.REVIEWER_STATUS_PENDING)
                      Text(
                        'جديد',
                        style: TextStyle(
                          color: Color(0xfff6ad55),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getActionText(reviewerData.reviewStatus),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: statusColor,
                    size: 16,
                  ),
                ],
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
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Color(0xff4299e1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Color(0xff4299e1),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'لا توجد مقالات مخصصة للتحكيم',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff2d3748),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'لم يتم تعيين أي مقالات لك للتحكيم العلمي بعد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.REVIEWER_STATUS_PENDING:
        return Color(0xfff6ad55);
      case AppConstants.REVIEWER_STATUS_IN_PROGRESS:
        return Color(0xff4299e1);
      case AppConstants.REVIEWER_STATUS_COMPLETED:
        return Color(0xff48bb78);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.REVIEWER_STATUS_PENDING:
        return Icons.hourglass_top;
      case AppConstants.REVIEWER_STATUS_IN_PROGRESS:
        return Icons.rate_review;
      case AppConstants.REVIEWER_STATUS_COMPLETED:
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.REVIEWER_STATUS_PENDING:
        return 'في الانتظار';
      case AppConstants.REVIEWER_STATUS_IN_PROGRESS:
        return 'قيد المراجعة';
      case AppConstants.REVIEWER_STATUS_COMPLETED:
        return 'مكتمل';
      default:
        return 'غير محدد';
    }
  }

  String _getActionText(String status) {
    switch (status) {
      case AppConstants.REVIEWER_STATUS_PENDING:
        return 'ابدأ التحكيم';
      case AppConstants.REVIEWER_STATUS_IN_PROGRESS:
        return 'متابعة التحكيم';
      case AppConstants.REVIEWER_STATUS_COMPLETED:
        return 'عرض التحكيم';
      default:
        return 'عرض المقال';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _openDocumentForReview(
      DocumentModel document, ReviewerModel reviewerData) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => Stage2ReviewerDocumentPage(
    //       document: document,
    //       reviewerData: reviewerData,
    //       onReviewSubmitted: () => _loadAssignedDocuments(),
    //     ),
    //   ),
    // );
  }
}
