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

  // Alternative implementation without ordering to use until indexes are created
  Widget _buildSimpleDocumentList(String status) {
    return StreamBuilder<QuerySnapshot>(
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
                  Text(_indexErrorMessage ?? 'خطأ في قاعدة البيانات'),
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
                      child: const Text('إنشاء الفهرس'),
                    ),
                ],
              ),
            );
          }
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final documents = snapshot.data!.docs;

        if (documents.isEmpty) {
          return Center(child: Text('لا توجد مستندات بحالة $status'));
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
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final document = documents[index];
            final data = document.data() as Map<String, dynamic>;
            final DateTime? timestamp =
                (data['timestamp'] as Timestamp?)?.toDate();
            final String formattedDate = timestamp != null
                ? DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp)
                : 'لا يوجد تاريخ';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  data['fullName'] ?? 'غير معروف',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      data['email'] ?? 'لا يوجد بريد إلكتروني',
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
                trailing: Icon(Icons.arrow_back_ios),
                leading: null,
                onTap: () => _navigateToDocumentDetails(context, document),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المستندات المرسلة'),
          backgroundColor: Color(0xffa86418),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Color(0xffcc9657),
            tabs: const [
              Tab(text: 'ملف مرسل'),
              Tab(text: 'قبول الملف'),
              Tab(text: 'الي المحكمين'),
              Tab(text: 'تم التحكيم'),
              Tab(text: 'تمت الموافقه'),
              Tab(text: 'تم الرفض'),
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
            _buildSimpleDocumentList('تمت الموافقه'),
            _buildSimpleDocumentList('تم الرفض'),
            _buildSimpleDocumentList('مرسل للتعديل'),
          ],
        ),
      ),
    );
  }
}
