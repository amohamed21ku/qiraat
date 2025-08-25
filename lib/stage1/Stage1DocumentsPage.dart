// pages/Stage1/Stage1DocumentsPage.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import '../App_Constants.dart';
import '../Document_Services.dart';
import '../models/document_model.dart';
import 'Stag1HeadEditorDetailsPage.dart';
import 'Stage1SecretaryDetailsPage.dart';
import 'Stage1EditorDetailsPage.dart';

class Stage1DocumentsPage extends StatefulWidget {
  @override
  _Stage1DocumentsPageState createState() => _Stage1DocumentsPageState();
}

class _Stage1DocumentsPageState extends State<Stage1DocumentsPage>
    with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();

  List<DocumentModel> _filteredDocuments = [];
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isSpreadsheetView = true; // Default to table view

  // Stream subscription for real-time updates
  Stream<List<DocumentModel>>? _documentsStream;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _filterOptions = [
    {'key': 'all', 'title': 'جميع المقالات', 'icon': Icons.all_inclusive},
    {'key': 'incoming', 'title': 'ملفات واردة', 'icon': Icons.inbox},
    {
      'key': 'secretary',
      'title': 'مراجعة السكرتير',
      'icon': Icons.assignment_ind
    },
    {
      'key': 'editor',
      'title': 'مراجعة مدير التحرير',
      'icon': Icons.supervisor_account
    },
    {
      'key': 'head',
      'title': 'مراجعة رئيس التحرير',
      'icon': Icons.admin_panel_settings
    },
    {'key': 'completed', 'title': 'مكتملة', 'icon': Icons.check_circle},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDocumentsStream();
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

  void _initializeDocumentsStream() {
    _documentsStream = _documentService.getStage1DocumentsStream();
  }

  List<DocumentModel> _applyFilters(List<DocumentModel> allDocuments) {
    List<DocumentModel> filtered = List.from(allDocuments);

    // Apply status filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((doc) {
        switch (_selectedFilter) {
          case 'incoming':
            return doc.status == AppConstants.INCOMING;
          case 'secretary':
            return [
              AppConstants.SECRETARY_REVIEW,
              AppConstants.SECRETARY_APPROVED,
              AppConstants.SECRETARY_REJECTED,
              AppConstants.SECRETARY_EDIT_REQUESTED,
            ].contains(doc.status);
          case 'editor':
            return [
              AppConstants.EDITOR_REVIEW,
              AppConstants.EDITOR_APPROVED,
              AppConstants.EDITOR_REJECTED,
              AppConstants.EDITOR_WEBSITE_RECOMMENDED,
              AppConstants.EDITOR_EDIT_REQUESTED,
            ].contains(doc.status);
          case 'head':
            return doc.status == AppConstants.HEAD_REVIEW;
          case 'completed':
            return [
              AppConstants.STAGE1_APPROVED,
              AppConstants.FINAL_REJECTED,
              AppConstants.WEBSITE_APPROVED,
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

    return filtered;
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
    return Container(
      padding: EdgeInsets.fromLTRB(20, 50, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyles.primaryColor,
            AppStyles.secondaryColor,
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
      child: Row(
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
              _isSpreadsheetView ? Icons.table_chart : Icons.view_agenda,
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
                  'المرحلة الأولى',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isSpreadsheetView
                      ? 'عرض جدولي لمراجعة وموافقة المقالات'
                      : 'مراجعة وموافقة المقالات',
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildFiltersSection() {
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
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter['key'];

                return Container(
                  margin: EdgeInsets.only(left: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter['key'];
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
                                colors: [
                                  AppStyles.primaryColor,
                                  AppStyles.secondaryColor
                                ],
                              )
                            : LinearGradient(
                                colors: [Colors.white, Colors.white],
                              ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppStyles.primaryColor
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: AppStyles.primaryColor.withOpacity(0.2),
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
                                : AppStyles.primaryColor,
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
                                    : AppStyles.primaryColor,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
    return StreamBuilder<List<DocumentModel>>(
      stream: _documentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppStyles.primaryColor),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final allDocuments = snapshot.data ?? [];
        final filteredDocuments = _applyFilters(allDocuments);

        // Update the filtered documents for the header count
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _filteredDocuments = filteredDocuments;
            });
          }
        });

        if (filteredDocuments.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            _buildSpreadsheetHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: filteredDocuments.length,
                itemBuilder: (context, index) {
                  return _buildSpreadsheetRow(filteredDocuments[index], index);
                },
              ),
            ),
          ],
        );
      },
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
            Expanded(flex: 2, child: _buildHeaderCell('المراجع الحالي')),
            Expanded(flex: 2, child: _buildHeaderCell('مدة المراجعة')),
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
    final statusColor = AppStyles.getStatusColor(document.status);
    final statusIcon = AppStyles.getStatusIcon(document.status);
    final formattedDate = DateFormat('MM/dd\nHH:mm').format(document.timestamp);
    final currentReviewer = _getCurrentReviewer(document.status);
    final reviewDuration = _getReviewDuration(document.timestamp);

    return Container(
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
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
                child: Text(
                  document.fullName.isNotEmpty ? document.fullName : 'غير محدد',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2d3748),
                  ),
                  overflow: TextOverflow.ellipsis,
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

              // Current Reviewer
              Expanded(
                flex: 2,
                child: Text(
                  currentReviewer,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Review Duration
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDurationColor(reviewDuration).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    reviewDuration,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getDurationColor(reviewDuration),
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
                      size: 16, color: AppStyles.primaryColor),
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

  String _getCurrentReviewer(String status) {
    if ([AppConstants.INCOMING, AppConstants.SECRETARY_REVIEW]
        .contains(status)) {
      return 'السكرتير';
    } else if ([
      AppConstants.SECRETARY_APPROVED,
      AppConstants.SECRETARY_REJECTED,
      AppConstants.SECRETARY_EDIT_REQUESTED,
      AppConstants.EDITOR_REVIEW
    ].contains(status)) {
      return 'مدير التحرير';
    } else if ([
      AppConstants.EDITOR_APPROVED,
      AppConstants.EDITOR_REJECTED,
      AppConstants.EDITOR_WEBSITE_RECOMMENDED,
      AppConstants.EDITOR_EDIT_REQUESTED,
      AppConstants.HEAD_REVIEW
    ].contains(status)) {
      return 'رئيس التحرير';
    } else {
      return 'مكتملة';
    }
  }

  String _getReviewDuration(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'يوم واحد';
    } else {
      return '${difference.inDays} أيام';
    }
  }

  Color _getDurationColor(String duration) {
    if (duration.contains('اليوم')) {
      return Colors.green;
    } else if (duration.contains('واحد') ||
        duration.contains('2') ||
        duration.contains('3')) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildCardView() {
    return StreamBuilder<List<DocumentModel>>(
      stream: _documentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppStyles.primaryColor),
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

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final allDocuments = snapshot.data ?? [];
        final filteredDocuments = _applyFilters(allDocuments);

        // Update the filtered documents for the header count
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _filteredDocuments = filteredDocuments;
            });
          }
        });

        if (filteredDocuments.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filteredDocuments.length,
          itemBuilder: (context, index) {
            final document = filteredDocuments[index];
            return _buildDocumentCard(document, index);
          },
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'خطأ في تحميل المستندات',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: Colors.grey),
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
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'لا توجد مستندات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'لم يتم العثور على مستندات تطابق المعايير المحددة',
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
    final statusColor = AppStyles.getStatusColor(document.status);
    final statusIcon = AppStyles.getStatusIcon(document.status);
    final statusName = AppStyles.getStatusDisplayName(document.status);

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
          color: statusColor.withOpacity(0.2),
          width: 1,
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
              // Header with status
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
                        Text(
                          statusName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
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
                      'المرحلة ${AppStyles.getStageNumber(document.status)}',
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

              // Progress indicator
              _buildProgressIndicator(document.status),

              SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToDetailsPage(document),
                      icon: Icon(Icons.visibility, size: 18),
                      label: Text('عرض التفاصيل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
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

  Widget _buildProgressIndicator(String status) {
    final steps = ['incoming', 'secretary', 'editor', 'head', 'completed'];
    int currentStep = _getCurrentStepIndex(status);

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
                  ? AppStyles.primaryColor
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  int _getCurrentStepIndex(String status) {
    if ([AppConstants.INCOMING].contains(status)) return 0;
    if ([
      AppConstants.SECRETARY_REVIEW,
      AppConstants.SECRETARY_APPROVED,
      AppConstants.SECRETARY_REJECTED,
      AppConstants.SECRETARY_EDIT_REQUESTED
    ].contains(status)) return 1;
    if ([
      AppConstants.EDITOR_REVIEW,
      AppConstants.EDITOR_APPROVED,
      AppConstants.EDITOR_REJECTED,
      AppConstants.EDITOR_WEBSITE_RECOMMENDED,
      AppConstants.EDITOR_EDIT_REQUESTED
    ].contains(status)) return 2;
    if ([AppConstants.HEAD_REVIEW].contains(status)) return 3;
    if ([
      AppConstants.STAGE1_APPROVED,
      AppConstants.FINAL_REJECTED,
      AppConstants.WEBSITE_APPROVED
    ].contains(status)) return 4;
    return 0;
  }

  String _getStageDescription(String status) {
    if ([AppConstants.INCOMING, AppConstants.SECRETARY_REVIEW]
        .contains(status)) {
      return 'مراجعة السكرتير';
    } else if ([
      AppConstants.SECRETARY_APPROVED,
      AppConstants.SECRETARY_REJECTED,
      AppConstants.SECRETARY_EDIT_REQUESTED,
      AppConstants.EDITOR_REVIEW
    ].contains(status)) {
      return 'مراجعة مدير التحرير';
    } else if ([
      AppConstants.EDITOR_APPROVED,
      AppConstants.EDITOR_REJECTED,
      AppConstants.EDITOR_WEBSITE_RECOMMENDED,
      AppConstants.EDITOR_EDIT_REQUESTED,
      AppConstants.HEAD_REVIEW
    ].contains(status)) {
      return 'مراجعة رئيس التحرير';
    } else {
      return 'مكتملة';
    }
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

    // Determine which detail page to navigate to based on document status
    if ([AppConstants.INCOMING, AppConstants.SECRETARY_REVIEW]
        .contains(document.status)) {
      page = Stage1SecretaryDetailsPage(document: document);
    } else if ([
      AppConstants.SECRETARY_APPROVED,
      AppConstants.SECRETARY_REJECTED,
      AppConstants.SECRETARY_EDIT_REQUESTED,
      AppConstants.EDITOR_REVIEW
    ].contains(document.status)) {
      page = Stage1EditorDetailsPage(document: document);
    } else {
      page = Stage1HeadEditorDetailsPage(document: document);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
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
              leading: Icon(Icons.visibility, color: AppStyles.primaryColor),
              title: Text('عرض التفاصيل'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetailsPage(document);
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.blue),
              title: Text('سجل الإجراءات'),
              onTap: () {
                Navigator.pop(context);
                // Implement action history view
              },
            ),
            ListTile(
              leading: Icon(Icons.download, color: Colors.green),
              title: Text('تحميل الملف'),
              onTap: () {
                Navigator.pop(context);
                // Implement file download
              },
            ),
          ],
        ),
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
