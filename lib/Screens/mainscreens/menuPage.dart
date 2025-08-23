// menuPage.dart - Clean version with reviewer-specific view
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../myTasks.dart';
import '../../stage1/Stage1DocumentsPage.dart';
import '../../stage2/stage2documetspage.dart';
import '../../stage2/stage2Reviewer.dart'; // Stage2ReviewerDetailsPage

import '../../Document_Services.dart';
import '../../App_Constants.dart';
import '../../stage3/stage3DocumentsPage.dart';
import '../Document_Handling/all_documents.dart';
import '../Userspage.dart';
import '../../models/document_model.dart';
import '../../models/reviewerModel.dart';
import 'IncomingFilesScreen.dart';
import 'SettingsPage.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  // User data from shared preferences
  String name = '';
  String id = '';
  String email = '';
  String position = '';
  bool isLoading = true;
  int incomingFilesCount = 0;
  int pendingTasksCount = 0;
  Map<String, dynamic> allStagesStatistics = {};

  // Reviewer-specific data
  List<DocumentModel> _assignedToMe = [];
  List<DocumentModel> _reviewedByMe = [];
  bool _reviewerDataLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final DocumentService _documentService = DocumentService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
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

  // Load user data from shared preferences
  Future<void> _loadUserData() async {
    final SharedPreferences logindata = await SharedPreferences.getInstance();
    setState(() {
      name = logindata.getString('name') ?? 'مستخدم';
      id = logindata.getString('id') ?? '';
      email = logindata.getString('email') ?? '';
      position = logindata.getString('position') ?? '';
      isLoading = false;
    });

    // If user is a reviewer, load reviewer-specific data
    if (_isReviewer()) {
      await _loadReviewerTasks();
    } else {
      // Load statistics and counts for non-reviewer users
      await Future.wait([
        _loadIncomingFilesCount(),
        _loadPendingTasksCount(),
        _loadAllStagesStatistics(),
      ]);
    }
  }

  // Check if user is a reviewer
  bool _isReviewer() {
    return position.contains('محكم') ||
        position == AppConstants.POSITION_REVIEWER ||
        position == AppConstants.REVIEWER_POLITICAL ||
        position == AppConstants.REVIEWER_ECONOMIC ||
        position == AppConstants.REVIEWER_SOCIAL ||
        position == AppConstants.REVIEWER_GENERAL;
  }

  // Load reviewer tasks
  Future<void> _loadReviewerTasks() async {
    try {
      setState(() => _reviewerDataLoading = true);

      if (id.isEmpty) {
        setState(() {
          _reviewerDataLoading = false;
          _assignedToMe = [];
          _reviewedByMe = [];
        });
        return;
      }

      // Fetch only documents assigned to this reviewer
      final docs = await _documentService.getDocumentsForReviewer(id);

      // Split into "Assigned to me" vs "Reviewed by me"
      final assigned = <DocumentModel>[];
      final reviewed = <DocumentModel>[];

      for (final d in docs) {
        final me = d.reviewers.firstWhere(
          (r) => r.userId == id,
          orElse: () => ReviewerModel(
            userId: id,
            name: '',
            email: '',
            position: '',
            reviewStatus: AppConstants.REVIEWER_STATUS_PENDING,
            assignedDate: DateTime.now(),
          ),
        );
        if (me.reviewStatus == AppConstants.REVIEWER_STATUS_COMPLETED) {
          reviewed.add(d);
        } else {
          assigned.add(d);
        }
      }

      setState(() {
        _assignedToMe = assigned;
        _reviewedByMe = reviewed;
        _reviewerDataLoading = false;
      });
    } catch (e) {
      setState(() {
        _reviewerDataLoading = false;
        _assignedToMe = [];
        _reviewedByMe = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المهام: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Check if user can view incoming files
  bool _canViewIncomingFiles() {
    return PermissionService.canReviewIncomingFiles(position);
  }

  // Load count of incoming files
  Future<void> _loadIncomingFilesCount() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('sent_documents')
          .where('status', whereIn: [
        AppConstants.INCOMING,
        AppConstants.SECRETARY_REVIEW
      ]).get();

      if (mounted) {
        setState(() {
          incomingFilesCount = snapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error loading incoming files count: $e');
    }
  }

  // Load count of pending tasks for current user
  Future<void> _loadPendingTasksCount() async {
    try {
      final documents =
          await _documentService.getDocumentsForUser(id, position);
      if (mounted) {
        setState(() {
          pendingTasksCount = documents.length;
        });
      }
    } catch (e) {
      print('Error loading pending tasks count: $e');
    }
  }

  // Load All Stages workflow statistics
  Future<void> _loadAllStagesStatistics() async {
    try {
      // Get Stage 1 statistics
      final stage1Stats = <String, int>{};
      for (String status in AppConstants.stage1Statuses) {
        final count = await _getDocumentCountByStatus(status);
        stage1Stats[status] = count;
      }

      // Get Stage 2 statistics
      final stage2Stats = <String, int>{};
      for (String status in AppConstants.stage2Statuses) {
        final count = await _getDocumentCountByStatus(status);
        stage2Stats[status] = count;
      }

      // Calculate metrics
      final stage1Total =
          stage1Stats.values.fold<int>(0, (sum, count) => sum + count);
      final stage1InProgress = stage1Stats[AppConstants.INCOMING]! +
          stage1Stats[AppConstants.SECRETARY_REVIEW]! +
          stage1Stats[AppConstants.EDITOR_REVIEW]! +
          stage1Stats[AppConstants.HEAD_REVIEW]!;
      final stage1Completed = stage1Stats[AppConstants.STAGE1_APPROVED]! +
          stage1Stats[AppConstants.FINAL_REJECTED]! +
          stage1Stats[AppConstants.WEBSITE_APPROVED]!;

      final stage2Total =
          stage2Stats.values.fold<int>(0, (sum, count) => sum + count);
      final stage2InProgress = stage2Stats[AppConstants.REVIEWERS_ASSIGNED]! +
          stage2Stats[AppConstants.UNDER_PEER_REVIEW]! +
          stage2Stats[AppConstants.PEER_REVIEW_COMPLETED]! +
          stage2Stats[AppConstants.HEAD_REVIEW_STAGE2]! +
          stage2Stats[AppConstants.LANGUAGE_EDITING_STAGE2]! +
          stage2Stats[AppConstants.LANGUAGE_EDITOR_COMPLETED]! +
          stage2Stats[AppConstants.CHEF_REVIEW_LANGUAGE_EDIT]!;
      final stage2Completed = stage2Stats[AppConstants.STAGE2_APPROVED]! +
          stage2Stats[AppConstants.STAGE2_REJECTED]! +
          stage2Stats[AppConstants.STAGE2_EDIT_REQUESTED]! +
          stage2Stats[AppConstants.STAGE2_WEBSITE_APPROVED]!;

      if (mounted) {
        setState(() {
          allStagesStatistics = {
            'stage1_metrics': {
              'total': stage1Total,
              'in_progress': stage1InProgress,
              'completed': stage1Completed,
            },
            'stage2_metrics': {
              'total': stage2Total,
              'in_progress': stage2InProgress,
              'completed': stage2Completed,
            },
            'stage3_metrics': {
              'total': 0,
              'in_progress': 0,
              'completed': 0,
            },
            'ready_to_publish': stage2Stats[AppConstants.STAGE2_APPROVED] ?? 0,
          };
        });
      }
    } catch (e) {
      print('Error loading all stages statistics: $e');
    }
  }

  Future<int> _getDocumentCountByStatus(String status) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('sent_documents')
          .where('status', isEqualTo: status)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting document count for status $status: $e');
      return 0;
    }
  }

  void navigateToStageFiles(int stage) {
    if (stage == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Stage1DocumentsPage()),
      );
    } else if (stage == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Stage2DocumentsPage()),
      );
    } else if (stage == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Stage3DocumentsPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ملفات المرحلة $stage - قريباً'),
          backgroundColor: Color(0xff4299e1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Navigate to ready to publish files
  void navigateToReadyToPublishFiles() {
    // For now, show Stage 2 approved documents
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Stage2DocumentsPage()),
    );
  }

  void navigateToTasksPage() {
    if (position == AppConstants.POSITION_SECRETARY) {
      // Navigate to secretary tasks
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyTasksPage()),
      );
    } else if (position == AppConstants.POSITION_MANAGING_EDITOR ||
        position == AppConstants.POSITION_EDITOR_CHIEF) {
      // Navigate to editor tasks (both stage 1 and stage 2)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyTasksPage()),
      );
    } else if (position == AppConstants.POSITION_HEAD_EDITOR) {
      // Navigate to head editor tasks (both stage 1 and stage 2)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyTasksPage()),
      );
    } else if (position.contains('محكم') ||
        position == AppConstants.POSITION_REVIEWER ||
        position == AppConstants.REVIEWER_POLITICAL ||
        position == AppConstants.REVIEWER_ECONOMIC ||
        position == AppConstants.REVIEWER_SOCIAL ||
        position == AppConstants.REVIEWER_GENERAL) {
      // Navigate to reviewer tasks
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyTasksPage()),
      );
    } else if (position == AppConstants.POSITION_LANGUAGE_EDITOR) {
      // Navigate to language editor tasks
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyTasksPage()),
      );
    } else if (position == AppConstants.POSITION_LAYOUT_DESIGNER) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('مهام التصميم والإخراج ستكون متاحة في المرحلة الثالثة'),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (position == AppConstants.POSITION_FINAL_REVIEWER) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('مهام المراجعة النهائية ستكون متاحة في المرحلة الثالثة'),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا توجد صفحة مهام محددة لهذا المستخدم'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String getFormattedDate() {
    DateTime now = DateTime.now();
    String day = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ][now.weekday % 7];
    String month = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ][now.month - 1];
    return "$day ${now.day} $month ${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xffcc9657)),
              ),
              SizedBox(height: 20),
              Text(
                'جاري التحميل...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xfff8f9fa),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 1024;
              bool isTablet = constraints.maxWidth > 768;
              bool isSmall = constraints.maxHeight < 600;

              return RefreshIndicator(
                onRefresh: _isReviewer() ? _loadReviewerTasks : _loadUserData,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Header Section (Same for all users)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 80 : 20,
                          vertical: isDesktop ? 50 : (isSmall ? 25 : 35),
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xffcc9657),
                              Color(0xffa86418),
                              Color(0xff8b5a2b),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              spreadRadius: 0,
                              blurRadius: 25,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Top bar with date and settings
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      getFormattedDate(),
                                      style: TextStyle(
                                        fontSize: isSmall ? 14 : 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.settings_outlined,
                                      color: Colors.white,
                                      size: isSmall ? 22 : 26,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SettingPage(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                                height: isDesktop ? 50 : (isSmall ? 30 : 40)),

                            // User welcome section
                            Column(
                              children: [
                                Text(
                                  "مرحباً بعودتك،",
                                  style: TextStyle(
                                    fontSize:
                                        isDesktop ? 24 : (isSmall ? 16 : 20),
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize:
                                        isDesktop ? 40 : (isSmall ? 24 : 30),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black.withOpacity(0.3),
                                        offset: Offset(2.0, 2.0),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (position.isNotEmpty) ...[
                                  SizedBox(height: 16),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      position,
                                      style: TextStyle(
                                        fontSize: isDesktop
                                            ? 18
                                            : (isSmall ? 14 : 16),
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Content Section - Different for Reviewers vs Others
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(
                            isDesktop ? 80 : (isSmall ? 12 : 20)),
                        child: _isReviewer()
                            ? _buildReviewerContent(
                                isDesktop, isTablet, isSmall)
                            : _buildRegularUserContent(
                                isDesktop, isTablet, isSmall),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Build reviewer-specific content
  Widget _buildReviewerContent(bool isDesktop, bool isTablet, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.task_alt, color: Color(0xffa86418), size: 24),
            SizedBox(width: 12),
            Text(
              "مهام المُحكِّم",
              style: TextStyle(
                fontSize: isDesktop ? 28 : (isSmall ? 20 : 24),
                fontWeight: FontWeight.bold,
                color: Color(0xff2d3748),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          "المقالات المُسندة إليك للمراجعة والتحكيم",
          style: TextStyle(
            fontSize: isDesktop ? 16 : 14,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 24),

        // Statistics Cards
        Row(
          children: [
            Expanded(
              child: _buildReviewerStatCard(
                title: "مُسندة إليّ",
                count: _assignedToMe.length,
                icon: Icons.assignment,
                color: Color(0xff4299e1),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildReviewerStatCard(
                title: "مُراجعة مُنجزة",
                count: _reviewedByMe.length,
                icon: Icons.check_circle,
                color: Color(0xff48bb78),
              ),
            ),
          ],
        ),
        SizedBox(height: 32),

        // Tasks Tabs
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  labelColor: Color(0xffa86418),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xffa86418),
                  indicatorWeight: 3,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment, size: 18),
                          SizedBox(width: 8),
                          Text('مُسندة إليّ'),
                          if (_assignedToMe.isNotEmpty) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xff4299e1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_assignedToMe.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 18),
                          SizedBox(width: 8),
                          Text('مراجعاتي المُنجزة'),
                          if (_reviewedByMe.isNotEmpty) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xff48bb78),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_reviewedByMe.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                height: 500,
                child: TabBarView(
                  children: [
                    _buildReviewerTasksList(_assignedToMe, isReviewed: false),
                    _buildReviewerTasksList(_reviewedByMe, isReviewed: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build regular user content (original menu)
  Widget _buildRegularUserContent(bool isDesktop, bool isTablet, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "لوحة التحكم الرئيسية",
          style: TextStyle(
            fontSize: isDesktop ? 28 : (isSmall ? 20 : 24),
            fontWeight: FontWeight.bold,
            color: Color(0xff2d3748),
          ),
        ),
        SizedBox(height: 8),
        Text(
          "الوصول السريع لجميع وظائف النظام",
          style: TextStyle(
            fontSize: isDesktop ? 16 : 14,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: isSmall ? 16 : 24),

        // Enhanced Grid layout for action cards
        LayoutBuilder(
          builder: (context, constraints) {
            // Priority actions (top row)
            List<Widget> priorityActions = [
              RectangularActionCard(
                title: "مهامي",
                subtitle: "المهام المعينة لي",
                icon: Icons.task_alt,
                gradient: [Color(0xff4299e1), Color(0xff3182ce)],
                onTap: navigateToTasksPage,
                notificationCount: pendingTasksCount,
              ),
              RectangularActionCard(
                title: "جميع المقالات",
                subtitle: "عرض شامل للمقالات",
                icon: Icons.library_books,
                gradient: [Color(0xff38b2ac), Color(0xff319795)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AllDocumentsPage()),
                  );
                },
              ),
              if (_canViewIncomingFiles())
                RectangularActionCard(
                  title: "المقالات الواردة",
                  subtitle: "مقالات جديدة للمراجعة",
                  icon: Icons.article,
                  gradient: [Color(0xfff56565), Color(0xffe53e3e)],
                  onTap: () async {
                    // Navigate to incoming files
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IncomingFilesPage(),
                      ),
                    ).then((_) {
                      _loadIncomingFilesCount();
                    });
                  },
                  notificationCount: incomingFilesCount,
                ),
            ];

            // Stage files (main section)
            List<Widget> stageActions = [
              RectangularActionCard(
                title: "ملفات المرحلة 1",
                subtitle: "مراجعة وموافقة أولية",
                icon: Icons.filter_1,
                gradient: [Color(0xffe53e3e), Color(0xffc53030)],
                onTap: () => navigateToStageFiles(1),
              ),
              RectangularActionCard(
                title: "ملفات المرحلة 2",
                subtitle: "التحكيم والمراجعة العلمية",
                icon: Icons.filter_2,
                gradient: [Color(0xffed8936), Color(0xffdd6b20)],
                onTap: () => navigateToStageFiles(2),
              ),
              RectangularActionCard(
                title: "ملفات المرحلة 3",
                subtitle: "التحرير النهائي والإخراج",
                icon: Icons.filter_3,
                gradient: [Color(0xff9f7aea), Color(0xff805ad5)],
                onTap: () => navigateToStageFiles(3),
              ),
              RectangularActionCard(
                title: "جاهز للنشر",
                subtitle: "الملفات المكتملة",
                icon: Icons.publish,
                gradient: [Color(0xff48bb78), Color(0xff38a169)],
                onTap: navigateToReadyToPublishFiles,
              ),
            ];

            // Management actions (bottom section)
            List<Widget> managementActions = [
              RectangularActionCard(
                title: "المستخدمون",
                subtitle: "إدارة المستخدمين",
                icon: Icons.people_outline,
                gradient: [Color(0xff667eea), Color(0xff764ba2)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UsersPage(),
                    ),
                  );
                },
              ),
              RectangularActionCard(
                title: "الموقع الإلكتروني",
                subtitle: "زيارة الموقع الرسمي",
                icon: Icons.language,
                gradient: [Color(0xfffc8181), Color(0xfff56565)],
                onTap: () async {
                  final Uri url = Uri.parse('https://qiraatafrican.com/');
                  await launchUrl(url);
                },
              ),
            ];

            return Column(
              children: [
                // Priority Actions Section
                if (priorityActions.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.priority_high,
                          color: Color(0xffa86418), size: 20),
                      SizedBox(width: 8),
                      Text(
                        "أولويات اليوم",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2d3748),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount:
                        isDesktop ? (priorityActions.length >= 3 ? 3 : 2) : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 3.2 : 4.0,
                    children: priorityActions,
                  ),
                  SizedBox(height: 32),
                ],

                // Stage Files Section
                Row(
                  children: [
                    Icon(Icons.group_work_rounded,
                        color: Color(0xffa86418), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "مراحل سير العمل",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2d3748),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: isDesktop ? 2 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 3.5 : 4.0,
                  children: stageActions,
                ),
                SizedBox(height: 32),

                // Management Section
                Row(
                  children: [
                    Icon(Icons.settings, color: Color(0xffa86418), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "إدارة النظام",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2d3748),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: isDesktop ? 2 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 3.5 : 4.0,
                  children: managementActions,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Build reviewer statistics card
  Widget _buildReviewerStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xff2d3748),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Build reviewer tasks list
  Widget _buildReviewerTasksList(List<DocumentModel> docs,
      {required bool isReviewed}) {
    if (_reviewerDataLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xffa86418)),
            ),
            SizedBox(height: 16),
            Text(
              'جاري تحميل المهام...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isReviewed
                  ? Icons.check_circle_outline
                  : Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              isReviewed ? 'لا توجد مراجعات مُنجزة' : 'لا توجد مهام مُسندة',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              isReviewed
                  ? 'ستظهر هنا المقالات التي راجعتها'
                  : 'ستظهر هنا المقالات المُسندة إليك للمراجعة',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: docs.length,
      itemBuilder: (context, index) =>
          _buildReviewerDocCard(docs[index], isReviewed),
    );
  }

  // Build reviewer document card
  Widget _buildReviewerDocCard(DocumentModel d, bool isReviewed) {
    final statusColor = AppStyles.getStage2StatusColor(d.status);
    final statusIcon = AppStyles.getStage2StatusIcon(d.status);
    final statusName = AppStyles.getStatusDisplayName(d.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Stage2ReviewerDetailsPage(document: d),
            ),
          );

          // Reload reviewer data if needed
          if (result == true || mounted) {
            await _loadReviewerTasks();
          }
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Row
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isReviewed
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isReviewed ? 'مُنجز' : 'قيد المراجعة',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isReviewed
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Document Title
              if (d.title?.isNotEmpty == true)
                Text(
                  d.title!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              SizedBox(height: 8),

              // Document URL/Path
              if (d.documentUrl?.isNotEmpty == true)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    d.documentUrl!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),

              SizedBox(height: 12),

              // Timestamp and Assignment Info
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Text(
                    d.timestamp != null
                        ? 'التاريخ: ${_formatDate(d.timestamp)}'
                        : 'التاريخ غير محدد',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Spacer(),
                  if (!isReviewed && id.isNotEmpty) _buildAssignmentDate(d),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentDate(DocumentModel d) {
    final reviewer = d.reviewers.firstWhere(
      (r) => r.userId == id,
      orElse: () => ReviewerModel(
        userId: id,
        name: '',
        email: '',
        position: '',
        reviewStatus: AppConstants.REVIEWER_STATUS_PENDING,
        assignedDate: DateTime.now(),
      ),
    );

    return Text(
      'أُسند في: ${_formatDate(reviewer.assignedDate)}',
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey.shade500,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildAllStagesStatisticsGrid(bool isDesktop, bool isTablet) {
    final stage1Metrics = allStagesStatistics['stage1_metrics'] ?? {};
    final stage2Metrics = allStagesStatistics['stage2_metrics'] ?? {};
    final stage3Metrics = allStagesStatistics['stage3_metrics'] ?? {};
    final readyToPublish = allStagesStatistics['ready_to_publish'] ?? 0;

    final List<Map<String, dynamic>> stats = [
      {
        'title': 'المرحلة 1',
        'subtitle': 'مراجعة أولية',
        'value': '${stage1Metrics['in_progress'] ?? 0}',
        'total': '${stage1Metrics['total'] ?? 0}',
        'icon': Icons.filter_1,
        'color': Color(0xff4299e1),
      },
      {
        'title': 'المرحلة 2',
        'subtitle': 'التحكيم العلمي',
        'value': '${stage2Metrics['in_progress'] ?? 0}',
        'total': '${stage2Metrics['total'] ?? 0}',
        'icon': Icons.filter_2,
        'color': Color(0xffed8936),
      },
      {
        'title': 'المرحلة 3',
        'subtitle': 'التحرير النهائي',
        'value': '${stage3Metrics['in_progress'] ?? 0}',
        'total': '${stage3Metrics['total'] ?? 0}',
        'icon': Icons.filter_3,
        'color': Color(0xff9f7aea),
      },
      {
        'title': 'جاهز للنشر',
        'subtitle': 'مكتمل',
        'value': '$readyToPublish',
        'total': '',
        'icon': Icons.publish,
        'color': Color(0xff48bb78),
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 2),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: stats.map((stat) => _buildEnhancedStatCard(stat)).toList(),
    );
  }

  Widget _buildEnhancedStatCard(Map<String, dynamic> stat) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            stat['color'].withOpacity(0.1),
            stat['color'].withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: stat['color'].withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: stat['color'].withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: stat['color'].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  stat['icon'],
                  color: stat['color'],
                  size: 24,
                ),
              ),
              if (stat['total'].isNotEmpty)
                Text(
                  '/${stat['total']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            stat['value'],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: stat['color'],
            ),
          ),
          SizedBox(height: 4),
          Text(
            stat['title'],
            style: TextStyle(
              fontSize: 14,
              color: Color(0xff2d3748),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            stat['subtitle'],
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// Rectangular Action Card Widget
class RectangularActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final int? notificationCount;

  const RectangularActionCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.notificationCount,
  }) : super(key: key);

  @override
  _RectangularActionCardState createState() => _RectangularActionCardState();
}

class _RectangularActionCardState extends State<RectangularActionCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _elevationAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: _isHovered
                          ? LinearGradient(
                              colors: widget.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [Colors.white, Colors.white],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _isHovered
                              ? widget.gradient[0].withOpacity(0.3)
                              : Colors.black.withOpacity(0.06),
                          spreadRadius: _isHovered ? 4 : 0,
                          blurRadius: (_isHovered ? 25 : 12) *
                              _elevationAnimation.value,
                          offset: Offset(0,
                              (_isHovered ? 8 : 4) * _elevationAnimation.value),
                        ),
                        if (_isHovered)
                          BoxShadow(
                            color: widget.gradient[1].withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 15,
                            offset: Offset(0, 12),
                          ),
                      ],
                      border: Border.all(
                        color: _isHovered
                            ? Colors.transparent
                            : widget.gradient[0].withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        children: [
                          // Icon container
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _isHovered
                                  ? Colors.white.withOpacity(0.2)
                                  : widget.gradient[0].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _isHovered
                                    ? Colors.white.withOpacity(0.3)
                                    : widget.gradient[0].withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              widget.icon,
                              size: 32,
                              color: _isHovered
                                  ? Colors.white
                                  : widget.gradient[0],
                            ),
                          ),
                          SizedBox(width: 20),

                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _isHovered
                                        ? Colors.white
                                        : Color(0xff2d3748),
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  widget.subtitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _isHovered
                                        ? Colors.white.withOpacity(0.9)
                                        : Colors.grey.shade600,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Arrow indicator
                          AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isHovered
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: _isHovered
                                  ? Colors.white
                                  : widget.gradient[0].withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Notification badge
                  if (widget.notificationCount != null &&
                      widget.notificationCount! > 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xffff4757), Color(0xffff3838)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xffff4757).withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        child: Text(
                          widget.notificationCount! > 99
                              ? '99+'
                              : widget.notificationCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  // Hover effect overlay
                  if (_isHovered)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.transparent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
