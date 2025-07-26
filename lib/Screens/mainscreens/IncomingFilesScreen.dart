import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:ui' as ui;
import 'dart:io';

import '../../Classes/current_user_providerr.dart';
import '../Document_Handling/DocumentDetails/DocumentDetails.dart';

class IncomingFilesPage extends StatefulWidget {
  const IncomingFilesPage({Key? key}) : super(key: key);

  @override
  State<IncomingFilesPage> createState() => _IncomingFilesPageState();
}

class _IncomingFilesPageState extends State<IncomingFilesPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _cardAnimationController;
  late Animation<double> _slideAnimation;

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

    _animationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Check if user can manage incoming files
  bool _canManageIncomingFiles(String? position) {
    return position == 'سكرتير تحرير' ||
        position == 'مدير التحرير' ||
        position == 'رئيس التحرير';
  }

  List<DocumentSnapshot> _sortDocuments(List<DocumentSnapshot> documents) {
    try {
      if (_selectedFilter == 'الأحدث') {
        documents.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>?;
          final bData = b.data() as Map<String, dynamic>?;

          if (aData == null || bData == null) return 0;

          final Timestamp? aTime = aData['timestamp'] as Timestamp?;
          final Timestamp? bTime = bData['timestamp'] as Timestamp?;

          if (aTime == null || bTime == null) return 0;

          return bTime.compareTo(aTime);
        });
      } else if (_selectedFilter == 'الأقدم') {
        documents.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>?;
          final bData = b.data() as Map<String, dynamic>?;

          if (aData == null || bData == null) return 0;

          final Timestamp? aTime = aData['timestamp'] as Timestamp?;
          final Timestamp? bTime = bData['timestamp'] as Timestamp?;

          if (aTime == null || bTime == null) return 0;

          return aTime.compareTo(bTime);
        });
      }
    } catch (e) {
      print('Error sorting documents: $e');
    }
    return documents;
  }

  List<DocumentSnapshot> _filterDocuments(List<DocumentSnapshot> documents) {
    if (_searchQuery.isEmpty) return documents;

    return documents.where((doc) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;

        final fullName = (data['fullName'] ?? '').toString().toLowerCase();
        final about = (data['about'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return fullName.contains(query) ||
            about.contains(query) ||
            email.contains(query);
      } catch (e) {
        print('Error filtering document: $e');
        return false;
      }
    }).toList();
  }

  Future<String?> _uploadFile(
      PlatformFile file, String documentId, String actionType) async {
    try {
      final currentUserProvider =
          Provider.of<CurrentUserProvider>(context, listen: false);
      final currentUser = currentUserProvider.currentUser;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${actionType}_${documentId}_${timestamp}_${file.name}';
      final path = 'action_files/$documentId/$fileName';

      final ref = FirebaseStorage.instance.ref().child(path);

      UploadTask uploadTask;
      if (file.bytes != null) {
        uploadTask = ref.putData(file.bytes!);
      } else if (file.path != null) {
        uploadTask = ref.putFile(File(file.path!));
      } else {
        throw Exception('No file data available');
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      throw e;
    }
  }

  Future<void> _updateDocumentStatus(
      DocumentSnapshot document, String newStatus,
      {String? comment, PlatformFile? attachedFile}) async {
    // Show loading dialog
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
                  attachedFile != null
                      ? 'جاري رفع الملف وتحديث الحالة...'
                      : 'جاري تحديث حالة الملف...',
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

      String? fileUrl;
      String? fileName;

      // Upload file if provided
      if (attachedFile != null) {
        fileUrl = await _uploadFile(
            attachedFile, document.id, newStatus.replaceAll(' ', '_'));
        fileName = attachedFile.name;
      }

      // Create action log entry
      Map<String, dynamic> actionLogEntry = {
        'action': newStatus,
        'userName': currentUser?.name ?? 'غير معروف',
        'userPosition': currentUser?.position ?? 'غير معروف',
        'userId': currentUser?.id ?? currentUser?.email ?? 'غير معروف',
        'timestamp': Timestamp.now(),
      };

      if (comment != null && comment.isNotEmpty) {
        actionLogEntry['comment'] = comment;
      }

      if (fileUrl != null) {
        actionLogEntry['attachedFileUrl'] = fileUrl;
        actionLogEntry['attachedFileName'] = fileName;
      }

      // Prepare update data
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
        'actionLog': FieldValue.arrayUnion([actionLogEntry]),
      };

      // Add specific timestamps and user info based on status
      if (newStatus == 'ملف مرسل') {
        updateData['processedDate'] = FieldValue.serverTimestamp();
        updateData['processedBy'] = currentUser?.name ?? 'غير معروف';
        updateData['processedById'] =
            currentUser?.id ?? currentUser?.email ?? 'غير معروف';
      } else if (newStatus == 'تم الرفض') {
        updateData['rejectedDate'] = FieldValue.serverTimestamp();
        updateData['rejectedBy'] = currentUser?.name ?? 'غير معروف';
        updateData['rejectedById'] =
            currentUser?.id ?? currentUser?.email ?? 'غير معروف';
        if (comment != null && comment.isNotEmpty) {
          updateData['rejectionReason'] = comment;
        }
      } else if (newStatus == 'مطلوب تعديل') {
        updateData['editRequestedDate'] = FieldValue.serverTimestamp();
        updateData['editRequestedBy'] = currentUser?.name ?? 'غير معروف';
        updateData['editRequestedById'] =
            currentUser?.id ?? currentUser?.email ?? 'غير معروف';
        if (comment != null && comment.isNotEmpty) {
          updateData['editComment'] = comment;
        }
      }

      await FirebaseFirestore.instance
          .collection('sent_documents')
          .doc(document.id)
          .update(updateData);

      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      // Show success snackbar
      _showSuccessSnackBar('تم تحديث حالة الملف بنجاح');
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog
      _showErrorSnackBar('خطأ في تحديث حالة الملف: $e');
    }
  }

  void _showActionDialog(DocumentSnapshot document) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
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
                        child: Icon(Icons.inbox, color: Colors.white, size: 28),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إجراء على الملف الوارد',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'اختر الإجراء المناسب للملف',
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
                    children: [
                      // Document info
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
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
                      SizedBox(height: 24),

                      // Action buttons
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  'قبول الملف',
                                  Icons.check_circle,
                                  Colors.green.shade600,
                                  () {
                                    Navigator.pop(context);
                                    _showDetailedActionDialog(
                                        document,
                                        'ملف مرسل',
                                        'قبول الملف',
                                        Colors.green.shade600);
                                  },
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  'طلب تعديل',
                                  Icons.edit,
                                  Colors.orange.shade600,
                                  () {
                                    Navigator.pop(context);
                                    _showDetailedActionDialog(
                                        document,
                                        'مطلوب تعديل',
                                        'طلب تعديل',
                                        Colors.orange.shade600);
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  'رفض الملف',
                                  Icons.cancel,
                                  Colors.red.shade600,
                                  () {
                                    Navigator.pop(context);
                                    _showDetailedActionDialog(
                                        document,
                                        'تم الرفض',
                                        'رفض الملف',
                                        Colors.red.shade600);
                                  },
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side:
                                        BorderSide(color: Colors.grey.shade400),
                                  ),
                                  child: Text(
                                    'إلغاء',
                                    style: TextStyle(
                                      fontSize: 14,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailedActionDialog(DocumentSnapshot document, String status,
      String action, Color actionColor) {
    final TextEditingController commentController = TextEditingController();
    PlatformFile? selectedFile;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
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
                        colors: [
                          Color.lerp(actionColor, Colors.white, 0.1)!,
                          Color.lerp(actionColor, Colors.black, 0.1)!
                        ],
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
                          child: Icon(
                            status == 'تم الرفض'
                                ? Icons.cancel
                                : status == 'مطلوب تعديل'
                                    ? Icons.edit
                                    : Icons.check_circle,
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
                                action,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'أضف تعليق أو ملف مرفق (اختياري)',
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
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Document info
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
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

                            // Comment section
                            Text(
                              'التعليق',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff2d3748),
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: TextField(
                                controller: commentController,
                                maxLines: 3,
                                textDirection: ui.TextDirection.rtl,
                                decoration: InputDecoration(
                                  hintText: 'اكتب تعليقك هنا (اختياري)...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
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
                                ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // File upload section
                            Text(
                              'ملف مرفق',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff2d3748),
                              ),
                            ),
                            SizedBox(height: 8),

                            if (selectedFile == null)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    style: BorderStyle.solid,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.grey.shade50,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.cloud_upload,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'اختر ملف للإرفاق (اختياري)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        try {
                                          FilePickerResult? result =
                                              await FilePicker.platform
                                                  .pickFiles(
                                            type: FileType.custom,
                                            allowedExtensions: [
                                              'pdf',
                                              'doc',
                                              'docx',
                                              'txt',
                                              'jpg',
                                              'png'
                                            ],
                                            allowMultiple: false,
                                          );

                                          if (result != null &&
                                              result.files.isNotEmpty) {
                                            setState(() {
                                              selectedFile = result.files.first;
                                            });
                                          }
                                        } catch (e) {
                                          _showErrorSnackBar(
                                              'خطأ في اختيار الملف: $e');
                                        }
                                      },
                                      icon: Icon(Icons.attach_file),
                                      label: Text('اختيار ملف'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.green.shade300),
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.green.shade50,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.attach_file,
                                        color: Colors.green.shade700,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedFile!.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade800,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (selectedFile!.size > 0)
                                            Text(
                                              '${(selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green.shade600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedFile = null;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.red.shade600,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            SizedBox(height: 24),

                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color.lerp(
                                              actionColor, Colors.white, 0.1)!,
                                          Color.lerp(
                                              actionColor, Colors.black, 0.1)!
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: actionColor.withOpacity(0.3),
                                          spreadRadius: 0,
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _updateDocumentStatus(
                                          document,
                                          status,
                                          comment: commentController.text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : commentController.text.trim(),
                                          attachedFile: selectedFile,
                                        );
                                      },
                                      icon: Icon(
                                        status == 'تم الرفض'
                                            ? Icons.cancel
                                            : status == 'مطلوب تعديل'
                                                ? Icons.edit
                                                : Icons.check_circle,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      label: Text(
                                        action,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
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
                                        borderRadius: BorderRadius.circular(12),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(color, Colors.white, 0.1)!,
            Color.lerp(color, Colors.black, 0.1)!
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
        icon: Icon(icon, color: Colors.white, size: 18),
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  secondaryColor.withOpacity(0.1)
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
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'جاري تحميل الملفات الواردة...',
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
    );
  }

  Widget _buildEmptyState() {
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
                  colors: [Colors.grey.shade100, Colors.grey.shade50],
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
                Icons.inbox_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'لا توجد ملفات واردة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'سيتم عرض الملفات الواردة الجديدة هنا',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
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
    final canManage = _canManageIncomingFiles(currentUser?.position);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xfff8f9fa),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 1024;

              return Column(
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
                    child: SafeArea(
                      child: Row(
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
                              onPressed: () => Navigator.pop(context,
                                  true), // Return true to refresh count
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الملفات الواردة',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 32 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'إدارة الملفات الواردة الجديدة من المؤلفين',
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
                              Icons.inbox,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
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
                              hintText: 'ابحث عن ملف وارد...',
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
                                border: Border.all(color: Colors.grey.shade300),
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
                            Row(
                              children: [
                                Icon(Icons.sort, color: primaryColor, size: 20),
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
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 80 : 20,
                        vertical: 20,
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('sent_documents')
                            .where('status', isEqualTo: 'ملف مرسل')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.red.shade200),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red, size: 48),
                                    SizedBox(height: 16),
                                    Text(
                                      'حدث خطأ في تحميل البيانات',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingState();
                          }

                          List<DocumentSnapshot> documents =
                              snapshot.data!.docs;
                          documents = _filterDocuments(documents);
                          documents = _sortDocuments(documents);

                          if (documents.isEmpty) {
                            return _buildEmptyState();
                          }

                          return AnimatedBuilder(
                            animation: _slideAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _slideAnimation.value),
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  itemCount: documents.length,
                                  itemBuilder: (context, index) {
                                    return AnimatedContainer(
                                      duration: Duration(
                                          milliseconds: 300 + (index * 100)),
                                      curve: Curves.easeOutBack,
                                      child: _buildIncomingFileCard(
                                          documents[index], canManage, index),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
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

  Widget _buildIncomingFileCard(
      DocumentSnapshot doc, bool canManage, int index) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return Container();

    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = timestamp != null
        ? DateFormat('yyyy-MM-dd • HH:mm').format(timestamp)
        : 'تاريخ غير محدد';

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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
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
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.inbox, color: Colors.white, size: 24),
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
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.new_releases,
                              size: 14, color: Colors.orange),
                          SizedBox(width: 4),
                          Text(
                            'ملف وارد',
                            style: TextStyle(
                              color: Colors.orange,
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

                // Email Row
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email, size: 16, color: primaryColor),
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

                // About section if available
                if (data['about'] != null &&
                    data['about'].toString().isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryColor.withOpacity(0.1)),
                    ),
                    child: Text(
                      data['about'],
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                // Action buttons for authorized users
                if (canManage) ...[
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
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
                      onPressed: () => _showActionDialog(doc),
                      icon: Icon(Icons.settings, color: Colors.white, size: 18),
                      label: Text(
                        'إدارة الملف',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 16),
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
}
