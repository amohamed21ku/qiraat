// widgets/document_info_card.dart
import 'package:flutter/material.dart';
import 'dart:math';

import '../Constants/App_Constants.dart';
import '../Services/Document_Services.dart';
import '../models/document_model.dart';

class DocumentInfoCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onViewFile;

  const DocumentInfoCard({
    Key? key,
    required this.document,
    required this.onViewFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (document.documentUrl == null || document.documentUrl!.isEmpty) {
      return _buildErrorCard();
    }

    return Container(
      padding: EdgeInsets.all(24),
      margin: EdgeInsets.only(bottom: 20),
      decoration: AppStyles.cardDecoration,
      child: _buildDocumentInfo(),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.red.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.error_outline, color: Colors.red, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مشكلة في الملف',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'رابط المستند غير متوفر',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentInfo() {
    // Use the FileService to get file information
    final FileInfo fileInfo = FileService.getFileInfo(
      document.documentUrl!,
      documentData: _buildDocumentDataMap(),
    );

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppStyles.primaryColor.withOpacity(0.1),
                    AppStyles.primaryColor.withOpacity(0.2)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                fileInfo.icon,
                color: AppStyles.primaryColor,
                size: 32,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نوع المستند',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    fileInfo.typeName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.primaryColor,
                    ),
                  ),
                  if (document.originalFileName != null &&
                      document.originalFileName!.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        document.originalFileName!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (document.fileSize != null && document.fileSize! > 0) ...[
                    SizedBox(height: 6),
                    Text(
                      _formatFileSize(document.fileSize!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _buildViewFileButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildViewFileButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppStyles.primaryColor, AppStyles.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppStyles.primaryColor.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onViewFile,
        icon: Icon(Icons.visibility, color: Colors.white, size: 20),
        label: Text(
          'عرض الملف',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: AppStyles.transparentButtonStyle,
      ),
    );
  }

  /// Build document data map for FileService
  Map<String, dynamic> _buildDocumentDataMap() {
    return {
      'documentType': document.documentType,
      'documentTypeName': document.documentTypeName,
      'originalFileName': document.originalFileName,
      'fileSize': document.fileSize,
    };
  }

  /// Format file size in human readable format
  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}
