// pages/Stage2/Stage2DocumentsPage.dart - Updated with proper Stage1 to Stage2 flow
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qiraat/stage2/stage2HeadEditor.dart';
import 'package:qiraat/stage2/stage2Reviewer.dart';
import 'dart:ui' as ui;

import '../../Classes/current_user_providerr.dart';
import '../Screens/Document_Handling/DocumentDetails/Constants/App_Constants.dart';
import '../Screens/Document_Handling/DocumentDetails/Services/Document_Services.dart';
import '../Screens/Document_Handling/DocumentDetails/models/document_model.dart';
import '../Screens/Document_Handling/DocumentDetails/models/reviewerModel.dart';

class Stage2DocumentsPage extends StatefulWidget {
  @override
  _Stage2DocumentsPageState createState() => _Stage2DocumentsPageState();
}

class _Stage2DocumentsPageState extends State<Stage2DocumentsPage>
    with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();

  List<DocumentModel> _allDocuments = [];
  List<DocumentModel> _filteredDocuments = [];
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isLoading = true;

  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPosition;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Stream subscription for real-time updates
  Stream<List<DocumentModel>>? _documentsStream;

  final List<Map<String, dynamic>> _filterOptions = [
    {'key': 'all', 'title': 'جميع المقالات', 'icon': Icons.all_inclusive},
    {
      'key': 'ready_for_assignment',
      'title': 'جاهز لتعيين المحكمين',
      'icon': Icons.assignment_ind
    },
    {'key': 'under_review', 'title': 'تحت التحكيم', 'icon': Icons.rate_review},
    {
      'key': 'review_completed',
      'title': 'انتهى التحكيم',
      'icon': Icons.check_circle
    },
    {
      'key': 'head_review',
      'title': 'مراجعة رئيس التحرير',
      'icon': Icons.admin_panel_settings
    },
    {'key': 'my_reviews', 'title': 'مراجعاتي', 'icon': Icons.person},
    {'key': 'completed', 'title': 'مكتملة', 'icon': Icons.verified},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentUserInfo();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
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
      _initializeDocumentsStream();
    }
  }

  void _initializeDocumentsStream() {
    if (_isHeadEditor()) {
      // Head editor sees all Stage 2 documents AND Stage 1 approved documents
      _documentsStream = _documentService.getStage2DocumentsStream();
    } else if (_isReviewer()) {
      // Reviewers see all Stage 2 documents but with different permissions
      _documentsStream = _documentService.getStage2DocumentsStream();
    } else {
      // Other users see Stage 2 documents they have access to
      _documentsStream = _documentService.getStage2DocumentsStream();
    }

    _documentsStream!.listen((documents) {
      if (mounted) {
        setState(() {
          _allDocuments = documents;
          _applyFilters();
          _isLoading = false;
        });
      }
    });
  }

  bool _isHeadEditor() {
    return _currentUserPosition == AppConstants.POSITION_HEAD_EDITOR;
  }

  bool _isReviewer() {
    return _currentUserPosition?.contains('محكم') == true ||
        _currentUserPosition == AppConstants.POSITION_REVIEWER;
  }

  void _applyFilters() {
    if (_allDocuments.isEmpty) {
      _filteredDocuments = [];
      return;
    }

    List<DocumentModel> filtered = List.from(_allDocuments);

    // Apply status filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((doc) {
        switch (_selectedFilter) {
          case 'ready_for_assignment':
            // THIS IS THE KEY CHANGE: Include STAGE1_APPROVED documents here
            return doc.status == AppConstants.STAGE1_APPROVED;
          case 'under_review':
            return [
              AppConstants.REVIEWERS_ASSIGNED,
              AppConstants.UNDER_PEER_REVIEW,
            ].contains(doc.status);
          case 'review_completed':
            return doc.status == AppConstants.PEER_REVIEW_COMPLETED;
          case 'head_review':
            return doc.status == AppConstants.HEAD_REVIEW_STAGE2;
          case 'my_reviews':
            // Show only documents where current user is assigned as reviewer
            return _isReviewer() &&
                doc.reviewers.isNotEmpty &&
                doc.reviewers
                    .any((reviewer) => reviewer.userId == _currentUserId);
          case 'completed':
            return [
              AppConstants.STAGE2_APPROVED,
              AppConstants.STAGE2_REJECTED,
              AppConstants.STAGE2_EDIT_REQUESTED,
              AppConstants.STAGE2_WEBSITE_APPROVED,
            ].contains(doc.status);
          default:
            return true;
        }
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        return doc.fullName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            doc.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            AppStyles.getStatusDisplayName(doc.status)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by priority: Stage1_approved documents first (highest priority for head editor)
    filtered.sort((a, b) {
      // Stage1_approved documents get highest priority
      if (a.status == AppConstants.STAGE1_APPROVED &&
          b.status != AppConstants.STAGE1_APPROVED) return -1;
      if (b.status == AppConstants.STAGE1_APPROVED &&
          a.status != AppConstants.STAGE1_APPROVED) return 1;

      // Then sort by timestamp (newest first)
      return b.timestamp.compareTo(a.timestamp);
    });

    setState(() {
      _filteredDocuments = filtered;
    });
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
              _buildFiltersSection(),
              Expanded(child: _buildDocumentsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 50, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isReviewer()
              ? [Colors.teal.shade600, Colors.teal.shade800]
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
                  _isReviewer()
                      ? Icons.rate_review
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
                      'المرحلة الثانية',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isReviewer()
                          ? 'التحكيم العلمي والمراجعة المتخصصة'
                          : 'إدارة التحكيم العلمي والمراجعة',
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
                  '${_filteredDocuments.length} مقال',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildStage2OverviewStats(),
        ],
      ),
    );
  }

  Widget _buildStage2OverviewStats() {
    if (_allDocuments.isEmpty) return SizedBox.shrink();

    // Count documents by status with special attention to STAGE1_APPROVED
    final readyForAssignment = _allDocuments
        .where((doc) => doc.status == AppConstants.STAGE1_APPROVED)
        .length;
    final underReview = _allDocuments
        .where((doc) => [
              AppConstants.REVIEWERS_ASSIGNED,
              AppConstants.UNDER_PEER_REVIEW
            ].contains(doc.status))
        .length;
    final reviewCompleted = _allDocuments
        .where((doc) => doc.status == AppConstants.PEER_REVIEW_COMPLETED)
        .length;
    final headReview = _allDocuments
        .where((doc) => doc.status == AppConstants.HEAD_REVIEW_STAGE2)
        .length;

    final myReviews = _isReviewer()
        ? _allDocuments
            .where((doc) =>
                doc.reviewers.isNotEmpty &&
                doc.reviewers
                    .any((reviewer) => reviewer.userId == _currentUserId))
            .length
        : 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          if (_isHeadEditor()) ...[
            Expanded(
              child: _buildStatItem(
                'جاهز للتعيين',
                readyForAssignment.toString(),
                Icons.assignment_ind,
                Colors.white,
                subtitle: 'من المرحلة الأولى',
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'تحت التحكيم',
                underReview.toString(),
                Icons.rate_review,
                Colors.white,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'جاهز للقرار',
                (reviewCompleted + headReview).toString(),
                Icons.check_circle,
                Colors.white,
              ),
            ),
          ] else if (_isReviewer()) ...[
            Expanded(
              child: _buildStatItem(
                'مراجعاتي',
                myReviews.toString(),
                Icons.person,
                Colors.white,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'قيد المراجعة',
                underReview.toString(),
                Icons.rate_review,
                Colors.white,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'مكتملة',
                reviewCompleted.toString(),
                Icons.check_circle,
                Colors.white,
              ),
            ),
          ] else ...[
            Expanded(
              child: _buildStatItem(
                'المجموع',
                _allDocuments.length.toString(),
                Icons.library_books,
                Colors.white,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'نشطة',
                (readyForAssignment +
                        underReview +
                        reviewCompleted +
                        headReview)
                    .toString(),
                Icons.trending_up,
                Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
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
        if (subtitle != null) ...[
          SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildFiltersSection() {
    // Filter available options based on user role
    List<Map<String, dynamic>> availableFilters =
        _filterOptions.where((filter) {
      if (filter['key'] == 'my_reviews') {
        return _isReviewer();
      }
      return true;
    }).toList();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                hintText: 'البحث في المقالات...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          SizedBox(height: 10),

          // Filter Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableFilters.map((filter) {
                final isSelected = _selectedFilter == filter['key'];
                final color = _isReviewer() ? Colors.teal : Colors.indigo;

                // Special styling for 'ready_for_assignment' when it has Stage1_approved documents
                bool hasReadyDocuments = filter['key'] ==
                        'ready_for_assignment' &&
                    _allDocuments.any(
                        (doc) => doc.status == AppConstants.STAGE1_APPROVED);

                return Container(
                  margin: EdgeInsets.only(left: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter['key'];
                        _applyFilters();
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: BoxConstraints(minWidth: 90),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [color.shade600, color.shade800],
                              )
                            : LinearGradient(
                                colors: [Colors.white, Colors.white],
                              ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? color.shade600
                              : (hasReadyDocuments
                                  ? Colors.green
                                  : Colors.grey.shade300),
                          width: hasReadyDocuments ? 2 : 1.5,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.shade600.withOpacity(0.2),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          if (hasReadyDocuments && !isSelected)
                            BoxShadow(
                              color: Colors.green.withOpacity(0.2),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            filter['icon'],
                            color: isSelected
                                ? Colors.white
                                : (hasReadyDocuments
                                    ? Colors.green
                                    : color.shade600),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              filter['title'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (hasReadyDocuments
                                        ? Colors.green
                                        : color.shade600),
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Show notification dot for ready documents
                          if (hasReadyDocuments && !isSelected) ...[
                            SizedBox(width: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color:
                  _isReviewer() ? Colors.teal.shade600 : Colors.indigo.shade600,
            ),
            SizedBox(height: 20),
            Text(
              'جاري تحميل المستندات...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredDocuments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredDocuments.length,
      itemBuilder: (context, index) {
        final document = _filteredDocuments[index];
        return _buildDocumentCard(document, index);
      },
    );
  }

  Widget _buildEmptyState() {
    String emptyMessage = _selectedFilter == 'ready_for_assignment'
        ? 'لا توجد مقالات جاهزة لتعيين المحكمين'
        : _selectedFilter == 'my_reviews'
            ? 'لا توجد مراجعات مخصصة لك'
            : 'لا توجد مستندات للتحكيم';

    String emptyDescription = _selectedFilter == 'ready_for_assignment'
        ? 'لم تصل أي مقالات معتمدة من المرحلة الأولى بعد'
        : _selectedFilter == 'my_reviews'
            ? 'لم يتم تعيين أي مقالات لك للمراجعة حتى الآن'
            : 'لم يتم العثور على مستندات تطابق المعايير المحددة';

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
              _selectedFilter == 'ready_for_assignment'
                  ? Icons.assignment_ind_outlined
                  : Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),
          Text(
            emptyMessage,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            emptyDescription,
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

  Widget _buildDocumentCard(DocumentModel document, int index) {
    final statusColor = AppStyles.getStage2StatusColor(document.status);
    final statusIcon = AppStyles.getStage2StatusIcon(document.status);
    final statusName = AppStyles.getStatusDisplayName(document.status);

    // Check if current user is assigned as reviewer
    final isAssignedReviewer = _isReviewer() &&
        document.reviewers.isNotEmpty &&
        document.reviewers.any((reviewer) => reviewer.userId == _currentUserId);

    // Get current user's review status if they are a reviewer
    ReviewerModel? currentUserReview;
    if (isAssignedReviewer) {
      currentUserReview = document.reviewers.firstWhere(
        (reviewer) => reviewer.userId == _currentUserId,
      );
    }

    // Special highlighting for Stage1_approved documents
    bool isReadyForAssignment = document.status == AppConstants.STAGE1_APPROVED;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isReadyForAssignment
              ? Colors.green.withOpacity(0.5)
              : statusColor.withOpacity(0.2),
          width: isReadyForAssignment ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToDetailsPage(document),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and special badge for ready documents
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              statusName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            if (isReadyForAssignment) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'جديد',
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
                          _getStageDescription(document.status),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(document.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Document info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.fullName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2d3748),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          document.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(0.1),
                          statusColor.withOpacity(0.05)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      'المرحلة 2',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Reviewers info or user's review status
              if (isAssignedReviewer && currentUserReview != null)
                _buildUserReviewStatus(currentUserReview!)
              else if (document.reviewers.isNotEmpty)
                _buildReviewersInfo(document)
              else if (isReadyForAssignment)
                _buildReadyForAssignmentInfo(),

              SizedBox(height: 16),

              // Progress indicator for Stage 2
              _buildStage2ProgressIndicator(document.status),

              SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToDetailsPage(document),
                      icon: Icon(_getActionIcon(document), size: 18),
                      label: Text(_getActionText(document)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isReadyForAssignment ? Colors.green : statusColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => _showQuickActions(document),
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadyForAssignmentInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.new_releases, color: Colors.green.shade600, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'معتمد من المرحلة الأولى - جاهز لتعيين المحكمين',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserReviewStatus(ReviewerModel reviewerInfo) {
    Color statusColor = _getReviewStatusColor(reviewerInfo.reviewStatus);
    String statusText = _getReviewStatusDisplayName(reviewerInfo.reviewStatus);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: statusColor, size: 16),
          SizedBox(width: 8),
          Text(
            'حالة مراجعتي: $statusText',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          Spacer(),
          if (reviewerInfo.assignedDate != null)
            Text(
              'منذ ${DateTime.now().difference(reviewerInfo.assignedDate!).inDays} أيام',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewersInfo(DocumentModel document) {
    final completedReviews = document.reviewers
        .where((reviewer) => reviewer.reviewStatus == 'Completed')
        .length;
    final totalReviewers = document.reviewers.length;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.indigo.shade100],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.people, color: Colors.indigo.shade600, size: 16),
          SizedBox(width: 8),
          Text(
            'المحكمون: $completedReviews/$totalReviewers',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: totalReviewers > 0 ? completedReviews / totalReviewers : 0,
              backgroundColor: Colors.indigo.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage2ProgressIndicator(String status) {
    final steps = ['ready', 'assigned', 'reviewing', 'completed', 'approved'];
    int currentStep = _getStage2StepIndex(status);

    return Row(
      children: List.generate(steps.length, (index) {
        bool isCompleted = index < currentStep;
        bool isCurrent = index == currentStep;

        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isCompleted || isCurrent
                  ? Colors.indigo.shade600
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  int _getStage2StepIndex(String status) {
    if ([AppConstants.STAGE1_APPROVED].contains(status)) return 0;
    if ([AppConstants.REVIEWERS_ASSIGNED].contains(status)) return 1;
    if ([AppConstants.UNDER_PEER_REVIEW].contains(status)) return 2;
    if ([AppConstants.PEER_REVIEW_COMPLETED, AppConstants.HEAD_REVIEW_STAGE2]
        .contains(status)) return 3;
    if ([
      AppConstants.STAGE2_APPROVED,
      AppConstants.STAGE2_REJECTED,
      AppConstants.STAGE2_EDIT_REQUESTED,
      AppConstants.STAGE2_WEBSITE_APPROVED
    ].contains(status)) return 4;
    return 0;
  }

  String _getStageDescription(String status) {
    if ([AppConstants.STAGE1_APPROVED].contains(status)) {
      return 'جاهز لتعيين المحكمين';
    } else if ([AppConstants.REVIEWERS_ASSIGNED, AppConstants.UNDER_PEER_REVIEW]
        .contains(status)) {
      return 'تحت التحكيم العلمي';
    } else if ([
      AppConstants.PEER_REVIEW_COMPLETED,
      AppConstants.HEAD_REVIEW_STAGE2
    ].contains(status)) {
      return 'مراجعة نتائج التحكيم';
    } else {
      return 'مكتملة';
    }
  }

  IconData _getActionIcon(DocumentModel document) {
    if (document.status == AppConstants.STAGE1_APPROVED) {
      return Icons.assignment_ind; // Assign reviewers icon
    }

    if (_isReviewer() &&
        document.reviewers.isNotEmpty &&
        document.reviewers
            .any((reviewer) => reviewer.userId == _currentUserId)) {
      final userReviewer = document.reviewers.firstWhere(
        (reviewer) => reviewer.userId == _currentUserId,
      );
      switch (userReviewer.reviewStatus) {
        case 'Pending':
          return Icons.play_arrow;
        case 'In Progress':
          return Icons.edit;
        case 'Completed':
          return Icons.visibility;
        default:
          return Icons.visibility;
      }
    }
    return Icons.visibility;
  }

  String _getActionText(DocumentModel document) {
    if (document.status == AppConstants.STAGE1_APPROVED) {
      return 'تعيين المحكمين';
    }

    if (_isReviewer() &&
        document.reviewers.isNotEmpty &&
        document.reviewers
            .any((reviewer) => reviewer.userId == _currentUserId)) {
      final userReviewer = document.reviewers.firstWhere(
        (reviewer) => reviewer.userId == _currentUserId,
      );
      switch (userReviewer.reviewStatus) {
        case 'Pending':
          return 'بدء المراجعة';
        case 'In Progress':
          return 'إكمال المراجعة';
        case 'Completed':
          return 'عرض المراجعة';
        default:
          return 'عرض التفاصيل';
      }
    }
    return 'عرض التفاصيل';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _navigateToDetailsPage(DocumentModel document) {
    Widget page;

    // Determine which detail page to navigate to based on user role and document status
    if (_isHeadEditor() ||
        [
          AppConstants.STAGE1_APPROVED,
          AppConstants.REVIEWERS_ASSIGNED,
          AppConstants.PEER_REVIEW_COMPLETED,
          AppConstants.HEAD_REVIEW_STAGE2
        ].contains(document.status)) {
      page = Stage2HeadEditorDetailsPage(document: document);
    } else {
      // For reviewers or when viewing review details
      page = Stage2ReviewerDetailsPage(document: document);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    ).then((_) {
      // Refresh the page when returning
      _applyFilters();
    });
  }

  void _showQuickActions(DocumentModel document) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.visibility, color: Colors.indigo.shade600),
              title: Text('عرض التفاصيل'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetailsPage(document);
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.blue),
              title: Text('سجل التحكيم'),
              onTap: () {
                Navigator.pop(context);
                _showReviewHistory(document);
              },
            ),
            if (document.reviewers.isNotEmpty)
              ListTile(
                leading: Icon(Icons.people, color: Colors.green),
                title: Text('المحكمون'),
                onTap: () {
                  Navigator.pop(context);
                  _showReviewersDialog(document);
                },
              ),
            if (document.status == AppConstants.STAGE1_APPROVED &&
                _isHeadEditor())
              ListTile(
                leading: Icon(Icons.assignment_ind, color: Colors.orange),
                title: Text('تعيين المحكمين'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToDetailsPage(document);
                },
              ),
            ListTile(
              leading: Icon(Icons.download, color: Colors.orange),
              title: Text('تحميل الملف'),
              onTap: () {
                Navigator.pop(context);
                // Implement file download
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('سيتم إضافة تحميل الملفات قريباً')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewHistory(DocumentModel document) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text('سجل التحكيم'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: document.actionLog.length,
              itemBuilder: (context, index) {
                final action = document.actionLog[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.history, color: Colors.blue.shade600),
                  ),
                  title: Text(action.action),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${action.userName} - ${action.userPosition}'),
                      if (action.comment != null && action.comment!.isNotEmpty)
                        Text(action.comment!,
                            style: TextStyle(fontStyle: FontStyle.italic)),
                      Text(_formatDate(action.timestamp)),
                    ],
                  ),
                );
              },
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

  void _showReviewersDialog(DocumentModel document) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text('المحكمون المعينون'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: document.reviewers.length,
              itemBuilder: (context, index) {
                final reviewer = document.reviewers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _getReviewStatusColor(reviewer.reviewStatus),
                    child: Text(
                      reviewer.name[0],
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(reviewer.name),
                  subtitle: Text(reviewer.position),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getReviewStatusColor(reviewer.reviewStatus),
                      borderRadius: BorderRadius.circular(12),
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
                );
              },
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
}
