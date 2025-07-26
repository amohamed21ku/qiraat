import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qiraat/Classes/current_user_providerr.dart';
import 'dart:ui' as ui;

import 'package:qiraat/Screens/Document_Handling/DocumentDetails/DocumentDetails.dart';

class EditorChiefTasksPage extends StatefulWidget {
  const EditorChiefTasksPage({Key? key}) : super(key: key);

  @override
  State<EditorChiefTasksPage> createState() => _EditorChiefTasksPageState();
}

class _EditorChiefTasksPageState extends State<EditorChiefTasksPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'جميع الملفات';
  List<String> _filterOptions = ['جميع الملفات', 'الأحدث', 'الأقدم'];

  // Define the theme colors
  final Color primaryColor = const Color(0xffa86418);
  final Color secondaryColor = const Color(0xffcc9657);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
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
      _showErrorSnackBar('غير مسموح لك بتعيين المحكمين');
      return;
    }

    List<String> selectedReviewers = [];
    Map<String, int> reviewerWorkload = await _getReviewerWorkload();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 0,
                        blurRadius: 30,
                        offset: Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Modern Header
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [secondaryColor, primaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.people_alt,
                                  color: Colors.white, size: 28),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'تعيين المحكمين',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'اختر المحكمين المناسبين لمراجعة المستند',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Document Info Card
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.description,
                                        color: primaryColor, size: 24),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'ملف: ${(document.data() as Map<String, dynamic>)['fullName'] ?? 'غير معروف'}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Color(0xff2d3748),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),

                              // Selected Count
                              if (selectedReviewers.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryColor.withOpacity(0.1),
                                        primaryColor.withOpacity(0.05)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: primaryColor.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: primaryColor, size: 24),
                                      SizedBox(width: 12),
                                      Text(
                                        'تم اختيار ${selectedReviewers.length} محكم',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(height: 16),

                              // Reviewers List
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.grey.shade50,
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
                                        return _buildErrorState(
                                            'خطأ في تحميل المحكمين',
                                            snapshot.error.toString());
                                      }

                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return _buildLoadingState(
                                            'جاري تحميل المحكمين...');
                                      }

                                      final reviewers =
                                          snapshot.data?.docs ?? [];

                                      if (reviewers.isEmpty) {
                                        return _buildEmptyState(
                                            'لا يوجد محكمين في النظام');
                                      }

                                      return ListView.builder(
                                        padding: EdgeInsets.all(12),
                                        itemCount: reviewers.length,
                                        itemBuilder: (context, index) {
                                          final reviewer = reviewers[index];
                                          final data = reviewer.data()
                                              as Map<String, dynamic>;
                                          final reviewerName =
                                              data['fullName'] ?? 'غير معروف';
                                          final reviewerEmail =
                                              data['email'] ?? '';
                                          final reviewerPosition =
                                              data['position'] ?? '';
                                          final reviewerId = reviewer.id;
                                          final workloadCount =
                                              reviewerWorkload[reviewerId] ?? 0;
                                          final isSelected = selectedReviewers
                                              .contains(reviewerId);

                                          String reviewerType = '';
                                          IconData reviewerIcon = Icons.person;
                                          Color typeColor = Colors.grey;

                                          if (reviewerPosition
                                              .contains('سياسي')) {
                                            reviewerType = 'سياسي';
                                            reviewerIcon =
                                                Icons.account_balance;
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

                                          return Container(
                                            margin: EdgeInsets.only(bottom: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isSelected
                                                    ? primaryColor
                                                    : Colors.grey.shade200,
                                                width: isSelected ? 2 : 1,
                                              ),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: primaryColor
                                                            .withOpacity(0.2),
                                                        spreadRadius: 0,
                                                        blurRadius: 10,
                                                        offset: Offset(0, 4),
                                                      ),
                                                    ]
                                                  : [
                                                      BoxShadow(
                                                        color: Colors.grey
                                                            .withOpacity(0.1),
                                                        spreadRadius: 0,
                                                        blurRadius: 5,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    if (isSelected) {
                                                      selectedReviewers
                                                          .remove(reviewerId);
                                                    } else {
                                                      selectedReviewers
                                                          .add(reviewerId);
                                                    }
                                                  });
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Padding(
                                                  padding: EdgeInsets.all(16),
                                                  child: Row(
                                                    children: [
                                                      // Workload Indicator
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 12,
                                                                vertical: 8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: workloadCount >
                                                                  3
                                                              ? Colors.red
                                                                  .withOpacity(
                                                                      0.1)
                                                              : workloadCount >
                                                                      1
                                                                  ? Colors
                                                                      .orange
                                                                      .withOpacity(
                                                                          0.1)
                                                                  : Colors.green
                                                                      .withOpacity(
                                                                          0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          border: Border.all(
                                                            color: workloadCount >
                                                                    3
                                                                ? Colors.red
                                                                : workloadCount >
                                                                        1
                                                                    ? Colors
                                                                        .orange
                                                                    : Colors
                                                                        .green,
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            Text(
                                                              '$workloadCount',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 18,
                                                                color: workloadCount >
                                                                        3
                                                                    ? Colors.red
                                                                    : workloadCount >
                                                                            1
                                                                        ? Colors
                                                                            .orange
                                                                        : Colors
                                                                            .green,
                                                              ),
                                                            ),
                                                            Text(
                                                              'ملف',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color: workloadCount >
                                                                        3
                                                                    ? Colors.red
                                                                    : workloadCount >
                                                                            1
                                                                        ? Colors
                                                                            .orange
                                                                        : Colors
                                                                            .green,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(width: 16),

                                                      // Reviewer Info
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              reviewerName,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                                color: Color(
                                                                    0xff2d3748),
                                                              ),
                                                            ),
                                                            SizedBox(height: 6),
                                                            if (reviewerEmail
                                                                .isNotEmpty)
                                                              Text(
                                                                reviewerEmail,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade600,
                                                                ),
                                                              ),
                                                            SizedBox(height: 8),
                                                            Container(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: typeColor
                                                                    .withOpacity(
                                                                        0.1),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                              child: Text(
                                                                'محكم $reviewerType',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      typeColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(width: 16),

                                                      // Type Icon
                                                      Container(
                                                        padding:
                                                            EdgeInsets.all(12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: typeColor
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Icon(
                                                            reviewerIcon,
                                                            color: typeColor,
                                                            size: 20),
                                                      ),
                                                      SizedBox(width: 16),

                                                      // Checkbox
                                                      Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isSelected
                                                              ? primaryColor
                                                              : Colors
                                                                  .transparent,
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? primaryColor
                                                                : Colors.grey
                                                                    .shade400,
                                                            width: 2,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: isSelected
                                                            ? Icon(Icons.check,
                                                                color: Colors
                                                                    .white,
                                                                size: 16)
                                                            : null,
                                                      ),
                                                    ],
                                                  ),
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
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: selectedReviewers.isEmpty
                                            ? null
                                            : LinearGradient(
                                                colors: [
                                                  primaryColor,
                                                  secondaryColor
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: selectedReviewers.isEmpty
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: primaryColor
                                                      .withOpacity(0.3),
                                                  spreadRadius: 0,
                                                  blurRadius: 10,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: selectedReviewers.isEmpty
                                            ? null
                                            : () async {
                                                Navigator.pop(context);
                                                await _assignReviewersToDocument(
                                                    document,
                                                    selectedReviewers);
                                              },
                                        icon: Icon(
                                          Icons.assignment_ind,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        label: Text(
                                          'تعيين المحكمين (${selectedReviewers.length})',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              selectedReviewers.isEmpty
                                                  ? Colors.grey.shade400
                                                  : Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(
                                            color: Colors.grey.shade400),
                                      ),
                                      child: Text(
                                        'إلغاء',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
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

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.error_outline, color: Colors.red, size: 48),
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 12, color: Colors.red.shade400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.people_outline,
                color: Colors.grey.shade400, size: 48),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message, textDirection: ui.TextDirection.rtl)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
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
            Expanded(child: Text(message, textDirection: ui.TextDirection.rtl)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 5),
      ),
    );
  }

  Future<void> _assignReviewersToDocument(
      DocumentSnapshot document, List<String> reviewerIds) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
                SizedBox(height: 20),
                Text(
                  'جاري تعيين المحكمين...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff2d3748),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'الرجاء الانتظار',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
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

      if (reviewerIds.isEmpty) {
        throw Exception('لم يتم اختيار أي محكمين');
      }

      if (document.id.isEmpty) {
        throw Exception('معرف الوثيقة غير صحيح');
      }

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
          }
        } catch (e) {
          print('Error fetching reviewer $reviewerId: $e');
        }
      }

      if (reviewers.isEmpty) {
        throw Exception('لم يتم العثور على بيانات المحكمين');
      }

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

      if (!mounted) return;

      navigator.pop();
      _showSuccessSnackBar('تم تعيين ${reviewers.length} محكم بنجاح');
    } catch (e) {
      print('Error assigning reviewers: $e');

      if (!mounted) return;

      navigator.pop();
      _showErrorSnackBar('خطأ في تعيين المحكمين: ${e.toString()}');
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
        backgroundColor: Color(0xfff8f9fa),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 1024;
              bool isTablet = constraints.maxWidth > 768;

              return SingleChildScrollView(
                child: Column(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.arrow_back,
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
                                      'إدارة المهام',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 32 : 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '${currentUser?.position ?? 'غير معروف'}',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 18 : 16,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Modern Tab Bar
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: primaryColor,
                        indicatorWeight: 3,
                        labelColor: primaryColor,
                        unselectedLabelColor: Colors.grey.shade600,
                        labelStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        unselectedLabelStyle: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14),
                        isScrollable: !isDesktop,
                        tabs: [
                          Tab(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text('بانتظار التعيين'),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text('قيد التحكيم'),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text('تمت المراجعة'),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text('جميع الملفات'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search and Filter Section
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 80 : 20,
                        vertical: 20,
                      ),
                      color: Colors.white,
                      child: Column(
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? 600 : double.infinity,
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'ابحث عن ملف...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                ),
                                suffixIcon: Container(
                                  margin: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.search,
                                    color: Colors.white,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Color(0xfff7fafc),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 20,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              textAlign: TextAlign.right,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedFilter,
                                    icon: Icon(Icons.arrow_drop_down,
                                        color: primaryColor),
                                    items: _filterOptions
                                        .map<DropdownMenuItem<String>>(
                                            (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedFilter = newValue;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                'ترتيب حسب:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xff2d3748),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 80 : 20,
                        vertical: 20,
                      ),
                      child: _isLoading
                          ? _buildLoadingState('جاري تحميل المهام...')
                          : Container(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildFilesList(
                                    status: 'قبول الملف',
                                    canAssignReviewers: canAssignReviewers,
                                    actionLabel: 'تعيين المحكمين',
                                    actionIcon: Icons.person_add,
                                    actionCallback:
                                        _showReviewerAssignmentDialog,
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
                                    canAssignReviewers: canAssignReviewers,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
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
          return _buildErrorState('حدث خطأ', snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState('جاري تحميل الملفات...');
        }

        List<DocumentSnapshot> documents = snapshot.data!.docs;
        documents = _filterDocuments(documents);
        documents = _sortDocuments(documents);

        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.folder_open,
                      size: 64, color: Colors.grey.shade400),
                ),
                SizedBox(height: 24),
                Text(
                  status == 'تم التحكيم'
                      ? 'لا توجد ملفات تمت مراجعتها بانتظار الموافقة النهائية'
                      : 'لا توجد ملفات متاحة',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'سيتم عرض الملفات هنا عند توفرها',
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

        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _buildHorizontalDocumentCard(
                documents[index],
                canAssignReviewers,
                actionLabel,
                actionIcon,
                actionCallback,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHorizontalDocumentCard(
    DocumentSnapshot doc,
    bool canAssignReviewers,
    String? actionLabel,
    IconData? actionIcon,
    Function(DocumentSnapshot)? actionCallback,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final docStatus = data['status'] ?? 'غير معروف';
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final formattedDate = DateFormat('yyyy-MM-dd • HH:mm').format(timestamp);

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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DocumentDetailsPage(document: doc),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Status indicator
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                SizedBox(width: 16),

                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and date row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data['fullName'] ?? 'غير معروف',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xff2d3748),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 12),
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
                      SizedBox(height: 8),

                      // Status and description row
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              docStatus,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              data['about'] ?? 'لا يوجد وصف',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Reviewers row (if any)
                      if (reviewers.isNotEmpty &&
                          (docStatus == 'الي المحكمين' ||
                              docStatus == 'تم التحكيم')) ...[
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.people,
                                size: 14, color: Colors.grey.shade600),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${reviewers.length} محكم مُعيَّن',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // Show reviewer status summary
                            ...reviewers.take(3).map<Widget>((reviewer) {
                              String reviewStatus = 'Pending';
                              if (reviewer is Map<String, dynamic>) {
                                reviewStatus =
                                    reviewer['review_status']?.toString() ??
                                        'Pending';
                              }
                              Color reviewColor = reviewStatus == 'Approved'
                                  ? Colors.green
                                  : Colors.orange;
                              return Container(
                                margin: EdgeInsets.only(left: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: reviewColor,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                            if (reviewers.length > 3)
                              Text(
                                '+${reviewers.length - 3}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Action button (if applicable)
                if (actionLabel != null &&
                    actionIcon != null &&
                    canAssignReviewers) ...[
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: docStatus == 'تم التحكيم'
                            ? [Colors.green.shade500, Colors.green.shade700]
                            : [primaryColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (docStatus == 'تم التحكيم'
                                  ? Colors.green
                                  : primaryColor)
                              .withOpacity(0.3),
                          spreadRadius: 0,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
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
                      icon: Icon(actionIcon, color: Colors.white, size: 16),
                      label: Text(
                        actionLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
}
