// Tasks/Reviewer_TaskPage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import '../../../Classes/current_user_providerr.dart';
import '../../Document_Handling/DocumentDetails/DocumentDetails.dart';
import '../../Document_Handling/DocumentDetails/Services/Document_Services.dart';

class ReviewerTasksPage extends StatefulWidget {
  const ReviewerTasksPage({Key? key}) : super(key: key);

  @override
  State<ReviewerTasksPage> createState() => _ReviewerTasksPageState();
}

class _ReviewerTasksPageState extends State<ReviewerTasksPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final DocumentService _documentService = DocumentService();

  // Theme colors
  final Color primaryColor = const Color(0xffa86418);
  final Color secondaryColor = const Color(0xffcc9657);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

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
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(
      String documentId, String reviewStatus, String comment) async {
    try {
      final currentUserProvider =
          Provider.of<CurrentUserProvider>(context, listen: false);
      final currentUser = currentUserProvider.currentUser;

      await _documentService.updateReviewerStatus(
        documentId,
        currentUser?.id ?? '',
        reviewStatus,
        comment,
        currentUser?.name ?? 'المحكم',
      );

      _showSuccessSnackBar('تم إرسال المراجعة بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في إرسال المراجعة: $e');
    }
  }

  void _showReviewDialog(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final TextEditingController commentController = TextEditingController();
    String selectedDecision = 'Approved';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.rate_review, color: primaryColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'مراجعة المقال',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document info
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'عنوان المقال:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          data['fullName'] ?? 'غير معروف',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xff2d3748),
                          ),
                        ),
                        if (data['about'] != null &&
                            data['about'].toString().isNotEmpty) ...[
                          SizedBox(height: 8),
                          Text(
                            'ملخص المقال:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            data['about'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Review decision
                  Text(
                    'قرار المراجعة:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xff2d3748),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: Text('موافقة على النشر'),
                          subtitle:
                              Text('المقال يلبي معايير المجلة ومناسب للنشر'),
                          value: 'Approved',
                          groupValue: selectedDecision,
                          onChanged: (value) {
                            setState(() {
                              selectedDecision = value!;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                        Divider(height: 1),
                        RadioListTile<String>(
                          title: Text('موافقة مع تعديلات'),
                          subtitle: Text('المقال جيد ولكن يحتاج تعديلات طفيفة'),
                          value: 'Minor Revisions',
                          groupValue: selectedDecision,
                          onChanged: (value) {
                            setState(() {
                              selectedDecision = value!;
                            });
                          },
                          activeColor: Colors.orange,
                        ),
                        Divider(height: 1),
                        RadioListTile<String>(
                          title: Text('تعديلات كبيرة مطلوبة'),
                          subtitle:
                              Text('المقال يحتاج تعديلات جوهرية وإعادة مراجعة'),
                          value: 'Major Revisions',
                          groupValue: selectedDecision,
                          onChanged: (value) {
                            setState(() {
                              selectedDecision = value!;
                            });
                          },
                          activeColor: Colors.orange.shade700,
                        ),
                        Divider(height: 1),
                        RadioListTile<String>(
                          title: Text('رفض المقال'),
                          subtitle: Text('المقال لا يلبي معايير المجلة'),
                          value: 'Rejected',
                          groupValue: selectedDecision,
                          onChanged: (value) {
                            setState(() {
                              selectedDecision = value!;
                            });
                          },
                          activeColor: Colors.red,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Comment section
                  Text(
                    'تعليقات وملاحظات المراجعة (مطلوبة):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xff2d3748),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'اكتب تعليقاتك التفصيلية هنا...\n\n'
                          'يرجى تضمين:\n'
                          '• نقاط القوة في المقال\n'
                          '• المجالات التي تحتاج تحسين\n'
                          '• اقتراحات محددة للتعديل\n'
                          '• أي ملاحظات أخرى مهمة',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 8,
                    textAlign: TextAlign.right,
                  ),

                  SizedBox(height: 16),

                  // Guidelines reminder
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'يرجى مراجعة المقال بناءً على معايير الجودة الأكاديمية والأصالة العلمية',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (commentController.text.trim().isEmpty) {
                    _showErrorSnackBar('يرجى إدخال تعليقات المراجعة');
                    return;
                  }
                  Navigator.pop(context);
                  _submitReview(
                      document.id, selectedDecision, commentController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'إرسال المراجعة',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = timestamp != null
        ? DateFormat('dd/MM/yyyy - HH:mm').format(timestamp)
        : 'تاريخ غير محدد';

    final reviewers = data['reviewers'] as List<dynamic>? ?? [];
    final currentUserProvider =
        Provider.of<CurrentUserProvider>(context, listen: false);
    final currentUser = currentUserProvider.currentUser;

    // Find current user's review status
    String userReviewStatus = 'Pending';
    String userComment = '';
    for (var reviewer in reviewers) {
      if (reviewer is Map<String, dynamic> &&
          (reviewer['userId'] == currentUser?.id ||
              reviewer['email'] == currentUser?.email)) {
        userReviewStatus = reviewer['reviewStatus'] ?? 'Pending';
        userComment = reviewer['comment'] ?? '';
        break;
      }
    }

    final isCompleted = userReviewStatus != 'Pending';
    final statusColor = isCompleted ? Colors.green : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DocumentDetailsPage(document: document),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_circle : Icons.schedule,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['fullName'] ?? 'غير معروف',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xff2d3748),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted ? Icons.check : Icons.pending,
                            size: 14,
                            color: statusColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            isCompleted ? 'تمت المراجعة' : 'في الانتظار',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Email
                Row(
                  children: [
                    Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data['email'] ?? 'لا يوجد بريد إلكتروني',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // About (if available)
                if (data['about'] != null &&
                    data['about'].toString().isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    data['about'],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Review deadline if available
                if (data['reviewDeadline'] != null) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.red.shade600),
                        SizedBox(width: 6),
                        Text(
                          'موعد التسليم: ${DateFormat('dd/MM/yyyy').format((data['reviewDeadline'] as Timestamp).toDate())}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // User's review status if completed
                if (isCompleted && userComment.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.rate_review,
                                color: Colors.green, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'مراجعتك:',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          userComment,
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 12,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 12),

                // Action Buttons
                if (!isCompleted) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showReviewDialog(document),
                          icon: Icon(Icons.rate_review, size: 16),
                          label: Text('بدء المراجعة',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DocumentDetailsPage(document: document),
                              ),
                            );
                          },
                          icon: Icon(Icons.visibility, size: 16),
                          label: Text('عرض التفاصيل',
                              style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            padding: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'تمت المراجعة',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DocumentDetailsPage(document: document),
                              ),
                            );
                          },
                          icon: Icon(Icons.visibility, size: 16),
                          label: Text('عرض التفاصيل',
                              style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            padding: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewerTasksList(String filter) {
    final currentUserProvider =
        Provider.of<CurrentUserProvider>(context, listen: false);
    final currentUser = currentUserProvider.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sent_documents')
          .where('status', isEqualTo: 'الي المحكمين')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ في تحميل البيانات: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        // Filter documents where current user is assigned as reviewer
        final allDocuments = snapshot.data!.docs;
        final myDocuments = allDocuments.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final reviewers = data['reviewers'] as List<dynamic>? ?? [];

          for (var reviewer in reviewers) {
            if (reviewer is Map<String, dynamic> &&
                (reviewer['userId'] == currentUser?.id ||
                    reviewer['email'] == currentUser?.email)) {
              if (filter == 'pending') {
                return reviewer['reviewStatus'] == 'Pending';
              } else if (filter == 'completed') {
                return reviewer['reviewStatus'] != 'Pending';
              }
              return true;
            }
          }
          return false;
        }).toList();

        if (myDocuments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filter == 'pending' ? Icons.schedule : Icons.check_circle,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  filter == 'pending'
                      ? 'لا توجد مقالات بانتظار مراجعتك'
                      : 'لم تكمل مراجعة أي مقال بعد',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  filter == 'pending'
                      ? 'ستظهر المقالات المعينة لك هنا'
                      : 'ستظهر المقالات المراجعة هنا',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: myDocuments.length,
          itemBuilder: (context, index) {
            return _buildTaskCard(myDocuments[index]);
          },
        );
      },
    );
  }

  Widget _buildStatisticsCard() {
    final currentUserProvider =
        Provider.of<CurrentUserProvider>(context, listen: false);
    final currentUser = currentUserProvider.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sent_documents')
          .where('status', isEqualTo: 'الي المحكمين')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 120,
            child:
                Center(child: CircularProgressIndicator(color: primaryColor)),
          );
        }

        final allDocuments = snapshot.data!.docs;
        int pendingCount = 0;
        int completedCount = 0;

        for (var doc in allDocuments) {
          final data = doc.data() as Map<String, dynamic>;
          final reviewers = data['reviewers'] as List<dynamic>? ?? [];

          for (var reviewer in reviewers) {
            if (reviewer is Map<String, dynamic> &&
                (reviewer['userId'] == currentUser?.id ||
                    reviewer['email'] == currentUser?.email)) {
              if (reviewer['reviewStatus'] == 'Pending') {
                pendingCount++;
              } else {
                completedCount++;
              }
              break;
            }
          }
        }

        return Container(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'ملخص مهام المحكم',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$pendingCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'في الانتظار',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$completedCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'مكتملة',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${pendingCount + completedCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'إجمالي',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [secondaryColor, primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مهام المحكم',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'مراجعة المقالات الأكاديمية وتقييمها',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.rate_review,
                            color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),
              ),

              // Statistics Card
              _buildStatisticsCard(),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: primaryColor,
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(
                      icon: Icon(Icons.schedule, size: 20),
                      text: 'في الانتظار',
                    ),
                    Tab(
                      icon: Icon(Icons.check_circle, size: 20),
                      text: 'مكتملة',
                    ),
                    Tab(
                      icon: Icon(Icons.analytics, size: 20),
                      text: 'الإحصائيات',
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReviewerTasksList('pending'),
                    _buildReviewerTasksList('completed'),
                    _buildDetailedStatistics(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedStatistics() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إحصائيات أداء المراجعة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff2d3748),
            ),
          ),
          SizedBox(height: 16),

          // Performance metrics cards
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'متوسط وقت المراجعة',
                '5.2 أيام',
                Icons.schedule,
                Colors.blue,
              ),
              _buildMetricCard(
                'معدل الموافقة',
                '72%',
                Icons.check_circle,
                Colors.green,
              ),
              _buildMetricCard(
                'المراجعات هذا الشهر',
                '8',
                Icons.calendar_month,
                Colors.orange,
              ),
              _buildMetricCard(
                'التقييم العام',
                'ممتاز',
                Icons.star,
                Colors.purple,
              ),
            ],
          ),

          SizedBox(height: 24),

          // Guidelines card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: primaryColor),
                    SizedBox(width: 12),
                    Text(
                      'إرشادات المراجعة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '• يرجى مراجعة المقالات في الوقت المحدد\n'
                  '• قدم تعليقات بناءة ومفصلة\n'
                  '• راجع الأصالة العلمية والمنهجية\n'
                  '• تأكد من جودة اللغة والأسلوب\n'
                  '• اقترح تحسينات محددة عند الحاجة',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
