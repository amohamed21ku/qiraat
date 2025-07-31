// pages/Tasks/Stage2HeadEditorTasksPage.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import '../../Classes/current_user_providerr.dart';
import '../Screens/Document_Handling/DocumentDetails/Constants/App_Constants.dart';
import '../Screens/Document_Handling/DocumentDetails/Services/Document_Services.dart';
import '../Screens/Document_Handling/DocumentDetails/models/document_model.dart';

class Stage2HeadEditorTasksPage extends StatefulWidget {
  @override
  _Stage2HeadEditorTasksPageState createState() =>
      _Stage2HeadEditorTasksPageState();
}

class _Stage2HeadEditorTasksPageState extends State<Stage2HeadEditorTasksPage>
    with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();

  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPosition;

  Map<String, List<DocumentModel>> _categorizedDocuments = {};
  bool _isLoading = true;

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
    if (_currentUserPosition != AppConstants.POSITION_HEAD_EDITOR) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final allDocuments = await _documentService.getAllStage2Documents();

      final categorized = <String, List<DocumentModel>>{
        'ready_for_assignment': [],
        'in_progress': [],
        'ready_for_decision': [],
        'overdue': [],
      };

      final now = DateTime.now();

      for (final document in allDocuments) {
        switch (document.status) {
          case AppConstants.STAGE1_APPROVED:
            categorized['ready_for_assignment']!.add(document);
            break;
          case AppConstants.REVIEWERS_ASSIGNED:
          case AppConstants.UNDER_PEER_REVIEW:
            // Check if overdue (more than 14 days in review)
            final assignedDate = _getAssignedDate(document);
            if (assignedDate != null &&
                now.difference(assignedDate).inDays > 14) {
              categorized['overdue']!.add(document);
            } else {
              categorized['in_progress']!.add(document);
            }
            break;
          case AppConstants.PEER_REVIEW_COMPLETED:
          case AppConstants.HEAD_REVIEW_STAGE2:
            categorized['ready_for_decision']!.add(document);
            break;
        }
      }

      setState(() {
        _categorizedDocuments = categorized;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tasks: $e');
      setState(() => _isLoading = false);
    }
  }

  DateTime? _getAssignedDate(DocumentModel document) {
    final assignedAction = document.actionLog
        .where((action) => action.action == 'تعيين المحكمين')
        .lastOrNull;
    return assignedAction?.timestamp;
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
          colors: [Colors.indigo.shade600, Colors.indigo.shade800],
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
                      'مهام التحكيم العلمي',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'إدارة عملية التحكيم والمراجعة العلمية',
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
          _buildTasksSummary(),
        ],
      ),
    );
  }

  Widget _buildTasksSummary() {
    final totalTasks = _categorizedDocuments.values
        .fold<int>(0, (sum, list) => sum + list.length);
    final urgentTasks = _categorizedDocuments['overdue']?.length ?? 0;
    final readyForDecision =
        _categorizedDocuments['ready_for_decision']?.length ?? 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'المجموع',
              totalTasks.toString(),
              Icons.assignment,
              Colors.white,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildSummaryItem(
              'عاجل',
              urgentTasks.toString(),
              Icons.warning,
              urgentTasks > 0 ? Colors.orange.shade200 : Colors.white,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildSummaryItem(
              'جاهز للقرار',
              readyForDecision.toString(),
              Icons.check_circle,
              readyForDecision > 0 ? Colors.green.shade200 : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
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
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.indigo.shade600),
          SizedBox(height: 20),
          Text(
            'جاري تحميل المهام...',
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
    if (_currentUserPosition != AppConstants.POSITION_HEAD_EDITOR) {
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
            // Urgent Tasks
            if (_categorizedDocuments['overdue']?.isNotEmpty ?? false)
              _buildTaskCategory(
                'المهام العاجلة',
                'تتطلب انتباهاً فورياً',
                _categorizedDocuments['overdue']!,
                Colors.red,
                Icons.warning,
                true,
              ),

            // Ready for Decision
            if (_categorizedDocuments['ready_for_decision']?.isNotEmpty ??
                false)
              _buildTaskCategory(
                'جاهز للقرار النهائي',
                'مقالات أنهى المحكمون مراجعتها',
                _categorizedDocuments['ready_for_decision']!,
                Colors.green,
                Icons.check_circle,
                false,
              ),

            // Ready for Assignment
            if (_categorizedDocuments['ready_for_assignment']?.isNotEmpty ??
                false)
              _buildTaskCategory(
                'جاهز لتعيين المحكمين',
                'مقالات معتمدة من المرحلة الأولى',
                _categorizedDocuments['ready_for_assignment']!,
                Colors.blue,
                Icons.assignment_ind,
                false,
              ),

            // In Progress
            if (_categorizedDocuments['in_progress']?.isNotEmpty ?? false)
              _buildTaskCategory(
                'قيد التحكيم',
                'المحكمون يراجعون هذه المقالات',
                _categorizedDocuments['in_progress']!,
                Colors.orange,
                Icons.rate_review,
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
                  .map((document) => _buildTaskItem(document, color, isUrgent))
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

  Widget _buildTaskItem(DocumentModel document, Color color, bool isUrgent) {
    final daysInStatus = DateTime.now().difference(document.timestamp).inDays;

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
        onTap: () => _navigateToDocument(document),
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
                    AppStyles.getStatusDisplayName(document.status),
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (document.reviewers.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      'المحكمون: ${_getReviewersStatus(document)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
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
                Text(
                  'منذ ${daysInStatus} أيام',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
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

  String _getReviewersStatus(DocumentModel document) {
    final completed =
        document.reviewers.where((r) => r.reviewStatus == 'Completed').length;
    final total = document.reviewers.length;
    return '$completed/$total';
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
            'هذه الصفحة مخصصة لرئيس التحرير فقط',
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
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'لا توجد مهام حالياً',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'جميع المقالات في المرحلة الثانية تحت السيطرة',
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

  void _navigateToDocument(DocumentModel document) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => Stage2HeadEditorDetailsPage(document: document),
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
                  return _buildTaskItem(documents[index], color, false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
