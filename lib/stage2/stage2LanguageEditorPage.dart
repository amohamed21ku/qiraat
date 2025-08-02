// pages/Stage2/Stage2LanguageEditorPage.dart - New file for Language Editor interface
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

import '../../Classes/current_user_providerr.dart';
import '../Screens/Document_Handling/DocumentDetails/Constants/App_Constants.dart';
import '../Screens/Document_Handling/DocumentDetails/Services/Document_Services.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/Action_history.dart';
import '../Screens/Document_Handling/DocumentDetails/Widgets/senderinfocard.dart';
import '../Screens/Document_Handling/DocumentDetails/models/document_model.dart';

class Stage2LanguageEditorPage extends StatefulWidget {
  final DocumentModel document;

  const Stage2LanguageEditorPage({Key? key, required this.document})
      : super(key: key);

  @override
  _Stage2LanguageEditorPageState createState() =>
      _Stage2LanguageEditorPageState();
}

class _Stage2LanguageEditorPageState extends State<Stage2LanguageEditorPage>
    with TickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();

  bool _isLoading = false;
  DocumentModel? _document;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPosition;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Language editing form controllers
  final TextEditingController _correctionsController = TextEditingController();
  final TextEditingController _suggestionsController = TextEditingController();
  final TextEditingController _generalCommentsController =
      TextEditingController();

  String? _attachedFileName;
  String? _attachedFileUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _initializeAnimations();
    _getCurrentUserInfo();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
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
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _correctionsController.dispose();
    _suggestionsController.dispose();
    _generalCommentsController.dispose();
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
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    _buildContent(),
                  ],
                ),
              ),
              if (_isLoading) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade800],
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
                child: Icon(Icons.spellcheck, color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التدقيق اللغوي',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'المرحلة الثانية - المراجعة اللغوية والأسلوبية',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.spellcheck, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة التدقيق',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'جاهز للتدقيق اللغوي والأسلوبي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(_document!.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Language Editing Guidelines
          _buildLanguageEditingGuidelines(),

          // Document Info Card
          _buildDocumentInfoCard(),

          // Sender Info Card (limited info for language editor)
          _buildLimitedSenderInfo(),

          // Language Editing Form
          _buildLanguageEditingForm(),

          // Previous Actions (filtered)
          if (_document!.actionLog.isNotEmpty) _buildFilteredActionHistory(),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLanguageEditingGuidelines() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade500,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.checklist, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'إرشادات التدقيق اللغوي',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildGuidelineItem('فحص القواعد النحوية والإملائية'),
          _buildGuidelineItem('مراجعة علامات الترقيم والتنسيق'),
          _buildGuidelineItem('تحسين وضوح التعبير والأسلوب'),
          _buildGuidelineItem('التأكد من سلامة المصطلحات العلمية'),
          _buildGuidelineItem('مراجعة تدفق النص والربط بين الفقرات'),
          _buildGuidelineItem('اقتراح تحسينات أسلوبية مناسبة'),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.green.shade500,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentInfoCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade100, Colors.green.shade200],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description,
                    color: Colors.green.shade700, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المستند للتدقيق اللغوي',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'اضغط لعرض أو تحميل الملف للمراجعة اللغوية',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildFileViewingSection(),
        ],
      ),
    );
  }

  Widget _buildFileViewingSection() {
    if (_document!.documentUrl != null && _document!.documentUrl!.isNotEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.grey.shade100],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الملف الأصلي للمقال',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ملف المقال للتدقيق اللغوي',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _handleViewFile,
                  icon: Icon(Icons.visibility, size: 18),
                  label: Text('عرض'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _handleDownloadFile,
                  icon: Icon(Icons.download, size: 18),
                  label: Text('تحميل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
            SizedBox(width: 12),
            Text(
              'لا يوجد ملف مرفق',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLimitedSenderInfo() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 24),
              SizedBox(width: 12),
              Text(
                'معلومات المقال',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'رقم المقال: ${_document!.id.substring(0, 8)}...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'تاريخ الإرسال: ${_formatDate(_document!.timestamp)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageEditingForm() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade500, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نموذج التدقيق اللغوي',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'قم بمراجعة النص لغوياً وأسلوبياً',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Form Content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Corrections Section
                _buildFormSection(
                  'التصحيحات اللغوية والنحوية',
                  'سجل هنا التصحيحات المطلوبة للقواعد النحوية والإملائية...',
                  _correctionsController,
                  Icons.spellcheck,
                  Colors.red,
                ),

                SizedBox(height: 24),

                // Suggestions Section
                _buildFormSection(
                  'اقتراحات التحسين الأسلوبي',
                  'اقترح تحسينات أسلوبية لجعل النص أكثر وضوحاً ودقة...',
                  _suggestionsController,
                  Icons.lightbulb_outline,
                  Colors.orange,
                ),

                SizedBox(height: 24),

                // General Comments Section
                _buildFormSection(
                  'تعليقات عامة (مطلوب)',
                  'تعليقاتك العامة حول النص والملاحظات الشاملة...',
                  _generalCommentsController,
                  Icons.comment,
                  Colors.blue,
                  isRequired: true,
                ),

                SizedBox(height: 24),

                // File Attachment Section
                _buildFileAttachmentSection(),

                SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _canSubmit() ? _showSubmitDialog : null,
                    icon: Icon(Icons.send, size: 24),
                    label: Text(
                      'إرسال التدقيق اللغوي',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(
    String title,
    String hint,
    TextEditingController controller,
    IconData icon,
    Color color, {
    bool isRequired = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title + (isRequired ? ' *' : ''),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 6,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildFileAttachmentSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, color: Colors.purple.shade600, size: 20),
              SizedBox(width: 12),
              Text(
                'إرفاق ملف التدقيق (اختياري)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'يمكنك إرفاق ملف يحتوي على التصحيحات المفصلة',
            style: TextStyle(
              fontSize: 12,
              color: Colors.purple.shade600,
            ),
          ),
          SizedBox(height: 12),
          InkWell(
            onTap: _isUploading ? null : _pickFile,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purple.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: _isUploading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.cloud_upload,
                            color: Colors.purple.shade600),
                  ),
                  Expanded(
                    child: Text(
                      _attachedFileName ?? 'اختر ملف للإرفاق (ملف التدقيق)',
                      style: TextStyle(
                        color: _attachedFileName != null
                            ? Colors.black
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (_attachedFileName != null && !_isUploading)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _attachedFileName = null;
                          _attachedFileUrl = null;
                        });
                      },
                      icon: Icon(Icons.close, color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredActionHistory() {
    // Filter out sensitive actions for language editor
    final filteredActions = _document!.actionLog.where((action) {
      return !action.action.contains('رفض') &&
          !action.action.contains('تحكيم') &&
          !action.action.contains('محكم');
    }).toList();

    if (filteredActions.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      child: ActionHistoryWidget(actionLog: filteredActions),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.green.shade600),
              SizedBox(height: 16),
              Text(
                'جاري معالجة الطلب...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  bool _canSubmit() {
    return _generalCommentsController.text.trim().isNotEmpty && !_isUploading;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // File handling methods
  Future<void> _handleViewFile() async {
    if (_document?.documentUrl == null || _document!.documentUrl!.isEmpty) {
      _showErrorSnackBar('رابط الملف غير متوفر');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        html.window.open(_document!.documentUrl!, '_blank');
        _showSuccessSnackBar('تم فتح الملف في تبويب جديد');
      } else {
        _showSuccessSnackBar('سيتم إضافة عرض الملفات على الهاتف قريباً');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في فتح الملف: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDownloadFile() async {
    if (_document?.documentUrl == null || _document!.documentUrl!.isEmpty) {
      _showErrorSnackBar('رابط الملف غير متوفر');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        final html.AnchorElement anchor =
            html.AnchorElement(href: _document!.documentUrl!)
              ..download = 'article_for_language_editing.pdf'
              ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);

        _showSuccessSnackBar('تم بدء تنزيل الملف');
      } else {
        _showSuccessSnackBar('سيتم إضافة تحميل الملفات على الهاتف قريباً');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في تحميل الملف: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    setState(() => _isUploading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        final file = result.files.single;
        final fileName = file.name;

        final uploadResult = await _uploadFileToFirebaseStorage(file);

        if (uploadResult != null) {
          setState(() {
            _attachedFileName = fileName;
            _attachedFileUrl = uploadResult;
          });
        } else {
          throw Exception('فشل في رفع الملف');
        }
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في رفع الملف: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<String?> _uploadFileToFirebaseStorage(PlatformFile file) async {
    try {
      final FirebaseStorage storage = FirebaseStorage.instance;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'language_editing/${timestamp}_${file.name}';

      Reference ref = storage.ref().child(fileName);

      if (kIsWeb) {
        if (file.bytes != null) {
          UploadTask uploadTask = ref.putData(
            file.bytes!,
            SettableMetadata(
                contentType: _getContentType(file.extension ?? '')),
          );

          TaskSnapshot snapshot = await uploadTask;
          return await snapshot.ref.getDownloadURL();
        }
      }

      return null;
    } catch (e) {
      print('Error uploading file to Firebase Storage: $e');
      return null;
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  void _showSubmitDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.send, color: Colors.green, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'إرسال التدقيق اللغوي',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'تأكيد إرسال التدقيق اللغوي لمدير التحرير',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ملخص التدقيق:'),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_correctionsController.text.isNotEmpty) ...[
                        Text('التصحيحات:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_correctionsController.text.length > 100
                            ? '${_correctionsController.text.substring(0, 100)}...'
                            : _correctionsController.text),
                        SizedBox(height: 8),
                      ],
                      if (_suggestionsController.text.isNotEmpty) ...[
                        Text('الاقتراحات:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_suggestionsController.text.length > 100
                            ? '${_suggestionsController.text.substring(0, 100)}...'
                            : _suggestionsController.text),
                        SizedBox(height: 8),
                      ],
                      Text('التعليقات العامة:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_generalCommentsController.text.length > 100
                          ? '${_generalCommentsController.text.substring(0, 100)}...'
                          : _generalCommentsController.text),
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
                Navigator.pop(context);
                _submitLanguageEditing();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('إرسال التدقيق'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLanguageEditing() async {
    setState(() => _isLoading = true);

    try {
      final reviewData = {
        'corrections': _correctionsController.text.trim(),
        'suggestions': _suggestionsController.text.trim(),
        'comment': _generalCommentsController.text.trim(),
        'attachedFileUrl': _attachedFileUrl,
        'attachedFileName': _attachedFileName,
      };

      await _documentService.submitLanguageEditorReview(
        _document!.id,
        _currentUserId!,
        _currentUserName!,
        reviewData,
      );

      _showSuccessSnackBar('تم إرسال التدقيق اللغوي بنجاح');
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('خطأ في إرسال التدقيق: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
      ),
    );
  }
}
