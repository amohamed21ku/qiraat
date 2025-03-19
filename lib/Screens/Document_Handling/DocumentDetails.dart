import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:qiraat/Classes/current_user_providerr.dart';
import 'package:qiraat/Screens/Document_Handling/UIComponents.dart';
import 'package:qiraat/Widgets/Components.dart';

class DocumentDetailsPage extends StatefulWidget {
  final DocumentSnapshot document;

  const DocumentDetailsPage({super.key, required this.document});

  @override
  State<DocumentDetailsPage> createState() => _DocumentDetailsPageState();
}

class _DocumentDetailsPageState extends State<DocumentDetailsPage> {
  bool _isLoading = false;
  List<String> selectedReviewers = [];
  bool isCurrentUserReviewer = false;
  bool hasCurrentUserApproved = false;
  Map<String, String> reviewerStatuses =
      {}; // Track review status for each reviewer

  @override
  void initState() {
    super.initState();
    _checkIfUserIsReviewer();
    _loadReviewerStatuses();
  }

  void _loadReviewerStatuses() {
    final data = widget.document.data() as Map<String, dynamic>;
    final reviewers = data['reviewers'] as List<dynamic>? ?? [];

    Map<String, String> statuses = {};
    for (var reviewer in reviewers) {
      statuses[reviewer['name']] = reviewer['review_status'];
    }

    setState(() {
      reviewerStatuses = statuses;
    });
  }

  void _checkIfUserIsReviewer() async {
    final data = widget.document.data() as Map<String, dynamic>;
    final reviewers = data['reviewers'] as List<dynamic>? ?? [];

    // Get current user
    final currentUserProvider =
        Provider.of<CurrentUserProvider>(context, listen: false);
    final currentUser = currentUserProvider.currentUser;

    if (currentUser != null) {
      for (var reviewer in reviewers) {
        if (reviewer['name'] == currentUser.name) {
          setState(() {
            isCurrentUserReviewer = true;
            hasCurrentUserApproved = reviewer['review_status'] == "Approved";
          });
          break;
        }
      }
    }
  }

  Future<void> _viewFile(String url, String fileName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDocDir.path}/$fileName';

