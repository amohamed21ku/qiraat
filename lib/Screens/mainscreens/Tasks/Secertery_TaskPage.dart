import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../Classes/current_user_providerr.dart';
import '../../Document_Handling/DocumentDetails.dart';

class SecretaryTasksPage extends StatefulWidget {
  const SecretaryTasksPage({Key? key}) : super(key: key);

  @override
  State<SecretaryTasksPage> createState() => _SecretaryTasksPageState();
}

class _SecretaryTasksPageState extends State<SecretaryTasksPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'جميع الملفات';
  List<String> _filterOptions = ['جميع الملفات', 'الأحدث', 'الأقدم'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      _isLoading = false;
    });
  }

  List<DocumentSnapshot> _sortDocuments(List<DocumentSnapshot> documents) {
    if (_selectedFilter == 'الأحدث') {
      documents.sort((a, b) {
        final Timestamp aTime =
            (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        final Timestamp bTime =
            (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        return bTime.compareTo(aTime);
      });
    } else if (_selectedFilter == 'الأقدم') {
      documents.sort((a, b) {
        final Timestamp aTime =
            (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        final Timestamp bTime =
            (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        return aTime.compareTo(bTime);
      });
    }
    return documents;
  }

  List<DocumentSnapshot> _filterDocuments(List<DocumentSnapshot> documents) {
    if (_searchQuery.isEmpty) return documents;

    return documents.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final fullName = (data['fullName'] ?? '').toString().toLowerCase();
      final about = (data['about'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return fullName.contains(query) || about.contains(query);
    }).toList();
  }

  bool _canAcceptRejectFiles(String? position) {
    return position == 'رئيس التحرير' ||
        position == 'مدير التحرير' ||
        position == 'سكرتير تحرير';
  }

  Future<void> _updateDocumentStatus(
      DocumentSnapshot document, String newStatus,
      {String? rejectionReason}) async {
    try {
      final currentUserProvider =
          Provider.of<CurrentUserProvider>(context, listen: false);
      final currentUser = currentUserProvider.currentUser;

      Map<String, dynamic> updateData = {
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Add action to action log
      Map<String, dynamic> actionLogEntry = {
        'action': newStatus,
        'performedBy': currentUser?.name ?? 'غير معروف',
        'performedByPosition': currentUser?.position ?? 'غير معروف',
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (rejectionReason != null) {
        actionLogEntry['rejectionReason'] = rejectionReason;
      }

      await FirebaseFirestore.instance
          .collection('sent_documents')
          .doc(document.id)
          .update({
        ...updateData,
        'actionLog': FieldValue.arrayUnion([actionLogEntry]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة الملف بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث حالة الملف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRejectDialog(DocumentSnapshot document) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'رفض الملف',
          textDirection: ui.TextDirection.rtl,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'برجاء إدخال سبب الرفض:',
              textDirection: ui.TextDirection.rtl,
            ),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              textDirection: ui.TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'سبب الرفض...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('برجاء إدخال سبب الرفض')),
                );
                return;
              }
              Navigator.pop(context);
              _updateDocumentStatus(document, 'تم الرفض',
                  rejectionReason: reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('رفض', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context);
    final currentUser = currentUserProvider.currentUser;
    final canAcceptReject = _canAcceptRejectFiles(currentUser?.position);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xffa86418),
        title: Text(
          'إدارة المهام - ${currentUser?.position ?? 'غير معروف'}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'ملفات بانتظار الموافقة'),
            Tab(text: 'جميع الملفات'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xffa86418)))
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'بحث عن ملف...',
                          prefixIcon:
                              Icon(Icons.search, color: Color(0xffa86418)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xffa86418)),
                          ),
                        ),
                        textDirection: ui.TextDirection.rtl,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ترتيب حسب:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          DropdownButton<String>(
                            value: _selectedFilter,
                            icon: Icon(Icons.arrow_drop_down,
                                color: Color(0xffa86418)),
                            elevation: 16,
                            underline: Container(
                              height: 2,
                              color: Color(0xffa86418),
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedFilter = newValue;
                                });
                              }
                            },
                            items: _filterOptions
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFilesList(
                          status: 'ملف مرسل', canAcceptReject: canAcceptReject),
                      _buildFilesList(
                          status: null, canAcceptReject: canAcceptReject),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilesList({String? status, required bool canAcceptReject}) {
    Query query = FirebaseFirestore.instance.collection('sent_documents');

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: Color(0xffa86418)));
        }

        List<DocumentSnapshot> documents = snapshot.data!.docs;
        documents = _filterDocuments(documents);
        documents = _sortDocuments(documents);

        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'لا توجد ملفات متاحة',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            final data = doc.data() as Map<String, dynamic>;
            final docStatus = data['status'] ?? 'غير معروف';
            final timestamp = (data['timestamp'] as Timestamp).toDate();
            final formattedDate =
                DateFormat('yyyy-MM-dd • HH:mm').format(timestamp);

            Color statusColor = Colors.grey;
            IconData statusIcon = Icons.circle;

            switch (docStatus) {
              case 'ملف مرسل':
                statusColor = Colors.blue;
                statusIcon = Icons.pending_actions;
                break;
              case 'قبول الملف':
                statusColor = Colors.green[700]!;
                statusIcon = Icons.check_circle;
                break;
              case 'تم الرفض':
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
                break;
              case 'الي المحكمين':
                statusColor = Colors.purple;
                statusIcon = Icons.people;
                break;
              case 'تم التحكيم':
                statusColor = Colors.teal;
                statusIcon = Icons.rate_review;
                break;
              case 'تمت الموافقه':
                statusColor = Colors.green;
                statusIcon = Icons.thumb_up;
                break;
              case 'مرسل للتعديل':
                statusColor = Colors.orange;
                statusIcon = Icons.edit;
                break;
            }

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentDetailsPage(document: doc),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: ui.TextDirection.rtl,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              textDirection: ui.TextDirection.rtl,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person,
                                        size: 16, color: Color(0xffa86418)),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        data['fullName'] ?? 'غير معروف',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                        textDirection: ui.TextDirection.rtl,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 14, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                SizedBox(width: 4),
                                Text(
                                  docStatus,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        data['about'] ?? 'لا يوجد وصف',
                        style: TextStyle(color: Colors.grey[800], fontSize: 14),
                        textDirection: ui.TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 16),
                      if (docStatus == 'ملف مرسل' && canAcceptReject)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _showRejectDialog(doc),
                              icon: Icon(Icons.close,
                                  color: Colors.white, size: 16),
                              label: Text('رفض',
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _updateDocumentStatus(doc, 'قبول الملف'),
                              icon: Icon(Icons.check,
                                  color: Colors.white, size: 16),
                              label: Text('قبول',
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xffa86418),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
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
    );
  }
}
