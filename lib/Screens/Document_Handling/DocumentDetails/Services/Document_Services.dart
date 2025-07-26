// services/document_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../models/document_model.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update document status with action logging
  Future<void> updateDocumentStatus(
    String documentId,
    String newStatus,
    String? comment,
    String userId,
    String userName,
    String userPosition, {
    String? attachedFileUrl,
    String? attachedFileName,
  }) async {
    try {
      final actionLog = ActionLogModel(
        action: newStatus,
        userName: userName,
        userPosition: userPosition,
        performedById: userId,
        timestamp: DateTime.now(),
        comment: comment,
        attachedFileUrl: attachedFileUrl,
        attachedFileName: attachedFileName,
      );

      final updateData = <String, dynamic>{
        'status': newStatus,
        'actionLog': FieldValue.arrayUnion([actionLog.toMap()]),
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': userName,
      };

      await _firestore
          .collection('sent_documents')
          .doc(documentId)
          .update(updateData);

      debugPrint('Document $documentId status updated to: $newStatus');
    } catch (e) {
      debugPrint('Error updating document status: $e');
      rethrow;
    }
  }

  /// Assign reviewers to a document
  Future<void> assignReviewers(
    String documentId,
    List<String> reviewerIds,
    String reviewerType,
    String assignedBy,
    String assignedById,
  ) async {
    try {
      if (reviewerIds.isEmpty) {
        throw ArgumentError('Reviewer IDs list cannot be empty');
      }

      List<Map<String, dynamic>> reviewers = [];
      List<ReviewerInfo> reviewerInfoList = [];

      for (String reviewerId in reviewerIds) {
        final reviewerDoc =
            await _firestore.collection('users').doc(reviewerId).get();

        if (reviewerDoc.exists) {
          final reviewerData = reviewerDoc.data() as Map<String, dynamic>;

          final reviewerMap = {
            'userId': reviewerId,
            'name': reviewerData['fullName'] ?? 'غير معروف',
            'email': reviewerData['email'] ?? '',
            'position': reviewerData['position'] ?? '',
            'review_status': 'Pending',
            'assigned_date': Timestamp.now(),
          };

          reviewers.add(reviewerMap);

          reviewerInfoList.add(ReviewerInfo(
            userId: reviewerId,
            name: reviewerData['fullName'] ?? 'غير معروف',
            email: reviewerData['email'] ?? '',
            position: reviewerData['position'] ?? '',
          ));
        } else {
          debugPrint('Reviewer with ID $reviewerId not found');
        }
      }

      if (reviewers.isEmpty) {
        throw Exception('No valid reviewers found');
      }

      // Create action log for reviewer assignment
      final actionLog = ActionLogModel(
        action: 'الي المحكمين',
        userName: assignedBy,
        userPosition: 'مدير التحرير', // or get from user data
        performedById: assignedById,
        timestamp: DateTime.now(),
        reviewers: reviewerInfoList,
        reviewerType: reviewerType,
      );

      final updateData = <String, dynamic>{
        'status': 'الي المحكمين',
        'reviewers': reviewers,
        'reviewer_type': reviewerType,
        'assigned_by': assignedBy,
        'assigned_by_id': assignedById,
        'assigned_date': FieldValue.serverTimestamp(),
        'actionLog': FieldValue.arrayUnion([actionLog.toMap()]),
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': assignedBy,
      };

      await _firestore
          .collection('sent_documents')
          .doc(documentId)
          .update(updateData);

      debugPrint(
          'Assigned ${reviewers.length} reviewers to document $documentId');
    } catch (e) {
      debugPrint('Error assigning reviewers: $e');
      rethrow;
    }
  }

  /// Remove specific reviewer from document (Enhanced admin function)
  Future<void> removeReviewerFromDocument(
    String documentId,
    String reviewerIdToRemove,
    String removedBy,
    String removedById,
  ) async {
    try {
      // Get current document
      final docSnapshot =
          await _firestore.collection('sent_documents').doc(documentId).get();

      if (!docSnapshot.exists) {
        throw Exception('Document not found');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      List<dynamic> existingReviewers = List.from(data['reviewers'] ?? []);

      // Find and remove the reviewer
      String removedReviewerName = 'Unknown';
      final updatedReviewers = existingReviewers.where((reviewer) {
        if (reviewer is Map<String, dynamic> &&
            reviewer['userId'] == reviewerIdToRemove) {
          removedReviewerName = reviewer['name'] ?? 'Unknown';
          return false; // Remove this reviewer
        }
        return true; // Keep all other reviewers
      }).toList();

      if (updatedReviewers.length == existingReviewers.length) {
        throw Exception('Reviewer not found in document');
      }

      final updateData = <String, dynamic>{
        'reviewers': updatedReviewers,
        'actionLog': FieldValue.arrayUnion([
          {
            'action': 'إزالة محكم',
            'userName': removedBy,
            'userPosition': 'إدارة التحرير',
            'performedById': removedById,
            'timestamp': Timestamp.now(),
            'comment': 'تم إزالة المحكم: $removedReviewerName',
          }
        ]),
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': removedBy,
      };

      await _firestore
          .collection('sent_documents')
          .doc(documentId)
          .update(updateData);

      debugPrint(
          'Removed reviewer $removedReviewerName from document $documentId');
    } catch (e) {
      debugPrint('Error removing reviewer: $e');
      rethrow;
    }
  }

  /// Admin override: Change document status to any status
  Future<void> adminChangeDocumentStatus(
    String documentId,
    String newStatus,
    String comment,
    String adminId,
    String adminName,
    String adminPosition,
  ) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
        'actionLog': FieldValue.arrayUnion([
          {
            'action': 'تغيير حالة إداري',
            'userName': adminName,
            'userPosition': adminPosition,
            'performedById': adminId,
            'timestamp': Timestamp.now(),
            'comment': 'تغيير الحالة إلى: $newStatus. السبب: $comment',
          }
        ]),
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': adminName,
        'admin_override': true,
        'admin_override_by': adminName,
        'admin_override_date': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('sent_documents')
          .doc(documentId)
          .update(updateData);

      debugPrint('Admin changed document $documentId status to: $newStatus');
    } catch (e) {
      debugPrint('Error changing document status: $e');
      rethrow;
    }
  }

  /// Get reviewer workload across all active documents
  Future<Map<String, int>> getReviewerWorkload() async {
    try {
      Map<String, int> workload = {};

      final querySnapshot = await _firestore
          .collection('sent_documents')
          .where('status', isEqualTo: 'الي المحكمين')
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final List<dynamic> reviewers = data['reviewers'] ?? [];

        for (var reviewer in reviewers) {
          String reviewerId = '';
          if (reviewer is Map<String, dynamic>) {
            reviewerId = reviewer['userId'] ?? reviewer['id'] ?? '';
          }

          if (reviewerId.isNotEmpty) {
            workload[reviewerId] = (workload[reviewerId] ?? 0) + 1;
          }
        }
      }

      return workload;
    } catch (e) {
      debugPrint('Error getting reviewer workload: $e');
      return {};
    }
  }

  /// Update reviewer status (approve/reject)
  Future<void> updateReviewerStatus(
    String documentId,
    String reviewerId,
    String newStatus,
    String? comment,
    String reviewerName,
  ) async {
    try {
      // Get current document
      final docSnapshot =
          await _firestore.collection('sent_documents').doc(documentId).get();

      if (!docSnapshot.exists) {
        throw Exception('Document not found');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      List<dynamic> reviewers = List.from(data['reviewers'] ?? []);

      bool reviewerFound = false;
      bool allApproved = true;

      // Update the specific reviewer's status
      for (int i = 0; i < reviewers.length; i++) {
        if (reviewers[i] is Map<String, dynamic>) {
          final reviewer = reviewers[i] as Map<String, dynamic>;

          if (reviewer['userId'] == reviewerId) {
            reviewers[i] = {
              ...reviewer,
              'review_status': newStatus,
              'comment': comment,
              'reviewed_date': Timestamp.now(),
            };
            reviewerFound = true;
          }

          // Check if all reviewers have approved
          if (reviewers[i]['review_status'] != 'Approved') {
            allApproved = false;
          }
        }
      }

      if (!reviewerFound) {
        throw Exception('Reviewer not found in document');
      }

      // Create action log
      final actionLog = ActionLogModel(
        action: newStatus == 'Approved' ? 'موافقة المحكم' : 'رفض المحكم',
        userName: reviewerName,
        userPosition: 'محكم', // You might want to get this from user data
        performedById: reviewerId,
        timestamp: DateTime.now(),
        comment: comment,
      );

      String documentStatus = data['status'];
      if (newStatus == 'Approved' && allApproved) {
        documentStatus = 'تم التحكيم';
      }

      final updateData = <String, dynamic>{
        'reviewers': reviewers,
        'status': documentStatus,
        'actionLog': FieldValue.arrayUnion([actionLog.toMap()]),
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': reviewerName,
      };

      if (allApproved) {
        updateData['all_approved_date'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('sent_documents')
          .doc(documentId)
          .update(updateData);

      debugPrint('Reviewer $reviewerId status updated to: $newStatus');
    } catch (e) {
      debugPrint('Error updating reviewer status: $e');
      rethrow;
    }
  }

  /// Get document by ID
  Future<DocumentModel?> getDocument(String documentId) async {
    try {
      final docSnapshot =
          await _firestore.collection('sent_documents').doc(documentId).get();

      if (docSnapshot.exists) {
        return DocumentModel.fromFirestore(docSnapshot);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting document: $e');
      return null;
    }
  }

  /// Get documents by status
  Future<List<DocumentModel>> getDocumentsByStatus(String status) async {
    try {
      final querySnapshot = await _firestore
          .collection('sent_documents')
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting documents by status: $e');
      return [];
    }
  }

  /// Stream documents for real-time updates
  Stream<List<DocumentModel>> streamDocumentsByStatus(String status) {
    return _firestore
        .collection('sent_documents')
        .where('status', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentModel.fromFirestore(doc))
            .toList());
  }

  /// Get reviewer statistics
  Future<Map<String, dynamic>> getReviewerStatistics(String reviewerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('sent_documents')
          .where('reviewers', arrayContainsAny: [
        {'userId': reviewerId}
      ]).get();

      int totalAssigned = 0;
      int approved = 0;
      int rejected = 0;
      int pending = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final List<dynamic> reviewers = data['reviewers'] ?? [];

        for (var reviewer in reviewers) {
          if (reviewer is Map<String, dynamic> &&
              reviewer['userId'] == reviewerId) {
            totalAssigned++;
            final status = reviewer['review_status'] ?? 'Pending';

            switch (status) {
              case 'Approved':
                approved++;
                break;
              case 'Rejected':
                rejected++;
                break;
              default:
                pending++;
            }
          }
        }
      }

      return {
        'totalAssigned': totalAssigned,
        'approved': approved,
        'rejected': rejected,
        'pending': pending,
        'completionRate':
            totalAssigned > 0 ? (approved + rejected) / totalAssigned : 0,
      };
    } catch (e) {
      debugPrint('Error getting reviewer statistics: $e');
      return {};
    }
  }
}

