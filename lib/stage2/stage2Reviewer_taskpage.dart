// pages/Tasks/Stage2ReviewerTasksPage.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import '../../Classes/current_user_providerr.dart';
import '../Screens/Document_Handling/DocumentDetails/Constants/App_Constants.dart';
import '../Screens/Document_Handling/DocumentDetails/Services/Document_Services.dart';
import '../Screens/Document_Handling/DocumentDetails/models/document_model.dart';
import '../Screens/Document_Handling/DocumentDetails/models/reviewerModel.dart';

class Stage2ReviewerTasksPage extends StatefulWidget {
  @override
  _Stage2ReviewerTasksPageState createState() =>
      _Stage2ReviewerTasksPageState();
}

class _Stage2ReviewerTasksPageState extends State<Stage2ReviewerTasksPage>
    with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();

  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPosition;

  Map<String, List<DocumentModel>> _categorizedDocuments = {};
  bool _isLoading = true;
  Map<String, dynamic> _reviewerStats = {};

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentUserInfo();
    _loadTasks();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
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
    }
  }

  Future<void> _loadTasks() async {
    if (!_isReviewer()) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final allDocuments = await _documentService.getAllStage2Documents();

      // Filter documents where current user is a reviewer
      final myDocuments = allDocuments.where((document) {
        return document.reviewers
            .any((reviewer) => reviewer.userId == _currentUserId);
      }).toList();

      final categorized = <String, List<DocumentModel>>{
        'pending': [],
        'in_progress': [],
        'completed': [],
        'overdue': [],
      };

      final now = DateTime.now();
      int totalReviews = 0;
      int completedReviews = 0;
      int averageRating = 0;
      List<int> ratings = [];

      for (final document in myDocuments) {
        final myReviewerInfo = document.reviewers.firstWhere(
          (reviewer) => reviewer.userId == _currentUserId,
        );

        totalReviews++;

        switch (myReviewerInfo.reviewStatus) {
          case 'Pending':
            // Check if overdue (more than 7 days)
            if (myReviewerInfo.assignedDate != null &&
                now.difference(myReviewerInfo.assignedDate!).inDays > 7) {
              categorized['overdue']!.add(document);
            } else {
              categorized['pending']!.add(document);
            }
            break;
          case 'In Progress':
            // Check if overdue (more than 14 days total)
            if (myReviewerInfo.assignedDate != null &&
                now.difference(myReviewerInfo.assignedDate!).inDays > 14) {
              categorized['overdue']!.add(document);
            } else {
              categorized['in_progress']!.add(document);
            }
            break;
          case 'Completed':
            categorized['completed']!.add(document);
            completedReviews++;
            // Extract rating if available (you might need to adjust based on your data structure)
            // This assumes rating is stored in the reviewer's comment or additional data
            break;
        }
      }

      // Calculate stats
      final stats = {
        'total': totalReviews,
        'completed': completedReviews,
        'pending': categorized['pending']!.length,
        'overdue': categorized['overdue']!.length,
        'completion_rate': totalReviews > 0
            ? (completedReviews / totalReviews * 100).round()
            : 0,
        'average_days': _calculateAverageReviewTime(myDocuments),
      };

      setState(() {
        _categorizedDocuments = categorized;
        _reviewerStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reviewer tasks: $e');
      setState(() => _isLoading = false);
    }
  }

  bool _isReviewer() {
    return _currentUserPosition?.contains('محكم') == true ||
        _currentUserPosition == AppConstants.POSITION_REVIEWER;
  }

  int _calculateAverageReviewTime(List<DocumentModel> documents) {
    final completedReviews = documents.where((doc) {
      final myReviewer = doc.reviewers.firstWhere(
        (r) => r.userId == _currentUserId,
        orElse: () => ReviewerModel(
          userId: '',
          name: '',
          email: '',
          position: '',
          reviewStatus: 'Pending',
          assignedDate: null,
        ),
      );
      return myReviewer.reviewStatus == 'Completed';
    }).toList();

    if (completedReviews.isEmpty) return 0;

    int totalDays = 0;
    for (final doc in completedReviews) {
      final reviewer =
          doc.reviewers.firstWhere((r) => r.userId == _currentUserId);
      if (reviewer.assignedDate != null) {
        // You might need to add a completedDate field to track this properly
        totalDays += DateTime.now().difference(reviewer.assignedDate!).inDays;
      }
    }

    return (totalDays / completedReviews.length).round();
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
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading ? _buildLoadingState() : _buildTasksContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade800],
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
                      'مهام التحكيم الخاصة بي',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'المقالات المعينة لك للمراجعة والتحكيم',
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
          _buildReviewerStats(),
        ],
      ),
    );
  }

  Widget _buildReviewerStats() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'إجمالي المهام',
                  '${_reviewerStats['total'] ?? 0}',
                  Icons.assignment,
                  Colors.white,
                ),
              ),
              Container(
                  width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              Expanded(
                child: _buildStatItem(
                  'مكتملة',
                  '${_reviewerStats['completed'] ?? 0}',
                  Icons.check_circle,
                  Colors.white,
                ),
              ),
              Container(
                  width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              Expanded(
                child: _buildStatItem(
                  'متأخرة',
                  '${_reviewerStats['overdue'] ?? 0}',
                  Icons.warning,
                  (_reviewerStats['overdue'] ?? 0) > 0
                      ? Colors.orange.shade200
                      : Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'معدل الإنجاز',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_reviewerStats['completion_rate'] ?? 0}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'متوسط وقت المراجعة',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_reviewerStats['average_days'] ?? 0} أيام',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.teal.shade600),
          SizedBox(height: 20),
          Text(
            'جاري تحميل مهام التحكيم...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksContent() {
    if (!_isReviewer()) {
      return _buildUnauthorizedView();
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overdue Tasks
            if (_categorizedDocuments['overdue']?.isNotEmpty ?? false)
              _buildTaskCategory(
                'مهام متأخرة',
                'تحتاج إلى انتباه فوري',
                _categorizedDocuments['overdue']!,
                Colors.red,
                Icons.warning,
                true,
              ),

            // Pending Tasks
            if (_categorizedDocuments['pending']?.isNotEmpty ?? false)
              _buildTaskCategory(
                'مهام في الانتظار',
                'مقالات جديدة للمراجعة',
                _categorizedDocuments['pending']!,
                Colors.blue,
                Icons.hourglass_top,
                false,
              ),

            // In Progress Tasks
            if (_categorizedDocuments['in_progress']?.isNotEmpty ?? false)
              _buildTaskCategory(
                'قيد المراجعة',
                'مراجعات بدأت ولم تكتمل',
                _categorizedDocuments['in_progress']!,
                Colors.orange,
                Icons.rate_review,
                false,
              ),

            // Completed Tasks
            if (_categorizedDocuments['completed']?.isNotEmpty ?? false)
              _buildTaskCategory(
                'مراجعات مكتملة',
                'المقالات التي أنهيت مراجعتها',
                _categorizedDocuments['completed']!,
                Colors.green,
                Icons.check_circle,
                false,
              ),

            // Empty state
            if (_categorizedDocuments.values.every((list) => list.isEmpty))
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCategory(
    String title,
    String subtitle,
    List<DocumentModel> documents,
    Color color,
    IconData icon,
    bool isUrgent,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
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
        border: isUrgent ? Border.all(color: color, width: 2) : null,
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
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
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (isUrgent) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'عاجل',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${documents.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Document List
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: documents
                  .take(3)
                  .map((document) =>
                      _buildReviewTaskItem(document, color, isUrgent))
                  .toList(),
            ),
          ),

          // Show More Button
          if (documents.length > 3)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextButton(
                onPressed: () => _showAllDocuments(title, documents, color),
                child: Text(
                  'عرض جميع المقالات (${documents.length})',
                  style: TextStyle(color: color),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewTaskItem(
      DocumentModel document, Color color, bool isUrgent) {
    final myReviewer = document.reviewers.firstWhere(
      (reviewer) => reviewer.userId == _currentUserId,
    );

    final daysAssigned = myReviewer.assignedDate != null
        ? DateTime.now().difference(myReviewer.assignedDate!).inDays
        : 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => _navigateToReview(document),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color,
              child: Text(
                document.fullName[0],
                style: TextStyle(
                  color: Colors.white,
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
                    document.fullName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2d3748),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getReviewStatusDisplayName(myReviewer.reviewStatus),
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'تم التعيين منذ $daysAssigned أيام',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isUrgent)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'متأخر',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getReviewPriorityColor(myReviewer.reviewStatus),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getReviewPriorityText(myReviewer.reviewStatus),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: color.withOpacity(0.7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  Color _getReviewPriorityColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.blue;
      case 'In Progress':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getReviewPriorityText(String status) {
    switch (status) {
      case 'Pending':
        return 'ابدأ الآن';
      case 'In Progress':
        return 'أكمل';
      case 'Completed':
        return 'مراجعة';
      default:
        return 'عرض';
    }
  }

  Widget _buildUnauthorizedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'غير مخول',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'هذه الصفحة مخصصة للمحكمين فقط',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'لا توجد مهام تحكيم',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'لم يتم تعيين أي مقالات لك للمراجعة حتى الآن',
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

  void _navigateToReview(DocumentModel document) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => Stage2ReviewerDetailsPage(document: document),
    //   ),
    // ).then((_) => _loadTasks()); // Refresh tasks when returning
  }

  void _showAllDocuments(
      String title, List<DocumentModel> documents, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
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
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  return _buildReviewTaskItem(documents[index], color, false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
