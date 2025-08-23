import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../App_Constants.dart';
import '../Document_Services.dart';
import '../Widgets/CustomHeader.dart';
import '../models/document_model.dart';
import '../models/reviewerModel.dart';
import '../stage2/stage2Reviewer.dart'; // Stage2ReviewerDetailsPage
import '../Classes/current_user_providerr.dart';

class ReviewerTasksPage extends StatefulWidget {
  const ReviewerTasksPage({super.key});

  @override
  State<ReviewerTasksPage> createState() => _ReviewerTasksPageState();
}

class _ReviewerTasksPageState extends State<ReviewerTasksPage>
    with SingleTickerProviderStateMixin {
  final _documentService = DocumentService();
  String? _uid;
  bool _loading = true;
  List<DocumentModel> _assigned = [];
  List<DocumentModel> _reviewed = [];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);

      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('id') ?? '';

      if (uid.isEmpty) {
        // Handle case where user ID is not found
        setState(() {
          _loading = false;
          _assigned = [];
          _reviewed = [];
        });
        return;
      }

      setState(() => _uid = uid);

      // Fetch only documents assigned to this reviewer (already sanitized in service)
      final docs = await _documentService.getDocumentsForReviewer(uid);

      // Split into "Assigned to me" vs "Reviewed by me"
      final assigned = <DocumentModel>[];
      final reviewed = <DocumentModel>[];

      for (final d in docs) {
        final me = d.reviewers.firstWhere(
          (r) => r.userId == uid,
          orElse: () => ReviewerModel(
            userId: uid,
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
        _assigned = assigned;
        _reviewed = reviewed;
        _loading = false;
      });
    } catch (e) {
      // Handle errors gracefully
      setState(() {
        _loading = false;
        _assigned = [];
        _reviewed = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppStyles.backgroundColor,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: Column(
                  children: [
                    const CustomHeader(),
                    Expanded(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            Container(
                              color: Colors.white,
                              child: TabBar(
                                controller: _tabController,
                                labelColor: AppConstants.primaryColor,
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: AppConstants.primaryColor,
                                tabs: const [
                                  Tab(
                                    text: 'مُسندة إليّ',
                                    icon: Icon(Icons.assignment),
                                  ),
                                  Tab(
                                    text: 'مراجعاتي المُنجزة',
                                    icon: Icon(Icons.check_circle),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildList(_assigned, isReviewed: false),
                                  _buildList(_reviewed, isReviewed: true),
                                ],
                              ),
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
  }

  Widget _buildList(List<DocumentModel> docs, {required bool isReviewed}) {
    if (docs.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(
                  isReviewed
                      ? Icons.check_circle_outline
                      : Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  isReviewed ? 'لا توجد مراجعات مُنجزة' : 'لا توجد مهام مُسندة',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) => _docCard(docs[index], isReviewed),
    );
  }

  Widget _docCard(DocumentModel d, bool isReviewed) {
    final statusColor = AppStyles.getStage2StatusColor(d.status);
    final statusIcon = AppStyles.getStage2StatusIcon(d.status);
    final statusName = AppStyles.getStatusDisplayName(d.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Stage2ReviewerDetailsPage(document: d),
            ),
          );

          // Reload data if needed
          if (result == true || mounted) {
            await _load();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Row
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        fontWeight: FontWeight.w500,
                        color: isReviewed
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Document Title
              if (d.title?.isNotEmpty == true)
                Text(
                  d.title!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 8),

              // Document URL/Path
              if (d.documentUrl?.isNotEmpty == true)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    d.documentUrl!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Timestamp and Assignment Info
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    d.timestamp != null
                        ? 'التاريخ: ${_formatDate(d.timestamp)}'
                        : 'التاريخ غير محدد',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  if (!isReviewed && _uid != null) _buildAssignmentDate(d),
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
      (r) => r.userId == _uid,
      orElse: () => ReviewerModel(
        userId: _uid!,
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
    // Simple Arabic date formatting - you might want to use intl package for better formatting
    return '${date.day}/${date.month}/${date.year}';
  }
}