class FileService {
  static const Map<String, String> supportedFileTypes = {
    '.pdf': 'application/pdf',
    '.doc': 'application/msword',
    '.docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.txt': 'text/plain',
    '.rtf': 'application/rtf',
    '.odt': 'application/vnd.oasis.opendocument.text',
  };

  /// Extract file extension from URL with optional document data
  static String getFileExtension(String url,
      {Map<String, dynamic>? documentData}) {
    try {
      // Try to get extension from documentData first
      if (documentData != null) {
        if (documentData.containsKey('documentType')) {
          String? docType = documentData['documentType'] as String?;
          if (docType != null &&
              docType.isNotEmpty &&
              supportedFileTypes.containsKey(docType)) {
            return docType;
          }
        }

        if (documentData.containsKey('originalFileName')) {
          String? originalFileName =
              documentData['originalFileName'] as String?;
          if (originalFileName != null) {
            String extension = path.extension(originalFileName).toLowerCase();
            if (extension.isNotEmpty &&
                supportedFileTypes.containsKey(extension)) {
              return extension;
            }
          }
        }
      }

      // Try to get extension from URL
      String urlPath = Uri.parse(url).path;
      String extension = path.extension(urlPath).toLowerCase();
      if (extension.isNotEmpty && supportedFileTypes.containsKey(extension)) {
        return extension;
      }

      // Try to get from URL query parameters
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

      // Default to PDF if nothing else works
      return '.pdf';
    } catch (e) {
      debugPrint('Error extracting file extension: $e');
      return '.pdf';
    }
  }

