import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this); // Updated to 8 tabs

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

  // Updated _getStatusColor method to include correct statuses
  Color _getStatusColor(String status) {
    switch (status) {
      case 'ملف مرسل':
        return Colors.blue.shade600;
      case 'قبول الملف':
        return Colors.green.shade700;
      case 'الي المحكمين':
        return Colors.purple.shade600;
      case 'تم التحكيم':
        return Colors.teal.shade600;
      case 'موافقة مدير التحرير':
        return Colors.orange.shade600;
      case 'موافقة رئيس التحرير':
      case 'تمت الموافقة النهائية':
        return Colors.green.shade600;
      case 'مرسل للتعديل من رئيس التحرير':
      case 'مرسل للتعديل':
        return Colors.blue.shade600;
      case 'رفض رئيس التحرير':
      case 'تم الرفض النهائي':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // Updated _getStatusIcon method to include correct statuses
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'ملف مرسل':
        return Icons.pending_actions;
      case 'قبول الملف':
        return Icons.check_circle;
      case 'الي المحكمين':
        return Icons.people;
      case 'تم التحكيم':
        return Icons.rate_review;
      case 'موافقة مدير التحرير':
        return Icons.approval;
      case 'موافقة رئيس التحرير':
      case 'تمت الموافقة النهائية':
        return Icons.verified;
      case 'مرسل للتعديل من رئيس التحرير':
      case 'مرسل للتعديل':
        return Icons.edit;
      case 'رفض رئيس التحرير':
      case 'تم الرفض النهائي':
        return Icons.cancel;
      default:
        return Icons.circle;
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
            'جاري تحميل المستندات...',
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
                Icons.folder_open,
                size: 80,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'لا توجد مستندات بحالة',
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
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(status).withOpacity(0.3),
                ),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(status),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'سيتم عرض المستندات هنا عند توفرها',
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

  Widget _buildSimpleDocumentList(String status) {
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
                      child: _buildModernDocumentCard(
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

  Widget _buildModernDocumentCard(
    DocumentSnapshot document,
    String status,
    int index,
  ) {
    final data = document.data() as Map<String, dynamic>;
    final DateTime? timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final String formattedDate = timestamp != null
        ? DateFormat('yyyy-MM-dd • HH:mm').format(timestamp)
        : 'لا يوجد تاريخ';

    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    List<dynamic> reviewers = data['reviewers'] ?? [];

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
                // Header Row
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
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
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

                // Show reviewer information if assigned
                if (reviewers.isNotEmpty &&
                    (status == 'الي المحكمين' || status == 'تم التحكيم')) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.05),
                          Colors.purple.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people, color: Colors.purple, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'المحكمون المعينون:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: reviewers.map<Widget>((reviewer) {
                            String reviewerName = 'غير معروف';
                            String reviewStatus = 'Pending';

                            if (reviewer is Map<String, dynamic>) {
                              reviewerName =
                                  reviewer['name']?.toString() ?? 'غير معروف';
                              reviewStatus =
                                  reviewer['review_status']?.toString() ??
                                      'Pending';
                            } else if (reviewer is String) {
                              reviewerName = reviewer;
                              reviewStatus = 'Pending';
                            }

                            if (reviewerName.isEmpty ||
                                reviewerName == 'null') {
                              reviewerName = 'غير معروف';
                            }

                            Color reviewColor = reviewStatus == 'Approved'
                                ? Colors.green
                                : Colors.orange;

                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    reviewColor.withOpacity(0.1),
                                    reviewColor.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: reviewColor.withOpacity(0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: reviewColor.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    reviewStatus == 'Approved'
                                        ? Icons.check_circle
                                        : Icons.pending,
                                    size: 16,
                                    color: reviewColor,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '$reviewerName (${reviewStatus == 'Approved' ? 'تم' : 'انتظار'})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: reviewColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],

                // Show completion date for reviewed documents
                if (status == 'تم التحكيم' &&
                    data['all_approved_date'] != null) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.teal.withOpacity(0.1),
                          Colors.teal.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.teal,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تم إكمال المراجعة: ${DateFormat('yyyy-MM-dd • HH:mm').format((data['all_approved_date'] as Timestamp).toDate())}',
                            style: TextStyle(
                              color: Colors.teal.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Show final decision information for final statuses
                if (status == 'موافقة رئيس التحرير' ||
                    status == 'تمت الموافقة النهائية' ||
                    status == 'رفض رئيس التحرير' ||
                    status == 'مرسل للتعديل من رئيس التحرير') ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(0.1),
                          statusColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'القرار النهائي: $status',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
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
              bool isTablet = constraints.maxWidth > 768;

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
                                  'المستندات المرسلة',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 32 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'تتبع حالة جميع المستندات المرسلة',
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
                              Icons.folder_shared,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Modern Tab Bar
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
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: [
                        _buildModernTab(
                          'ملف مرسل',
                          Icons.pending_actions,
                          Colors.blue.shade600,
                        ),
                        _buildModernTab(
                          'قبول الملف',
                          Icons.check_circle,
                          Colors.green.shade700,
                        ),
                        _buildModernTab(
                          'الي المحكمين',
                          Icons.people,
                          Colors.purple.shade600,
                        ),
                        _buildModernTab(
                          'تم التحكيم',
                          Icons.rate_review,
                          Colors.teal.shade600,
                        ),
                        _buildModernTab(
                          'موافقة مدير التحرير',
                          Icons.approval,
                          Colors.orange.shade600,
                        ),
                        _buildModernTab(
                          'موافقة رئيس التحرير',
                          Icons.verified,
                          Colors.green.shade600,
                        ),
                        _buildModernTab(
                          'مرسل للتعديل',
                          Icons.edit,
                          Colors.orange.shade600,
                        ),
                        _buildModernTab(
                          'مرفوض',
                          Icons.cancel,
                          Colors.red.shade600,
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSimpleDocumentList('ملف مرسل'),
                        _buildSimpleDocumentList('قبول الملف'),
                        _buildSimpleDocumentList('الي المحكمين'),
                        _buildSimpleDocumentList('تم التحكيم'),
                        _buildSimpleDocumentList('موافقة مدير التحرير'),
                        _buildSimpleDocumentList('موافقة رئيس التحرير'),
                        _buildSimpleDocumentList(
                          'مرسل للتعديل من رئيس التحرير',
                        ),
                        _buildSimpleDocumentList('رفض رئيس التحرير'),
                      ],
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), SizedBox(width: 6), Text(text)],
      ),
    );
  }
}
