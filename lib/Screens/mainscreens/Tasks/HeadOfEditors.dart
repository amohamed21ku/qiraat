import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qiraat/Classes/current_user_providerr.dart';
import 'package:qiraat/Screens/Document_Handling/DocumentDetails/DocumentDetails.dart';
import 'dart:ui' as ui;

class HeadOfEditorsTasksPage extends StatefulWidget {
  @override
  _HeadOfEditorsTasksPageState createState() => _HeadOfEditorsTasksPageState();
}

class _HeadOfEditorsTasksPageState extends State<HeadOfEditorsTasksPage>
    with TickerProviderStateMixin {
  String selectedFilter = 'يحتاج مراجعة';
  bool isLoading = false;
  bool isInitialLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final Color primaryColor = const Color(0xffa86418);
  final Color secondaryColor = const Color(0xffcc9657);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();

    // Set initial loading to false after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          isInitialLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    Query baseQuery = FirebaseFirestore.instance.collection('sent_documents');

    switch (selectedFilter) {
      case 'يحتاج مراجعة':
        return baseQuery
            .where('status', isEqualTo: 'موافقة مدير التحرير')
            .snapshots();
      case 'تمت الموافقة':
        return baseQuery.where('status', whereIn: [
          'موافقة رئيس التحرير',
          'تمت الموافقة النهائية'
        ]).snapshots();
      case 'مرسل للتعديل':
        return baseQuery
            .where('status', isEqualTo: 'مرسل للتعديل من رئيس التحرير')
            .snapshots();
      case 'مرفوض':
        return baseQuery
            .where('status', isEqualTo: 'رفض رئيس التحرير')
            .snapshots();
      case 'جميع المهام':
      default:
        return baseQuery.where('status', whereIn: [
          'موافقة مدير التحرير',
          'موافقة رئيس التحرير',
          'تمت الموافقة النهائية',
          'مرسل للتعديل من رئيس التحرير',
          'رفض رئيس التحرير'
        ]).snapshots();
    }
  }

  List<String> get filterOptions => [
        'يحتاج مراجعة',
        'تمت الموافقة',
        'مرسل للتعديل',
        'مرفوض',
        'جميع المهام',
      ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'موافقة مدير التحرير':
        return Colors.orange[600]!;
      case 'موافقة رئيس التحرير':
      case 'تمت الموافقة النهائية':
        return Colors.green[600]!;
      case 'مرسل للتعديل من رئيس التحرير':
        return Colors.blue[600]!;
      case 'رفض رئيس التحرير':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'موافقة مدير التحرير':
        return Icons.pending_actions;
      case 'موافقة رئيس التحرير':
      case 'تمت الموافقة النهائية':
        return Icons.verified;
      case 'مرسل للتعديل من رئيس التحرير':
        return Icons.edit;
      case 'رفض رئيس التحرير':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'موافقة مدير التحرير':
        return 'يحتاج موافقة رئيس التحرير';
      case 'موافقة رئيس التحرير':
        return 'تمت الموافقة النهائية';
      case 'تمت الموافقة النهائية':
        return 'تمت الموافقة النهائية';
      case 'مرسل للتعديل من رئيس التحرير':
        return 'مرسل للتعديل';
      case 'رفض رئيس التحرير':
        return 'مرفوض نهائياً';
      default:
        return status;
    }
  }

  Future<void> _updateDocumentStatus(
      DocumentSnapshot document, String newStatus, String? comment) async {
    setState(() {
      isLoading = true;
    });

    try {
      final currentUserProvider =
          Provider.of<CurrentUserProvider>(context, listen: false);
      final currentUser = currentUserProvider.currentUser;

      final actionLog = {
        'timestamp': Timestamp.now(),
        'action': newStatus,
        'userName': currentUser?.name ?? 'رئيس التحرير',
        'userPosition': 'رئيس التحرير',
        'userId': currentUser?.id ?? currentUser?.email ?? '',
        'comment': comment,
      };

      await FirebaseFirestore.instance
          .collection('sent_documents')
          .doc(document.id)
          .update({
        'status': newStatus,
        'head_editor_decision_date': FieldValue.serverTimestamp(),
        'actionLog': FieldValue.arrayUnion([actionLog]),
      });

      _showSuccessSnackBar('تم تحديث حالة المستند بنجاح');
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء تحديث المستند: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDecisionDialog(DocumentSnapshot document) {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 600,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
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
                          child:
                              Icon(Icons.gavel, color: Colors.white, size: 28),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'قرار رئيس التحرير',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'اتخذ القرار النهائي بشأن المستند',
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

                  // Content
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Document info
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50]!,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.description,
                                  color: primaryColor, size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'المستند: ${(document.data() as Map<String, dynamic>)['fullName'] ?? 'غير معروف'}',
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

                        Text(
                          'تعليق (اختياري)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2d3748),
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'أضف تعليقك على القرار...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                            maxLines: 3,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Action buttons
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDecisionButton(
                                    'موافقة نهائية',
                                    Icons.verified,
                                    Colors.green[600]!,
                                    () {
                                      Navigator.pop(context);
                                      _updateDocumentStatus(
                                          document,
                                          'موافقة رئيس التحرير',
                                          commentController.text);
                                    },
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildDecisionButton(
                                    'إرسال للتعديل',
                                    Icons.edit,
                                    Colors.orange[600]!,
                                    () {
                                      Navigator.pop(context);
                                      _updateDocumentStatus(
                                          document,
                                          'مرسل للتعديل من رئيس التحرير',
                                          commentController.text);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDecisionButton(
                                    'رفض نهائي',
                                    Icons.block,
                                    Colors.red[600]!,
                                    () {
                                      Navigator.pop(context);
                                      _updateDocumentStatus(
                                          document,
                                          'رفض رئيس التحرير',
                                          commentController.text);
                                    },
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side:
                                          BorderSide(color: Colors.grey[400]!),
                                    ),
                                    child: Text(
                                      'إلغاء',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700]!,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDecisionButton(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(color, Colors.white, 0.2)!,
            Color.lerp(color, Colors.black, 0.2)!
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 2),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Widget _buildDocumentCard(DocumentSnapshot document, bool isDesktop) {
    final data = document.data() as Map<String, dynamic>;
    final String fullName = data['fullName'] ?? 'غير معروف';
    final String email = data['email'] ?? 'غير متوفر';
    final String status = data['status'] ?? 'غير معروف';
    final DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
    final String formattedDate =
        DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp);

    final Color statusColor = _getStatusColor(status);
    final IconData statusIcon = _getStatusIcon(status);
    final String statusDisplayText = _getStatusDisplayText(status);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
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
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2d3748),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600]!,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status == 'موافقة مدير التحرير')
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _showDecisionDialog(document),
                        icon: Icon(Icons.gavel, color: Colors.white, size: 16),
                        label: Text(
                          'اتخاذ قرار',
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
              ),
              SizedBox(height: 16),

              // Status and date row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusDisplayText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Spacer(),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[500]!),
                      SizedBox(width: 6),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500]!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Additional info
              if (data.containsKey('education') &&
                  data['education'] != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50]!,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school, size: 16, color: Colors.grey[600]!),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'التعليم: ${data['education']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700]!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredStream(),
      builder: (context, snapshot) {
        // Handle errors
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[600]!),
                SizedBox(height: 16),
                Text(
                  'حدث خطأ في تحميل البيانات',
                  style: TextStyle(fontSize: 18, color: Colors.red[600]!),
                ),
                SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]!),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // This will rebuild the widget and retry the stream
                    });
                  },
                  child: Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting ||
            isInitialLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryColor),
                SizedBox(height: 16),
                Text(
                  'جاري تحميل المهام...',
                  style: TextStyle(color: Colors.grey[600]!),
                ),
              ],
            ),
          );
        }

        // Handle data
        final documents = snapshot.data?.docs ?? [];

        // Sort documents by timestamp
        if (documents.isNotEmpty) {
          documents.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aTimestamp = aData['timestamp'] as Timestamp?;
            final bTimestamp = bData['timestamp'] as Timestamp?;

            if (aTimestamp == null || bTimestamp == null) return 0;
            return bTimestamp.compareTo(aTimestamp);
          });
        }

        // Handle empty state
        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey[100]!,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey[400]!,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'لا توجد مهام',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2d3748),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _getEmptyStateMessage(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600]!,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedFilter = 'جميع المهام';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('عرض جميع المهام'),
                ),
              ],
            ),
          );
        }

        // Show documents
        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            return _buildDocumentCard(documents[index], true);
          },
        );
      },
    );
  }

  String _getEmptyStateMessage() {
    switch (selectedFilter) {
      case 'يحتاج مراجعة':
        return 'لا توجد مستندات تحتاج موافقة رئيس التحرير حالياً';
      case 'تمت الموافقة':
        return 'لا توجد مستندات تمت الموافقة عليها نهائياً';
      case 'مرسل للتعديل':
        return 'لا توجد مستندات مرسلة للتعديل من رئيس التحرير';
      case 'مرفوض':
        return 'لا توجد مستندات مرفوضة من رئيس التحرير';
      case 'جميع المهام':
      default:
        return 'لا توجد مستندات تحتاج موافقة رئيس التحرير';
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 1024;

              return Stack(
                children: [
                  Column(
                    children: [
                      // Header
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'مهام رئيس التحرير',
                                        style: TextStyle(
                                          fontSize: isDesktop ? 32 : 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'إدارة الموافقات النهائية للمستندات',
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
                            SizedBox(height: 20),

                            // Filter dropdown
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedFilter,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  icon: Icon(Icons.arrow_drop_down,
                                      color: Colors.white),
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                  items: filterOptions.map((filter) {
                                    return DropdownMenuItem(
                                      value: filter,
                                      child: Text(
                                        filter,
                                        style:
                                            TextStyle(color: Colors.grey[800]!),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedFilter = value;
                                        isInitialLoading = true;
                                      });
                                      // Reset loading state after filter change
                                      Future.delayed(
                                          Duration(milliseconds: 300), () {
                                        if (mounted) {
                                          setState(() {
                                            isInitialLoading = false;
                                          });
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _slideAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 80 : 20,
                                  vertical: 20,
                                ),
                                child: _buildStreamContent(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // Loading overlay for actions
                  if (isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.7),
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
                              CircularProgressIndicator(
                                  color: primaryColor, strokeWidth: 3),
                              SizedBox(height: 20),
                              Text(
                                'جاري المعالجة...',
                                style: TextStyle(
                                  color: Color(0xff2d3748),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
