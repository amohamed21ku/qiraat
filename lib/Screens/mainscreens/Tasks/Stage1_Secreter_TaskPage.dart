// Tasks/Stage1_Secretary_TaskPage.dart - Secretary Tasks for Stage 1 Approval Workflow
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import '../../../../Classes/current_user_providerr.dart';
import '../../Document_Handling/DocumentDetails/Constants/App_Constants.dart';
import '../../Document_Handling/DocumentDetails/DocumentDetails.dart';
import '../../Document_Handling/DocumentDetails/Services/Document_Services.dart';

class Stage1SecretaryTasksPage extends StatefulWidget {
  @override
  _Stage1SecretaryTasksPageState createState() =>
      _Stage1SecretaryTasksPageState();
}

class _Stage1SecretaryTasksPageState extends State<Stage1SecretaryTasksPage>
    with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Secretary-specific statuses for Stage 1
  final List<String> secretaryStatuses = [
    AppConstants.INCOMING,
    AppConstants.SECRETARY_REVIEW,
    AppConstants.SECRETARY_APPROVED,
    AppConstants.SECRETARY_REJECTED,
    AppConstants.SECRETARY_EDIT_REQUESTED,
  ];

  Map<String, int> statusCounts = {};
  bool isLoading = true;
  String? currentUserId;
  String? currentUserName;
  String? currentUserPosition;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: secretaryStatuses.length, vsync: this);

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeUserData();
    _loadTaskCounts();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeUserData() {
    final currentUserProvider =
        Provider.of<CurrentUserProvider>(context, listen: false);
    final currentUser = currentUserProvider.currentUser;

    if (currentUser != null) {
      currentUserId = currentUser.id ?? currentUser.email;
      currentUserName = currentUser.name;
      currentUserPosition = currentUser.position;
    }
  }

  Future<void> _loadTaskCounts() async {
    setState(() => isLoading = true);

    try {
      for (String status in secretaryStatuses) {
        final docs = await _documentService.getDocumentsByStatus(status);
        statusCounts[status] = docs.length;
      }
    } catch (e) {
      print('Error loading task counts: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xfff8f9fa),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildStatisticsCards(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: secretaryStatuses
                      .map((status) => _buildTaskList(status))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
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
                    icon: Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مهام سكرتير التحرير',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'المرحلة الأولى: الموافقة والمراجعة الأولية',
                        style: TextStyle(
                          fontSize: 16,
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
                  child:
                      Icon(Icons.assignment_ind, color: Colors.white, size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    if (isLoading) {
      return Container(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final totalTasks =
        statusCounts.values.fold<int>(0, (sum, count) => sum + count);
    final pendingTasks = (statusCounts[AppConstants.INCOMING] ?? 0) +
        (statusCounts[AppConstants.SECRETARY_REVIEW] ?? 0);
    final completedTasks =
        (statusCounts[AppConstants.SECRETARY_APPROVED] ?? 0) +
            (statusCounts[AppConstants.SECRETARY_REJECTED] ?? 0) +
            (statusCounts[AppConstants.SECRETARY_EDIT_REQUESTED] ?? 0);

    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'إجمالي المهام',
              totalTasks.toString(),
              Icons.assignment,
              Colors.blue,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'في الانتظار',
              pendingTasks.toString(),
              Icons.pending,
              Colors.orange,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'مكتملة',
              completedTasks.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
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
        indicatorColor: AppStyles.primaryColor,
        indicatorWeight: 3,
        labelColor: AppStyles.primaryColor,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        tabs: secretaryStatuses.map((status) {
          final count = statusCounts[status] ?? 0;
          return Tab(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppStyles.getStatusIcon(status), size: 16),
                    SizedBox(width: 4),
                    if (count > 0)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  AppStyles.getStatusDisplayName(status),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sent_documents')
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('خطأ في تحميل المهام: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final documents = snapshot.data!.docs;

        if (documents.isEmpty) {
          return _buildEmptyState(status);
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            return _buildTaskCard(documents[index], status);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(DocumentSnapshot document, String status) {
    final data = document.data() as Map<String, dynamic>;
    final DateTime? timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final String formattedDate = timestamp != null
        ? DateFormat('yyyy-MM-dd • HH:mm').format(timestamp)
        : 'لا يوجد تاريخ';

    final statusColor = AppStyles.getStatusColor(status);
    final statusIcon = AppStyles.getStatusIcon(status);
    final priority = _getTaskPriority(status, timestamp);

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
        ],
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDocumentDetails(document),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with priority
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
                    Column(
                      children: [
                        if (priority['level'] > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: priority['color'],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              priority['text'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        SizedBox(height: 4),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

                // Author Email
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email,
                          size: 16, color: AppStyles.primaryColor),
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

                // Next Action Required
                if (_getNextAction(status).isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.next_plan, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الإجراء المطلوب: ${_getNextAction(status)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action button for pending items
                if (_canTakeAction(status)) ...[
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade500, Colors.green.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToDocumentDetails(document),
                      icon: Icon(Icons.edit, color: Colors.white, size: 20),
                      label: Text(
                        _getActionButtonText(status),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppStyles.primaryColor),
          SizedBox(height: 16),
          Text(
            'جاري تحميل المهام...',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              AppStyles.getStatusIcon(status),
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'لا توجد مهام',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'لا توجد مقالات بحالة ${AppStyles.getStatusDisplayName(status)}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          SizedBox(height: 16),
          Text(
            'خطأ في التحميل',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToDocumentDetails(DocumentSnapshot document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentDetailsPage(document: document),
      ),
    ).then((_) {
      // Refresh counts when returning
      _loadTaskCounts();
    });
  }

  Map<String, dynamic> _getTaskPriority(String status, DateTime? timestamp) {
    if (timestamp == null)
      return {'level': 0, 'text': '', 'color': Colors.grey};

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    // Priority based on status and time
    switch (status) {
      case AppConstants.INCOMING:
        if (difference.inHours > 24) {
          return {'level': 3, 'text': 'عاجل', 'color': Colors.red};
        } else if (difference.inHours > 12) {
          return {'level': 2, 'text': 'مهم', 'color': Colors.orange};
        } else if (difference.inHours > 6) {
          return {'level': 1, 'text': 'عادي', 'color': Colors.blue};
        }
        break;

      case AppConstants.SECRETARY_REVIEW:
        if (difference.inDays > 2) {
          return {'level': 3, 'text': 'متأخر', 'color': Colors.red};
        } else if (difference.inDays > 1) {
          return {'level': 2, 'text': 'مهم', 'color': Colors.orange};
        }
        break;
    }

    return {'level': 0, 'text': '', 'color': Colors.grey};
  }

  String _getNextAction(String status) {
    switch (status) {
      case AppConstants.INCOMING:
        return 'بدء المراجعة الأولية';
      case AppConstants.SECRETARY_REVIEW:
        return 'اتخاذ قرار (موافقة/رفض/تعديل)';
      case AppConstants.SECRETARY_APPROVED:
        return 'في انتظار مدير التحرير';
      case AppConstants.SECRETARY_REJECTED:
        return 'تم الرفض - إشعار المؤلف';
      case AppConstants.SECRETARY_EDIT_REQUESTED:
        return 'في انتظار مدير التحرير';
      default:
        return '';
    }
  }

  bool _canTakeAction(String status) {
    return [
      AppConstants.INCOMING,
      AppConstants.SECRETARY_REVIEW,
    ].contains(status);
  }

  String _getActionButtonText(String status) {
    switch (status) {
      case AppConstants.INCOMING:
        return 'بدء المراجعة';
      case AppConstants.SECRETARY_REVIEW:
        return 'اتخاذ قرار';
      default:
        return 'عرض التفاصيل';
    }
  }
}
