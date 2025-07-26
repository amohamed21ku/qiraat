import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qiraat/Classes/current_user_providerr.dart';
import 'dart:ui' as ui;

import 'package:qiraat/Screens/Document_Handling/DocumentDetails/DocumentDetails.dart';

class ReviewerTasksPage extends StatefulWidget {
  const ReviewerTasksPage({Key? key}) : super(key: key);

  @override
  State<ReviewerTasksPage> createState() => _ReviewerTasksPageState();
}

class _ReviewerTasksPageState extends State<ReviewerTasksPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _cardAnimationController;
  late Animation<double> _slideAnimation;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'جميع الملفات';
  List<String> _filterOptions = ['جميع الملفات', 'الأحدث', 'الأقدم'];

  // Define the theme colors matching EditorChiefTasksPage
  final Color primaryColor = const Color(0xffa86418);
  final Color secondaryColor = const Color(0xffcc9657);

  String? currentUserId;
  String? currentUserName;
  String? currentUserEmail;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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
          parent: _cardAnimationController, curve: Curves.easeOutBack),
    );

    _getCurrentUserInfo();
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _cardAnimationController.dispose();
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
    _cardAnimationController.forward();
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
        final reviewerUserId = reviewer['userId'] ?? reviewer['id'] ?? '';
        if (reviewerUserId.isNotEmpty && reviewerUserId == currentUserId) {
          return true;
        }

        final reviewerEmail = reviewer['email'] ?? '';
        if (reviewerEmail.isNotEmpty &&
            (reviewerEmail == currentUserId ||
                reviewerEmail == currentUserEmail)) {
          return true;
        }

        final reviewerName = reviewer['name'] ?? reviewer['fullName'] ?? '';
        if (reviewerName.isNotEmpty &&
            currentUserName != null &&
            reviewerName.toLowerCase().trim() ==
                currentUserName!.toLowerCase().trim()) {
          return true;
        }
      } else if (reviewer is String) {
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

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  secondaryColor.withOpacity(0.1)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xff2d3748),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'الرجاء الانتظار...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, bool completed) {
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
                  colors: [
                    Colors.grey.shade100,
                    Colors.grey.shade50,
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
              child: Icon(
                completed ? Icons.task_alt : Icons.assignment_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              completed
                  ? 'سيتم عرض الملفات المكتملة هنا'
                  : 'سيتم عرض الملفات المطلوب تحكيمها هنا',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            if (currentUserId == null || currentUserId!.isEmpty)
              Container(
                margin: EdgeInsets.only(top: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'تأكد من تسجيل الدخول بشكل صحيح',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserProvider = Provider.of<CurrentUserProvider>(context);
    final currentUser = currentUserProvider.currentUser;

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
                                      'قائمة التحكيم',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 32 : 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '${currentUser?.position ?? 'محكم'} • ${currentUser?.name ?? 'غير معروف'}',
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
                                  Icons.rate_review,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ],
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
                        indicatorColor: primaryColor,
                        indicatorWeight: 3,
                        labelColor: primaryColor,
                        unselectedLabelColor: Colors.grey.shade600,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        tabs: [
                          Tab(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.pending_actions, size: 20),
                                  SizedBox(width: 8),
                                  Text('بإنتظار التحكيم'),
                                ],
                              ),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.task_alt, size: 20),
                                  SizedBox(width: 8),
                                  Text('تم التحكيم'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search and Filter Section
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 80 : 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? 600 : double.infinity,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
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
                                    gradient: LinearGradient(
                                      colors: [primaryColor, secondaryColor],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
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
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
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
                                            fontWeight: FontWeight.w500,
                                          ),
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
                              Row(
                                children: [
                                  Icon(Icons.sort,
                                      color: primaryColor, size: 20),
                                  SizedBox(width: 8),
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
                                  _buildReviewerFilesList(completed: false),
                                  _buildReviewerFilesList(completed: true),
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

  Widget _buildReviewerFilesList({required bool completed}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sent_documents')
          .where('status', isEqualTo: 'الي المحكمين')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'حدث خطأ في تحميل البيانات',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState('جاري تحميل الملفات...');
        }

        try {
          List<DocumentSnapshot> allDocuments = snapshot.data?.docs ?? [];
          List<DocumentSnapshot> assignedDocuments =
              _filterAssignedDocuments(allDocuments);
          List<DocumentSnapshot> filteredDocuments =
              _filterByCompletionStatus(assignedDocuments, completed);
          filteredDocuments = _filterDocuments(filteredDocuments);
          filteredDocuments = _sortDocuments(filteredDocuments);

          if (filteredDocuments.isEmpty) {
            return _buildEmptyState(
                completed
                    ? 'لا توجد ملفات تم تحكيمها'
                    : 'لا توجد ملفات بإنتظار التحكيم',
                completed);
          }

          return AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredDocuments.length,
                  itemBuilder: (context, index) {
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      curve: Curves.easeOutBack,
                      child: _buildModernDocumentCard(
                        filteredDocuments[index],
                        completed,
                        index,
                      ),
                    );
                  },
                ),
              );
            },
          );
        } catch (e) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'حدث خطأ في معالجة البيانات',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$e',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildModernDocumentCard(
      DocumentSnapshot doc, bool completed, int index) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return Container();

    final timestamp = data['timestamp'] as Timestamp?;
    final formattedDate = timestamp != null
        ? DateFormat('yyyy-MM-dd • HH:mm').format(timestamp.toDate())
        : 'تاريخ غير محدد';

    String reviewerStatus = _getCurrentUserReviewStatus(data);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
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
        border: Border.all(
          color: completed
              ? Colors.green.withOpacity(0.3)
              : primaryColor.withOpacity(0.1),
          width: 1,
        ),
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
                          colors: completed
                              ? [Colors.green.shade400, Colors.green.shade600]
                              : [primaryColor.withOpacity(0.8), secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (completed ? Colors.green : primaryColor)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        completed ? Icons.task_alt : Icons.rate_review,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['fullName']?.toString() ?? 'غير معروف',
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
                              Icon(Icons.schedule,
                                  size: 14, color: Colors.grey.shade600),
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people, size: 14, color: Colors.purple),
                          SizedBox(width: 4),
                          Text(
                            'الي المحكمين',
                            style: TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Content
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    data['about']?.toString() ?? 'لا يوجد وصف',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                SizedBox(height: 16),

                // Review type
                if (data['reviewer_type'] != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.1),
                          secondaryColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category, size: 16, color: primaryColor),
                        SizedBox(width: 6),
                        Text(
                          'نوع التحكيم: ${data['reviewer_type']}',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 16),

                // Status and Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (completed)
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.1),
                                Colors.green.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'حالة التحكيم: $reviewerStatus',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!completed)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
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
                                color: Colors.white, size: 18),
                            label: Text(
                              'بدء التحكيم',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (completed) ...[
                      SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DocumentDetailsPage(document: doc),
                            ),
                          );
                        },
                        icon: Icon(Icons.visibility,
                            color: primaryColor, size: 18),
                        label: Text(
                          'عرض التفاصيل',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
