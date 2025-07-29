// widgets/action_history_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
// Web imports
import 'dart:html' as html;

import '../Constants/App_Constants.dart';
import '../models/document_model.dart';

class ActionHistoryWidget extends StatelessWidget {
  final List<ActionLogModel> actionLog;

  const ActionHistoryWidget({
    Key? key,
    required this.actionLog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (actionLog.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(24),
      margin: EdgeInsets.only(top: 20),
      decoration: AppStyles.simpleCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 20),
          _buildActionsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade100, Colors.blue.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.history, color: Colors.blue.shade700, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سجل الإجراءات',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'تاريخ جميع الإجراءات المتخذة',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${actionLog.length}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsList() {
    // Reverse the list to show most recent actions first
    final reversedActions = actionLog.reversed.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: reversedActions.length,
      itemBuilder: (context, index) {
        return ActionCard(action: reversedActions[index]);
      },
    );
  }
}

class ActionCard extends StatefulWidget {
  final ActionLogModel action;

  const ActionCard({Key? key, required this.action}) : super(key: key);

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard> {
  bool _isLoading = false;

  // Supported file types mapping
  final Map<String, String> supportedFileTypes = {
    '.pdf': 'application/pdf',
    '.doc': 'application/msword',
    '.docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.txt': 'text/plain',
    '.rtf': 'application/rtf',
    '.odt': 'application/vnd.oasis.opendocument.text',
  };

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('MMM dd, yyyy - hh:mm a').format(widget.action.timestamp);
    final actionInfo = _getActionInfo(widget.action.action);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            actionInfo['color'].withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: actionInfo['color'].withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: actionInfo['color'].withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: actionInfo['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    actionInfo['icon'],
                    color: actionInfo['color'],
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.action.action,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: actionInfo['color'],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // File attachment indicator
                if (widget.action.attachedFileUrl != null)
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.attach_file,
                      color: Colors.blue,
                      size: 16,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            _buildActionDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionDetails() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performed by
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey.shade600),
              SizedBox(width: 8),
              Text(
                'بواسطة:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${widget.action.userName} (${widget.action.userPosition})',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xff2d3748),
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: ui.TextDirection.rtl,
                ),
              ),
            ],
          ),

          // Comment
          if (widget.action.comment != null &&
              widget.action.comment!.isNotEmpty) ...[
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.comment, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text(
                  'تعليق:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.action.comment!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff2d3748),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],

          // Attached file
          if (widget.action.attachedFileUrl != null) ...[
            SizedBox(height: 12),
            _buildAttachedFile(),
          ],

          // Reviewers (for reviewer assignment actions)
          if (widget.action.reviewers != null &&
              widget.action.reviewers!.isNotEmpty) ...[
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text(
                  'المحكمون:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.action.reviewers!.map((reviewer) {
                      final actionInfo = _getActionInfo(widget.action.action);
                      return Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: actionInfo['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          reviewer.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: actionInfo['color'],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachedFile() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.05),
            Colors.blue.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getFileIcon(widget.action.attachedFileName ?? ''),
              color: Colors.blue.shade700,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملف مرفق:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  widget.action.attachedFileName ?? 'ملف مرفق',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade500, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _handleViewFile(),
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.visibility, color: Colors.white, size: 16),
              label: Text(
                'عرض',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleViewFile() async {
    if (widget.action.attachedFileUrl == null ||
        widget.action.attachedFileUrl!.isEmpty) {
      _showErrorSnackBar('رابط الملف غير متوفر');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final documentData = _buildDocumentDataMap();

      if (kIsWeb) {
        await _handleWebFileView(documentData);
      } else {
        String fileExtension =
            _getFileExtension(documentData, widget.action.attachedFileUrl!);

        if (!supportedFileTypes.containsKey(fileExtension)) {
          throw Exception(
              'نوع الملف غير مدعوم: ${_getFileTypeDisplayName(documentData, fileExtension)}');
        }

        await _handleMobileFileView(documentData, fileExtension);
      }
    } catch (e) {
      String errorMessage = _getErrorMessage(e);
      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleWebFileView(Map<String, dynamic> documentData) async {
    try {
      final String fileUrl = widget.action.attachedFileUrl!;
      final String fileExtension = _getFileExtension(documentData, fileUrl);
      final String fileName = _getFileName(documentData, fileUrl);

      if (!supportedFileTypes.containsKey(fileExtension)) {
        throw Exception(
            'نوع الملف غير مدعوم: ${_getFileTypeDisplayName(documentData, fileExtension)}');
      }

      _showWebViewOptionsDialog(fileUrl, fileName, fileExtension, documentData);
    } catch (e) {
      throw Exception('فشل في تجهيز الملف للعرض: $e');
    }
  }

  void _showWebViewOptionsDialog(String fileUrl, String fileName,
      String fileExtension, Map<String, dynamic> documentData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.description, color: AppStyles.primaryColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'خيارات عرض الملف',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 20),
                _buildWebViewOption(
                  icon: Icons.open_in_new,
                  title: 'فتح في تبويب جديد',
                  subtitle: 'فتح الملف في تبويب منفصل',
                  onTap: () async {
                    Navigator.pop(context);
                    await _openInNewTab(fileUrl);
                  },
                ),
                SizedBox(height: 12),
                _buildWebViewOption(
                  icon: Icons.download,
                  title: 'تنزيل الملف',
                  subtitle: 'حفظ الملف على جهازك',
                  onTap: () async {
                    Navigator.pop(context);
                    await _downloadFileWeb(fileUrl, fileName, documentData);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebViewOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppStyles.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppStyles.primaryColor, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Future<void> _openInNewTab(String fileUrl) async {
    try {
      html.window.open(fileUrl, '_blank');
      _showSuccessSnackBar('تم فتح الملف في تبويب جديد');
    } catch (e) {
      _showErrorSnackBar('فشل في فتح الملف في تبويب جديد');
    }
  }

  Future<void> _downloadFileWeb(String fileUrl, String fileName,
      Map<String, dynamic> documentData) async {
    try {
      setState(() => _isLoading = true);

      try {
        final html.AnchorElement anchor = html.AnchorElement(href: fileUrl)
          ..download = fileName
          ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);

        _showSuccessSnackBar('تم بدء تنزيل الملف: $fileName');
        return;
      } catch (e) {
        // Continue to method 2
      }

      final dio = Dio();
      final response = await dio.get(
        fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;
        final fileExtension = _getFileExtension(documentData, fileUrl);
        final mimeType =
            supportedFileTypes[fileExtension] ?? 'application/octet-stream';

        final blob = html.Blob([bytes], mimeType);
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);

        final html.AnchorElement anchor = html.AnchorElement(href: blobUrl)
          ..download = fileName
          ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);

        html.Url.revokeObjectUrl(blobUrl);

        _showSuccessSnackBar('تم تنزيل الملف بنجاح: $fileName');
      } else {
        throw Exception('فشل في تنزيل الملف: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('فشل في تنزيل الملف: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMobileFileView(
      Map<String, dynamic> documentData, String fileExtension) async {
    String fileName;
    if (documentData.containsKey('originalFileName') &&
        documentData['originalFileName'] != null) {
      fileName = documentData['originalFileName'];
    } else {
      fileName =
          'attachment_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
    }

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String filePath = '${appDocDir.path}/$fileName';

    await Dio().download(
      widget.action.attachedFileUrl!,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          double progress = received / total;
          debugPrint(
              'Download progress: ${(progress * 100).toStringAsFixed(0)}%');
        }
      },
    );

    final File file = File(filePath);
    if (!await file.exists()) {
      throw Exception('فشل في تنزيل الملف');
    }

    final int fileSize = await file.length();
    if (fileSize == 0) {
      throw Exception('الملف فارغ أو تالف');
    }

    final OpenResult result = await OpenFile.open(
      filePath,
      type: supportedFileTypes[fileExtension],
    );

    switch (result.type) {
      case ResultType.done:
        _showSuccessSnackBar('تم فتح الملف بنجاح');
        break;
      case ResultType.noAppToOpen:
        _showWarningSnackBar(
            'لا يوجد تطبيق مناسب لفتح هذا النوع من الملفات\nالرجاء تثبيت تطبيق مناسب لـ ${_getFileTypeDisplayName(documentData, fileExtension)}');
        break;
      case ResultType.permissionDenied:
        _showErrorSnackBar('تم رفض الإذن لفتح الملف');
        break;
      case ResultType.fileNotFound:
        _showErrorSnackBar('لم يتم العثور على الملف');
        break;
      case ResultType.error:
        _showErrorSnackBar('حدث خطأ أثناء فتح الملف: ${result.message}');
        break;
    }
  }

  // Helper methods
  String _getFileName(Map<String, dynamic> documentData, String url) {
    if (documentData.containsKey('originalFileName') &&
        documentData['originalFileName'] != null &&
        documentData['originalFileName'].toString().isNotEmpty) {
      return documentData['originalFileName'];
    }

    // Try to get filename from attachedFileName in action
    if (widget.action.attachedFileName != null &&
        widget.action.attachedFileName!.isNotEmpty) {
      return widget.action.attachedFileName!;
    }

    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final lastSegment = segments.last;
        if (lastSegment.contains('.')) {
          return lastSegment;
        }
      }
    } catch (e) {
      // Continue to fallback
    }

    final fileExtension = _getFileExtension(documentData, url);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'attachment_$timestamp$fileExtension';
  }

  String _getErrorMessage(dynamic e) {
    String errorMessage = 'حدث خطأ أثناء فتح الملف';

    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'انتهت مهلة الاتصال. تحقق من اتصال الإنترنت';
          break;
        case DioExceptionType.badResponse:
          errorMessage = 'خطأ في الخادم: ${e.response?.statusCode}';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'خطأ في الاتصال. تحقق من اتصال الإنترنت';
          break;
        default:
          errorMessage = 'فشل في تنزيل الملف';
      }
    } else if (e is Exception) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    return errorMessage;
  }

  Map<String, dynamic> _buildDocumentDataMap() {
    return {
      'originalFileName': widget.action.attachedFileName,
      'fileSize': null, // Not available in ActionLogModel
    };
  }

  String _getFileExtension(Map<String, dynamic> documentData, String url) {
    try {
      // First try to get extension from attachedFileName
      if (widget.action.attachedFileName != null) {
        String extension =
            path.extension(widget.action.attachedFileName!).toLowerCase();
        if (extension.isNotEmpty && supportedFileTypes.containsKey(extension)) {
          return extension;
        }
      }

      if (documentData.containsKey('originalFileName')) {
        String? originalFileName = documentData['originalFileName'] as String?;
        if (originalFileName != null) {
          String extension = path.extension(originalFileName).toLowerCase();
          if (extension.isNotEmpty &&
              supportedFileTypes.containsKey(extension)) {
            return extension;
          }
        }
      }

      String urlPath = Uri.parse(url).path;
      String extension = path.extension(urlPath).toLowerCase();
      if (extension.isNotEmpty && supportedFileTypes.containsKey(extension)) {
        return extension;
      }

      Uri uri = Uri.parse(url);
      if (uri.queryParameters.containsKey('type')) {
        String type = uri.queryParameters['type']!.toLowerCase();
        switch (type) {
          case 'pdf':
            return '.pdf';
          case 'doc':
            return '.doc';
          case 'docx':
            return '.docx';
          case 'txt':
            return '.txt';
          case 'rtf':
            return '.rtf';
          case 'odt':
            return '.odt';
        }
      }
      return '.pdf';
    } catch (e) {
      debugPrint('Error extracting file extension: $e');
      return '.pdf';
    }
  }

  String _getFileTypeDisplayName(
      Map<String, dynamic> documentData, String extension) {
    return _getFileTypeName(extension);
  }

  String _getFileTypeName(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return 'PDF';
      case '.doc':
        return 'Word Document (DOC)';
      case '.docx':
        return 'Word Document (DOCX)';
      case '.txt':
        return 'Text Document';
      case '.rtf':
        return 'Rich Text Format';
      case '.odt':
        return 'OpenDocument Text';
      default:
        return 'Document';
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
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 4),
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

  Map<String, dynamic> _getActionInfo(String actionType) {
    Color actionColor = AppStyles.primaryColor;
    IconData actionIcon = Icons.info;

    if (actionType.contains('رفض') || actionType.contains('الرفض')) {
      actionColor = Colors.red;
      actionIcon = Icons.cancel;
    } else if (actionType.contains('موافقة') ||
        actionType.contains('قبول') ||
        actionType.contains('مرسل') ||
        actionType.contains('تمت')) {
      actionColor = Colors.green;
      actionIcon = Icons.check_circle;
    } else if (actionType.contains('تعديل') || actionType.contains('مطلوب')) {
      actionColor = Colors.orange;
      actionIcon = Icons.edit;
    } else if (actionType.contains('محكمين') || actionType.contains('الي')) {
      actionColor = Colors.blue;
      actionIcon = Icons.people;
    } else if (actionType.contains('مدير التحرير')) {
      actionColor = Colors.purple;
      actionIcon = Icons.approval;
    }

    return {
      'color': actionColor,
      'icon': actionIcon,
    };
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.attach_file;
    }
  }
}
