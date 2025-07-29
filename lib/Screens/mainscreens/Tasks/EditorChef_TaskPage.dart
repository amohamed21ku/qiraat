// Tasks/EditorChef_TaskPage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import '../../../Classes/current_user_providerr.dart';
import '../../Document_Handling/DocumentDetails/Constants/App_Constants.dart';
import '../../Document_Handling/DocumentDetails/DocumentDetails.dart';
import '../../Document_Handling/DocumentDetails/Services/Document_Services.dart';

class EditorChiefTasksPage extends StatefulWidget {
  const EditorChiefTasksPage({Key? key}) : super(key: key);

  @override
  State<EditorChiefTasksPage> createState() => _EditorChiefTasksPageState();
}

class _EditorChiefTasksPageState extends State<EditorChiefTasksPage>
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
    _tabController = TabController(length: 5, vsync: this);

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

  Future<void> _updateDocumentStatus(
      String documentId, String newStatus, String comment) async {
    try {
      final currentUserProvider =
          Provider.of<CurrentUserProvider>(context, listen: false);
      final currentUser = currentUserProvider.currentUser;

      await _documentService.updateDocumentStatus(
        documentId,
        newStatus,
        comment,
        currentUser?.id ?? '',
        currentUser?.name ?? 'مدير التحرير',
        'مدير التحرير',
      );

      _showSuccessSnackBar('تم تحديث حالة المقال بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في تحديث المقال: $e');
    }
  }

  void _showQuickActionDialog(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final status = data['status'] ?? '';

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.supervisor_account, color: primaryColor),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'إجراءات مدير التحرير',
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
                Text('مقال: ${data['fullName'] ?? 'غير معروف'}'),
                SizedBox(height: 16),
                if (status == 'مراجعة مدير التحرير') ...[
                  _buildQuickActionButton(
                    'إرسال لرئيس التحرير',
                    Icons.arrow_upward,
                    Colors.blue,
                    () {
                      Navigator.pop(context);
                      _updateDocumentStatus(
                        document.id,
                        'مراجعة رئيس التحرير',
                        'مدير التحرير يوصي بالموافقة على المقال',
                      );
                    },
                  ),
                  SizedBox(height: 8),
                  _buildQuickActionButton(
                    'طلب تعديل من المؤلف',
                    Icons.edit,
                    Colors.orange,
                    () {
                      Navigator.pop(context);
                      _showCommentDialog(
                        document.id,
                        'مطلوب تعديل من المؤلف',
                        'طلب تعديلات من مدير التحرير',
                      );
                    },
                  ),
                  SizedBox(height: 8),
                  _buildQuickActionButton(
                    'رفض المقال',
                    Icons.cancel,
                    Colors.red,
                    () {
                      Navigator.pop(context);
                      _showCommentDialog(
                        document.id,
                        'مرفوض نهائياً',
                        'رفض المقال من مدير التحرير',
                      );
                    },
                  ),
                ] else if (status == 'تم التحكيم') ...[
                  _buildQuickActionButton(
                    'إرسال للتحرير اللغوي',
                    Icons.spellcheck,
                    Colors.green,
                    () {
                      Navigator.pop(context);
                      _updateDocumentStatus(
                        document.id,
                        'التحرير اللغوي',
                        'انتهى التحكيم بنجاح - جاهز للتحرير اللغوي',
                      );
                    },
                  ),
                  SizedBox(height: 8),
                  _buildQuickActionButton(
                    'طلب تعديل بناءً على المحكمين',
                    Icons.edit_note,
                    Colors.orange,
                    () {
                      Navigator.pop(context);
                      _showCommentDialog(
                        document.id,
                        'مطلوب تعديل من المؤلف',
                        'طلب تعديلات بناءً على تعليقات المحكمين',
                      );
                    },
                  ),
                ] else if (status == 'المراجعة الأولى للإخراج') ...[
                  _buildQuickActionButton(
                    'إرسال لرئيس التحرير للمراجعة',
                    Icons.send,
                    Colors.blue,
                    () {
                      Navigator.pop(context);
                      _updateDocumentStatus(
                        document.id,
                        'مراجعة رئيس التحرير للإخراج',
                        'مدير التحرير وافق على الإخراج',
                      );
                    },
                  ),
                  SizedBox(height: 8),
                  _buildQuickActionButton(
                    'إعادة للتصميم',
                    Icons.refresh,
                    Colors.orange,
                    () {
                      Navigator.pop(context);
                      _showCommentDialog(
                        document.id,
                        'التصميم والإخراج',
                        'مطلوب تعديلات في التصميم',
                      );
                    },
                  ),
                ] else if (status == 'الي المحكمين') ...[
                  _buildQuickActionButton(
                    'إدارة المحكمين',
                    Icons.people_outline,
                    Colors.purple,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DocumentDetailsPage(document: document),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 8),
                  _buildQuickActionButton(
                    'إنهاء التحكيم إدارياً',
                    Icons.check_circle,
                    Colors.green,
                    () {
                      Navigator.pop(context);
                      _updateDocumentStatus(
                        document.id,
                        'تم التحكيم',
                        'إنهاء التحكيم إدارياً من مدير التحرير',
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      String title, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(
          title,
          style: TextStyle(fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _showCommentDialog(
      String documentId, String newStatus, String actionTitle) {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(actionTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'التعليق (مطلوب)',
                  hintText: 'اكتب تعليقك المفصل هنا...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 4,
                textAlign: TextAlign.right,
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
                if (commentController.text.trim().isEmpty) {
                  _showErrorSnackBar('يرجى إدخال تعليق');
                  return;
                }
                Navigator.pop(context);
                _updateDocumentStatus(
                    documentId, newStatus, commentController.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: Text('تأكيد', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewerManagementDialog(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final reviewers = data['reviewers'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('إدارة المحكمين'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المحكمون المعيّنون (${reviewers.length}):'),
                SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: reviewers.length,
                    itemBuilder: (context, index) {
                      final reviewer = reviewers[index] as Map<String, dynamic>;
                      final status = reviewer['reviewStatus'] ?? 'Pending';

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: status == 'Approved'
                                ? Colors.green
                                : Colors.orange,
                            child: Icon(
                              status == 'Approved'
                                  ? Icons.check
                                  : Icons.schedule,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          title: Text(reviewer['name'] ?? 'غير معروف'),
                          subtitle: Text(reviewer['position'] ?? ''),
                          trailing: status == 'Pending'
                              ? IconButton(
                                  icon: Icon(Icons.check_circle,
                                      color: Colors.green),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _approveReviewerDirectly(
                                        document.id, reviewer['userId']);
                                  },
                                )
                              : Icon(Icons.check_circle, color: Colors.green),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DocumentDetailsPage(document: document),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child:
                  Text('إدارة متقدمة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveReviewerDirectly(
      String documentId, String reviewerId) async {
    try {
      await _documentService.updateReviewerStatus(
        documentId,
        reviewerId,
        'Approved',
        'موافقة إدارية من مدير التحرير',
        'مدير التحرير',
      );
      _showSuccessSnackBar('تمت الموافقة الإدارية للمحكم');
    } catch (e) {
      _showErrorSnackBar('خطأ في الموافقة: $e');
    }
  }

  Widget _buildTaskCard(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = timestamp != null
        ? DateFormat('dd/MM/yyyy - HH:mm').format(timestamp)
        : 'تاريخ غير محدد';

    final status = data['status'] ?? '';
    final statusColor = AppStyles.getStatusColor(status);
    final reviewers = data['reviewers'] as List<dynamic>? ?? [];

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
                        AppStyles.getStatusIcon(status),
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
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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

                // Reviewer info for articles under review
                if (status == 'الي المحكمين' && reviewers.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people, color: Colors.purple, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'المحكمون (${reviewers.length})',
                              style: TextStyle(
                                color: Colors.purple,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: reviewers.take(3).map((reviewer) {
                            final reviewerData =
                                reviewer as Map<String, dynamic>;
                            final reviewStatus =
                                reviewerData['reviewStatus'] ?? 'Pending';
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: reviewStatus == 'Approved'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: reviewStatus == 'Approved'
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                reviewerData['name'] ?? 'غير معروف',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: reviewStatus == 'Approved'
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (reviewers.length > 3)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'و ${reviewers.length - 3} محكمين آخرين',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

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

                SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    if (status == 'الي المحكمين') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showReviewerManagementDialog(document),
                          icon: Icon(Icons.people_outline, size: 16),
                          label: Text('إدارة المحكمين',
                              style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purple,
                            side: BorderSide(color: Colors.purple),
                            padding: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showQuickActionDialog(document),
                        icon: Icon(Icons.flash_on, size: 16),
                        label:
                            Text('إجراء سريع', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          padding: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
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
                        label: Text('تفاصيل', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }

  Widget _buildTaskList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sent_documents')
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: false)
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

        final documents = snapshot.data!.docs;

        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  AppStyles.getStatusIcon(status),
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  'لا توجد مقالات بحالة "$status"',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            return _buildTaskCard(documents[index]);
          },
        );
      },
    );
  }

  Widget _buildStatisticsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sent_documents')
          .where('status', whereIn: [
        'مراجعة مدير التحرير',
        'الي المحكمين',
        'تم التحكيم',
        'المراجعة الأولى للإخراج'
      ]).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 120,
            child:
                Center(child: CircularProgressIndicator(color: primaryColor)),
          );
        }

        final documents = snapshot.data!.docs;
        final reviewCount = documents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'مراجعة مدير التحرير';
        }).length;

        final underReviewersCount = documents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'الي المحكمين';
        }).length;

        final completedReviewCount = documents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'تم التحكيم';
        }).length;

        final layoutReviewCount = documents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'المراجعة الأولى للإخراج';
        }).length;

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
                'ملخص مهام مدير التحرير',
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
                          '$reviewCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'للمراجعة',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 35,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$underReviewersCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'مع المحكمين',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 35,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$completedReviewCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'تم التحكيم',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 35,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$layoutReviewCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'مراجعة إخراج',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
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
                              'مهام مدير التحرير',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'إدارة سير العمل وتنسيق المحكمين',
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
                        child: Icon(Icons.supervisor_account,
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
                  labelStyle:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  isScrollable: true,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.assignment, size: 18),
                      text: 'للمراجعة',
                    ),
                    Tab(
                      icon: Icon(Icons.people, size: 18),
                      text: 'مع المحكمين',
                    ),
                    Tab(
                      icon: Icon(Icons.rate_review, size: 18),
                      text: 'تم التحكيم',
                    ),
                    Tab(
                      icon: Icon(Icons.preview, size: 18),
                      text: 'مراجعة الإخراج',
                    ),
                    Tab(
                      icon: Icon(Icons.analytics, size: 18),
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
                    _buildTaskList('مراجعة مدير التحرير'),
                    _buildTaskList('الي المحكمين'),
                    _buildTaskList('تم التحكيم'),
                    _buildTaskList('المراجعة الأولى للإخراج'),
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
            'تفاصيل الأداء والإحصائيات',
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
                '3.2 أيام',
                Icons.schedule,
                Colors.blue,
              ),
              _buildMetricCard(
                'معدل الموافقة',
                '78%',
                Icons.check_circle,
                Colors.green,
              ),
              _buildMetricCard(
                'المقالات المعالجة اليوم',
                '8',
                Icons.today,
                Colors.orange,
              ),
              _buildMetricCard(
                'متوسط عدد المحكمين',
                '2.5',
                Icons.people,
                Colors.purple,
              ),
            ],
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
