import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qiraat/Classes/current_user_providerr.dart';
import 'dart:ui' as ui;

import 'package:qiraat/Screens/Document_Handling/DocumentDetails.dart';

class ReviewerTasksPage extends StatefulWidget {
  const ReviewerTasksPage({Key? key}) : super(key: key);

  @override
  State<ReviewerTasksPage> createState() => _ReviewerTasksPageState();
}

class _ReviewerTasksPageState extends State<ReviewerTasksPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'جميع الملفات';
  List<String> _filterOptions = ['جميع الملفات', 'الأحدث', 'الأقدم'];

  String? currentUserId; // Store current user's unique ID
  String? currentUserName; // Store current user's name for fallback
  String? currentUserEmail; // Store current user's email for matching

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentUserInfo();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Get current user's unique information
  Future<void> _getCurrentUserInfo() async {
    final currentUserProvider =
        Provider.of<CurrentUserProvider>(context, listen: false);
    final currentUser = currentUserProvider.currentUser;

    if (currentUser != null) {
      setState(() {
        currentUserId = currentUser.id ?? currentUser.email;
        currentUserName = currentUser.name;
        currentUserEmail = currentUser.email;
      });

      print(
          'Current User Info - ID: $currentUserId, Name: $currentUserName, Email: $currentUserEmail');
    } else {
      print('WARNING: No current user found');
    }
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

  // Check if current user matches a reviewer using multiple strategies
  bool _isCurrentUserReviewer(dynamic reviewer) {
    if (currentUserId == null || currentUserId!.isEmpty) {
      return false;
    }

    try {
      if (reviewer is Map<String, dynamic>) {
        // Check using unique ID (preferred method)
        final reviewerUserId = reviewer['userId'] ?? reviewer['id'] ?? '';
        if (reviewerUserId.isNotEmpty && reviewerUserId == currentUserId) {
          return true;
        }

        // Check using email (secondary method)
        final reviewerEmail = reviewer['email'] ?? '';
        if (reviewerEmail.isNotEmpty &&
            (reviewerEmail == currentUserId ||
                reviewerEmail == currentUserEmail)) {
          return true;
        }

        // Check using name (fallback method for old data)
        final reviewerName = reviewer['name'] ?? reviewer['fullName'] ?? '';
        if (reviewerName.isNotEmpty &&
            currentUserName != null &&
            reviewerName.toLowerCase().trim() ==
                currentUserName!.toLowerCase().trim()) {
          return true;
        }
      } else if (reviewer is String) {
        // Handle old string format
        if (reviewer == currentUserId ||
            reviewer == currentUserName ||
            reviewer == currentUserEmail) {
          return true;
        }
      }
    } catch (e) {
      print('Error checking if current user is reviewer: $e');
    }

    return false;
  }

  // Updated filtering method to use unique user identification
  List<DocumentSnapshot> _filterAssignedDocuments(
      List<DocumentSnapshot> allDocuments) {
    if (currentUserId == null || currentUserId!.isEmpty) {
      print('WARNING: No current user ID found');
      return [];
    }

    return allDocuments.where((doc) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;

        final reviewers = data['reviewers'];
        if (reviewers == null) return false;

        List<dynamic> reviewersList = [];
        if (reviewers is List) {
          reviewersList = reviewers;
        } else if (reviewers is Map) {
          reviewersList = [reviewers];
        } else {
          return false;
        }

        // Check if current user is in the reviewers list
        for (var reviewer in reviewersList) {
          if (_isCurrentUserReviewer(reviewer)) {
            return true;
          }
        }
        return false;
      } catch (e) {
        print('Error filtering assigned documents: $e');
        return false;
      }
    }).toList();
  }

  // Updated method to filter by completion status using unique identification
  List<DocumentSnapshot> _filterByCompletionStatus(
      List<DocumentSnapshot> assignedDocuments, bool completed) {
    if (currentUserId == null || currentUserId!.isEmpty) {
      return [];
    }

    return assignedDocuments.where((doc) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;

        final reviewers = data['reviewers'];
        if (reviewers == null) return false;

        List<dynamic> reviewersList = [];
        if (reviewers is List) {
          reviewersList = reviewers;
        } else if (reviewers is Map) {
          reviewersList = [reviewers];
        } else {
          return false;
        }

        bool hasReviewed = false;
        for (var reviewer in reviewersList) {
          if (_isCurrentUserReviewer(reviewer)) {
            String reviewStatus = 'Pending';

            if (reviewer is Map<String, dynamic>) {
              reviewStatus = reviewer['review_status']?.toString() ?? 'Pending';
            }
            // For string format, we assume not reviewed yet

            hasReviewed = (reviewStatus == 'Approved');
            break;
          }
        }

        return hasReviewed == completed;
      } catch (e) {
        print('Error filtering by completion status: $e');
        return false;
      }
    }).toList();
  }

  // Get current user's review status for a document
  String _getCurrentUserReviewStatus(Map<String, dynamic> data) {
    try {
      final reviewers = data['reviewers'];
      if (reviewers == null) return 'في انتظار الموافقة';

      List<dynamic> reviewersList = [];
      if (reviewers is List) {
        reviewersList = reviewers;
      } else if (reviewers is Map) {
        reviewersList = [reviewers];
      }

      for (var reviewer in reviewersList) {
        if (_isCurrentUserReviewer(reviewer)) {
          if (reviewer is Map<String, dynamic>) {
            final status = reviewer['review_status']?.toString() ?? 'Pending';
            return status == 'Approved' ? 'تمت الموافقة' : 'في انتظار الموافقة';
          }
          return 'في انتظار الموافقة';
        }
      }
    } catch (e) {
      print('Error getting current user review status: $e');
    }

    return 'في انتظار الموافقة';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context);
    final currentUser = currentUserProvider.currentUser;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Color(0xffa86418),
          title: Text(
            'قائمة التحكيم',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'بإنتظار التحكيم'),
              Tab(text: 'تم التحكيم'),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildReviewerFilesList(completed: false),
                        _buildReviewerFilesList(completed: true),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Updated widget builder for reviewer files list with unique ID support
  Widget _buildReviewerFilesList({required bool completed}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sent_documents')
          .where('status', isEqualTo: 'الي المحكمين')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 12),
                Text(
                  'حدث خطأ في تحميل البيانات',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: Color(0xffa86418)));
        }

        try {
          List<DocumentSnapshot> allDocuments = snapshot.data?.docs ?? [];

          if (allDocuments.isNotEmpty) {
            print(
                'Found ${allDocuments.length} documents with status "الي المحكمين"');
          }

          // Filter documents assigned to current user using unique ID
          List<DocumentSnapshot> assignedDocuments =
              _filterAssignedDocuments(allDocuments);

          print(
              'Found ${assignedDocuments.length} documents assigned to current user');

          // Filter by completion status
          List<DocumentSnapshot> filteredDocuments =
              _filterByCompletionStatus(assignedDocuments, completed);

          print(
              'Found ${filteredDocuments.length} documents with completion status: $completed');

          // Apply search and sort filters
          filteredDocuments = _filterDocuments(filteredDocuments);
          filteredDocuments = _sortDocuments(filteredDocuments);

          if (filteredDocuments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    completed
                        ? 'لا توجد ملفات تم تحكيمها'
                        : 'لا توجد ملفات بإنتظار التحكيم',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  if (currentUserId == null || currentUserId!.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'تأكد من تسجيل الدخول بشكل صحيح',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  // Debug information
                  if (currentUserId != null)
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'معلومات المستخدم الحالي:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'ID: ${currentUserId?.substring(0, 20)}...',
                              style: TextStyle(fontSize: 10),
                            ),
                            if (currentUserName != null)
                              Text(
                                'الاسم: $currentUserName',
                                style: TextStyle(fontSize: 10),
                              ),
                            if (currentUserEmail != null)
                              Text(
                                'البريد: $currentUserEmail',
                                style: TextStyle(fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: filteredDocuments.length,
            itemBuilder: (context, index) {
              try {
                if (index >= filteredDocuments.length) {
                  return Container();
                }

                final doc = filteredDocuments[index];
                final data = doc.data() as Map<String, dynamic>?;

                if (data == null) {
                  return Container();
                }

                final timestamp = data['timestamp'] as Timestamp?;
                final formattedDate = timestamp != null
                    ? DateFormat('yyyy-MM-dd • HH:mm')
                        .format(timestamp.toDate())
                    : 'تاريخ غير محدد';

                // Get current user's review status for this document
                String reviewerStatus = _getCurrentUserReviewStatus(data);

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
                          builder: (context) =>
                              DocumentDetailsPage(document: doc),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.person,
                                            size: 16, color: Color(0xffa86418)),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            data['fullName']?.toString() ??
                                                'غير معروف',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
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
                                  color: Colors.purple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.purple, width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.people,
                                        size: 14, color: Colors.purple),
                                    SizedBox(width: 4),
                                    Text(
                                      'الي المحكمين',
                                      style: TextStyle(
                                        color: Colors.purple,
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
                            data['about']?.toString() ?? 'لا يوجد وصف',
                            style: TextStyle(
                                color: Colors.grey[800], fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 12),

                          // Review type and assignment info
                          if (data['reviewer_type'] != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xffa86418).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Color(0xffa86418).withOpacity(0.3)),
                              ),
                              child: Text(
                                'نوع التحكيم: ${data['reviewer_type']}',
                                style: TextStyle(
                                  color: Color(0xffa86418),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                          SizedBox(height: 12),

                          // Show review status
                          if (completed)
                            Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 14, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'حالة التحكيم: $reviewerStatus',
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 14),
                                ),
                              ],
                            ),

                          SizedBox(height: 16),

                          // Action button
                          if (!completed)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DocumentDetailsPage(document: doc),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.rate_review,
                                      color: Colors.white, size: 16),
                                  label: Text('بدء التحكيم',
                                      style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xffa86418),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),

                          // Show completed review info
                          if (completed)
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.task_alt,
                                      color: Colors.green, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'تم إكمال تحكيم هذا المستند',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DocumentDetailsPage(
                                                  document: doc),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'عرض التفاصيل',
                                      style:
                                          TextStyle(color: Color(0xffa86418)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              } catch (e) {
                print('Error building list item at index $index: $e');
                return Container();
              }
            },
          );
        } catch (e) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 12),
                Text(
                  'حدث خطأ في معالجة البيانات',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '$e',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
