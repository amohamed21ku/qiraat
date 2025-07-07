import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qiraat/Classes/current_user_providerr.dart';
import 'dart:ui' as ui;

import 'package:qiraat/Screens/Document_Handling/DocumentDetails.dart';

class EditorChiefTasksPage extends StatefulWidget {
  const EditorChiefTasksPage({Key? key}) : super(key: key);

  @override
  State<EditorChiefTasksPage> createState() => _EditorChiefTasksPageState();
}

class _EditorChiefTasksPageState extends State<EditorChiefTasksPage>
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
    _tabController =
        TabController(length: 4, vsync: this); // Changed from 3 to 4 tabs
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
    try {
      if (_selectedFilter == 'الأحدث') {
        documents.sort((a, b) {
          try {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;

            if (aData == null || bData == null) return 0;

            final aTime = aData['timestamp'] as Timestamp?;
            final bTime = bData['timestamp'] as Timestamp?;

            if (aTime == null || bTime == null) return 0;

            return bTime.compareTo(aTime);
          } catch (e) {
            print('Error sorting documents: $e');
            return 0;
          }
        });
      } else if (_selectedFilter == 'الأقدم') {
        documents.sort((a, b) {
          try {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;

            if (aData == null || bData == null) return 0;

            final aTime = aData['timestamp'] as Timestamp?;
            final bTime = bData['timestamp'] as Timestamp?;

            if (aTime == null || bTime == null) return 0;

            return aTime.compareTo(bTime);
          } catch (e) {
            print('Error sorting documents: $e');
            return 0;
          }
        });
      }
    } catch (e) {
      print('Error in _sortDocuments: $e');
    }
    return documents;
  }

  List<DocumentSnapshot> _filterDocuments(List<DocumentSnapshot> documents) {
    if (_searchQuery.isEmpty) return documents;

    return documents.where((doc) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;

        final fullName = (data['fullName']?.toString() ?? '').toLowerCase();
        final about = (data['about']?.toString() ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return fullName.contains(query) || about.contains(query);
      } catch (e) {
        print('Error filtering document: $e');
        return false;
      }
    }).toList();
  }

  bool _canAssignReviewers(String? position) {
    return position == 'رئيس التحرير' || position == 'مدير التحرير';
  }

  Future<Map<String, int>> _getReviewerWorkload() async {
    Map<String, int> workload = {};

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('sent_documents')
          .where('status', isEqualTo: 'الي المحكمين')
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final List<dynamic> reviewers = data['reviewers'] ?? [];

        for (var reviewer in reviewers) {
          String reviewerId = '';
          if (reviewer is Map<String, dynamic>) {
            reviewerId = reviewer['userId'] ?? reviewer['id'] ?? '';
          }

          if (reviewerId.isNotEmpty) {
            workload[reviewerId] = (workload[reviewerId] ?? 0) + 1;
          }
        }
      }
    } catch (e) {
      print('Error getting reviewer workload: $e');
    }

    return workload;
  }

  void _showReviewerAssignmentDialog(DocumentSnapshot document) async {
    final currentUserProvider =
        Provider.of<CurrentUserProvider>(context, listen: false);
    final currentUser = currentUserProvider.currentUser;

    if (!_canAssignReviewers(currentUser?.position)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'غير مسموح لك بتعيين المحكمين',
            textDirection: ui.TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<String> selectedReviewers = []; // Now stores user IDs
    Map<String, int> reviewerWorkload = await _getReviewerWorkload();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.8,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xffa86418).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.people_alt,
                                color: Color(0xffa86418), size: 28),
                            SizedBox(width: 12),
                            Text(
                              'تعيين المحكمين',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffa86418),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Document Info
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.description, color: Colors.grey[600]),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ملف: ${(document.data() as Map<String, dynamic>)['fullName'] ?? 'غير معروف'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Selected Reviewers Count
                      if (selectedReviewers.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xffa86418).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xffa86418)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Color(0xffa86418)),
                              SizedBox(width: 8),
                              Text(
                                'تم اختيار ${selectedReviewers.length} محكم',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xffa86418),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 12),

                      // Reviewers List
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .where('position', whereIn: [
                              'محكم سياسي',
                              'محكم اقتصادي',
                              'محكم اجتماعي'
                            ]).snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error,
                                          color: Colors.red, size: 48),
                                      SizedBox(height: 12),
                                      Text(
                                        'خطأ في تحميل المحكمين',
                                        style: TextStyle(color: Colors.red),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '${snapshot.error}',
                                        style: TextStyle(
                                            color: Colors.red, fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Color(0xffa86418),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'جاري تحميل المحكمين...',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final reviewers = snapshot.data?.docs ?? [];

                              if (reviewers.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.people_outline,
                                          color: Colors.grey[400], size: 64),
                                      SizedBox(height: 16),
                                      Text(
                                        'لا يوجد محكمين في النظام',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'تأكد من وجود مستخدمين بمنصب "محكم" في قاعدة البيانات',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding: EdgeInsets.all(8),
                                itemCount: reviewers.length,
                                itemBuilder: (context, index) {
                                  final reviewer = reviewers[index];
                                  final data =
                                      reviewer.data() as Map<String, dynamic>;
                                  final reviewerName =
                                      data['fullName'] ?? 'غير معروف';
                                  final reviewerEmail = data['email'] ?? '';
                                  final reviewerPosition =
                                      data['position'] ?? '';
                                  final reviewerId =
                                      reviewer.id; // Use Firestore document ID
                                  final workloadCount =
                                      reviewerWorkload[reviewerId] ?? 0;
                                  final isSelected =
                                      selectedReviewers.contains(reviewerId);

                                  // Get reviewer type for icon and color
                                  String reviewerType = '';
                                  IconData reviewerIcon = Icons.person;
                                  Color typeColor = Colors.grey;

                                  if (reviewerPosition.contains('سياسي')) {
                                    reviewerType = 'سياسي';
                                    reviewerIcon = Icons.account_balance;
                                    typeColor = Colors.blue;
                                  } else if (reviewerPosition
                                      .contains('اقتصادي')) {
                                    reviewerType = 'اقتصادي';
                                    reviewerIcon = Icons.trending_up;
                                    typeColor = Colors.green;
                                  } else if (reviewerPosition
                                      .contains('اجتماعي')) {
                                    reviewerType = 'اجتماعي';
                                    reviewerIcon = Icons.people;
                                    typeColor = Colors.purple;
                                  }

                                  return Card(
                                    margin: EdgeInsets.only(bottom: 8),
                                    elevation: isSelected ? 4 : 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected
                                            ? Color(0xffa86418)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            selectedReviewers
                                                .remove(reviewerId);
                                          } else {
                                            selectedReviewers.add(reviewerId);
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            // Workload Indicator
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: workloadCount > 3
                                                    ? Colors.red
                                                        .withOpacity(0.1)
                                                    : workloadCount > 1
                                                        ? Colors.orange
                                                            .withOpacity(0.1)
                                                        : Colors.green
                                                            .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: workloadCount > 3
                                                      ? Colors.red
                                                      : workloadCount > 1
                                                          ? Colors.orange
                                                          : Colors.green,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    '$workloadCount',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: workloadCount > 3
                                                          ? Colors.red
                                                          : workloadCount > 1
                                                              ? Colors.orange
                                                              : Colors.green,
                                                    ),
                                                  ),
                                                  Text(
                                                    'ملف',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: workloadCount > 3
                                                          ? Colors.red
                                                          : workloadCount > 1
                                                              ? Colors.orange
                                                              : Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 12),

                                            // Reviewer Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    reviewerName,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  if (reviewerEmail.isNotEmpty)
                                                    Text(
                                                      reviewerEmail,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 8,
                                                                vertical: 2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: typeColor
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                          'محكم $reviewerType',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: typeColor,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 12),

                                            // Reviewer Type Icon
                                            Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color:
                                                    typeColor.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(reviewerIcon,
                                                  color: typeColor, size: 20),
                                            ),
                                            SizedBox(width: 12),

                                            // Checkbox
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Color(0xffa86418)
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? Color(0xffa86418)
                                                      : Colors.grey,
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: isSelected
                                                  ? Icon(Icons.check,
                                                      color: Colors.white,
                                                      size: 16)
                                                  : null,
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
                        ),
                      ),
                      SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: selectedReviewers.isEmpty
                                  ? null
                                  : () async {
                                      Navigator.pop(context);
                                      await _assignReviewersToDocument(
                                          document, selectedReviewers);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedReviewers.isEmpty
                                    ? Colors.grey[400]
                                    : Color(0xffa86418),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: selectedReviewers.isEmpty ? 0 : 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assignment_ind,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'تعيين المحكمين (${selectedReviewers.length})',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey),
                                ),
                              ),
                              child: Text(
                                'إلغاء',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
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

  // Updated _assignReviewersToDocument function without reviewer type
  Future<void> _assignReviewersToDocument(
      DocumentSnapshot document, List<String> reviewerIds) async {
    // Get navigator and scaffold messenger before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xffa86418)),
                SizedBox(height: 16),
                Text('جاري تعيين المحكمين...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final currentUserProvider =
          Provider.of<CurrentUserProvider>(context, listen: false);
      final currentUser = currentUserProvider.currentUser;

      // Validate inputs
      if (reviewerIds.isEmpty) {
        throw Exception('لم يتم اختيار أي محكمين');
      }

      if (document.id.isEmpty) {
        throw Exception('معرف الوثيقة غير صحيح');
      }

      print(
          'Assigning ${reviewerIds.length} reviewers to document ${document.id}');
      print('Reviewer IDs: $reviewerIds');

      // Get reviewer details from their IDs
      List<Map<String, dynamic>> reviewers = [];
      for (String reviewerId in reviewerIds) {
        try {
          DocumentSnapshot reviewerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(reviewerId)
              .get();

          if (reviewerDoc.exists) {
            final reviewerData = reviewerDoc.data() as Map<String, dynamic>;
            reviewers.add({
              'userId': reviewerId,
              'name': reviewerData['fullName'] ?? 'غير معروف',
              'email': reviewerData['email'] ?? '',
              'position': reviewerData['position'] ?? '',
              'review_status': 'Pending',
              'assigned_date': Timestamp.now(),
            });
          } else {
            print('Reviewer document not found: $reviewerId');
          }
        } catch (e) {
          print('Error fetching reviewer $reviewerId: $e');
        }
      }

      if (reviewers.isEmpty) {
        throw Exception('لم يتم العثور على بيانات المحكمين');
      }

      // First operation: Update main document fields
      await FirebaseFirestore.instance
          .collection('sent_documents')
          .doc(document.id)
          .update({
        'status': 'الي المحكمين',
        'reviewers': reviewers,
        'assigned_by': currentUser?.name ?? 'غير معروف',
        'assigned_by_id': currentUser?.id ?? '',
        'assigned_date': FieldValue.serverTimestamp(),
      });

      // Second operation: Add action log entry
      Map<String, dynamic> actionLogEntry = {
        'action': 'الي المحكمين',
        'userName': currentUser?.name ?? 'غير معروف',
        'performedById': currentUser?.id ?? '',
        'userPosition': currentUser?.position ?? 'غير معروف',
        'reviewers': reviewers,
        'timestamp': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('sent_documents')
          .doc(document.id)
          .update({
        'actionLog': FieldValue.arrayUnion([actionLogEntry]),
      });

      print('Document updated successfully');

      // Check if widget is still mounted before using navigator/scaffold
      if (!mounted) return;

      // Close loading dialog
      navigator.pop();

      // Show success message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'تم تعيين ${reviewers.length} محكم بنجاح',
            textDirection: ui.TextDirection.rtl,
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error assigning reviewers: $e');

      // Check if widget is still mounted before using navigator/scaffold
      if (!mounted) return;

      // Close loading dialog
      navigator.pop();

      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في تعيين المحكمين: ${e.toString()}',
            textDirection: ui.TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'إعادة المحاولة',
            onPressed: () {
              _showReviewerAssignmentDialog(document);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context);
    final currentUser = currentUserProvider.currentUser;
    final canAssignReviewers = _canAssignReviewers(currentUser?.position);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Color(0xffa86418),
          title: Text(
            'إدارة المهام - ${currentUser?.position ?? 'غير معروف'}',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            isScrollable: true,
            tabs: [
              Tab(text: 'بانتظار التعيين'),
              Tab(text: 'قيد التحكيم'),
              Tab(text: 'تمت المراجعة'),
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
                          textAlign: TextAlign.right,
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
                            DropdownButton<String>(
                              value: _selectedFilter,
                              icon: Icon(Icons.arrow_drop_down,
                                  color: Color(0xffa86418)),
                              elevation: 16,
                              underline: Container(
                                  height: 2, color: Color(0xffa86418)),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedFilter = newValue;
                                  });
                                }
                              },
                              items: _filterOptions
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                            Text(
                              'ترتيب حسب:',
                              style: TextStyle(fontWeight: FontWeight.bold),
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
                          status: 'قبول الملف',
                          canAssignReviewers: canAssignReviewers,
                          actionLabel: 'تعيين المحكمين',
                          actionIcon: Icons.person_add,
                          actionCallback: _showReviewerAssignmentDialog,
                        ),
                        _buildFilesList(
                          status: 'الي المحكمين',
                          canAssignReviewers: canAssignReviewers,
                          actionLabel: 'متابعة',
                          actionIcon: Icons.visibility,
                        ),
                        _buildFilesList(
                          status: 'تم التحكيم',
                          canAssignReviewers: canAssignReviewers,
                          actionLabel: 'الموافقة النهائية',
                          actionIcon: Icons.gavel,
                        ),
                        _buildFilesList(
                            status: null,
                            canAssignReviewers: canAssignReviewers),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFilesList({
    String? status,
    required bool canAssignReviewers,
    String? actionLabel,
    IconData? actionIcon,
    Function(DocumentSnapshot)? actionCallback,
  }) {
    Query query = FirebaseFirestore.instance.collection('sent_documents');

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'حدث خطأ: ${snapshot.error}',
              textDirection: ui.TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          );
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
                  status == 'تم التحكيم'
                      ? 'لا توجد ملفات تمت مراجعتها بانتظار الموافقة النهائية'
                      : 'لا توجد ملفات متاحة',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  textDirection: ui.TextDirection.rtl,
                  textAlign: TextAlign.center,
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

            // Get reviewers information if available
            List<dynamic> reviewers = data['reviewers'] ?? [];

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
              case 'تمت الموافقة النهائية':
                statusColor = Colors.green;
                statusIcon = Icons.verified;
                break;
              case 'تم الرفض النهائي':
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                                Text(
                                  docStatus,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(statusIcon, size: 14, color: statusColor),
                              ],
                            ),
                          ),
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
                      Text(
                        data['about'] ?? 'لا يوجد وصف',
                        style: TextStyle(color: Colors.grey[800], fontSize: 14),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Show reviewer information if assigned
                      if (reviewers.isNotEmpty &&
                          (docStatus == 'الي المحكمين' ||
                              docStatus == 'تم التحكيم'))
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
                                  reviewerName = reviewer['name']?.toString() ??
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
                      if (docStatus == 'تم التحكيم' &&
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

                      SizedBox(height: 16),
                      // Action button if applicable
                      if (actionLabel != null &&
                          actionIcon != null &&
                          canAssignReviewers)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                if (actionCallback != null) {
                                  actionCallback(doc);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DocumentDetailsPage(document: doc),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(actionIcon,
                                  color: Colors.white, size: 16),
                              label: Text(actionLabel,
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: docStatus == 'تم التحكيم'
                                    ? Colors.green
                                    : Color(0xffa86418),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
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
