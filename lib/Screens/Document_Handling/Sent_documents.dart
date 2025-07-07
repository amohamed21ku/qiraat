import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qiraat/Screens/Document_Handling/DocumentDetails.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;

class SentDocumentsPage extends StatefulWidget {
  const SentDocumentsPage({super.key});

  @override
  State<SentDocumentsPage> createState() => _SentDocumentsPageState();
}

class _SentDocumentsPageState extends State<SentDocumentsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _indexErrorMessage;
  String? _indexErrorUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToDocumentDetails(
      BuildContext context, DocumentSnapshot document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentDetailsPage(document: document),
      ),
    );
  }

  void _extractIndexErrorInfo(String errorMessage) {
    // Extract the URL from the error message
    final RegExp urlRegex =
        RegExp(r'https://console\.firebase\.google\.com/.*?(?=,|\s|$)');
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

  // Get status color based on document status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'ملف مرسل':
        return Colors.blue;
      case 'قبول الملف':
        return Colors.green[700]!;
      case 'الي المحكمين':
        return Colors.purple;
      case 'تم التحكيم':
        return Colors.teal;
      case 'تمت الموافقة النهائية':
        return Colors.green;
      case 'تم الرفض النهائي':
        return Colors.red;
      case 'مرسل للتعديل':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Get status icon based on document status
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
      case 'تمت الموافقة النهائية':
        return Icons.verified;
      case 'تم الرفض النهائي':
        return Icons.cancel;
      case 'مرسل للتعديل':
        return Icons.edit;
      default:
        return Icons.circle;
    }
  }

  // Alternative implementation without ordering to use until indexes are created
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
            // Check if it's an index error
            final errorMessage = snapshot.error.toString();
            if (errorMessage.contains('FAILED_PRECONDITION') &&
                errorMessage.contains('requires an index')) {
              _extractIndexErrorInfo(errorMessage);
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _indexErrorMessage ?? 'خطأ في قاعدة البيانات',
                      textDirection: ui.TextDirection.rtl,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (_indexErrorUrl != null)
                      ElevatedButton(
                        onPressed: () async {
                          final Uri url = Uri.parse(_indexErrorUrl!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xffa86418),
                        ),
                        child: const Text(
                          'إنشاء الفهرس',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              );
            }
            return Center(
              child: Text(
                'خطأ: ${snapshot.error}',
                textDirection: ui.TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xffa86418),
              ),
            );
          }

          final documents = snapshot.data!.docs;

          if (documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد مستندات بحالة $status',
                    textDirection: ui.TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Sort documents locally
          documents.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aTimestamp = aData['timestamp'] as Timestamp?;
            final bTimestamp = bData['timestamp'] as Timestamp?;

            if (aTimestamp == null || bTimestamp == null) return 0;
            return bTimestamp.compareTo(aTimestamp); // Descending order
          });

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              final data = document.data() as Map<String, dynamic>;
              final DateTime? timestamp =
                  (data['timestamp'] as Timestamp?)?.toDate();
              final String formattedDate = timestamp != null
                  ? DateFormat('yyyy-MM-dd • HH:mm').format(timestamp)
                  : 'لا يوجد تاريخ';

              final statusColor = _getStatusColor(status);
              final statusIcon = _getStatusIcon(status);

              // Get reviewers information if available
              List<dynamic> reviewers = data['reviewers'] ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => _navigateToDocumentDetails(context, document),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row with status and name
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Status badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: statusColor, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(statusIcon,
                                      size: 14, color: statusColor),
                                ],
                              ),
                            ),
                            // Name and date
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          data['fullName'] ?? 'غير معروف',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                          textAlign: TextAlign.right,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.person,
                                          size: 16, color: Color(0xffa86418)),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.calendar_today,
                                          size: 14, color: Colors.grey),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),

                        // Email
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                data['email'] ?? 'لا يوجد بريد إلكتروني',
                                textDirection: ui.TextDirection.rtl,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.email, size: 14, color: Colors.grey),
                          ],
                        ),

                        // About section if available
                        if (data['about'] != null &&
                            data['about'].toString().isNotEmpty)
                          Column(
                            children: [
                              SizedBox(height: 8),
                              Text(
                                data['about'],
                                style: TextStyle(
                                    color: Colors.grey[800], fontSize: 14),
                                textAlign: TextAlign.right,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),

                        // Show reviewer information if assigned
                        if (reviewers.isNotEmpty &&
                            (status == 'الي المحكمين' ||
                                status == 'تم التحكيم'))
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(height: 12),
                              Text(
                                'المحكمون المعينون:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xffa86418),
                                ),
                                textAlign: TextAlign.right,
                              ),
                              SizedBox(height: 4),
                              Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 6,
                                runSpacing: 6,
                                children: reviewers.map<Widget>((reviewer) {
                                  String reviewerName = 'غير معروف';
                                  String reviewStatus = 'Pending';

                                  if (reviewer is Map<String, dynamic>) {
                                    reviewerName =
                                        reviewer['name']?.toString() ??
                                            'غير معروف';
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
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: reviewColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: reviewColor, width: 1),
                                    ),
                                    child: Text(
                                      '$reviewerName (${reviewStatus == 'Approved' ? 'تم' : 'انتظار'})',
                                      style: TextStyle(
                                          fontSize: 12, color: reviewColor),
                                      textDirection: ui.TextDirection.rtl,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),

                        // Show completion date for reviewed documents
                        if (status == 'تم التحكيم' &&
                            data['all_approved_date'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.teal.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'تم إكمال المراجعة: ${DateFormat('yyyy-MM-dd • HH:mm').format((data['all_approved_date'] as Timestamp).toDate())}',
                                      style: TextStyle(
                                        color: Colors.teal,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.check_circle_outline,
                                        color: Colors.teal, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),

                        // Show final decision information for final statuses
                        if (status == 'تمت الموافقة النهائية' ||
                            status == 'تم الرفض النهائي' ||
                            status == 'مرسل للتعديل')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: statusColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'القرار النهائي: $status',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(statusIcon,
                                        color: statusColor, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text(
            'المستندات المرسلة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xffa86418),
          iconTheme: IconThemeData(color: Colors.white),
          automaticallyImplyLeading: true,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: Icon(Icons.arrow_back_ios), // RTL back arrow
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'ملف مرسل'),
              Tab(text: 'قبول الملف'),
              Tab(text: 'الي المحكمين'),
              Tab(text: 'تم التحكيم'),
              Tab(text: 'موافقة نهائية'),
              Tab(text: 'رفض نهائي'),
              Tab(text: 'مرسل للتعديل'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSimpleDocumentList('ملف مرسل'),
            _buildSimpleDocumentList('قبول الملف'),
            _buildSimpleDocumentList('الي المحكمين'),
            _buildSimpleDocumentList('تم التحكيم'),
            _buildSimpleDocumentList('تمت الموافقة النهائية'),
            _buildSimpleDocumentList('تم الرفض النهائي'),
            _buildSimpleDocumentList('مرسل للتعديل'),
          ],
        ),
      ),
    );
  }
}