  /// Extract file extension from URL only (simplified version)
  static String getFileExtensionFromUrl(String url) {
    try {
      String urlPath = Uri.parse(url).path;
      String extension = path.extension(urlPath).toLowerCase();

      if (extension.isNotEmpty && supportedFileTypes.containsKey(extension)) {
        return extension;
      }

      // Try to get from URL query parameters
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

      // Default to PDF
      return '.pdf';
    } catch (e) {
      debugPrint('Error extracting file extension from URL: $e');
      return '.pdf';
    }
  }

  /// Extract file extension from filename
  static String getFileExtensionFromFilename(String filename) {
    try {
      String extension = path.extension(filename).toLowerCase();

      if (extension.isNotEmpty && supportedFileTypes.containsKey(extension)) {
        return extension;
      }

      // Default to PDF
      return '.pdf';
    } catch (e) {
      debugPrint('Error extracting file extension from filename: $e');
      return '.pdf';
    }
  }

  /// Get display name for file type
  static String getFileTypeDisplayName(
      String extension, String? originalFileName) {
    // If we have an original filename, try to extract a meaningful type name
    if (originalFileName != null && originalFileName.isNotEmpty) {
      String fileExt = getFileExtensionFromFilename(originalFileName);
      if (fileExt.isNotEmpty && supportedFileTypes.containsKey(fileExt)) {
        return getFileTypeName(fileExt);
      }
    }

    return getFileTypeName(extension);
  }