      await Dio().download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint('${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      setState(() {
        _isLoading = false;
      });

      await OpenFile.open(filePath);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء فتح الملف: $e')),
      );
    }
  }

  Future<void> _updateDocumentStatus(String newStatus, String? comment) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserProvider =
          Provider.of<CurrentUserProvider>(context, listen: false);
      final currentUser = currentUserProvider.currentUser;

      final docRef = FirebaseFirestore.instance
          .collection('sent_documents')
          .doc(widget.document.id);

      // Create a new action log entry
      final actionLog = {
        'timestamp': Timestamp.now(),
        'action': newStatus,
        'userName': currentUser?.name,
        'userPosition': currentUser?.position,
        'comment': comment,
      };

      if (newStatus == 'الي المحكمين') {
        actionLog['reviewers'] = selectedReviewers;

        // Create reviewers list with initial "Not Reviewed" status
        List<Map<String, dynamic>> reviewersList = [];
        for (String reviewerName in selectedReviewers) {
          reviewersList
              .add({'name': reviewerName, 'review_status': 'Not Reviewed'});
        }

        // Update document with reviewers and status
        await docRef.update({
          'status': newStatus,
          'reviewers': reviewersList,
          'actionLog': FieldValue.arrayUnion([actionLog]),
        });
      } else if (newStatus == 'موافقة المحكم') {
        // For reviewer approval, update their status in the reviewers array
        final data = widget.document.data() as Map<String, dynamic>;
        List<dynamic> reviewers = List.from(data['reviewers'] ?? []);

        // Find and update current reviewer's status
        for (int i = 0; i < reviewers.length; i++) {
          if (reviewers[i]['name'] == currentUser?.name) {
            reviewers[i]['review_status'] = 'Approved';
            break;
          }
        }

        // Check if all reviewers have approved
        bool allApproved = true;
        for (var reviewer in reviewers) {
          if (reviewer['review_status'] != 'Approved') {
            allApproved = false;
            break;
          }
        }

        // Update the document
        if (allApproved) {
          // If all approved, change status to تم التحكيم
          await docRef.update({
            'status': 'تم التحكيم',
            'reviewers': reviewers,
            'actionLog': FieldValue.arrayUnion([actionLog]),
          });
        } else {
          // Otherwise just update the reviewers list
          await docRef.update({
            'reviewers': reviewers,
            'actionLog': FieldValue.arrayUnion([actionLog]),
          });
        }
      } else {
        // For other actions, update both status and action log
        await docRef.update({
          'status': newStatus,
          'actionLog': FieldValue.arrayUnion([actionLog]),
        });
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث حالة المستند بنجاح')),
      );

      // Refresh the page to show updated status
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DocumentDetailsPage(document: widget.document),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحديث حالة المستند: $e')),
      );
    }
  }

  Future<void> _showReviewerApprovalDialog() async {
    final TextEditingController commentController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تقييم المستند'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('أدخل تعليقك وتقييمك للمستند'),
                SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    labelText: 'التعليق (مطلوب)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('موافقة', style: TextStyle(color: Color(0xffa86418))),
              onPressed: () async {
                if (commentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('الرجاء إدخال تعليق')),
                  );
                  return;
                }
                Navigator.of(context).pop();

                // Update the document with the reviewer's approval
                await _updateDocumentStatus(
                    'موافقة المحكم', commentController.text);

                // Update local state
                setState(() {
                  hasCurrentUserApproved = true;
                  final currentUserProvider =
                      Provider.of<CurrentUserProvider>(context, listen: false);
                  final currentUser = currentUserProvider.currentUser;
                  if (currentUser != null) {
                    reviewerStatuses[currentUser.name] = 'Approved';
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAcceptRejectDialog() async {
    final TextEditingController commentController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('اختر الإجراء'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('هل تريد قبول أو رفض هذا المستند؟'),
                SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    labelText: 'تعليق (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('رفض', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _updateDocumentStatus('تم الرفض', commentController.text);
              },
            ),
            TextButton(
              child: Text('قبول', style: TextStyle(color: Color(0xffa86418))),
              onPressed: () {
                Navigator.of(context).pop();
                _updateDocumentStatus('قبول الملف', commentController.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAssignReviewersDialog() async {
    final List<String> tempSelectedReviewers = List.from(selectedReviewers);
    List<Map<String, dynamic>> reviewers = [];

    // Fetch all users with position 'محكم'
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('position', isEqualTo: 'محكم')
          .get();

      reviewers = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': (doc.data() as Map<String, dynamic>)['fullName'],
              })
          .toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحميل المحكمين: $e')),
      );
      return;
    }

    final TextEditingController commentController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('تعيين المحكمين'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('اختر المحكمين لهذا المستند:'),
                    SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: reviewers.length,
                        itemBuilder: (context, index) {
                          final reviewer = reviewers[index];
                          return CheckboxListTile(
                            title: Text(reviewer['name']),
                            value: tempSelectedReviewers
                                .contains(reviewer['name']),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  tempSelectedReviewers.add(reviewer['name']);
                                } else {
                                  tempSelectedReviewers
                                      .remove(reviewer['name']);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        labelText: 'تعليق (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('إلغاء'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child:
                      Text('تعيين', style: TextStyle(color: Color(0xffa86418))),
                  onPressed: () {
                    if (tempSelectedReviewers.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('الرجاء اختيار محكم واحد على الأقل')),
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    setState(() {
                      selectedReviewers = tempSelectedReviewers;
                    });
                    _updateDocumentStatus(
                        'الي المحكمين', commentController.text);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons(String status) {
    if (status == 'ملف مرسل') {
      return ElevatedButton.icon(
        onPressed: _showAcceptRejectDialog,
        icon: Icon(Icons.assignment_turned_in, color: Colors.white),
        label: Text(
          'قبول / رفض الملف',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xffa86418),
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
      );
    } else if (status == 'قبول الملف') {
      return ElevatedButton.icon(
        onPressed: _showAssignReviewersDialog,
        icon: Icon(Icons.person_add, color: Colors.white),
        label: Text(
          'تعيين المحكمين',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xffa86418),
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
      );
    } else if (status == 'الي المحكمين' &&
        isCurrentUserReviewer &&
        !hasCurrentUserApproved) {
      return ElevatedButton.icon(
        onPressed: _showReviewerApprovalDialog,
        icon: Icon(Icons.thumb_up, color: Colors.white),
        label: Text(
          'الموافقة والتعليق',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xffa86418),
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
      );
    } else if (status == 'الي المحكمين' &&
        isCurrentUserReviewer &&
        hasCurrentUserApproved) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'تمت موافقتك على المستند',
              style: TextStyle(color: Colors.green),
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink(); // No button for other statuses
  }

  Widget _buildReviewersStatusWidget() {
    final data = widget.document.data() as Map<String, dynamic>;
    final reviewers = data['reviewers'] as List<dynamic>? ?? [];

    if (reviewers.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'حالة المحكمين',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xffa86418),
              ),
            ),
          ),
          const Divider(height: 30, thickness: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: reviewers.length,
            itemBuilder: (context, index) {
              final reviewer = reviewers[index];
              final Color statusColor = reviewer['review_status'] == 'Approved'
                  ? Colors.green
                  : Colors.orange;
              final IconData statusIcon =
                  reviewer['review_status'] == 'Approved'
                      ? Icons.check_circle
                      : Icons.hourglass_top;
              final String statusText = reviewer['review_status'] == 'Approved'
                  ? 'تمت الموافقة'
                  : 'في انتظار المراجعة';

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor),
                        SizedBox(width: 8),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(reviewer['name']),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionHistory() {
    final Map<String, dynamic> data =
        widget.document.data() as Map<String, dynamic>;
    final List<dynamic> actionLog = data['actionLog'] ?? [];

    if (actionLog.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'سجل الإجراءات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xffa86418),
              ),
            ),
          ),
          const Divider(height: 30, thickness: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: actionLog.length,
            itemBuilder: (context, index) {
              final action = actionLog[actionLog.length -
                  1 -
                  index]; // Reverse order to show newest first
              final DateTime timestamp =
                  (action['timestamp'] as Timestamp).toDate();
              final String formattedDate =
                  DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp);

              // Determine action color based on the action type
              Color actionColor = Color(0xffa86418);
              if (action['action'] == 'تم الرفض') {
                actionColor = Colors.red;
              } else if (action['action'] == 'موافقة المحكم') {
                actionColor = Colors.green;
              }

              return Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${action['action']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: actionColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(':الإجراء'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                            '${action['userName']} (${action['userPosition']})'),
                        const SizedBox(width: 8),
                        Text(':بواسطة'),
                      ],
                    ),
                    if (action['comment'] != null &&
                        action['comment'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                action['comment'],
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(':تعليق'),
                          ],
                        ),
                      ),
                    if (action['reviewers'] != null &&
                        (action['reviewers'] as List).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(':المحكمون'),
                            const SizedBox(height: 4),
                            ...List.generate(
                              (action['reviewers'] as List).length,
                              (i) => Padding(
                                padding: const EdgeInsets.only(
                                    right: 16.0, top: 4.0),
                                child: Text('- ${action['reviewers'][i]}'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.document.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'غير معروف';
    final DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
    final String formattedDate =
        DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('تفاصيل المستند'),
        backgroundColor: Color(0xffa86418),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatusProgressBar(
                  status: status,
                ),
                SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (data['documentUrl'] != null) {
                                await _viewFile(data['documentUrl'],
                                    'document_${widget.document.id}.pdf');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('عنوان URL للمستند غير متوفر')),
                                );
                              }
                            },
                            icon: Icon(
                              Icons.visibility,
                              color: Colors.white,
                            ),
                            label: Text(
                              'عرض المستند',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xffa86418),
                            ),
                          ),
                          Spacer(), // Pushes the title to the center
                        ],
                      ),
                      Center(
                        child: Text(
                          'بيانات المرسل',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffa86418),
                          ),
                        ),
                      ),
                      const Divider(height: 30, thickness: 1),
                      detailRow(
                          'الاسم الكامل', data['fullName'] ?? 'غير متوفر'),
                      detailRow(
                          'البريد الإلكتروني', data['email'] ?? 'غير متوفر'),
                      detailRow('حول', data['about'] ?? 'غير متوفر'),
                      detailRow('التعليم', data['education'] ?? 'غير متوفر'),
                      detailRow('الحالة', data['status'] ?? 'غير متوفر'),
                      detailRow('التاريخ', formattedDate),
                    ],
                  ),
                ),
                _buildActionButtons(status),
                _buildReviewersStatusWidget(),
                _buildActionHistory(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
