// pages/AllDocumentsPage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import '../../App_Constants.dart';
import '../../Document_Services.dart';
import '../../models/document_model.dart';

class AllDocumentsPage extends StatefulWidget {
  @override
  _AllDocumentsPageState createState() => _AllDocumentsPageState();
}

class _AllDocumentsPageState extends State<AllDocumentsPage>
    with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();

  List<DocumentModel> _allDocuments = [];
  List<DocumentModel> _filteredDocuments = [];
  bool _isLoading = true;

  // Filters
  String _searchQuery = '';
  String _selectedStage = 'all';
  String _selectedStatus = 'all';
  String _selectedSort = 'timestamp';
  bool _sortAscending = false;
  bool _isSpreadsheetView = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Statistics
  Map<String, int> _statistics = {};

  final List<Map<String, dynamic>> _stageFilters = [
    {'key': 'all', 'title': 'جميع المراحل', 'icon': Icons.all_inclusive},
    {'key': '1', 'title': 'المرحلة الأولى', 'icon': Icons.filter_1},
    {'key': '2', 'title': 'المرحلة الثانية', 'icon': Icons.filter_2},
    {'key': '3', 'title': 'المرحلة الثالثة', 'icon': Icons.filter_3},
  ];

  final List<Map<String, dynamic>> _sortOptions = [
    {'key': 'timestamp', 'title': 'التاريخ'},
    {'key': 'fullName', 'title': 'اسم المؤلف'},
    {'key': 'status', 'title': 'الحالة'},
    {'key': 'stage', 'title': 'المرحلة'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAllDocuments();
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

  Future<void> _loadAllDocuments() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get documents from all stages
      final stage1Docs = await _documentService.getAllStage1Documents();
      final stage2Docs = await _documentService.getAllStage2Documents();
      final stage3Docs = await _documentService.getAllStage3Documents();

      final allDocs = <DocumentModel>[];
      allDocs.addAll(stage1Docs);
      allDocs.addAll(stage2Docs);
      allDocs.addAll(stage3Docs);

      // Remove duplicates (documents might appear in multiple stages)
      final uniqueDocs = <String, DocumentModel>{};
      for (final doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }

      if (mounted) {
        setState(() {
          _allDocuments = uniqueDocs.values.toList();
          _calculateStatistics();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading all documents: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateStatistics() {
    _statistics.clear();

    for (final doc in _allDocuments) {
      final stage = AppStyles.getStageNumber(doc.status);
      final stageKey = 'stage_$stage';
      _statistics[stageKey] = (_statistics[stageKey] ?? 0) + 1;

      // Count by status
      _statistics[doc.status] = (_statistics[doc.status] ?? 0) + 1;
    }

    _statistics['total'] = _allDocuments.length;
    _statistics['stage_1_count'] = _statistics['stage_1'] ?? 0;
    _statistics['stage_2_count'] = _statistics['stage_2'] ?? 0;
    _statistics['stage_3_count'] = _statistics['stage_3'] ?? 0;
  }

  void _applyFilters() {
    List<DocumentModel> filtered = List.from(_allDocuments);

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

    // Apply stage filter
    if (_selectedStage != 'all') {
      int stage = int.parse(_selectedStage);
      filtered = filtered.where((doc) {
        return AppStyles.getStageNumber(doc.status) == stage;
      }).toList();
    }

    // Apply status filter
    if (_selectedStatus != 'all') {
      filtered = filtered.where((doc) {
        return doc.status == _selectedStatus;
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      dynamic aValue, bValue;

      switch (_selectedSort) {
        case 'fullName':
          aValue = a.fullName;
          bValue = b.fullName;
          break;
        case 'status':
          aValue = AppStyles.getStatusDisplayName(a.status);
          bValue = AppStyles.getStatusDisplayName(b.status);
          break;
        case 'stage':
          aValue = AppStyles.getStageNumber(a.status);
          bValue = AppStyles.getStageNumber(b.status);
          break;
        case 'timestamp':
        default:
          aValue = a.timestamp;
          bValue = b.timestamp;
          break;
      }

      int comparison;
      if (aValue is DateTime && bValue is DateTime) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = aValue.toString().compareTo(bValue.toString());
      }

      return _sortAscending ? comparison : -comparison;
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
            Color(0xff8b5a2b),
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
                child: Icon(
                  _isSpreadsheetView ? Icons.table_chart : Icons.library_books,
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
                      'جميع المقالات',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isSpreadsheetView
                          ? 'عرض جدولي شامل للمقالات'
                          : 'عرض شامل لجميع المقالات في النظام',
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
                  '${_filteredDocuments.length} / ${_allDocuments.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildStatisticsOverview(),
        ],
      ),
    );
  }

  Widget _buildStatisticsOverview() {
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
            child: _buildStatItem(
              'المجموع',
              (_statistics['total'] ?? 0).toString(),
              Icons.library_books,
              Colors.white,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              'المرحلة 1',
              (_statistics['stage_1_count'] ?? 0).toString(),
              Icons.filter_1,
              Colors.white,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              'المرحلة 2',
              (_statistics['stage_2_count'] ?? 0).toString(),
              Icons.filter_2,
              Colors.white,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              'المرحلة 3',
              (_statistics['stage_3_count'] ?? 0).toString(),
              Icons.filter_3,
              Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.3),
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

          // Filter Controls Row
          Row(
            children: [
              // Stage Filter
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStage,
                      isExpanded: true,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      items:
                          _stageFilters.map<DropdownMenuItem<String>>((filter) {
                        return DropdownMenuItem<String>(
                          value: filter['key'] as String,
                          child: Row(
                            children: [
                              Icon(filter['icon'] as IconData,
                                  size: 16, color: AppStyles.primaryColor),
                              SizedBox(width: 8),
                              Text(filter['title'] as String,
                                  style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStage = value!;
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                ),
              ),

              SizedBox(width: 8),

              // Sort By
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSort,
                      isExpanded: true,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      items:
                          _sortOptions.map<DropdownMenuItem<String>>((option) {
                        return DropdownMenuItem<String>(
                          value: option['key'] as String,
                          child: Text(option['title'] as String,
                              style: TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSort = value!;
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                ),
              ),

              SizedBox(width: 8),

              // Sort Direction
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: AppStyles.primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardView() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppStyles.primaryColor),
            SizedBox(height: 20),
            Text(
              'جاري تحميل المقالات...',
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

  Widget _buildSpreadsheetView() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppStyles.primaryColor),
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
            Expanded(flex: 1, child: _buildHeaderCell('المرحلة')),
            Expanded(flex: 3, child: _buildHeaderCell('اسم المؤلف')),
            Expanded(flex: 3, child: _buildHeaderCell('البريد الإلكتروني')),
            Expanded(flex: 3, child: _buildHeaderCell('الحالة')),
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
    final stage = AppStyles.getStageNumber(document.status);
    final formattedDate = DateFormat('MM/dd\nHH:mm').format(document.timestamp);

    return Container(
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: InkWell(
        onTap: () => _showDocumentDetails(document),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Stage
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStageColor(stage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _getStageColor(stage).withOpacity(0.3)),
                  ),
                  child: Text(
                    '$stage',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStageColor(stage),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Name
              Expanded(
                flex: 3,
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
                  onPressed: () => _showDocumentDetails(document),
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
              _searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.library_books_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'لا توجد مقالات تطابق البحث'
                : 'لا توجد مقالات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'جرب تغيير كلمات البحث أو المرشحات'
                : 'لم يتم العثور على أي مقالات في النظام',
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
    final stage = AppStyles.getStageNumber(document.status);

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
        onTap: () => _showDocumentDetails(document),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and stage
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
                          _getStageDescription(stage),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStageColor(stage).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _getStageColor(stage).withOpacity(0.3)),
                        ),
                        child: Text(
                          'المرحلة $stage',
                          style: TextStyle(
                            color: _getStageColor(stage),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDate(document.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
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
                          document.fullName.isNotEmpty
                              ? document.fullName
                              : 'غير محدد',
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
                          document.email.isNotEmpty
                              ? document.email
                              : 'لا يوجد بريد إلكتروني',
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
                ],
              ),

              SizedBox(height: 16),

              // Progress indicator
              _buildProgressIndicator(document.status, stage),

              SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showDocumentDetails(document),
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

  Widget _buildProgressIndicator(String status, int stage) {
    List<String> stageStatuses;
    switch (stage) {
      case 1:
        stageStatuses = AppConstants.stage1Statuses;
        break;
      case 2:
        stageStatuses = AppConstants.stage2Statuses;
        break;
      case 3:
        stageStatuses = AppConstants.stage3Statuses;
        break;
      default:
        return SizedBox.shrink();
    }

    int currentIndex = stageStatuses.indexOf(status);
    if (currentIndex == -1) currentIndex = 0;

    double progress = (currentIndex + 1) / stageStatuses.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'تقدم المرحلة $stage',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getStageColor(stage),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(_getStageColor(stage)),
          minHeight: 6,
        ),
      ],
    );
  }

  Color _getStageColor(int stage) {
    switch (stage) {
      case 1:
        return Colors.red[600] ?? Colors.red;
      case 2:
        return Colors.orange[600] ?? Colors.orange;
      case 3:
        return Colors.purple[600] ?? Colors.purple;
      default:
        return Colors.grey[600] ?? Colors.grey;
    }
  }

  String _getStageDescription(int stage) {
    switch (stage) {
      case 1:
        return 'مراجعة وموافقة أولية';
      case 2:
        return 'التحكيم العلمي والمراجعة';
      case 3:
        return 'الإنتاج النهائي والنشر';
      default:
        return 'مرحلة غير معروفة';
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

  void _showDocumentDetails(DocumentModel document) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(AppStyles.getStatusIcon(document.status),
                  color: AppStyles.getStatusColor(document.status)),
              SizedBox(width: 8),
              Text('تفاصيل المقال'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                    'المؤلف:',
                    document.fullName.isNotEmpty
                        ? document.fullName
                        : 'غير محدد'),
                _buildDetailRow('البريد الإلكتروني:',
                    document.email.isNotEmpty ? document.email : 'غير محدد'),
                _buildDetailRow('المرحلة:',
                    'المرحلة ${AppStyles.getStageNumber(document.status)}'),
                _buildDetailRow(
                    'الحالة:', AppStyles.getStatusDisplayName(document.status)),
                _buildDetailRow('التاريخ:', _formatDate(document.timestamp)),
                SizedBox(height: 16),
                if (document.actionLog.isNotEmpty) ...[
                  Text(
                    'آخر الإجراءات:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 150,
                    child: ListView.builder(
                      itemCount: document.actionLog.length.clamp(0, 5),
                      itemBuilder: (context, index) {
                        final action = document.actionLog[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• ${action.action} - ${action.userName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إغلاق'),
            ),
            if (document.documentUrl != null &&
                document.documentUrl!.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implement file download/view
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('سيتم إضافة عرض الملفات قريباً')),
                  );
                },
                child: Text('عرض الملف'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.getStatusColor(document.status),
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
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
                _showDocumentDetails(document);
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.blue),
              title: Text('سجل الإجراءات'),
              onTap: () {
                Navigator.pop(context);
                _showActionHistory(document);
              },
            ),
            if (document.documentUrl != null &&
                document.documentUrl!.isNotEmpty)
              ListTile(
                leading: Icon(Icons.download, color: Colors.green),
                title: Text('تحميل الملف'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement file download
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

  void _showActionHistory(DocumentModel document) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text('سجل الإجراءات'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: document.actionLog.length,
              itemBuilder: (context, index) {
                final action = document.actionLog[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppStyles.primaryColor.withOpacity(0.1),
                    child: Icon(Icons.history, color: AppStyles.primaryColor),
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