  /// Get icon for file type
  static IconData getFileTypeIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.txt':
        return Icons.text_snippet;
      case '.rtf':
        return Icons.article;
      case '.odt':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Get human readable file type name
  static String getFileTypeName(String extension) {
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

  /// Check if file type is supported
  static bool isFileTypeSupported(String extension) {
    return supportedFileTypes.containsKey(extension.toLowerCase());
  }

  /// Get MIME type for file extension
  static String? getMimeType(String extension) {
    return supportedFileTypes[extension.toLowerCase()];
  }

  /// Get all supported file extensions
  static List<String> getSupportedExtensions() {
    return supportedFileTypes.keys.toList();
  }

  /// Get all supported MIME types
  static List<String> getSupportedMimeTypes() {
    return supportedFileTypes.values.toList();
  }

  /// Check if URL points to a supported file type
  static bool isUrlSupported(String url) {
    String extension = getFileExtensionFromUrl(url);
    return isFileTypeSupported(extension);
  }

  /// Get file info from URL and optional document data
  static FileInfo getFileInfo(String url,
      {Map<String, dynamic>? documentData}) {
    String extension = getFileExtension(url, documentData: documentData);

    return FileInfo(
      extension: extension,
      typeName: getFileTypeName(extension),
      icon: getFileTypeIcon(extension),
      mimeType: getMimeType(extension),
      isSupported: isFileTypeSupported(extension),
    );
  }
}

/// File information data class
class FileInfo {
  final String extension;
  final String typeName;
  final IconData icon;
  final String? mimeType;
  final bool isSupported;

  const FileInfo({
    required this.extension,
    required this.typeName,
    required this.icon,
    this.mimeType,
    required this.isSupported,
  });

  @override
  String toString() {
    return 'FileInfo(extension: $extension, typeName: $typeName, isSupported: $isSupported)';
  }
}

// services/permission_service.dart
class PermissionService {
  static bool canAssignReviewers(String? position) {
    return position == 'رئيس التحرير' || position == 'مدير التحرير';
  }

  static bool canFinalApprove(String? position) {
    return position == 'مدير التحرير' || position == 'رئيس التحرير';
  }

  static bool isHeadOfEditors(String? position) {
    return position == 'رئيس التحرير';
  }

  static bool isEditorChief(String? position) {
    return position == 'مدير التحرير';
  }
}
