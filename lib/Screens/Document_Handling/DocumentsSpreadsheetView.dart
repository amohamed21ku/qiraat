// DocumentsSpreadsheetView.dart - Spreadsheet-like view for all documents
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import 'DocumentDetails/Constants/App_Constants.dart';
import 'DocumentDetails/DocumentDetails.dart';

class DocumentsSpreadsheetView extends StatefulWidget {
  const DocumentsSpreadsheetView({super.key});

  @override
  State<DocumentsSpreadsheetView> createState() =>
      _DocumentsSpreadsheetViewState();
}

class _DocumentsSpreadsheetViewState extends State<DocumentsSpreadsheetView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Filtering and sorting
  String _searchQuery = '';
  String _selectedStage = 'all';
  String _selectedStatus = 'all';
  String _sortBy = 'timestamp';
  bool _sortAscending = false;

  // Colors
  final Color primaryColor = const Color(0xffa86418);
  final Color secondaryColor = const Color(0xffcc9657);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToDocumentDetails(DocumentSnapshot document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentDetailsPage(document: document),
      ),
    );
  }

  List<DocumentSnapshot> _filterAndSortDocuments(
      List<DocumentSnapshot> documents) {
    List<DocumentSnapshot> filtered = documents.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final fullName = (data['fullName'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final about = (data['about'] ?? '').toString().toLowerCase();
      final status = data['status'] ?? '';
      final stage = AppStyles.getStageNumber(status);

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!fullName.contains(query) &&
            !email.contains(query) &&
            !about.contains(query)) {
          return false;
        }
      }

      // Stage filter
      if (_selectedStage != 'all') {
        if (_selectedStage == '1' && stage != 1) return false;
        if (_selectedStage == '2' && stage != 2) return false;
        if (_selectedStage == '3' && stage != 3) return false;
      }

      // Status filter
      if (_selectedStatus != 'all' && status != _selectedStatus) {
        return false;
      }

      return true;
    }).toList();

    // Sort documents
    filtered.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      dynamic aValue, bValue;

      switch (_sortBy) {
        case 'fullName':
          aValue = aData['fullName'] ?? '';
          bValue = bData['fullName'] ?? '';
          break;
        case 'email':
          aValue = aData['email'] ?? '';
          bValue = bData['email'] ?? '';
          break;
        case 'status':
          aValue = AppStyles.getStatusDisplayName(aData['status'] ?? '');
          bValue = AppStyles.getStatusDisplayName(bData['status'] ?? '');
          break;
        case 'stage':
          aValue = AppStyles.getStageNumber(aData['status'] ?? '');
          bValue = AppStyles.getStageNumber(bData['status'] ?? '');
          break;
        case 'timestamp':
        default:
          aValue = aData['timestamp'] as Timestamp?;
          bValue = bData['timestamp'] as Timestamp?;
          if (aValue == null && bValue == null) return 0;
          if (aValue == null) return 1;
          if (bValue == null) return -1;
          break;
      }

      int comparison;
      if (aValue is Timestamp && bValue is Timestamp) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = aValue.toString().compareTo(bValue.toString());
      }

      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [secondaryColor, primaryColor, Color(0xff8b5a2b)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Title and back button
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'جدول المقالات الشامل',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'عرض مبسط لجميع المقالات في النظام',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.table_chart, color: Colors.white, size: 32),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Filters and search
            Row(
              children: [
                // Search bar
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'البحث في المقالات...',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.white.withOpacity(0.7)),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Stage filter
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStage,
                        dropdownColor: primaryColor,
                        style: TextStyle(color: Colors.white),
                        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                        items: [
                          DropdownMenuItem(
                              value: 'all', child: Text('كل المراحل')),
                          DropdownMenuItem(
                              value: '1', child: Text('المرحلة 1')),
                          DropdownMenuItem(
                              value: '2', child: Text('المرحلة 2')),
                          DropdownMenuItem(
                              value: '3', child: Text('المرحلة 3')),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedStage = value!),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Sort dropdown
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        dropdownColor: primaryColor,
                        style: TextStyle(color: Colors.white),
                        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                        items: [
                          DropdownMenuItem(
                              value: 'timestamp', child: Text('التاريخ')),
                          DropdownMenuItem(
                              value: 'fullName', child: Text('الاسم')),
                          DropdownMenuItem(
                              value: 'status', child: Text('الحالة')),
                          DropdownMenuItem(
                              value: 'stage', child: Text('المرحلة')),
                        ],
                        onChanged: (value) => setState(() => _sortBy = value!),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),

                // Sort direction
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _sortAscending = !_sortAscending),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
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
            // Document ID
            Expanded(
              flex: 1,
              child: Text('ID',
                  style: _headerTextStyle(), textAlign: TextAlign.center),
            ),
            // Name
            Expanded(
              flex: 3,
              child: Text('اسم المؤلف', style: _headerTextStyle()),
            ),
            // Email
            Expanded(
              flex: 3,
              child: Text('البريد الإلكتروني', style: _headerTextStyle()),
            ),
            // Stage
            Expanded(
              flex: 1,
              child: Text('المرحلة',
                  style: _headerTextStyle(), textAlign: TextAlign.center),
            ),
            // Status
            Expanded(
              flex: 3,
              child: Text('الحالة',
                  style: _headerTextStyle(), textAlign: TextAlign.center),
            ),
            // Date
            Expanded(
              flex: 2,
              child: Text('التاريخ',
                  style: _headerTextStyle(), textAlign: TextAlign.center),
            ),
            // Responsible
            Expanded(
              flex: 2,
              child: Text('المسؤول',
                  style: _headerTextStyle(), textAlign: TextAlign.center),
            ),
            // Actions
            Expanded(
              flex: 1,
              child: Text('', style: _headerTextStyle()),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _headerTextStyle() {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Color(0xff2d3748),
    );
  }

  Widget _buildTableRow(DocumentSnapshot document, int index) {
    final data = document.data() as Map<String, dynamic>;
    final DateTime? timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final String formattedDate =
        timestamp != null ? DateFormat('MM/dd\nHH:mm').format(timestamp) : '--';

    final String status = data['status'] ?? '';
    final Color statusColor = AppStyles.getStatusColor(status);
    final IconData statusIcon = AppStyles.getStatusIcon(status);
    final int stage = AppStyles.getStageNumber(status);
    final String responsibleRole = _getResponsibleRole(status);

    return Container(
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToDocumentDetails(document),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Document ID
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    document.id.substring(0, 8),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Name
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['fullName'] ?? 'غير معروف',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2d3748),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (data['about'] != null &&
                        data['about'].toString().isNotEmpty)
                      Text(
                        data['about'].toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Email
              Expanded(
                flex: 3,
                child: Text(
                  data['email'] ?? '--',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

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
                          AppStyles.getStatusDisplayName(status),
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

              // Responsible
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    responsibleRole,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Actions
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: Icon(Icons.arrow_forward_ios,
                      size: 16, color: primaryColor),
                  onPressed: () => _navigateToDocumentDetails(document),
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

  Color _getStageColor(int stage) {
    switch (stage) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getResponsibleRole(String status) {
    switch (status) {
      case AppConstants.INCOMING:
      case AppConstants.SECRETARY_REVIEW:
        return 'السكرتير';
      case AppConstants.SECRETARY_APPROVED:
      case AppConstants.SECRETARY_EDIT_REQUESTED:
      case AppConstants.EDITOR_REVIEW:
        return 'مدير التحرير';
      case AppConstants.EDITOR_APPROVED:
      case AppConstants.EDITOR_REJECTED:
      case AppConstants.EDITOR_WEBSITE_RECOMMENDED:
      case AppConstants.EDITOR_EDIT_REQUESTED:
      case AppConstants.HEAD_REVIEW:
      case AppConstants.STAGE1_APPROVED:
      case AppConstants.REVIEWERS_ASSIGNED:
      case AppConstants.PEER_REVIEW_COMPLETED:
      case AppConstants.HEAD_REVIEW_STAGE2:
        return 'رئيس التحرير';
      case AppConstants.UNDER_PEER_REVIEW:
        return 'المحكمين';
      case AppConstants.STAGE1_APPROVED:
      case AppConstants.FINAL_REJECTED:
      case AppConstants.WEBSITE_APPROVED:
      case AppConstants.STAGE2_APPROVED:
      case AppConstants.STAGE2_REJECTED:
      case AppConstants.STAGE2_EDIT_REQUESTED:
      case AppConstants.STAGE2_WEBSITE_APPROVED:
        return 'مكتمل';
      default:
        return '--';
    }
  }

  Widget _buildStatsSummary(List<DocumentSnapshot> documents) {
    final stage1Count = documents.where((doc) {
      final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
      return AppStyles.getStageNumber(status) == 1;
    }).length;

    final stage2Count = documents.where((doc) {
      final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
      return AppStyles.getStageNumber(status) == 2;
    }).length;

    final stage3Count = documents.where((doc) {
      final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
      return AppStyles.getStageNumber(status) == 3;
    }).length;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem('إجمالي المقالات', '${documents.length}', Colors.blue),
          SizedBox(width: 20),
          _buildStatItem('المرحلة 1', '$stage1Count', Colors.red),
          SizedBox(width: 20),
          _buildStatItem('المرحلة 2', '$stage2Count', Colors.orange),
          SizedBox(width: 20),
          _buildStatItem('المرحلة 3', '$stage3Count', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xfff8f9fa),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sent_documents')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          'خطأ في تحميل البيانات: ${snapshot.error}',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    );
                  }

                  final allDocuments = snapshot.data!.docs;
                  final filteredDocuments =
                      _filterAndSortDocuments(allDocuments);

                  return Expanded(
                    child: Column(
                      children: [
                        _buildStatsSummary(filteredDocuments),
                        _buildTableHeader(),
                        Expanded(
                          child: filteredDocuments.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'لا توجد مقالات تطابق معايير البحث',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredDocuments.length,
                                  itemBuilder: (context, index) {
                                    return _buildTableRow(
                                        filteredDocuments[index], index);
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
