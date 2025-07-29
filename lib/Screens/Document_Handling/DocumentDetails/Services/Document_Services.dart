// Services/Document_Services.dart - Updated with Stage 1 streaming capabilities
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../Constants/App_Constants.dart';
import '../models/document_model.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add the missing streaming method for Stage 1 documents
  Stream<List<DocumentModel>> getStage1DocumentsStream() {
    try {
      return _firestore
          .collection('sent_documents')
          .where('status', whereIn: AppConstants.stage1Statuses)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => DocumentModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      debugPrint('Error creating Stage 1 documents stream: $e');
      // Return empty stream in case of error
      return Stream.value([]);
    }
  }

  // Optimized method to get all Stage 1 documents at once (for initial load if needed)
  Future<List<DocumentModel>> getAllStage1Documents() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('sent_documents')
          .where('status', whereIn: AppConstants.stage1Statuses)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching Stage 1 documents: $e');
      throw e;
    }
  }

  /// Update document status for Stage 1 workflow
  Future<void> updateDocumentStatus(
    String documentId,
    String newStatus,
    String? comment,
    String userId,
    String userName,
    String userPosition, {
    String? attachedFileUrl,
    String? attachedFileName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Create action description based on status
      String actionDescription = _getActionDescription(newStatus);

      final actionLog = ActionLogModel(
        action: actionDescription,
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
        'lastUpdatedById': userId,
        'lastUpdatedByPosition': userPosition,
        'stage': AppStyles.getStageNumber(newStatus),
      };

      // Add status-specific data and timestamps
      updateData.addAll(_getStage1StatusSpecificData(
          newStatus, userName, userId, userPosition));

      // Add any additional data
      if (additionalData != null) {
        updateData.addAll(additionalData);
      }

      await _firestore
          .collection('sent_documents')
          .doc(documentId)
          .update(updateData);

      debugPrint(
          'Document $documentId status updated to: $newStatus by $userName ($userPosition)');
    } catch (e) {
      debugPrint('Error updating document status: $e');
      rethrow;
    }
  }

  /// Get action description for Stage 1 statuses
  String _getActionDescription(String status) {
    switch (status) {
      case AppConstants.SECRETARY_REVIEW:
        return 'بدء مراجعة السكرتير';
      case AppConstants.SECRETARY_APPROVED:
        return 'موافقة السكرتير';
      case AppConstants.SECRETARY_REJECTED:
        return 'رفض السكرتير';
      case AppConstants.SECRETARY_EDIT_REQUESTED:
        return 'طلب تعديل من السكرتير';
      case AppConstants.EDITOR_REVIEW:
        return 'بدء مراجعة مدير التحرير';
      case AppConstants.EDITOR_APPROVED:
        return 'موافقة مدير التحرير';
      case AppConstants.EDITOR_REJECTED:
        return 'رفض مدير التحرير';
      case AppConstants.EDITOR_WEBSITE_RECOMMENDED:
        return 'توصية بالنشر على الموقع';
      case AppConstants.EDITOR_EDIT_REQUESTED:
        return 'طلب تعديل من مدير التحرير';
      case AppConstants.HEAD_REVIEW:
        return 'بدء المراجعة النهائية من رئيس التحرير';
      case AppConstants.STAGE1_APPROVED:
        return 'الموافقة النهائية للمرحلة الثانية';
      case AppConstants.FINAL_REJECTED:
        return 'الرفض النهائي';
      case AppConstants.WEBSITE_APPROVED:
        return 'موافقة النشر على الموقع';
      default:
        return 'تحديث الحالة';
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

  /// Get status-specific data for Stage 1 workflow
  Map<String, dynamic> _getStage1StatusSpecificData(
      String status, String userName, String userId, String userPosition) {
    final data = <String, dynamic>{};
    final timestamp = FieldValue.serverTimestamp();

    switch (status) {
      case AppConstants.SECRETARY_REVIEW:
        data.addAll({
          'secretaryReviewStartDate': timestamp,
          'secretaryReviewBy': userName,
          'secretaryReviewById': userId,
          'currentStage': 'secretary_review',
        });
        break;

      case AppConstants.SECRETARY_APPROVED:
        data.addAll({
          'secretaryApprovalDate': timestamp,
          'secretaryApprovedBy': userName,
          'secretaryApprovedById': userId,
          'secretaryDecision': 'approved',
        });
        break;

      case AppConstants.SECRETARY_REJECTED:
        data.addAll({
          'secretaryRejectionDate': timestamp,
          'secretaryRejectedBy': userName,
          'secretaryRejectedById': userId,
          'secretaryDecision': 'rejected',
          // Note: Removed 'stage1Status': 'rejected_by_secretary' to allow further review
        });
        break;

      case AppConstants.SECRETARY_EDIT_REQUESTED:
        data.addAll({
          'secretaryEditRequestDate': timestamp,
          'secretaryEditRequestBy': userName,
          'secretaryEditRequestById': userId,
          'secretaryDecision': 'edit_requested',
        });
        break;

      case AppConstants.EDITOR_REVIEW:
        data.addAll({
          'editorReviewStartDate': timestamp,
          'editorReviewBy': userName,
          'editorReviewById': userId,
          'currentStage': 'editor_review',
        });
        break;

      case AppConstants.EDITOR_APPROVED:
        data.addAll({
          'editorApprovalDate': timestamp,
          'editorApprovedBy': userName,
          'editorApprovedById': userId,
          'editorDecision': 'approved',
        });
        break;

      case AppConstants.EDITOR_REJECTED:
        data.addAll({
          'editorRejectionDate': timestamp,
          'editorRejectedBy': userName,
          'editorRejectedById': userId,
          'editorDecision': 'rejected',
          // Note: Not marking as final rejection to allow head editor review
        });
        break;

      case AppConstants.EDITOR_WEBSITE_RECOMMENDED:
        data.addAll({
          'editorWebsiteRecommendationDate': timestamp,
          'editorWebsiteRecommendedBy': userName,
          'editorWebsiteRecommendedById': userId,
          'editorDecision': 'website_recommended',
        });
        break;

      case AppConstants.EDITOR_EDIT_REQUESTED:
        data.addAll({
          'editorEditRequestDate': timestamp,
          'editorEditRequestBy': userName,
          'editorEditRequestById': userId,
          'editorDecision': 'edit_requested',
        });
        break;

      case AppConstants.HEAD_REVIEW:
        data.addAll({
          'headReviewStartDate': timestamp,
          'headReviewBy': userName,
          'headReviewById': userId,
          'currentStage': 'head_review',
        });
        break;

      case AppConstants.STAGE1_APPROVED:
        data.addAll({
          'stage1CompletionDate': timestamp,
          'stage1ApprovedBy': userName,
          'stage1ApprovedById': userId,
          'finalDecision': 'approved_for_stage2',
          'readyForStage2': true,
          'stage1Status': 'completed_approved',
        });
        break;

      case AppConstants.FINAL_REJECTED:
        data.addAll({
          'finalRejectionDate': timestamp,
          'finalRejectedBy': userName,
          'finalRejectedById': userId,
          'finalDecision': 'rejected',
          'stage1Status': 'completed_rejected',
        });
        break;

      case AppConstants.WEBSITE_APPROVED:
        data.addAll({
          'websiteApprovalDate': timestamp,
          'websiteApprovedBy': userName,
          'websiteApprovedById': userId,
          'finalDecision': 'approved_for_website',
          'stage1Status': 'completed_website',
        });
        break;
    }

    return data;
  }

  /// Get documents for Stage 1 workflow based on user position - Updated to include rejected files
  Future<List<DocumentModel>> getDocumentsForUser(
      String userId, String userPosition) async {
    try {
      List<DocumentModel> documents = [];

      // Get documents based on user position and Stage 1 workflow
      if (userPosition == AppConstants.POSITION_SECRETARY) {
        // Secretary can handle incoming and review files
        documents.addAll(await getDocumentsByStatus(AppConstants.INCOMING));
        documents
            .addAll(await getDocumentsByStatus(AppConstants.SECRETARY_REVIEW));
      } else if (userPosition == AppConstants.POSITION_MANAGING_EDITOR) {
        // Managing Editor can handle:
        // 1. Files approved by secretary
        // 2. Files rejected by secretary (to potentially override the decision)
        // 3. Files with edit requests from secretary
        // 4. Files currently under editor review
        documents
            .addAll(await getDocumentsByStatus(AppConstants.EDITOR_REVIEW));
        documents.addAll(
            await getDocumentsByStatus(AppConstants.SECRETARY_APPROVED));
        documents.addAll(await getDocumentsByStatus(
            AppConstants.SECRETARY_REJECTED)); // Added this
        documents.addAll(
            await getDocumentsByStatus(AppConstants.SECRETARY_EDIT_REQUESTED));
      } else if (userPosition == AppConstants.POSITION_HEAD_EDITOR) {
        // Head Editor can handle:
        // 1. Files approved by managing editor
        // 2. Files rejected by managing editor (to potentially override the decision)
        // 3. Files with website recommendations
        // 4. Files with edit requests from managing editor
        // 5. Files currently under head editor review
        documents.addAll(await getDocumentsByStatus(AppConstants.HEAD_REVIEW));
        documents
            .addAll(await getDocumentsByStatus(AppConstants.EDITOR_APPROVED));
        documents.addAll(await getDocumentsByStatus(
            AppConstants.EDITOR_REJECTED)); // Added this
        documents.addAll(await getDocumentsByStatus(
            AppConstants.EDITOR_WEBSITE_RECOMMENDED));
        documents.addAll(
            await getDocumentsByStatus(AppConstants.EDITOR_EDIT_REQUESTED));
      }
      // Note: Reviewer functionality will be added in Stage 2

      // Sort by priority and date
      documents.sort((a, b) {
        final aPriority = _getStage1StatusPriority(a.status);
        final bPriority = _getStage1StatusPriority(b.status);

        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }

        return b.timestamp.compareTo(a.timestamp);
      });

      return documents;
    } catch (e) {
      debugPrint('Error getting documents for user: $e');
      return [];
    }
  }

  /// Get status priority for Stage 1 workflow - Updated priorities
  int _getStage1StatusPriority(String status) {
    const priorityMap = {
      // High priority (need immediate action)
      AppConstants.INCOMING: 1,
      AppConstants.SECRETARY_REVIEW: 2,
      AppConstants.EDITOR_REVIEW: 3,
      AppConstants.HEAD_REVIEW: 4,

      // Medium priority (ready for next reviewer)
      AppConstants.SECRETARY_APPROVED: 5,
      AppConstants.SECRETARY_EDIT_REQUESTED: 6,
      AppConstants.EDITOR_APPROVED: 7,
      AppConstants.EDITOR_WEBSITE_RECOMMENDED: 8,
      AppConstants.EDITOR_EDIT_REQUESTED: 9,

      // Lower priority (rejected files that can be overridden)
      AppConstants.SECRETARY_REJECTED: 10,
      AppConstants.EDITOR_REJECTED: 11,

      // Completed (lowest priority)
      AppConstants.STAGE1_APPROVED: 20,
      AppConstants.FINAL_REJECTED: 21,
      AppConstants.WEBSITE_APPROVED: 22,
    };

    return priorityMap[status] ?? 999;
  }

  /// Get Stage 1 workflow statistics
  Future<Map<String, dynamic>> getStage1Statistics() async {
    try {
      final statistics = <String, dynamic>{};

      // Get counts for each Stage 1 status
      for (String status in AppConstants.stage1Statuses) {
        final count = await _getDocumentCountByStatus(status);
        statistics[status] = count;
      }

      // Calculate Stage 1 workflow efficiency metrics
      final totalDocuments =
          statistics.values.fold<int>(0, (sum, count) => count + sum);
      final approvedForStage2 = statistics[AppConstants.STAGE1_APPROVED] ?? 0;
      final finallyRejected = statistics[AppConstants.FINAL_REJECTED] ?? 0;
      final websiteApproved = statistics[AppConstants.WEBSITE_APPROVED] ?? 0;
      final completed = approvedForStage2 + finallyRejected + websiteApproved;
      final inProgress = totalDocuments - completed;

      // Calculate override statistics
      final secretaryRejected =
          statistics[AppConstants.SECRETARY_REJECTED] ?? 0;
      final editorRejected = statistics[AppConstants.EDITOR_REJECTED] ?? 0;
      final totalRejections = secretaryRejected + editorRejected;

      statistics['stage1_metrics'] = {
        'total': totalDocuments,
        'approved_for_stage2': approvedForStage2,
        'finally_rejected': finallyRejected,
        'website_approved': websiteApproved,
        'completed': completed,
        'in_progress': inProgress,
        'secretary_rejected': secretaryRejected,
        'editor_rejected': editorRejected,
        'total_rejections': totalRejections,
        'completion_rate':
            totalDocuments > 0 ? (completed / totalDocuments * 100).round() : 0,
        'approval_rate':
            completed > 0 ? (approvedForStage2 / completed * 100).round() : 0,
        'rejection_rate': totalDocuments > 0
            ? (totalRejections / totalDocuments * 100).round()
            : 0,
      };

      return statistics;
    } catch (e) {
      debugPrint('Error getting Stage 1 statistics: $e');
      return {};
    }
  }

  /// Get document count by status
  Future<int> _getDocumentCountByStatus(String status) async {
    try {
      final querySnapshot = await _firestore
          .collection('sent_documents')
          .where('status', isEqualTo: status)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting document count for status $status: $e');
      return 0;
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
        'stage': AppStyles.getStageNumber(newStatus),
        'actionLog': FieldValue.arrayUnion([
          {
            'action': 'تغيير حالة إداري',
            'userName': adminName,
            'userPosition': adminPosition,
            'performedById': adminId,
            'timestamp': Timestamp.now(),
            'comment':
                'تغيير الحالة إلى: ${AppStyles.getStatusDisplayName(newStatus)}. السبب: $comment',
            'isAdminOverride': true,
          }
        ]),
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': adminName,
        'adminOverride': true,
        'adminOverrideBy': adminName,
        'adminOverrideDate': FieldValue.serverTimestamp(),
      };

      // Add status-specific data
      updateData.addAll(_getStage1StatusSpecificData(
          newStatus, adminName, adminId, adminPosition));

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

  /// Get documents by multiple statuses (useful for filtering)
  Future<List<DocumentModel>> getDocumentsByStatuses(
      List<String> statuses) async {
    try {
      if (statuses.isEmpty) return [];

      // For multiple statuses, we need to use 'whereIn' or multiple queries
      if (statuses.length <= 10) {
        // Firestore limit for 'whereIn'
        final querySnapshot = await _firestore
            .collection('sent_documents')
            .where('status', whereIn: statuses)
            .orderBy('timestamp', descending: true)
            .get();

        return querySnapshot.docs
            .map((doc) => DocumentModel.fromFirestore(doc))
            .toList();
      } else {
        // For more than 10 statuses, use multiple queries
        List<DocumentModel> allDocuments = [];
        for (String status in statuses) {
          final docs = await getDocumentsByStatus(status);
          allDocuments.addAll(docs);
        }

        // Sort by timestamp
        allDocuments.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return allDocuments;
      }
    } catch (e) {
      debugPrint('Error getting documents by statuses: $e');
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

  /// Get documents ready for Stage 2 (approved in Stage 1)
  Future<List<DocumentModel>> getDocumentsReadyForStage2() async {
    try {
      final querySnapshot = await _firestore
          .collection('sent_documents')
          .where('status', isEqualTo: AppConstants.STAGE1_APPROVED)
          .orderBy('stage1CompletionDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting documents ready for Stage 2: $e');
      return [];
    }
  }

  /// Get Stage 1 workflow progress for a document
  Map<String, dynamic> getStage1Progress(DocumentModel document) {
    final steps = AppConstants.getStage1WorkflowSteps();
    int currentStepIndex = -1;

    for (int i = 0; i < steps.length; i++) {
      if (steps[i]['status'] == document.status) {
        currentStepIndex = i;
        break;
      }
    }

    // Handle final statuses that don't appear in the main workflow
    if (currentStepIndex == -1) {
      if (AppStyles.isStage1FinalStatus(document.status)) {
        currentStepIndex = steps.length; // Completed
      }
    }

    double progressPercentage =
        currentStepIndex >= 0 ? (currentStepIndex + 1) / steps.length : 0.0;

    return {
      'currentStepIndex': currentStepIndex,
      'totalSteps': steps.length,
      'progressPercentage': progressPercentage,
      'isCompleted': AppStyles.isStage1FinalStatus(document.status),
      'currentStep': currentStepIndex >= 0 && currentStepIndex < steps.length
          ? steps[currentStepIndex]
          : null,
    };
  }

  /// Get all documents with their Stage 1 decisions summary
  Future<Map<String, dynamic>> getStage1DecisionsSummary() async {
    try {
      final summaryData = <String, dynamic>{};

      // Secretary decisions
      final secretaryApproved =
          await _getDocumentCountByStatus(AppConstants.SECRETARY_APPROVED);
      final secretaryRejected =
          await _getDocumentCountByStatus(AppConstants.SECRETARY_REJECTED);
      final secretaryEditRequested = await _getDocumentCountByStatus(
          AppConstants.SECRETARY_EDIT_REQUESTED);

      summaryData['secretary_decisions'] = {
        'approved': secretaryApproved,
        'rejected': secretaryRejected,
        'edit_requested': secretaryEditRequested,
      };

      // Editor decisions
      final editorApproved =
          await _getDocumentCountByStatus(AppConstants.EDITOR_APPROVED);
      final editorRejected =
          await _getDocumentCountByStatus(AppConstants.EDITOR_REJECTED);
      final editorWebsiteRecommended = await _getDocumentCountByStatus(
          AppConstants.EDITOR_WEBSITE_RECOMMENDED);
      final editorEditRequested =
          await _getDocumentCountByStatus(AppConstants.EDITOR_EDIT_REQUESTED);

      summaryData['editor_decisions'] = {
        'approved': editorApproved,
        'rejected': editorRejected,
        'website_recommended': editorWebsiteRecommended,
        'edit_requested': editorEditRequested,
      };

      // Final decisions
      final stage1Approved =
          await _getDocumentCountByStatus(AppConstants.STAGE1_APPROVED);
      final finallyRejected =
          await _getDocumentCountByStatus(AppConstants.FINAL_REJECTED);
      final websiteApproved =
          await _getDocumentCountByStatus(AppConstants.WEBSITE_APPROVED);

      summaryData['final_decisions'] = {
        'approved_for_stage2': stage1Approved,
        'finally_rejected': finallyRejected,
        'website_approved': websiteApproved,
      };

      return summaryData;
    } catch (e) {
      debugPrint('Error getting Stage 1 decisions summary: $e');
      return {};
    }
  }

  /// Check if document can proceed to action based on previous decisions - Updated
  bool canProceedWithAction(
      DocumentModel document, String action, String userPosition) {
    // Basic permission checks
    switch (document.status) {
      case AppConstants.INCOMING:
        return userPosition == AppConstants.POSITION_SECRETARY;

      case AppConstants.SECRETARY_REVIEW:
        return userPosition == AppConstants.POSITION_SECRETARY;

      case AppConstants.SECRETARY_APPROVED:
      case AppConstants.SECRETARY_REJECTED: // Added this
      case AppConstants.SECRETARY_EDIT_REQUESTED:
        return userPosition == AppConstants.POSITION_MANAGING_EDITOR;

      case AppConstants.EDITOR_REVIEW:
        return userPosition == AppConstants.POSITION_MANAGING_EDITOR;

      case AppConstants.EDITOR_APPROVED:
      case AppConstants.EDITOR_REJECTED: // Added this
      case AppConstants.EDITOR_WEBSITE_RECOMMENDED:
      case AppConstants.EDITOR_EDIT_REQUESTED:
        return userPosition == AppConstants.POSITION_HEAD_EDITOR;

      case AppConstants.HEAD_REVIEW:
        return userPosition == AppConstants.POSITION_HEAD_EDITOR;

      default:
        // Already processed or invalid status
        return false;
    }
  }

  /// Get workflow stage name
  String getWorkflowStageName(String status) {
    if (AppConstants.stage1Statuses.contains(status)) {
      return 'المرحلة الأولى: الموافقة';
    }
    // Future stages will be added here
    return 'مرحلة غير معروفة';
  }

  /// Check if a document was rejected at any stage and can be overridden
  bool canBeOverridden(DocumentModel document, String userPosition) {
    switch (document.status) {
      case AppConstants.SECRETARY_REJECTED:
        // Managing editor can override secretary rejection
        return userPosition == AppConstants.POSITION_MANAGING_EDITOR;

      case AppConstants.EDITOR_REJECTED:
        // Head editor can override managing editor rejection
        return userPosition == AppConstants.POSITION_HEAD_EDITOR;

      default:
        return false;
    }
  }

  /// Get rejection reason from action log
  String? getRejectionReason(DocumentModel document) {
    // Find the most recent rejection action
    final rejectionActions = document.actionLog
        .where((action) => action.action.contains('رفض'))
        .toList();

    if (rejectionActions.isNotEmpty) {
      rejectionActions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return rejectionActions.first.comment;
    }

    return null;
  }

  /// Get potential overriders for a rejected document
  List<String> getPotentialOverriders(String status) {
    switch (status) {
      case AppConstants.SECRETARY_REJECTED:
        return [AppConstants.POSITION_MANAGING_EDITOR];

      case AppConstants.EDITOR_REJECTED:
        return [AppConstants.POSITION_HEAD_EDITOR];

      default:
        return [];
    }
  }
}

// Rest of the service classes remain the same...
// Permission service for Stage 1 workflow - Updated
class PermissionService {
  static bool canReviewIncomingFiles(String? position) {
    return position == AppConstants.POSITION_SECRETARY;
  }

  static bool canManageWorkflow(String? position) {
    return position == AppConstants.POSITION_MANAGING_EDITOR ||
        position == AppConstants.POSITION_HEAD_EDITOR;
  }

  static bool isEditorialSecretary(String? position) {
    return position == AppConstants.POSITION_SECRETARY;
  }

  static bool isManagingEditor(String? position) {
    return position == AppConstants.POSITION_MANAGING_EDITOR;
  }

  static bool isEditorInChief(String? position) {
    return position == AppConstants.POSITION_HEAD_EDITOR;
  }

  static bool isReviewer(String? position) {
    return position?.contains('محكم') == true;
  }

  static bool isLanguageEditor(String? position) {
    return position == AppConstants.POSITION_LANGUAGE_EDITOR;
  }

  static bool isLayoutDesigner(String? position) {
    return position == AppConstants.POSITION_LAYOUT_DESIGNER;
  }

  static bool isFinalReviewer(String? position) {
    return position == AppConstants.POSITION_FINAL_REVIEWER;
  }

  static bool isAuthor(String? position) {
    return position == AppConstants.POSITION_AUTHOR;
  }

  static bool canPerformAction(String status, String action, String? position) {
    final availableActions =
        AppConstants.getAvailableActions(status, position ?? '');
    return availableActions.any((actionMap) => actionMap['action'] == action);
  }

  static List<String> getAvailableActionsForUser(
      String status, String? position) {
    final actions = AppConstants.getAvailableActions(status, position ?? '');
    return actions.map<String>((action) => action['action'] as String).toList();
  }

  /// Check if user can override a rejection decision
  static bool canOverrideRejection(String status, String? position) {
    switch (status) {
      case AppConstants.SECRETARY_REJECTED:
        return position == AppConstants.POSITION_MANAGING_EDITOR;

      case AppConstants.EDITOR_REJECTED:
        return position == AppConstants.POSITION_HEAD_EDITOR;

      default:
        return false;
    }
  }

  /// Check if user has higher authority than the rejector
  static bool hasHigherAuthority(
      String rejectingPosition, String? userPosition) {
    const authorityLevels = {
      AppConstants.POSITION_SECRETARY: 1,
      AppConstants.POSITION_MANAGING_EDITOR: 2,
      AppConstants.POSITION_HEAD_EDITOR: 3,
    };

    final rejectingLevel = authorityLevels[rejectingPosition] ?? 0;
    final userLevel = authorityLevels[userPosition] ?? 0;

    return userLevel > rejectingLevel;
  }
}

// File handling service (unchanged from original)
class FileService {
  static const Map<String, String> supportedFileTypes =
      AppConstants.supportedFileTypes;

  static String getFileExtension(String url,
      {Map<String, dynamic>? documentData}) {
    try {
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

  static bool isFileTypeSupported(String extension) {
    return supportedFileTypes.containsKey(extension.toLowerCase());
  }

  static String? getMimeType(String extension) {
    return supportedFileTypes[extension.toLowerCase()];
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
