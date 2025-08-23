// pages/MyTasksPage.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qiraat/stage1/Stag1HeadEditorDetailsPage.dart';
import 'package:qiraat/stage1/Stage1EditorDetailsPage.dart';
import 'package:qiraat/stage1/Stage1SecretaryDetailsPage.dart';
import 'package:qiraat/stage2/Stage2ChefEditorLanguageReview.dart';
import 'package:qiraat/stage2/stage2HeadEditor.dart';
import 'package:qiraat/stage2/stage2LanguageEditorPage.dart';
import 'package:qiraat/stage2/stage2Reviewer.dart';
import 'package:qiraat/stage3/Stage3ManagingEditor.dart';
import 'package:qiraat/stage3/stage3FinalReviewerPage.dart';
import 'package:qiraat/stage3/stage3HeadEditorPage.dart';
import 'package:qiraat/stage3/stage3LayoutDesign.dart';
import 'dart:ui' as ui;

import '../Classes/current_user_providerr.dart';
import '../App_Constants.dart';
import '../Document_Services.dart';
import '../models/document_model.dart';

class MyTasksPage extends StatefulWidget {
  @override
  _MyTasksPageState createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage>
    with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();

  List<DocumentModel> _allTasks = [];
  List<DocumentModel> _filteredTasks = [];
  String _searchQuery = '';
  String _selectedStageFilter = 'all';
  String _selectedStatusFilter = 'all';
  bool _isLoading = true;

  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPosition;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _stageFilters = [
    {'key': 'all', 'title': 'جميع المراحل', 'icon': Icons.all_inclusive},
    {'key': '1', 'title': 'المرحلة الأولى', 'icon': Icons.filter_1},
    {'key': '2', 'title': 'المرحلة الثانية', 'icon': Icons.filter_2},
    {'key': '3', 'title': 'المرحلة الثالثة', 'icon': Icons.filter_3},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentUserInfo();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _getCurrentUserInfo() async {
    final currentUserProvider =
        Provider.of<CurrentUserProvider>(context, listen: false);
    final currentUser = currentUserProvider.currentUser;

    if (currentUser != null) {
      setState(() {
        _currentUserId = currentUser.id ?? currentUser.email;
        _currentUserName = currentUser.name;
        _currentUserPosition = currentUser.position;
      });
      await _loadUserTasks();
    }
  }

  Future<void> _loadUserTasks() async {
    if (_currentUserId == null || _currentUserPosition == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final tasks = await _documentService.getDocumentsForUser(
        _currentUserId!,
        _currentUserPosition!,
      );

      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user tasks: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<DocumentModel> filtered = List.from(_allTasks);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        return doc.fullName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            doc.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            AppStyles.getStatusDisplayName(doc.status)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply stage filter
    if (_selectedStageFilter != 'all') {
      int stage = int.parse(_selectedStageFilter);
      filtered = filtered.where((doc) {
        return AppStyles.getStageNumber(doc.status) == stage;
      }).toList();
    }

    // Apply status filter
    if (_selectedStatusFilter != 'all') {
      filtered = filtered.where((doc) {
        return doc.status == _selectedStatusFilter;
      }).toList();
    }

    // Sort by priority and timestamp
    filtered.sort((a, b) {
      final aPriority = _getTaskPriority(a.status);
      final bPriority = _getTaskPriority(b.status);

      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }

      return b.timestamp.compareTo(a.timestamp);
    });

    setState(() {
      _filteredTasks = filtered;
    });
  }

  int _getTaskPriority(String status) {
    // High priority tasks (needs immediate action)
    final highPriorityStatuses = [
      AppConstants.INCOMING,
      AppConstants.SECRETARY_REVIEW,
      AppConstants.EDITOR_REVIEW,
      AppConstants.HEAD_REVIEW,
      AppConstants.STAGE1_APPROVED,
      AppConstants.LANGUAGE_EDITING_STAGE2,
      AppConstants.CHEF_REVIEW_LANGUAGE_EDIT,
      AppConstants.LAYOUT_DESIGN_STAGE3,
      AppConstants.FINAL_REVIEW_STAGE,
      AppConstants.FINAL_MODIFICATIONS,
    ];

    if (highPriorityStatuses.contains(status)) {
      return 1; // High priority
    }

    return 2; // Normal priority
  }

  String _getUserRoleDescription() {
    switch (_currentUserPosition) {
      case AppConstants.POSITION_SECRETARY:
        return 'مراجعة الملفات الواردة والتحقق من المتطلبات';
      case AppConstants.POSITION_MANAGING_EDITOR:
      case AppConstants.POSITION_EDITOR_CHIEF:
        return 'مراجعة المحتوى وإدارة سير العمل';
      case AppConstants.POSITION_HEAD_EDITOR:
        return 'الإشراف العام واتخاذ القرارات النهائية';
      case AppConstants.POSITION_LANGUAGE_EDITOR:
        return 'التدقيق اللغوي والأسلوبي';
      case AppConstants.POSITION_LAYOUT_DESIGNER:
        return 'التصميم والإخراج الفني';
      case AppConstants.POSITION_FINAL_REVIEWER:
        return 'المراجعة النهائية قبل النشر';
      default:
        if (_currentUserPosition?.contains('محكم') == true) {
          return 'التحكيم العلمي والأكاديمي';
        }
        return 'إدارة المهام';
    }
  }

  Color _getUserRoleColor() {
    switch (_currentUserPosition) {
      case AppConstants.POSITION_SECRETARY:
        return Colors.blue.shade600;
      case AppConstants.POSITION_MANAGING_EDITOR:
      case AppConstants.POSITION_EDITOR_CHIEF:
        return Colors.purple.shade600;
      case AppConstants.POSITION_HEAD_EDITOR:
        return Colors.indigo.shade600;
      case AppConstants.POSITION_LANGUAGE_EDITOR:
        return Colors.green.shade600;
      case AppConstants.POSITION_LAYOUT_DESIGNER:
        return Colors.deepPurple.shade600;
      case AppConstants.POSITION_FINAL_REVIEWER:
        return Colors.orange.shade600;
      default:
        if (_currentUserPosition?.contains('محكم') == true) {
          return Colors.teal.shade600;
        }
        return AppStyles.primaryColor;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppStyles.backgroundColor,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildFiltersSection(),
              Expanded(child: _buildTasksList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final userColor = _getUserRoleColor();

    return Container(
      padding: EdgeInsets.fromLTRB(20, 50, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [userColor, userColor.withOpacity(0.8)],
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
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.task_alt,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مهامي',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _getUserRoleDescription(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_filteredTasks.length} مهمة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildTasksOverviewStats(),
        ],
      ),
    );
  }

  Widget _buildTasksOverviewStats() {
    if (_allTasks.isEmpty) return SizedBox.shrink();

    final highPriorityTasks = _allTasks.where((task) {
      return _getTaskPriority(task.status) == 1;
    }).length;

    final stage1Tasks = _allTasks.where((task) {
      return AppStyles.getStageNumber(task.status) == 1;
    }).length;

    final stage2Tasks = _allTasks.where((task) {
      return AppStyles.getStageNumber(task.status) == 2;
    }).length;

    final stage3Tasks = _allTasks.where((task) {
      return AppStyles.getStageNumber(task.status) == 3;
    }).length;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'عالية الأولوية',
              highPriorityTasks.toString(),
              Icons.priority_high,
              Colors.white,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              'المرحلة 1',
              stage1Tasks.toString(),
              Icons.filter_1,
              Colors.white,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              'المرحلة 2',
              stage2Tasks.toString(),
              Icons.filter_2,
              Colors.white,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              'المرحلة 3',
              stage3Tasks.toString(),
              Icons.filter_3,
              Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                hintText: 'البحث في المهام...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          SizedBox(height: 10),

          // Filter Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Stage filters
                ..._stageFilters.map((filter) {
                  final isSelected = _selectedStageFilter == filter['key'];
                  final color = _getUserRoleColor();

                  return Container(
                    margin: EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedStageFilter = filter['key'];
                          _applyFilters();
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(minWidth: 90),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    color.withOpacity(0.6),
                                    color.withOpacity(0.8)
                                  ],
                                )
                              : LinearGradient(
                                  colors: [Colors.white, Colors.white],
                                ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? color.withOpacity(0.6)
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              filter['icon'],
                              color: isSelected
                                  ? Colors.white
                                  : color.withOpacity(0.6),
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                filter['title'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : color.withOpacity(0.6),
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: _getUserRoleColor(),
            ),
            SizedBox(height: 20),
            Text(
              'جاري تحميل المهام...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredTasks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        return _buildTaskCard(task, index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.task_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'لا توجد مهام',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'لا توجد مهام تطابق البحث'
                : 'لم يتم تعيين أي مهام لك حالياً',
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

  Widget _buildTaskCard(DocumentModel task, int index) {
    final statusColor = AppStyles.getStatusColor(task.status);
    final statusIcon = AppStyles.getStatusIcon(task.status);
    final statusName = AppStyles.getStatusDisplayName(task.status);
    final stageNumber = AppStyles.getStageNumber(task.status);
    final isHighPriority = _getTaskPriority(task.status) == 1;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isHighPriority
              ? Colors.red.withOpacity(0.5)
              : statusColor.withOpacity(0.2),
          width: isHighPriority ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToTaskDetails(task),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and priority
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              statusName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            if (isHighPriority) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'عاجل',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _getTaskDescription(task.status),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStageColor(stageNumber).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  _getStageColor(stageNumber).withOpacity(0.3)),
                        ),
                        child: Text(
                          'المرحلة $stageNumber',
                          style: TextStyle(
                            color: _getStageColor(stageNumber),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDate(task.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Document info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.fullName.isNotEmpty ? task.fullName : 'مستند',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2d3748),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          task.email.isNotEmpty
                              ? task.email
                              : 'بدون بريد إلكتروني',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Action required section
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(0.1),
                      statusColor.withOpacity(0.05)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment, color: statusColor, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getRequiredAction(task.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Action button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToTaskDetails(task),
                      icon: Icon(Icons.play_arrow, size: 18),
                      label: Text('إنجاز المهمة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isHighPriority ? Colors.red : statusColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => _showTaskQuickActions(task),
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStageColor(int stage) {
    switch (stage) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getTaskDescription(String status) {
    switch (status) {
      case AppConstants.INCOMING:
      case AppConstants.SECRETARY_REVIEW:
        return 'يحتاج مراجعة السكرتير';
      case AppConstants.EDITOR_REVIEW:
        return 'يحتاج مراجعة مدير التحرير';
      case AppConstants.HEAD_REVIEW:
        return 'يحتاج مراجعة رئيس التحرير';
      case AppConstants.STAGE1_APPROVED:
        return 'جاهز لتعيين المحكمين';
      case AppConstants.LANGUAGE_EDITING_STAGE2:
        return 'يحتاج تدقيق لغوي';
      case AppConstants.CHEF_REVIEW_LANGUAGE_EDIT:
        return 'يحتاج مراجعة التدقيق اللغوي';
      case AppConstants.LAYOUT_DESIGN_STAGE3:
        return 'يحتاج إخراج فني';
      case AppConstants.FINAL_REVIEW_STAGE:
        return 'يحتاج مراجعة نهائية';
      case AppConstants.FINAL_MODIFICATIONS:
        return 'يحتاج تعديلات نهائية';
      default:
        return 'يحتاج إجراء';
    }
  }

  String _getRequiredAction(String status) {
    switch (status) {
      case AppConstants.INCOMING:
      case AppConstants.SECRETARY_REVIEW:
        return 'مراجعة الملف والتحقق من المتطلبات';
      case AppConstants.EDITOR_REVIEW:
        return 'مراجعة المحتوى وتقييم الملاءمة';
      case AppConstants.HEAD_REVIEW:
        return 'اتخاذ القرار النهائي للمرحلة الأولى';
      case AppConstants.STAGE1_APPROVED:
        return 'تعيين المحكمين المتخصصين';
      case AppConstants.LANGUAGE_EDITING_STAGE2:
        return 'التدقيق اللغوي والأسلوبي';
      case AppConstants.CHEF_REVIEW_LANGUAGE_EDIT:
        return 'مراجعة عمل المدقق اللغوي';
      case AppConstants.LAYOUT_DESIGN_STAGE3:
        return 'التصميم والإخراج الفني';
      case AppConstants.FINAL_REVIEW_STAGE:
        return 'المراجعة النهائية والتدقيق';
      case AppConstants.FINAL_MODIFICATIONS:
        return 'تطبيق التعديلات النهائية';
      default:
        return 'اتخاذ الإجراء المطلوب';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool _isReviewer() {
    return _currentUserPosition?.contains('محكم') ?? false;
  }

  bool _isLayoutDesigner() {
    return _currentUserPosition == AppConstants.POSITION_LAYOUT_DESIGNER;
  }

  bool _isFinalReviewer() {
    return _currentUserPosition == AppConstants.POSITION_FINAL_REVIEWER;
  }

  bool _isHeadEditor() {
    return _currentUserPosition == AppConstants.POSITION_HEAD_EDITOR;
  }

  bool _isManagingEditor() {
    return _currentUserPosition == AppConstants.POSITION_MANAGING_EDITOR ||
        _currentUserPosition == AppConstants.POSITION_EDITOR_CHIEF;
  }

  void _navigateToTaskDetails(DocumentModel document) {
    final stage = AppStyles.getStageNumber(document.status);
    late Widget page;

    switch (stage) {
      case 1:
        // Stage 1
        if ([AppConstants.INCOMING, AppConstants.SECRETARY_REVIEW]
            .contains(document.status)) {
          page = Stage1SecretaryDetailsPage(document: document);
        } else if ([AppConstants.EDITOR_REVIEW, AppConstants.HEAD_REVIEW]
            .contains(document.status)) {
          page = Stage1EditorDetailsPage(document: document);
        } else {
          page = Stage1HeadEditorDetailsPage(document: document);
        }
        break;

      case 2:
        // Stage 2
        if (_currentUserPosition == AppConstants.POSITION_LANGUAGE_EDITOR &&
            document.status == AppConstants.LANGUAGE_EDITING_STAGE2) {
          page = Stage2LanguageEditorPage(document: document);
        } else if ((_currentUserPosition ==
                    AppConstants.POSITION_MANAGING_EDITOR ||
                _currentUserPosition == AppConstants.POSITION_EDITOR_CHIEF) &&
            (document.status == AppConstants.LANGUAGE_EDITOR_COMPLETED ||
                document.status == AppConstants.CHEF_REVIEW_LANGUAGE_EDIT)) {
          page = Stage2ChefEditorLanguageReviewPage(document: document);
        } else if (_isHeadEditor() ||
            [
              AppConstants.STAGE1_APPROVED,
              AppConstants.REVIEWERS_ASSIGNED,
              AppConstants.PEER_REVIEW_COMPLETED,
              AppConstants.HEAD_REVIEW_STAGE2,
              AppConstants.LANGUAGE_EDITING_STAGE2,
              AppConstants.LANGUAGE_EDITOR_COMPLETED,
              AppConstants.CHEF_REVIEW_LANGUAGE_EDIT,
            ].contains(document.status)) {
          page = Stage2HeadEditorDetailsPage(document: document);
        } else if (_isReviewer() &&
            document.reviewers.any((r) => r.userId == _currentUserId)) {
          page = Stage2ReviewerDetailsPage(document: document);
        } else {
          page = Stage2HeadEditorDetailsPage(document: document);
        }
        break;

      case 3:
        // Stage 3
        if (_isLayoutDesigner() &&
            [
              AppConstants.LAYOUT_DESIGN_STAGE3,
              AppConstants.LAYOUT_REVISION_REQUESTED,
              AppConstants.FINAL_MODIFICATIONS,
              AppConstants.STAGE2_APPROVED
            ].contains(document.status)) {
          page = Stage3LayoutDesignerPage(document: document);
        } else if (_isFinalReviewer() &&
            document.status == AppConstants.FINAL_REVIEW_STAGE) {
          page = Stage3FinalReviewerPage(document: document);
        } else if (_isManagingEditor()) {
          page = Stage3ManagingEditorPage(document: document);
        } else if (_isHeadEditor()) {
          page = Stage3HeadEditorPage(document: document);
        } else {
          // fallback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('صفحة تفاصيل هذا المستخدم - قيد التطوير'),
              backgroundColor: Colors.deepPurple.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        break;

      default:
        // Shouldn't happen, but just in case:
        page = Stage1HeadEditorDetailsPage(document: document);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) => _applyFilters());
  }

  void _showTaskQuickActions(DocumentModel task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.play_arrow, color: _getUserRoleColor()),
              title: Text('إنجاز المهمة'),
              onTap: () {
                Navigator.pop(context);
                _navigateToTaskDetails(task);
              },
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.blue),
              title: Text('تفاصيل المهمة'),
              subtitle: Text(_getRequiredAction(task.status)),
              onTap: () {
                Navigator.pop(context);
                // Show task details dialog
                _showTaskDetailsDialog(task);
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.green),
              title: Text('سجل الإجراءات'),
              onTap: () {
                Navigator.pop(context);
                _showTaskHistory(task);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetailsDialog(DocumentModel task) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(AppStyles.getStatusIcon(task.status),
                  color: AppStyles.getStatusColor(task.status)),
              SizedBox(width: 8),
              Text('تفاصيل المهمة'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                  'الحالة:', AppStyles.getStatusDisplayName(task.status)),
              _buildDetailRow('المرحلة:',
                  'المرحلة ${AppStyles.getStageNumber(task.status)}'),
              _buildDetailRow('المؤلف:',
                  task.fullName.isNotEmpty ? task.fullName : 'غير محدد'),
              _buildDetailRow('البريد الإلكتروني:',
                  task.email.isNotEmpty ? task.email : 'غير محدد'),
              _buildDetailRow('التاريخ:', _formatDate(task.timestamp)),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppStyles.getStatusColor(task.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getRequiredAction(task.status),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.getStatusColor(task.status),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToTaskDetails(task);
              },
              child: Text('إنجاز المهمة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.getStatusColor(task.status),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskHistory(DocumentModel task) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text('سجل إجراءات المهمة'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: task.actionLog.length,
              itemBuilder: (context, index) {
                final action = task.actionLog[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        AppStyles.getStatusColor(task.status).withOpacity(0.1),
                    child: Icon(Icons.history,
                        color: AppStyles.getStatusColor(task.status)),
                  ),
                  title: Text(action.action),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${action.userName} - ${action.userPosition}'),
                      if (action.comment != null && action.comment!.isNotEmpty)
                        Text(action.comment!,
                            style: TextStyle(fontStyle: FontStyle.italic)),
                      Text(_formatDate(action.timestamp)),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
}
