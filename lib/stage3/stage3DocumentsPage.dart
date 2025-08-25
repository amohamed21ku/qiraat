// pages/Stage3/Stage3DocumentsPage.dart - Stage 3 Production Workflow with Dual View
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qiraat/stage3/stage3FinalReviewerPage.dart';
import 'package:qiraat/stage3/stage3HeadEditorPage.dart';
import 'package:qiraat/stage3/stage3LayoutDesign.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import '../../Classes/current_user_providerr.dart';
import '../App_Constants.dart';
import '../Document_Services.dart';
import '../models/document_model.dart';
import 'Stage3ManagingEditor.dart';

class Stage3DocumentsPage extends StatefulWidget {
  @override
  _Stage3DocumentsPageState createState() => _Stage3DocumentsPageState();
}

class _Stage3DocumentsPageState extends State<Stage3DocumentsPage>
    with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();

  List<DocumentModel> _allDocuments = [];
  List<DocumentModel> _filteredDocuments = [];
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSpreadsheetView = true; // Default to table view

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
      'key': 'ready_for_layout',
      'title': 'جاهز للإخراج الفني',
      'icon': Icons.design_services
    },
    {'key': 'in_layout', 'title': 'في الإخراج الفني', 'icon': Icons.palette},
    {
      'key': 'layout_review',
      'title': 'مراجعة الإخراج',
      'icon': Icons.rate_review
    },
    {
      'key': 'final_review',
      'title': 'المراجعة النهائية',
      'icon': Icons.fact_check
    },
    {
      'key': 'final_modifications',
      'title': 'التعديلات النهائية',
      'icon': Icons.edit
    },
    {
      'key': 'final_approval',
      'title': 'الاعتماد النهائي',
      'icon': Icons.verified_user
    },
    {'key': 'published', 'title': 'منشور', 'icon': Icons.publish},
    {'key': 'my_tasks', 'title': 'مهامي', 'icon': Icons.person},
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
    _documentsStream = _documentService.getStage3DocumentsStream();

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

  bool _isLayoutDesigner() {
    return _currentUserPosition == AppConstants.POSITION_LAYOUT_DESIGNER;
  }

  bool _isFinalReviewer() {
    return _currentUserPosition == AppConstants.POSITION_FINAL_REVIEWER;
  }

  bool _isHeadEditor() {
    return _currentUserPosition == AppConstants.POSITION_HEAD_EDITOR;
  }

  bool _isManagingEditor() {
    return _currentUserPosition == AppConstants.POSITION_MANAGING_EDITOR;
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
          case 'ready_for_layout':
            return doc.status == AppConstants.STAGE2_APPROVED;
          case 'in_layout':
            return [
              AppConstants.LAYOUT_DESIGN_STAGE3,
              AppConstants.LAYOUT_REVISION_REQUESTED,
            ].contains(doc.status);
          case 'layout_review':
            return [
              AppConstants.LAYOUT_DESIGN_COMPLETED,
              AppConstants.MANAGING_EDITOR_REVIEW_LAYOUT,
              AppConstants.HEAD_EDITOR_FIRST_REVIEW,
            ].contains(doc.status);
          case 'final_review':
            return doc.status == AppConstants.FINAL_REVIEW_STAGE;
          case 'final_modifications':
            return [
              AppConstants.FINAL_REVIEW_COMPLETED,
              AppConstants.FINAL_MODIFICATIONS,
            ].contains(doc.status);
          case 'final_approval':
            return [
              AppConstants.MANAGING_EDITOR_FINAL_CHECK,
              AppConstants.HEAD_EDITOR_FINAL_APPROVAL,
            ].contains(doc.status);
          case 'published':
            return doc.status == AppConstants.PUBLISHED;
          case 'my_tasks':
            return _getMyTasks().contains(doc.status);
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

    // Sort by priority based on user role
    filtered.sort((a, b) {
      // User-specific priority sorting
      if (_isLayoutDesigner()) {
        if (a.status == AppConstants.LAYOUT_DESIGN_STAGE3 &&
            b.status != AppConstants.LAYOUT_DESIGN_STAGE3) return -1;
        if (b.status == AppConstants.LAYOUT_DESIGN_STAGE3 &&
            a.status != AppConstants.LAYOUT_DESIGN_STAGE3) return 1;
        if (a.status == AppConstants.FINAL_MODIFICATIONS &&
            b.status != AppConstants.FINAL_MODIFICATIONS) return -1;
        if (b.status == AppConstants.FINAL_MODIFICATIONS &&
            a.status != AppConstants.FINAL_MODIFICATIONS) return 1;
      }

      if (_isFinalReviewer()) {
        if (a.status == AppConstants.FINAL_REVIEW_STAGE &&
            b.status != AppConstants.FINAL_REVIEW_STAGE) return -1;
        if (b.status == AppConstants.FINAL_REVIEW_STAGE &&
            a.status != AppConstants.FINAL_REVIEW_STAGE) return 1;
      }

      if (_isManagingEditor()) {
        if (a.status == AppConstants.MANAGING_EDITOR_REVIEW_LAYOUT &&
            b.status != AppConstants.MANAGING_EDITOR_REVIEW_LAYOUT) return -1;
        if (b.status == AppConstants.MANAGING_EDITOR_REVIEW_LAYOUT &&
            a.status != AppConstants.MANAGING_EDITOR_REVIEW_LAYOUT) return 1;
        if (a.status == AppConstants.MANAGING_EDITOR_FINAL_CHECK &&
            b.status != AppConstants.MANAGING_EDITOR_FINAL_CHECK) return -1;
        if (b.status == AppConstants.MANAGING_EDITOR_FINAL_CHECK &&
            a.status != AppConstants.MANAGING_EDITOR_FINAL_CHECK) return 1;
      }

      if (_isHeadEditor()) {
        if (a.status == AppConstants.STAGE2_APPROVED &&
            b.status != AppConstants.STAGE2_APPROVED) return -1;
        if (b.status == AppConstants.STAGE2_APPROVED &&
            a.status != AppConstants.STAGE2_APPROVED) return 1;
        if (a.status == AppConstants.HEAD_EDITOR_FINAL_APPROVAL &&
            b.status != AppConstants.HEAD_EDITOR_FINAL_APPROVAL) return -1;
        if (b.status == AppConstants.HEAD_EDITOR_FINAL_APPROVAL &&
            a.status != AppConstants.HEAD_EDITOR_FINAL_APPROVAL) return 1;
      }

      // Then sort by timestamp (newest first)
      return b.timestamp.compareTo(a.timestamp);
    });

    setState(() {
      _filteredDocuments = filtered;
    });
  }

  List<String> _getMyTasks() {
    if (_isLayoutDesigner()) {
      return [
        AppConstants.LAYOUT_DESIGN_STAGE3,
        AppConstants.LAYOUT_REVISION_REQUESTED,
        AppConstants.FINAL_MODIFICATIONS,
      ];
    } else if (_isFinalReviewer()) {
      return [AppConstants.FINAL_REVIEW_STAGE];
    } else if (_isManagingEditor()) {
      return [
        AppConstants.MANAGING_EDITOR_REVIEW_LAYOUT,
        AppConstants.MANAGING_EDITOR_FINAL_CHECK,
      ];
    } else if (_isHeadEditor()) {
      return [
        AppConstants.STAGE2_APPROVED,
        AppConstants.HEAD_EDITOR_FIRST_REVIEW,
        AppConstants.HEAD_EDITOR_FINAL_APPROVAL,
      ];
    }
    return [];
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
              Expanded(
                child: _isSpreadsheetView
                    ? _buildSpreadsheetView()
                    : _buildCardView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    Color headerColor = _isLayoutDesigner()
        ? Colors.purple.shade600
        : _isFinalReviewer()
            ? Colors.indigo.shade600
            : Colors.deepPurple.shade600;

    IconData headerIcon = _isSpreadsheetView
        ? Icons.table_chart
        : (_isLayoutDesigner()
            ? Icons.design_services
            : _isFinalReviewer()
                ? Icons.fact_check
                : Icons.publish);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 50, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [headerColor, headerColor.withOpacity(0.8)],
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
                  headerIcon,
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
                      'المرحلة الثالثة',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isSpreadsheetView
                          ? 'عرض جدولي للإنتاج النهائي والنشر'
                          : _getUserRoleDescription(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              _buildViewToggle(),
              SizedBox(width: 12),
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
          _buildStage3OverviewStats(),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.view_agenda,
            isSelected: !_isSpreadsheetView,
            onTap: () => setState(() => _isSpreadsheetView = false),
          ),
          SizedBox(width: 4),
          _buildToggleButton(
            icon: Icons.table_chart,
            isSelected: _isSpreadsheetView,
            onTap: () => setState(() => _isSpreadsheetView = true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  String _getUserRoleDescription() {
    if (_isLayoutDesigner()) {
      return 'الإخراج الفني والتصميم النهائي';
    } else if (_isFinalReviewer()) {
      return 'المراجعة والتدقيق النهائي';
    } else if (_isManagingEditor()) {
      return 'إدارة الإنتاج والمراجعة النهائية';
    } else if (_isHeadEditor()) {
      return 'الإشراف والاعتماد النهائي للنشر';
    } else {
      return 'الإنتاج النهائي والنشر';
    }
  }

  Widget _buildStage3OverviewStats() {
    if (_allDocuments.isEmpty) return SizedBox.shrink();

    // Count documents by status
    final readyForLayout = _allDocuments
        .where((doc) => doc.status == AppConstants.STAGE2_APPROVED)
        .length;
    final inLayout = _allDocuments
        .where((doc) => [
              AppConstants.LAYOUT_DESIGN_STAGE3,
              AppConstants.LAYOUT_REVISION_REQUESTED
            ].contains(doc.status))
        .length;
    final inReview = _allDocuments
        .where((doc) => [
              AppConstants.LAYOUT_DESIGN_COMPLETED,
              AppConstants.MANAGING_EDITOR_REVIEW_LAYOUT,
              AppConstants.HEAD_EDITOR_FIRST_REVIEW,
              AppConstants.FINAL_REVIEW_STAGE,
            ].contains(doc.status))
        .length;
    final inFinalStages = _allDocuments
        .where((doc) => [
              AppConstants.FINAL_MODIFICATIONS,
              AppConstants.MANAGING_EDITOR_FINAL_CHECK,
              AppConstants.HEAD_EDITOR_FINAL_APPROVAL,
            ].contains(doc.status))
        .length;
    final published = _allDocuments
        .where((doc) => doc.status == AppConstants.PUBLISHED)
        .length;

    final myTasks =
        _allDocuments.where((doc) => _getMyTasks().contains(doc.status)).length;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          if (_isLayoutDesigner()) ...[
            Expanded(
              child: _buildStatItem(
                'مهامي',
                myTasks.toString(),
                Icons.design_services,
                Colors.white,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'في الإخراج',
                inLayout.toString(),
                Icons.palette,
                Colors.white,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'تعديلات نهائية',
                inFinalStages.toString(),
                Icons.edit,
                Colors.white,
              ),
            ),
          ] else if (_isFinalReviewer()) ...[
            Expanded(
              child: _buildStatItem(
                'للمراجعة النهائية',
                myTasks.toString(),
                Icons.fact_check,
                Colors.white,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'في المراجعة',
                inReview.toString(),
                Icons.rate_review,
                Colors.white,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'منشور',
                published.toString(),
                Icons.publish,
                Colors.white,
              ),
            ),
          ] else if (_isManagingEditor()) ...[
            Expanded(
              child: _buildStatItem(
                'للمراجعة',
                myTasks.toString(),
                Icons.supervisor_account,
                Colors.white,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'في الإخراج',
                inLayout.toString(),
                Icons.design_services,
                Colors.white,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'للاعتماد النهائي',
                inFinalStages.toString(),
                Icons.verified_user,
                Colors.white,
              ),
            ),
          ] else if (_isHeadEditor()) ...[
            Expanded(
              child: _buildStatItem(
                'جاهز للإخراج',
                readyForLayout.toString(),
                Icons.design_services,
                Colors.white,
                subtitle: 'من المرحلة الثانية',
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'للاعتماد النهائي',
                myTasks.toString(),
                Icons.verified_user,
                Colors.white,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'منشور',
                published.toString(),
                Icons.publish,
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
                'في الإنتاج',
                (readyForLayout + inLayout + inReview + inFinalStages)
                    .toString(),
                Icons.settings,
                Colors.white,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'منشور',
                published.toString(),
                Icons.publish,
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
      if (filter['key'] == 'my_tasks') {
        return _getMyTasks().isNotEmpty;
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
                final color = Colors.deepPurple;

                // Special styling for ready documents
                bool hasReadyDocuments = filter['key'] == 'ready_for_layout' &&
                    _allDocuments.any(
                        (doc) => doc.status == AppConstants.STAGE2_APPROVED);

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

  Widget _buildSpreadsheetView() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.deepPurple.shade600,
        ),
      );
    }

    return Column(
      children: [
        _buildSpreadsheetHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredDocuments.length,
            itemBuilder: (context, index) {
              return _buildSpreadsheetRow(_filteredDocuments[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpreadsheetHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(flex: 2, child: _buildHeaderCell('اسم المؤلف')),
            Expanded(flex: 3, child: _buildHeaderCell('البريد الإلكتروني')),
            Expanded(flex: 3, child: _buildHeaderCell('الحالة')),
            Expanded(flex: 2, child: _buildHeaderCell('المسؤول الحالي')),
            Expanded(flex: 2, child: _buildHeaderCell('مدة الإنتاج')),
            Expanded(flex: 2, child: _buildHeaderCell('التاريخ')),
            Expanded(flex: 1, child: _buildHeaderCell('')),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xff2d3748),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSpreadsheetRow(DocumentModel document, int index) {
    final statusColor = AppStyles.getStage3StatusColor(document.status);
    final statusIcon = AppStyles.getStage3StatusIcon(document.status);
    final formattedDate = DateFormat('MM/dd\nHH:mm').format(document.timestamp);
    final currentResponsible = _getCurrentResponsible(document.status);
    final productionDuration = _getProductionDuration(document.timestamp);

    // Check if this is a task for current user
    final isMyTask = _getMyTasks().contains(document.status);

    // Special highlighting for Stage2_approved documents
    bool isReadyForLayout = document.status == AppConstants.STAGE2_APPROVED;

    return Container(
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          left: isReadyForLayout || isMyTask
              ? BorderSide(color: Colors.green, width: 3)
              : BorderSide.none,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToDetailsPage(document),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Author Name
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    if (isReadyForLayout)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        margin: EdgeInsets.only(left: 8),
                      )
                    else if (isMyTask)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                        margin: EdgeInsets.only(left: 8),
                      ),
                    Expanded(
                      child: Text(
                        document.fullName.isNotEmpty
                            ? document.fullName
                            : 'غير محدد',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2d3748),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Email
              Expanded(
                flex: 3,
                child: Text(
                  document.email.isNotEmpty ? document.email : '--',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Status
              Expanded(
                flex: 3,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          AppStyles.getStatusDisplayName(document.status),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Current Responsible
              Expanded(
                flex: 2,
                child: Text(
                  currentResponsible,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Production Duration
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getDurationColor(productionDuration).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    productionDuration,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getDurationColor(productionDuration),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Date
              Expanded(
                flex: 2,
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Actions
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: Icon(Icons.arrow_forward_ios,
                      size: 16,
                      color: isReadyForLayout || isMyTask
                          ? Colors.green
                          : Colors.deepPurple.shade600),
                  onPressed: () => _navigateToDetailsPage(document),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrentResponsible(String status) {
    if ([AppConstants.STAGE2_APPROVED].contains(status)) {
      return 'رئيس التحرير';
    } else if ([
      AppConstants.LAYOUT_DESIGN_STAGE3,
      AppConstants.LAYOUT_REVISION_REQUESTED,
      AppConstants.FINAL_MODIFICATIONS
    ].contains(status)) {
      return 'مصمم الإخراج';
    } else if ([
      AppConstants.LAYOUT_DESIGN_COMPLETED,
      AppConstants.MANAGING_EDITOR_REVIEW_LAYOUT,
      AppConstants.MANAGING_EDITOR_FINAL_CHECK
    ].contains(status)) {
      return 'مدير التحرير';
    } else if ([
      AppConstants.HEAD_EDITOR_FIRST_REVIEW,
      AppConstants.HEAD_EDITOR_FINAL_APPROVAL
    ].contains(status)) {
      return 'رئيس التحرير';
    } else if ([AppConstants.FINAL_REVIEW_STAGE].contains(status)) {
      return 'المراجع النهائي';
    } else {
      return 'منشور';
    }
  }

  String _getProductionDuration(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'يوم واحد';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} أيام';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} أسابيع';
    } else {
      return '${(difference.inDays / 30).floor()} أشهر';
    }
  }

  Color _getDurationColor(String duration) {
    if (duration.contains('اليوم') || duration.contains('واحد')) {
      return Colors.green;
    } else if (duration.contains('أيام') && !duration.contains('7')) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildCardView() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.deepPurple.shade600,
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
    String emptyMessage = _selectedFilter == 'ready_for_layout'
        ? 'لا توجد مقالات جاهزة للإخراج الفني'
        : _selectedFilter == 'my_tasks'
            ? 'لا توجد مهام معينة لك'
            : 'لا توجد مستندات للإنتاج';

    String emptyDescription = _selectedFilter == 'ready_for_layout'
        ? 'لم تصل أي مقالات معتمدة من المرحلة الثانية بعد'
        : _selectedFilter == 'my_tasks'
            ? 'لم يتم تعيين أي مقالات لك حتى الآن'
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
              _selectedFilter == 'ready_for_layout'
                  ? Icons.design_services_outlined
                  : Icons.article_outlined,
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
    final statusColor = AppStyles.getStage3StatusColor(document.status);
    final statusIcon = AppStyles.getStage3StatusIcon(document.status);
    final statusName = AppStyles.getStatusDisplayName(document.status);

    // Check if this is a task for current user
    final isMyTask = _getMyTasks().contains(document.status);

    // Special highlighting for Stage2_approved documents
    bool isReadyForLayout = document.status == AppConstants.STAGE2_APPROVED;

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
          color: isReadyForLayout
              ? Colors.green.withOpacity(0.5)
              : isMyTask
                  ? statusColor.withOpacity(0.5)
                  : statusColor.withOpacity(0.2),
          width: (isReadyForLayout || isMyTask) ? 2 : 1,
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
              // Header with status and special badges
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
                            if (isReadyForLayout) ...[
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
                            if (isMyTask && !isReadyForLayout) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'مهمتي',
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
                      'المرحلة 3',
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

              // Stage 3 specific info
              if (isReadyForLayout)
                _buildReadyForLayoutInfo()
              else if (document.status == AppConstants.LAYOUT_DESIGN_STAGE3)
                _buildLayoutInProgressInfo()
              else if (document.status == AppConstants.FINAL_REVIEW_STAGE)
                _buildFinalReviewInfo(),

              SizedBox(height: 16),

              // Progress indicator for Stage 3
              _buildStage3ProgressIndicator(document.status),

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
                        backgroundColor: isReadyForLayout || isMyTask
                            ? statusColor
                            : statusColor.withOpacity(0.8),
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

  Widget _buildReadyForLayoutInfo() {
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
              'معتمد من المرحلة الثانية - جاهز للإخراج الفني',
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

  Widget _buildLayoutInProgressInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.purple.shade100],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.design_services, color: Colors.purple.shade600, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'جاري العمل على الإخراج الفني والتصميم',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalReviewInfo() {
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
          Icon(Icons.fact_check, color: Colors.indigo.shade600, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'في المراجعة النهائية قبل النشر',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage3ProgressIndicator(String status) {
    final steps = ['ready', 'layout', 'review', 'final', 'published'];
    int currentStep = _getStage3StepIndex(status);

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
                  ? Colors.deepPurple.shade600
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  int _getStage3StepIndex(String status) {
    if ([AppConstants.STAGE2_APPROVED].contains(status)) return 0;
    if ([
      AppConstants.LAYOUT_DESIGN_STAGE3,
      AppConstants.LAYOUT_REVISION_REQUESTED
    ].contains(status)) return 1;
    if ([
      AppConstants.LAYOUT_DESIGN_COMPLETED,
      AppConstants.MANAGING_EDITOR_REVIEW_LAYOUT,
      AppConstants.HEAD_EDITOR_FIRST_REVIEW,
      AppConstants.FINAL_REVIEW_STAGE
    ].contains(status)) return 2;
    if ([
      AppConstants.FINAL_MODIFICATIONS,
      AppConstants.MANAGING_EDITOR_FINAL_CHECK,
      AppConstants.HEAD_EDITOR_FINAL_APPROVAL
    ].contains(status)) return 3;
    if ([AppConstants.PUBLISHED].contains(status)) return 4;
    return 0;
  }

  String _getStageDescription(String status) {
    if ([AppConstants.STAGE2_APPROVED].contains(status)) {
      return 'جاهز للإخراج الفني';
    } else if ([
      AppConstants.LAYOUT_DESIGN_STAGE3,
      AppConstants.LAYOUT_REVISION_REQUESTED
    ].contains(status)) {
      return 'في مرحلة الإخراج الفني';
    } else if ([
      AppConstants.LAYOUT_DESIGN_COMPLETED,
      AppConstants.MANAGING_EDITOR_REVIEW_LAYOUT,
      AppConstants.HEAD_EDITOR_FIRST_REVIEW,
      AppConstants.FINAL_REVIEW_STAGE
    ].contains(status)) {
      return 'في مرحلة المراجعة';
    } else if ([
      AppConstants.FINAL_MODIFICATIONS,
      AppConstants.MANAGING_EDITOR_FINAL_CHECK,
      AppConstants.HEAD_EDITOR_FINAL_APPROVAL
    ].contains(status)) {
      return 'في المراحل النهائية';
    } else if ([AppConstants.PUBLISHED].contains(status)) {
      return 'تم النشر';
    }
    return 'في الإنتاج';
  }

  IconData _getActionIcon(DocumentModel document) {
    if (document.status == AppConstants.STAGE2_APPROVED) {
      return Icons.design_services;
    }

    // Check user-specific actions
    if (_isLayoutDesigner() && _getMyTasks().contains(document.status)) {
      return Icons.edit;
    }
    if (_isFinalReviewer() &&
        document.status == AppConstants.FINAL_REVIEW_STAGE) {
      return Icons.fact_check;
    }
    if (_isManagingEditor() && _getMyTasks().contains(document.status)) {
      return Icons.rate_review;
    }
    if (_isHeadEditor() && _getMyTasks().contains(document.status)) {
      return Icons.verified_user;
    }

    return Icons.visibility;
  }

  String _getActionText(DocumentModel document) {
    if (document.status == AppConstants.STAGE2_APPROVED) {
      return 'إرسال للإخراج الفني';
    }

    // Check user-specific actions
    if (_isLayoutDesigner() && _getMyTasks().contains(document.status)) {
      if (document.status == AppConstants.LAYOUT_DESIGN_STAGE3) {
        return 'إكمال الإخراج الفني';
      } else if (document.status == AppConstants.FINAL_MODIFICATIONS) {
        return 'إكمال التعديلات النهائية';
      }
      return 'إكمال المهمة';
    }
    if (_isFinalReviewer() &&
        document.status == AppConstants.FINAL_REVIEW_STAGE) {
      return 'إجراء المراجعة النهائية';
    }
    if (_isManagingEditor() && _getMyTasks().contains(document.status)) {
      return 'مراجعة واتخاذ قرار';
    }
    if (_isHeadEditor() && _getMyTasks().contains(document.status)) {
      return 'مراجعة واعتماد';
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
    Widget? page;

    // Route to appropriate detail page based on user role and document status

    if (_isLayoutDesigner() &&
        [
          AppConstants.LAYOUT_DESIGN_STAGE3,
          AppConstants.LAYOUT_REVISION_REQUESTED,
          AppConstants.FINAL_MODIFICATIONS,
          AppConstants.STAGE2_APPROVED
        ].contains(document.status)) {
      page = Stage3LayoutDesignerPage(document: document);
    }
    // TODO: Add other detail pages as they are created
    else if (_isFinalReviewer() &&
        document.status == AppConstants.FINAL_REVIEW_STAGE) {
      page = Stage3FinalReviewerPage(document: document);
    } else if (_isManagingEditor()) {
      page = Stage3ManagingEditorPage(document: document);
    } else if (_isHeadEditor()) {
      page = Stage3HeadEditorPage(document: document);
    }

    if (page != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page!),
      ).then((_) {
        _applyFilters();
      });
    } else {
      // Show placeholder for pages not yet implemented
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('صفحة تفاصيل هذا المستخدم - قيد التطوير'),
          backgroundColor: Colors.deepPurple.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
              leading:
                  Icon(Icons.visibility, color: Colors.deepPurple.shade600),
              title: Text('عرض التفاصيل'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetailsPage(document);
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.blue),
              title: Text('سجل الإنتاج'),
              onTap: () {
                Navigator.pop(context);
                _showProductionHistory(document);
              },
            ),
            ListTile(
              leading: Icon(Icons.download, color: Colors.orange),
              title: Text('تحميل الملف'),
              onTap: () {
                Navigator.pop(context);
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

  void _showProductionHistory(DocumentModel document) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text('سجل الإنتاج'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: document.actionLog.length,
              itemBuilder: (context, index) {
                final action = document.actionLog[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade100,
                    child:
                        Icon(Icons.history, color: Colors.deepPurple.shade600),
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
}
