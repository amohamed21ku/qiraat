// Sent_documents.dart - Updated for Stage 1 Approval Workflow
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import 'package:url_launcher/url_launcher.dart';

import 'DocumentDetails/Constants/App_Constants.dart';
import 'DocumentDetails/DocumentDetails.dart';

class SentDocumentsPage extends StatefulWidget {
  const SentDocumentsPage({super.key});

  @override
  State<SentDocumentsPage> createState() => _SentDocumentsPageState();
}

class _SentDocumentsPageState extends State<SentDocumentsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _cardAnimationController;
  late Animation<double> _slideAnimation;

  String? _indexErrorMessage;
  String? _indexErrorUrl;

  // Define the theme colors matching other pages
  final Color primaryColor = const Color(0xffa86418);
  final Color secondaryColor = const Color(0xffcc9657);

  // Stage filter
  int _selectedStage = 1; // Default to Stage 1

  @override
  void initState() {
    super.initState();
    // Initialize with Stage 1 statuses
    _tabController =
        TabController(length: AppConstants.stage1Statuses.length, vsync: this);

    // Initialize animations
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _navigateToDocumentDetails(
    BuildContext context,
    DocumentSnapshot document,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentDetailsPage(document: document),
      ),
    );
  }

  void _extractIndexErrorInfo(String errorMessage) {
    final RegExp urlRegex = RegExp(
      r'https://console\.firebase\.google\.com/.*?(?=,|\s|$)',
    );
    final match = urlRegex.firstMatch(errorMessage);

    if (match != null) {
      _indexErrorUrl = match.group(0);
      _indexErrorMessage =
          'مطلوب فهرس Firestore. يرجى إنشاء الفهرس لاستخدام هذه الميزة.';
    } else {
      _indexErrorMessage =
          'خطأ في استعلام Firestore. يرجى التحقق من تكوين قاعدة البيانات.';
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  secondaryColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'جاري تحميل المقالات...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xff2d3748),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'الرجاء الانتظار',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade100, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                AppStyles.getStatusIcon(status),
                size: 80,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'لا توجد مقالات بحالة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppStyles.getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppStyles.getStatusColor(status).withOpacity(0.3),
                ),
              ),
              child: Text(
                AppStyles.getStatusDisplayName(status),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.getStatusColor(status),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'سيتم عرض المقالات هنا عند توفرها',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.error_outline, color: Colors.red, size: 48),
            ),
            SizedBox(height: 16),
            Text(
              _indexErrorMessage ?? 'خطأ في قاعدة البيانات',
              textDirection: ui.TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 16),
            if (_indexErrorUrl != null)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final Uri url = Uri.parse(_indexErrorUrl!);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  icon: Icon(Icons.build, color: Colors.white),
                  label: Text(
                    'إنشاء الفهرس',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentList(String status) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sent_documents')
            .where('status', isEqualTo: status)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final errorMessage = snapshot.error.toString();
            if (errorMessage.contains('FAILED_PRECONDITION') &&
                errorMessage.contains('requires an index')) {
              _extractIndexErrorInfo(errorMessage);
              return _buildErrorState(errorMessage);
            }
            return _buildErrorState(errorMessage);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          final documents = snapshot.data!.docs;

          if (documents.isEmpty) {
            return _buildEmptyState(status);
          }

          // Sort documents locally
          documents.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aTimestamp = aData['timestamp'] as Timestamp?;
            final bTimestamp = bData['timestamp'] as Timestamp?;

            if (aTimestamp == null || bTimestamp == null) return 0;
            return bTimestamp.compareTo(aTimestamp);
          });

          return AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      curve: Curves.easeOutBack,
                      child: _buildStage1DocumentCard(
                        documents[index],
                        status,
                        index,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStage1DocumentCard(
    DocumentSnapshot document,
    String status,
    int index,
  ) {
    final data = document.data() as Map<String, dynamic>;
    final DateTime? timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final String formattedDate = timestamp != null
        ? DateFormat('yyyy-MM-dd • HH:mm').format(timestamp)
        : 'لا يوجد تاريخ';

    final statusColor = AppStyles.getStatusColor(status);
    final statusIcon = AppStyles.getStatusIcon(status);
    final stage = AppStyles.getStageNumber(status);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDocumentDetails(context, document),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with Stage Badge
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor.withOpacity(0.8), statusColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(statusIcon, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['fullName'] ?? 'غير معروف',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xff1a202c),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: primaryColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            'المرحلة $stage',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            AppStyles.getStatusDisplayName(status),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Email Row
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email, size: 16, color: primaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['email'] ?? 'لا يوجد بريد إلكتروني',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // About section if available
                if (data['about'] != null &&
                    data['about'].toString().isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryColor.withOpacity(0.1)),
                    ),
                    child: Text(
                      data['about'],
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                // Stage 1 Progress indicator
                _buildStage1Progress(status, data),

                // Show responsible user for next action
                _buildResponsibleUser(status),

                // Show review history if available
                if (data['actionLog'] != null)
                  _buildReviewHistory(data['actionLog'] as List),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStage1Progress(String status, Map<String, dynamic> data) {
    final steps = AppConstants.getStage1WorkflowSteps();
    int currentIndex = -1;

    for (int i = 0; i < steps.length; i++) {
      if (steps[i]['status'] == status) {
        currentIndex = i;
        break;
      }
    }

    // Handle intermediate statuses
    if (currentIndex == -1) {
      if (status.startsWith('secretary_')) {
        currentIndex = 1; // Secretary review phase
      } else if (status.startsWith('editor_')) {
        currentIndex = 2; // Editor review phase
      } else if (AppStyles.isStage1FinalStatus(status)) {
        currentIndex = steps.length - 1; // Completed
      }
    }

    if (currentIndex == -1) return SizedBox.shrink();

    final progress = (currentIndex + 1) / steps.length;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تقدم المرحلة الأولى',
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
                  color: AppStyles.getStatusColor(status),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                AlwaysStoppedAnimation<Color>(AppStyles.getStatusColor(status)),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsibleUser(String status) {
    String responsibleRole = _getResponsibleRole(status);
    if (responsibleRole.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, color: Colors.blue, size: 16),
          SizedBox(width: 8),
          Text(
            'في انتظار: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            responsibleRole,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewHistory(List actionLog) {
    if (actionLog.isEmpty) return SizedBox.shrink();

    // Show only the last 2 actions
    final recentActions = actionLog.reversed.take(2).toList();

    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Text(
                'آخر الإجراءات:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...recentActions
              .map((action) => Container(
                    margin: EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${action['action'] ?? ''} - ${action['userName'] ?? ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  String _getResponsibleRole(String status) {
    switch (status) {
      case AppConstants.INCOMING:
      case AppConstants.SECRETARY_REVIEW:
        return 'سكرتير التحرير';
      case AppConstants.SECRETARY_APPROVED:
      case AppConstants.SECRETARY_EDIT_REQUESTED:
      case AppConstants.EDITOR_REVIEW:
        return 'مدير التحرير';
      case AppConstants.EDITOR_APPROVED:
      case AppConstants.EDITOR_REJECTED:
      case AppConstants.EDITOR_WEBSITE_RECOMMENDED:
      case AppConstants.EDITOR_EDIT_REQUESTED:
      case AppConstants.HEAD_REVIEW:
        return 'رئيس التحرير';
      default:
        return '';
    }
  }

  Widget _buildStageSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Text(
            'المرحلة:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff2d3748),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStageChip(1, 'الموافقة', true),
                  SizedBox(width: 8),
                  _buildStageChip(2, 'التحكيم', false),
                  SizedBox(width: 8),
                  _buildStageChip(3, 'الإنتاج', false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageChip(int stage, String title, bool isAvailable) {
    bool isSelected = _selectedStage == stage;

    return InkWell(
      onTap: isAvailable
          ? () {
              setState(() {
                _selectedStage = stage;
                // Update tab controller for new stage
                _tabController = TabController(
                    length: AppConstants.stage1Statuses.length, vsync: this);
              });
            }
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isAvailable ? Colors.grey.shade100 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isAvailable ? Colors.grey.shade300 : Colors.grey.shade400),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$stage',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isAvailable ? primaryColor : Colors.grey.shade500),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isAvailable ? Color(0xff2d3748) : Colors.grey.shade500),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            if (!isAvailable) ...[
              SizedBox(width: 4),
              Icon(
                Icons.lock,
                size: 12,
                color: Colors.grey.shade500,
              ),
            ],
          ],
        ),
      ),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 1024;

              return Column(
                children: [
                  // Modern Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 80 : 20,
                      vertical: isDesktop ? 40 : 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          secondaryColor,
                          primaryColor,
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
                    child: SafeArea(
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'المقالات الأكاديمية',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 32 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'تتبع مسار المقالات في النظام الأكاديمي - المرحلة الأولى: الموافقة',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 18 : 16,
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
                            child: Icon(
                              Icons.library_books,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Stage Selector
                  _buildStageSelector(),

                  // Tab Bar for Stage 1 Statuses
                  Container(
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
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: primaryColor,
                      indicatorWeight: 3,
                      labelColor: primaryColor,
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      tabs: AppConstants.stage1Statuses
                          .map((status) => _buildModernTab(
                                AppStyles.getStatusDisplayName(status),
                                AppStyles.getStatusIcon(status),
                                AppStyles.getStatusColor(status),
                              ))
                          .toList(),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: AppConstants.stage1Statuses
                          .map((status) => _buildDocumentList(status))
                          .toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModernTab(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
