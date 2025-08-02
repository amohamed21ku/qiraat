// Services/Document_Services.dart - Fixed import conflicts and null safety issues
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../Constants/App_Constants.dart';
import '../models/document_model.dart';
// Use alias to avoid conflicts
import '../models/reviewerModel.dart' as ReviewerModelFile;

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add this method to Document_Services.dart to automatically transition statuses

  Future<void> submitReviewerReview(
    String documentId,
    String reviewerId,
    Map<String, dynamic> reviewData,
    String reviewerName,
  ) async {
    try {
      if (documentId.isEmpty || reviewerId.isEmpty) {
        throw Exception('Document ID and Reviewer ID cannot be empty');
      }

      final docSnapshot =
          await _firestore.collection('sent_documents').doc(documentId).get();

      if (!docSnapshot.exists) {
        throw Exception('Document not found');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      List<dynamic> reviewers = List.from(data['reviewers'] ?? []);

      if (reviewers.isEmpty) {
        throw Exception('No reviewers found for this document');
      }

      bool reviewerFound = false;
      bool allCompleted = true;

      for (int i = 0; i < reviewers.length; i++) {
        if (reviewers[i] is Map<String, dynamic>) {
          final reviewer = reviewers[i] as Map<String, dynamic>;

          if (reviewer['userId'] == reviewerId) {
            String safeName = reviewerName.isNotEmpty
                ? reviewerName
                : (reviewer['name']?.toString().isNotEmpty == true
                    ? reviewer['name']
                    : 'Unknown Reviewer');

            reviewers[i] = {
              ...reviewer,
              'name': safeName,
              'reviewStatus': AppConstants.REVIEWER_STATUS_COMPLETED,
              'rating': reviewData['rating'] ?? 0,
              'recommendation': reviewData['recommendation'] ?? '',
              'comment': reviewData['comment'] ?? '',
              'attachedFileUrl': reviewData['attachedFileUrl'],
              'attachedFileName': reviewData['attachedFileName'],
              'submittedDate': Timestamp.now(),
              'reviewData': reviewData,
            };
            reviewerFound = true;
          }

          if (reviewers[i]['reviewStatus'] !=
              AppConstants.REVIEWER_STATUS_COMPLETED) {
            allCompleted = false;
          }
        }
      }

      if (!reviewerFound) {
        throw Exception('Reviewer not found in document');
      }

      final actionLog = ActionLogModel(
        action: 'إرسال التحكيم النهائي',
        userName: reviewerName.isNotEmpty ? reviewerName : 'Unknown Reviewer',
        userPosition: 'محكم',
        performedById: reviewerId,
        timestamp: DateTime.now(),
        comment: reviewData['comment']?.toString() ?? '',
        attachedFileUrl: reviewData['attachedFileUrl']?.toString(),
        attachedFileName: reviewData['attachedFileName']?.toString(),
      );

      // FIXED: Proper status transition when all reviews are completed
      String documentStatus = data['status'];
      if (allCompleted) {
        // Automatically transition to HEAD_REVIEW_STAGE2 instead of just PEER_REVIEW_COMPLETED
        documentStatus = AppConstants.HEAD_REVIEW_STAGE2;
      }

      final updateData = <String, dynamic>{
        'reviewers': reviewers,
        'status': documentStatus,
        'actionLog': FieldValue.arrayUnion([actionLog.toMap()]),
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy':
            reviewerName.isNotEmpty ? reviewerName : 'Unknown Reviewer',
      };

      if (allCompleted) {
        updateData['allReviewsCompletedDate'] = FieldValue.serverTimestamp();
        updateData['headReviewStage2StartDate'] = FieldValue.serverTimestamp();
        updateData['currentStage'] = 'head_review_stage2';
        updateData['readyForHeadReview'] = true;

        // Add action log for automatic transition
        final transitionActionLog = ActionLogModel(
          action: 'انتهاء جميع المراجعات - انتقال تلقائي لمراجعة رئيس التحرير',
          userName: 'النظام',
          userPosition: 'تلقائي',
          performedById: 'system',
          timestamp: DateTime.now(),
          comment:
              'تم انتهاء جميع المحكمين من مراجعة المقال، انتقال تلقائي لمراجعة رئيس التحرير',
        );

        updateData['actionLog'] = FieldValue.arrayUnion(
            [actionLog.toMap(), transitionActionLog.toMap()]);
      }

      await _firestore
          .collection('sent_documents')
          .doc(documentId)
          .update(updateData);

      debugPrint('Review submitted by $reviewerId successfully');
      if (allCompleted) {
        debugPrint(
            'All reviews completed - transitioned to HEAD_REVIEW_STAGE2');
      }
    } catch (e) {
      debugPrint('Error submitting reviewer review: $e');
      rethrow;
    }
  }

// NEW: Method to handle Chef Editor review of language editing
  Future<void> submitChefEditorLanguageReview(
    String documentId,
    String chefEditorId,
    String chefEditorName,
    String decision, // 'approve' or 'reject'
    String comment,
  ) async {
    try {
      String nextStatus;
      String actionDescription;

      if (decision == 'approve') {
        nextStatus = AppConstants
            .HEAD_REVIEW_STAGE2; // Back to head editor for final decision
        actionDescription = 'الموافقة على التدقيق اللغوي';
      } else {
        nextStatus =
            AppConstants.LANGUAGE_EDITING_STAGE2; // Back to language editor
        actionDescription = 'إعادة للتدقيق اللغوي';
      }

      final actionLog = ActionLogModel(
        action: actionDescription,
        userName: chefEditorName,
        userPosition: AppConstants.POSITION_MANAGING_EDITOR,
        performedById: chefEditorId,
        timestamp: DateTime.now(),
        comment: comment,
      );

      final updateData = <String, dynamic>{
        'status': nextStatus,
        'chefReviewLanguageEditDecision': decision,
        'chefReviewLanguageEditDate': FieldValue.serverTimestamp(),
        'chefReviewLanguageEditBy': chefEditorName,
        'chefReviewLanguageEditById': chefEditorId,
        'chefReviewLanguageEditComment': comment,
        'actionLog': FieldValue.arrayUnion([actionLog.toMap()]),
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': chefEditorName,
      };

      if (decision == 'approve') {
        updateData['languageEditingApproved'] = true;
        updateData['readyForFinalDecision'] = true;
        updateData['currentStage'] = 'head_review_stage2_final';
      } else {
        updateData['languageEditingApproved'] = false;
        updateData['languageEditingRejectedReason'] = comment;
        updateData['currentStage'] = 'language_editing_revision';
      }

      await _firestore
          .collection('sent_documents')
          .doc(documentId)
          .update(updateData);

      debugPrint('Chef editor language review submitted: $decision');
    } catch (e) {
      debugPrint('Error submitting chef editor language review: $e');
      rethrow;
    }
  }

// Enhanced method to get documents for language editor with proper filtering
  Future<List<DocumentModel>> getDocumentsForLanguageEditor() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('sent_documents')
          .where('status', isEqualTo: AppConstants.LANGUAGE_EDITING_STAGE2)
          .orderBy('languageEditingAssignedDate',
              descending: false) // Oldest first (FIFO)
          .get();

      List<DocumentModel> documents =
          snapshot.docs.map((doc) => DocumentModel.fromFirestore(doc)).toList();

      debugPrint('Found ${documents.length} documents for language editor');
      return documents;
    } catch (e) {
      debugPrint('Error fetching language editor documents: $e');
      return [];
    }
  }

// Enhanced method to get documents for chef editor language review
  Future<List<DocumentModel>> getDocumentsForChefLanguageReview() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('sent_documents')
          .where('status', isEqualTo: AppConstants.CHEF_REVIEW_LANGUAGE_EDIT)
          .orderBy('languageEditingCompletedDate', descending: false)
          .get();

      List<DocumentModel> documents =
          snapshot.docs.map((doc) => DocumentModel.fromFirestore(doc)).toList();

      debugPrint(
          'Found ${documents.length} documents for chef language review');
      return documents;
    } catch (e) {
      debugPrint('Error fetching chef language review documents: $e');
      return [];
    }
  }

  /// Get all documents across all stages
  Future<List<Map<String, dynamic>>> getAllDocuments() async {
    try {
      final snapshot = await _firestore
          .collection('sent_documents')
          .orderBy('timestamp', descending: true)
          .get();

      final documents = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'بدون عنوان',
          'type': data['documentType'] ?? 'غير معروف',
          'date': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp)
                  .toDate()
                  .toString()
                  .split(' ')[0]
              : 'لا يوجد تاريخ',
          'url': data['documentUrl'],
          'status': data['status'],
        };
      }).toList();

      return documents;
    } catch (e) {
      debugPrint('Error fetching all documents: $e');
      return [];
    }
  }

  // ==================== STAGE 1 METHODS ====================

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
      return Stream.value([]);
    }
  }

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

  // ==================== STAGE 2 METHODS ====================

  // NEW: Get documents for Language Editor
  // Future<List<DocumentModel>> getDocumentsForLanguageEditor() async {
  //   try {
  //     QuerySnapshot snapshot = await _firestore
  //         .collection('sent_documents')
  //         .where('status', isEqualTo: AppConstants.LANGUAGE_EDITING_STAGE2)
  //         .orderBy('languageEditingAssignedDate',
  //             descending: false) // Oldest first
  //         .get();
  //
  //     return snapshot.docs
  //         .map((doc) => DocumentModel.fromFirestore(doc))
  //         .toList();
  //   } catch (e) {
  //     debugPrint('Error fetching language editor documents: $e');
  //     return [];
  //   }
  // }

  Future<void> submitLanguageEditorReview(
    String documentId,
    String languageEditorId,
    String languageEditorName,
    Map<String, dynamic> reviewData,
  ) async {
    try {
      final actionLog = ActionLogModel(
        action: 'إنهاء التدقيق اللغوي',
        userName: languageEditorName,
        userPosition: AppConstants.POSITION_LANGUAGE_EDITOR,
        performedById: languageEditorId,
        timestamp: DateTime.now(),
        comment: reviewData['comment'] ?? '',
        attachedFileUrl: reviewData['attachedFileUrl'],
        attachedFileName: reviewData['attachedFileName'],
      );

      await _firestore.collection('sent_documents').doc(documentId).update({
        'status': AppConstants.LANGUAGE_EDITOR_COMPLETED,
        'languageEditingCompletedDate': FieldValue.serverTimestamp(),
        'languageEditingCompletedBy': languageEditorName,
        'languageEditingCompletedById': languageEditorId,
        'languageEditingData': {
          'comment': reviewData['comment'],
          'attachedFileUrl': reviewData['attachedFileUrl'],
          'attachedFileName': reviewData['attachedFileName'],
          'corrections': reviewData['corrections'] ?? '',
          'suggestions': reviewData['suggestions'] ?? '',
          'completedDate': Timestamp.now(),
        },
        'actionLog': FieldValue.arrayUnion([actionLog.toMap()]),
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': languageEditorName,
      });

      debugPrint('Language editor review submitted successfully');
    } catch (e) {
      debugPrint('Error submitting language editor review: $e');
      rethrow;
    }
  }

  Stream<List<DocumentModel>> getStage2DocumentsStream() {
    try {
      return _firestore
          .collection('sent_documents')
          .where('status', whereIn: AppConstants.stage2Statuses)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => DocumentModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      debugPrint('Error creating Stage 2 documents stream: $e');
      return Stream.value([]);
    }
  }

  Future<List<DocumentModel>> getAllStage2Documents() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('sent_documents')
          .where('status', whereIn: AppConstants.stage2Statuses)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching Stage 2 documents: $e');
      throw e;
    }
  }

  Future<List<DocumentModel>> getDocumentsReadyForStage2() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('sent_documents')
          .where('status', isEqualTo: AppConstants.STAGE1_APPROVED)
          .orderBy('stage1CompletionDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting documents ready for Stage 2: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableReviewers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      List<Map<String, dynamic>> reviewers = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        String name =
            (data['name']?.toString() ?? data['fullName']?.toString() ?? '')
                .trim();
        String email = (data['email']?.toString() ?? '').trim();
        String position = (data['position']?.toString() ?? '').trim();

        if (name.isEmpty || email.isEmpty) {
          debugPrint('Skipping user with missing data: ${doc.id}');
          continue;
        }

        bool isReviewer = position.contains('محكم') ||
            position.contains('reviewer') ||
            position.contains('Reviewer') ||
            position == AppConstants.POSITION_REVIEWER ||
            position == AppConstants.REVIEWER_POLITICAL ||
            position == AppConstants.REVIEWER_ECONOMIC ||
            position == AppConstants.REVIEWER_SOCIAL ||
            position == AppConstants.REVIEWER_GENERAL;

        if (isReviewer) {
          String specialization = 'عام';
          if (position.contains('سياسي') || position.contains('Political')) {
            specialization = 'سياسي';
          } else if (position.contains('اقتصادي') ||
              position.contains('Economic')) {
            specialization = 'اقتصادي';
          } else if (position.contains('اجتماعي') ||
              position.contains('Social')) {
            specialization = 'اجتماعي';
          }

          reviewers.add({
            'id': doc.id,
            'userId':
                data['uid']?.toString() ?? data['id']?.toString() ?? doc.id,
            'name': name,
            'email': email,
            'position': position,
            'specialization':
                data['specialization']?.toString() ?? specialization,
            'isActive': data['isActive'] ?? true,
          });
        }
      }

      debugPrint('Found ${reviewers.length} available reviewers');
      return reviewers;
    } catch (e) {
      debugPrint('Error fetching available reviewers: $e');
      return [];
    }
  }

  Future<void> assignReviewersToDocument(
    String documentId,
    List<Map<String, dynamic>> selectedReviewers,
    String assignedBy,
    String assignedByName,
    String assignedByPosition,
  ) async {
    try {
      final validatedReviewers = selectedReviewers.where((reviewer) {
        return reviewer['name'] != null &&
            reviewer['name'].toString().trim().isNotEmpty &&
            reviewer['email'] != null &&
            reviewer['position'] != null;
      }).toList();

      if (validatedReviewers.isEmpty) {
        throw Exception('No valid reviewers found in selection');
      }

      // Use the alias to create ReviewerModel instances
      final reviewers = validatedReviewers.map((reviewer) {
        return ReviewerModelFile.ReviewerModel(
          userId: reviewer['userId']?.toString() ??
              reviewer['id']?.toString() ??
              '',
          name: reviewer['name'].toString().trim(),
          email: reviewer['email'].toString().trim(),
          position: reviewer['position'].toString().trim(),
          reviewStatus: AppConstants.REVIEWER_STATUS_PENDING,
          assignedDate: DateTime.now(),
        );
      }).toList();

      final actionLog = ActionLogModel(
        action: 'تعيين المحكمين',
        userName: assignedByName,
        userPosition: assignedByPosition,
        performedById: assignedBy,
        timestamp: DateTime.now(),
        comment: 'تم تعيين ${reviewers.length} محكمين للمقال',
      );

      await _firestore.collection('sent_documents').doc(documentId).update({
        'reviewers': reviewers.map((r) => r.toMap()).toList(),
        'status': AppConstants.REVIEWERS_ASSIGNED,
        'stage': 2,
        'reviewersAssignedDate': FieldValue.serverTimestamp(),
        'reviewersAssignedBy': assignedByName,
        'reviewersAssignedById': assignedBy,
        'actionLog': FieldValue.arrayUnion([actionLog.toMap()]),
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': assignedByName,
        'lastUpdatedById': assignedBy,
      });

      debugPrint(
          '${reviewers.length} valid reviewers assigned to document $documentId successfully');
    } catch (e) {
      debugPrint('Error assigning reviewers: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getReviewerStatistics(String reviewerId) async {
    try {
      if (reviewerId.isEmpty) {
        return _getEmptyStatistics();
      }

      final snapshot = await _firestore
          .collection('sent_documents')
          .where('reviewers', arrayContains: {'userId': reviewerId}).get();

      int totalAssigned = 0;
      int completed = 0;
      int pending = 0;
      int inProgress = 0;
      List<int> ratings = [];
      int totalDays = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final reviewers = List<dynamic>.from(data['reviewers'] ?? []);

        for (final reviewerData in reviewers) {
          if (reviewerData is Map<String, dynamic> &&
              reviewerData['userId'] == reviewerId) {
            totalAssigned++;
            final status = reviewerData['reviewStatus']?.toString() ?? '';

            switch (status) {
              case AppConstants.REVIEWER_STATUS_COMPLETED:
                completed++;
                if (reviewerData['rating'] != null) {
                  try {
                    ratings.add(int.parse(reviewerData['rating'].toString()));
                  } catch (e) {
                    debugPrint(
                        'Invalid rating value: ${reviewerData['rating']}');
                  }
                }
                if (reviewerData['assignedDate'] != null &&
                    reviewerData['submittedDate'] != null) {
                  try {
                    final assignedDate =
                        (reviewerData['assignedDate'] as Timestamp).toDate();
                    final submittedDate =
                        (reviewerData['submittedDate'] as Timestamp).toDate();
                    totalDays += submittedDate.difference(assignedDate).inDays;
                  } catch (e) {
                    debugPrint('Error calculating review days: $e');
                  }
                }
                break;
              case AppConstants.REVIEWER_STATUS_IN_PROGRESS:
                inProgress++;
                break;
              case AppConstants.REVIEWER_STATUS_PENDING:
                pending++;
                break;
            }
            break;
          }
        }
      }

      final averageRating = ratings.isNotEmpty
          ? ratings.reduce((a, b) => a + b) / ratings.length
          : 0.0;
      final averageDays = completed > 0 ? totalDays / completed : 0;

      return {
        'total_assigned': totalAssigned,
        'completed': completed,
        'pending': pending,
        'in_progress': inProgress,
        'completion_rate':
            totalAssigned > 0 ? (completed / totalAssigned * 100).round() : 0,
        'average_rating': averageRating.toStringAsFixed(1),
        'average_review_days': averageDays.round(),
      };
    } catch (e) {
      debugPrint('Error getting reviewer statistics: $e');
      return _getEmptyStatistics();
    }
  }

  Map<String, dynamic> _getEmptyStatistics() {
    return {
      'total_assigned': 0,
      'completed': 0,
      'pending': 0,
      'in_progress': 0,
      'completion_rate': 0,
      'average_rating': '0.0',
      'average_review_days': 0,
    };
  }

  // Future<void> submitReviewerReview(
  //   String documentId,
  //   String reviewerId,
  //   Map<String, dynamic> reviewData,
  //   String reviewerName,
  // ) async {
  //   try {
  //     if (documentId.isEmpty || reviewerId.isEmpty) {
  //       throw Exception('Document ID and Reviewer ID cannot be empty');
  //     }
  //
  //     final docSnapshot =
  //         await _firestore.collection('sent_documents').doc(documentId).get();
  //
  //     if (!docSnapshot.exists) {
  //       throw Exception('Document not found');
  //     }
  //
  //     final data = docSnapshot.data() as Map<String, dynamic>;
  //     List<dynamic> reviewers = List.from(data['reviewers'] ?? []);
  //
  //     if (reviewers.isEmpty) {
  //       throw Exception('No reviewers found for this document');
  //     }
  //
  //     bool reviewerFound = false;
  //     bool allCompleted = true;
  //
  //     for (int i = 0; i < reviewers.length; i++) {
  //       if (reviewers[i] is Map<String, dynamic>) {
  //         final reviewer = reviewers[i] as Map<String, dynamic>;
  //
  //         if (reviewer['userId'] == reviewerId) {
  //           String safeName = reviewerName.isNotEmpty
  //               ? reviewerName
  //               : (reviewer['name']?.toString().isNotEmpty == true
  //                   ? reviewer['name']
  //                   : 'Unknown Reviewer');
  //
  //           reviewers[i] = {
  //             ...reviewer,
  //             'name': safeName,
  //             'reviewStatus': AppConstants.REVIEWER_STATUS_COMPLETED,
  //             'rating': reviewData['rating'] ?? 0,
  //             'recommendation': reviewData['recommendation'] ?? '',
  //             'comment': reviewData['comment'] ?? '',
  //             'attachedFileUrl': reviewData['attachedFileUrl'],
  //             'attachedFileName': reviewData['attachedFileName'],
  //             'submittedDate': Timestamp.now(),
  //             'reviewData': reviewData,
  //           };
  //           reviewerFound = true;
  //         }
  //
  //         if (reviewers[i]['reviewStatus'] !=
  //             AppConstants.REVIEWER_STATUS_COMPLETED) {
  //           allCompleted = false;
  //         }
  //       }
  //     }
  //
  //     if (!reviewerFound) {
  //       throw Exception('Reviewer not found in document');
  //     }
  //
  //     final actionLog = ActionLogModel(
  //       action: 'إرسال التحكيم النهائي',
  //       userName: reviewerName.isNotEmpty ? reviewerName : 'Unknown Reviewer',
  //       userPosition: 'محكم',
  //       performedById: reviewerId,
  //       timestamp: DateTime.now(),
  //       comment: reviewData['comment']?.toString() ?? '',
  //       attachedFileUrl: reviewData['attachedFileUrl']?.toString(),
  //       attachedFileName: reviewData['attachedFileName']?.toString(),
  //     );
  //
  //     String documentStatus = data['status'];
  //     if (allCompleted) {
  //       documentStatus = AppConstants.PEER_REVIEW_COMPLETED;
  //     }
  //
  //     final updateData = <String, dynamic>{
  //       'reviewers': reviewers,
  //       'status': documentStatus,
  //       'actionLog': FieldValue.arrayUnion([actionLog.toMap()]),
  //       'lastUpdated': FieldValue.serverTimestamp(),
  //       'lastUpdatedBy':
  //           reviewerName.isNotEmpty ? reviewerName : 'Unknown Reviewer',
  //     };
  //
  //     if (allCompleted) {
  //       updateData['allReviewsCompletedDate'] = FieldValue.serverTimestamp();
  //     }
  //
  //     await _firestore
  //         .collection('sent_documents')
  //         .doc(documentId)
  //         .update(updateData);
  //
  //     debugPrint('Review submitted by $reviewerId successfully');
  //   } catch (e) {
  //     debugPrint('Error submitting reviewer review: $e');
  //     rethrow;
  //   }
  // }

  Future<void> savereviewDraft(
    String documentId,
    String reviewerId,
    Map<String, dynamic> draftData,
  ) async {
    try {
      await _firestore
          .collection('reviewer_drafts')
          .doc('${documentId}_$reviewerId')
          .set({
        'documentId': documentId,
        'reviewerId': reviewerId,
        'draftData': draftData,
        'lastSaved': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Review draft saved for reviewer $reviewerId');
    } catch (e) {
      debugPrint('Error saving review draft: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getReviewDraft(
    String documentId,
    String reviewerId,
  ) async {
    try {
      final docSnapshot = await _firestore
          .collection('reviewer_drafts')
          .doc('${documentId}_$reviewerId')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return data['draftData'];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting review draft: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getStage2Statistics() async {
    try {
      final statistics = <String, dynamic>{};

      for (String status in AppConstants.stage2Statuses) {
        final count = await _getDocumentCountByStatus(status);
        statistics[status] = count;
      }

      final totalDocuments =
          statistics.values.fold<int>(0, (sum, count) => count + sum);
      final readyForReview = statistics[AppConstants.STAGE1_APPROVED] ?? 0;
      final underReview = statistics[AppConstants.UNDER_PEER_REVIEW] ?? 0;
      final reviewCompleted =
          statistics[AppConstants.PEER_REVIEW_COMPLETED] ?? 0;
      final approved = statistics[AppConstants.STAGE2_APPROVED] ?? 0;
      final rejected = statistics[AppConstants.STAGE2_REJECTED] ?? 0;
      final editRequested = statistics[AppConstants.STAGE2_EDIT_REQUESTED] ?? 0;
      final websiteApproved =
          statistics[AppConstants.STAGE2_WEBSITE_APPROVED] ?? 0;

      final completed = approved + rejected + editRequested + websiteApproved;
      final inProgress = totalDocuments - completed;

      statistics['stage2_metrics'] = {
        'total': totalDocuments,
        'ready_for_review': readyForReview,
        'under_review': underReview,
        'review_completed': reviewCompleted,
        'approved': approved,
        'rejected': rejected,
        'edit_requested': editRequested,
        'website_approved': websiteApproved,
        'completed': completed,
        'in_progress': inProgress,
        'completion_rate':
            totalDocuments > 0 ? (completed / totalDocuments * 100).round() : 0,
        'approval_rate':
            completed > 0 ? (approved / completed * 100).round() : 0,
      };

      return statistics;
    } catch (e) {
      debugPrint('Error getting Stage 2 statistics: $e');
      return {};
    }
  }

  Future<void> updateReviewerStatusSecure(
    String documentId,
    String reviewerId,
    String newStatus,
    String? comment,
    String reviewerName,
  ) async {
    try {
      final docSnapshot =
          await _firestore.collection('sent_documents').doc(documentId).get();

      if (!docSnapshot.exists) {
        throw Exception('Document not found');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      List<dynamic> reviewers = List.from(data['reviewers'] ?? []);

      bool reviewerFound = false;
      for (int i = 0; i < reviewers.length; i++) {
        if (reviewers[i] is Map<String, dynamic>) {
          final reviewer = reviewers[i] as Map<String, dynamic>;

          if (reviewer['userId'] == reviewerId) {
            String storedName = reviewer['name']?.toString() ?? '';
            if (storedName != reviewerName) {
              throw Exception('Reviewer name mismatch - security violation');
            }

            reviewers[i] = {
              ...reviewer,
              'reviewStatus': newStatus,
              'comment': comment ?? '',
              'reviewedDate': Timestamp.now(),
            };
            reviewerFound = true;
            break;
          }
        }
      }

      if (!reviewerFound) {
        throw Exception('Reviewer not authorized for this document');
      }

      bool allCompleted = true;
      for (var reviewer in reviewers) {
        if (reviewer['reviewStatus'] !=
            AppConstants.REVIEWER_STATUS_COMPLETED) {
          allCompleted = false;
          break;
        }
      }

      final actionLog = ActionLogModel(
        action: _getReviewerActionDescription(newStatus),
        userName: reviewerName,
        userPosition: 'محكم',
        performedById: reviewerId,
        timestamp: DateTime.now(),
        comment: comment,
      );

      final updateData = <String, dynamic>{
        'reviewers': reviewers,
        'actionLog': FieldValue.arrayUnion([actionLog.toMap()]),
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': reviewerName,
      };

      if (allCompleted && newStatus == AppConstants.REVIEWER_STATUS_COMPLETED) {
        updateData['status'] = AppConstants.PEER_REVIEW_COMPLETED;
        updateData['allReviewsCompletedDate'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('sent_documents')
          .doc(documentId)
          .update(updateData);

      debugPrint('Reviewer $reviewerId status updated securely to: $newStatus');
    } catch (e) {
      debugPrint('Error updating reviewer status securely: $e');
      rethrow;
    }
  }

// Enhanced Document Service methods - Add these to your Document_Services.dart

// Update the submitReviewerReview method to handle detailed review data
  Future<void> submitReviewerReviewDetailed(
    String documentId,
    String reviewerId,
    Map<String, dynamic> reviewData,
    String reviewerName,
  ) async {
    try {
      if (documentId.isEmpty || reviewerId.isEmpty) {
        throw Exception('Document ID and Reviewer ID cannot be empty');
      }

      // Validate detailed review data
      if (!_validateDetailedReviewData(reviewData)) {
        throw Exception('Invalid or incomplete review data provided');
      }

      final docSnapshot =
          await _firestore.collection('sent_documents').doc(documentId).get();

      if (!docSnapshot.exists) {
        throw Exception('Document not found');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      List<dynamic> reviewers = List.from(data['reviewers'] ?? []);

      if (reviewers.isEmpty) {
        throw Exception('No reviewers found for this document');
      }

      bool reviewerFound = false;
      bool allCompleted = true;

      for (int i = 0; i < reviewers.length; i++) {
        if (reviewers[i] is Map<String, dynamic>) {
          final reviewer = reviewers[i] as Map<String, dynamic>;

          if (reviewer['userId'] == reviewerId) {
            String safeName = reviewerName.isNotEmpty
                ? reviewerName
                : (reviewer['name']?.toString().isNotEmpty == true
                    ? reviewer['name']
                    : 'Unknown Reviewer');

            // Enhanced reviewer data with detailed review information
            reviewers[i] = {
              ...reviewer,
              'name': safeName,
              'reviewStatus': AppConstants.REVIEWER_STATUS_COMPLETED,

              // Core review data
              'rating': reviewData['rating'] ?? 0,
              'recommendation': reviewData['recommendation'] ?? '',
              'comment': reviewData['comment'] ?? '',

              // Detailed review fields
              'strengths': reviewData['strengths'] ?? '',
              'weaknesses': reviewData['weaknesses'] ?? '',
              'recommendations': reviewData['recommendations'] ?? '',
              'methodology_assessment':
                  reviewData['methodology_assessment'] ?? '',
              'originality_score': reviewData['originality_score'] ?? 0,
              'clarity_score': reviewData['clarity_score'] ?? 0,
              'significance_score': reviewData['significance_score'] ?? 0,

              // File attachments
              'attachedFileUrl': reviewData['attachedFileUrl'],
              'attachedFileName': reviewData['attachedFileName'],

              // Timestamps
              'submittedDate': Timestamp.now(),
              'reviewData': reviewData,

              // Review completion metadata
              'reviewDurationDays':
                  _calculateReviewDuration(reviewer['assignedDate']),
              'lastModified': Timestamp.now(),
            };
            reviewerFound = true;
          }

          if (reviewers[i]['reviewStatus'] !=
              AppConstants.REVIEWER_STATUS_COMPLETED) {
            allCompleted = false;
          }
        }
      }

      if (!reviewerFound) {
        throw Exception('Reviewer not found in document');
      }

      // Create detailed action log entry
      final actionLog = ActionLogModel(
        action: 'إرسال التحكيم المفصل',
        userName: reviewerName.isNotEmpty ? reviewerName : 'Unknown Reviewer',
        userPosition: 'محكم',
        performedById: reviewerId,
        timestamp: DateTime.now(),
        comment: _buildDetailedReviewSummary(reviewData),
        attachedFileUrl: reviewData['attachedFileUrl']?.toString(),
        attachedFileName: reviewData['attachedFileName']?.toString(),
      );

      String documentStatus = data['status'];
      if (allCompleted) {
        documentStatus = AppConstants.PEER_REVIEW_COMPLETED;
      }

      final updateData = <String, dynamic>{
        'reviewers': reviewers,
        'status': documentStatus,
        'actionLog': FieldValue.arrayUnion([actionLog.toMap()]),
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy':
            reviewerName.isNotEmpty ? reviewerName : 'Unknown Reviewer',

        // Add review completion statistics
        'reviewStatistics': _calculateReviewStatistics(reviewers),
      };

      if (allCompleted) {
        updateData['allReviewsCompletedDate'] = FieldValue.serverTimestamp();
        updateData['reviewSummary'] = _generateReviewSummary(reviewers);
      }

      await _firestore
          .collection('sent_documents')
          .doc(documentId)
          .update(updateData);

      debugPrint('Detailed review submitted by $reviewerId successfully');
    } catch (e) {
      debugPrint('Error submitting detailed reviewer review: $e');
      rethrow;
    }
  }

// Validate detailed review data
  bool _validateDetailedReviewData(Map<String, dynamic> reviewData) {
    final requiredFields = [
      'rating',
      'recommendation',
      'comment',
      'strengths',
      'weaknesses',
      'recommendations'
    ];

    for (String field in requiredFields) {
      if (!reviewData.containsKey(field) ||
          reviewData[field] == null ||
          reviewData[field].toString().trim().isEmpty) {
        debugPrint('Missing or empty required field: $field');
        return false;
      }
    }

    final rating = reviewData['rating'];
    if (rating is! num || rating < 1.0 || rating > 5.0) {
      debugPrint('Invalid rating value: $rating');
      return false;
    }

    final validRecommendations = [
      'accept',
      'minor_revision',
      'major_revision',
      'reject'
    ];
    if (!validRecommendations.contains(reviewData['recommendation'])) {
      debugPrint('Invalid recommendation: ${reviewData['recommendation']}');
      return false;
    }

    return true;
  }

// Calculate review duration
  int _calculateReviewDuration(dynamic assignedDate) {
    if (assignedDate == null) return 0;

    DateTime assigned;
    if (assignedDate is Timestamp) {
      assigned = assignedDate.toDate();
    } else if (assignedDate is DateTime) {
      assigned = assignedDate;
    } else {
      return 0;
    }

    return DateTime.now().difference(assigned).inDays;
  }

// Build detailed review summary for action log
  String _buildDetailedReviewSummary(Map<String, dynamic> reviewData) {
    final rating = reviewData['rating'] ?? 0;
    final recommendation = reviewData['recommendation'] ?? '';
    final comment = reviewData['comment'] ?? '';

    String summary = 'التقييم: $rating/5 نجوم\n';
    summary += 'التوصية: ${_getRecommendationTextArabic(recommendation)}\n';

    if (comment.length > 100) {
      summary += 'التعليق: ${comment.substring(0, 100)}...\n';
    } else {
      summary += 'التعليق: $comment\n';
    }

    return summary;
  }

// Get Arabic recommendation text
  String _getRecommendationTextArabic(String recommendation) {
    switch (recommendation) {
      case 'accept':
        return 'قبول للنشر';
      case 'minor_revision':
        return 'تعديلات طفيفة';
      case 'major_revision':
        return 'تعديلات كبيرة';
      case 'reject':
        return 'رفض النشر';
      default:
        return 'غير محدد';
    }
  }

// Calculate review statistics
  Map<String, dynamic> _calculateReviewStatistics(List<dynamic> reviewers) {
    final completedReviews = reviewers
        .where(
            (r) => r['reviewStatus'] == AppConstants.REVIEWER_STATUS_COMPLETED)
        .toList();

    if (completedReviews.isEmpty) {
      return {
        'total_reviewers': reviewers.length,
        'completed_reviews': 0,
        'average_rating': 0.0,
        'recommendation_distribution': {},
        'completion_rate': 0.0,
      };
    }

    // Calculate average rating
    final ratings = completedReviews
        .where((r) => r['rating'] != null && r['rating'] > 0)
        .map((r) => (r['rating'] as num).toDouble())
        .toList();

    final averageRating = ratings.isNotEmpty
        ? ratings.reduce((a, b) => a + b) / ratings.length
        : 0.0;

    // Calculate recommendation distribution
    final recommendations = <String, int>{
      'accept': 0,
      'minor_revision': 0,
      'major_revision': 0,
      'reject': 0,
    };

    for (var review in completedReviews) {
      final rec = review['recommendation']?.toString() ?? '';
      if (recommendations.containsKey(rec)) {
        recommendations[rec] = recommendations[rec]! + 1;
      }
    }

    return {
      'total_reviewers': reviewers.length,
      'completed_reviews': completedReviews.length,
      'average_rating': averageRating,
      'recommendation_distribution': recommendations,
      'completion_rate': completedReviews.length / reviewers.length,
      'last_updated': Timestamp.now(),
    };
  }

// Generate comprehensive review summary
  Map<String, dynamic> _generateReviewSummary(List<dynamic> reviewers) {
    final completedReviews = reviewers
        .where(
            (r) => r['reviewStatus'] == AppConstants.REVIEWER_STATUS_COMPLETED)
        .toList();

    final statistics = _calculateReviewStatistics(reviewers);

    // Collect common themes
    final strengths = <String>[];
    final weaknesses = <String>[];
    final recommendations = <String>[];

    for (var review in completedReviews) {
      if (review['strengths'] != null &&
          review['strengths'].toString().isNotEmpty) {
        strengths.add(review['strengths'].toString());
      }
      if (review['weaknesses'] != null &&
          review['weaknesses'].toString().isNotEmpty) {
        weaknesses.add(review['weaknesses'].toString());
      }
      if (review['recommendations'] != null &&
          review['recommendations'].toString().isNotEmpty) {
        recommendations.add(review['recommendations'].toString());
      }
    }

    // Generate overall recommendation
    final recDistribution =
        statistics['recommendation_distribution'] as Map<String, int>;
    final totalRecs = recDistribution.values.reduce((a, b) => a + b);
    String overallRecommendation = 'آراء متباينة';

    if (totalRecs > 0) {
      final acceptPercentage = (recDistribution['accept']! / totalRecs * 100);
      final rejectPercentage = (recDistribution['reject']! / totalRecs * 100);

      if (acceptPercentage >= 60) {
        overallRecommendation = 'موصى بالقبول للنشر';
      } else if (rejectPercentage >= 50) {
        overallRecommendation = 'موصى بالرفض';
      } else if (recDistribution['major_revision']! >= (totalRecs / 2)) {
        overallRecommendation = 'يحتاج تعديلات كبيرة';
      } else {
        overallRecommendation = 'يحتاج مراجعة دقيقة - آراء متباينة';
      }
    }

    return {
      'statistics': statistics,
      'overall_recommendation': overallRecommendation,
      'common_strengths': strengths,
      'common_weaknesses': weaknesses,
      'improvement_recommendations': recommendations,
      'generated_at': Timestamp.now(),
      'summary_ready': true,
    };
  }

// Get detailed review analytics for head editor
  Future<Map<String, dynamic>> getDetailedReviewAnalytics(
      String documentId) async {
    try {
      final docSnapshot =
          await _firestore.collection('sent_documents').doc(documentId).get();

      if (!docSnapshot.exists) {
        throw Exception('Document not found');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      final reviewers = List<dynamic>.from(data['reviewers'] ?? []);

      final completedReviews = reviewers
          .where((r) =>
              r['reviewStatus'] == AppConstants.REVIEWER_STATUS_COMPLETED)
          .toList();

      if (completedReviews.isEmpty) {
        return {
          'status': 'no_reviews',
          'message': 'لا توجد مراجعات مكتملة',
        };
      }

      // Get stored statistics or calculate them
      Map<String, dynamic> analytics =
          data['reviewStatistics'] ?? _calculateReviewStatistics(reviewers);

      // Add additional analytics
      analytics['detailed_reviews'] = completedReviews
          .map((review) => {
                'reviewer_name': review['name'],
                'reviewer_position': review['position'],
                'rating': review['rating'],
                'recommendation': review['recommendation'],
                'submission_date': review['submittedDate'],
                'review_duration': review['reviewDurationDays'],
                'has_attachments': review['attachedFileUrl'] != null,
              })
          .toList();

      analytics['review_quality_metrics'] =
          _calculateQualityMetrics(completedReviews);

      return {
        'status': 'success',
        'analytics': analytics,
        'summary': data['reviewSummary'],
      };
    } catch (e) {
      debugPrint('Error getting detailed review analytics: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

// Calculate review quality metrics
  Map<String, dynamic> _calculateQualityMetrics(List<dynamic> reviews) {
    if (reviews.isEmpty) return {};

    int totalWords = 0;
    int reviewsWithAttachments = 0;
    List<int> durations = [];

    for (var review in reviews) {
      // Count words in comments, strengths, weaknesses, and recommendations
      final comment = review['comment']?.toString() ?? '';
      final strengths = review['strengths']?.toString() ?? '';
      final weaknesses = review['weaknesses']?.toString() ?? '';
      final recommendations = review['recommendations']?.toString() ?? '';

      totalWords += comment.split(' ').length;
      totalWords += strengths.split(' ').length;
      totalWords += weaknesses.split(' ').length;
      totalWords += recommendations.split(' ').length;

      if (review['attachedFileUrl'] != null) {
        reviewsWithAttachments++;
      }

      if (review['reviewDurationDays'] != null) {
        durations.add(review['reviewDurationDays'] as int);
      }
    }

    final averageWords = totalWords / reviews.length;
    final attachmentRate = reviewsWithAttachments / reviews.length * 100;
    final averageDuration = durations.isNotEmpty
        ? durations.reduce((a, b) => a + b) / durations.length
        : 0.0;

    return {
      'average_words_per_review': averageWords.round(),
      'attachment_rate': attachmentRate.round(),
      'average_review_duration_days': averageDuration.round(),
      'quality_score': _calculateOverallQualityScore(
          averageWords, attachmentRate, averageDuration),
    };
  }

// Calculate overall quality score
  double _calculateOverallQualityScore(
      double avgWords, double attachmentRate, double avgDuration) {
    double score = 0.0;

    // Word count scoring (max 40 points)
    if (avgWords >= 200)
      score += 40;
    else if (avgWords >= 100)
      score += 30;
    else if (avgWords >= 50)
      score += 20;
    else
      score += 10;

    // Attachment rate scoring (max 30 points)
    score += (attachmentRate * 0.3);

    // Duration scoring (max 30 points) - optimal is 7-14 days
    if (avgDuration >= 7 && avgDuration <= 14)
      score += 30;
    else if (avgDuration >= 5 && avgDuration <= 21)
      score += 20;
    else if (avgDuration >= 3 && avgDuration <= 30)
      score += 10;
    else
      score += 5;

    return score.clamp(0.0, 100.0);
  }

  Future<List<DocumentModel>> getDocumentsForReviewer(String reviewerId) async {
    try {
      final snapshot = await _firestore
          .collection('sent_documents')
          .where('status', whereIn: [
        AppConstants.REVIEWERS_ASSIGNED,
        AppConstants.UNDER_PEER_REVIEW,
        AppConstants.PEER_REVIEW_COMPLETED,
      ]).get();

      List<DocumentModel> assignedDocuments = [];

      for (final doc in snapshot.docs) {
        final docModel = DocumentModel.fromFirestore(doc);

        final isAssignedReviewer = docModel.reviewers.any(
          (reviewer) => reviewer.userId == reviewerId,
        );

        if (isAssignedReviewer) {
          final sanitizedDoc =
              _sanitizeDocumentForReviewer(docModel, reviewerId);
          assignedDocuments.add(sanitizedDoc);
        }
      }

      assignedDocuments.sort((a, b) {
        final aReviewer = a.reviewers.firstWhere(
          (reviewer) => reviewer.userId == reviewerId,
          orElse: () => ReviewerModelFile.ReviewerModel(
            userId: '',
            name: '',
            email: '',
            position: '',
            reviewStatus: AppConstants.REVIEWER_STATUS_PENDING,
            assignedDate: DateTime.now(),
          ),
        );

        final bReviewer = b.reviewers.firstWhere(
          (reviewer) => reviewer.userId == reviewerId,
          orElse: () => ReviewerModelFile.ReviewerModel(
            userId: '',
            name: '',
            email: '',
            position: '',
            reviewStatus: AppConstants.REVIEWER_STATUS_PENDING,
            assignedDate: DateTime.now(),
          ),
        );

        return bReviewer.assignedDate!.compareTo(aReviewer.assignedDate!);
      });

      return assignedDocuments;
    } catch (e) {
      debugPrint('Error getting documents for reviewer: $e');
      return [];
    }
  }

  DocumentModel _sanitizeDocumentForReviewer(
      DocumentModel document, String reviewerId) {
    final currentReviewerData = document.reviewers
        .where((reviewer) => reviewer.userId == reviewerId)
        .toList();

    final sanitizedActionLog = document.actionLog
        .where((action) => _isActionVisibleToReviewer(action))
        .toList();

    return DocumentModel(
      id: document.id,
      documentUrl: document.documentUrl,
      status: document.status,
      timestamp: document.timestamp,
      reviewers: currentReviewerData,
      actionLog: sanitizedActionLog,
      fullName: '',
      email: '',
    );
  }

  bool _isActionVisibleToReviewer(ActionLogModel action) {
    final hiddenActions = [
      'موافقة السكرتير',
      'رفض السكرتير',
      'موافقة مدير التحرير',
      'رفض مدير التحرير',
      'الموافقة النهائية',
      'الرفض النهائي',
    ];

    return !hiddenActions
        .any((hiddenAction) => action.action.contains(hiddenAction));
  }

  // ==================== COMMON METHODS ====================

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

      if (AppStyles.isStage1Status(newStatus)) {
        updateData.addAll(_getStage1StatusSpecificData(
            newStatus, userName, userId, userPosition));
      } else if (AppStyles.isStage2Status(newStatus)) {
        updateData.addAll(_getStage2StatusSpecificData(
            newStatus, userName, userId, userPosition));
      }

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
      case AppConstants.REVIEWERS_ASSIGNED:
        return 'تعيين المحكمين';
      case AppConstants.UNDER_PEER_REVIEW:
        return 'بدء التحكيم العلمي';
      case AppConstants.PEER_REVIEW_COMPLETED:
        return 'انتهاء التحكيم العلمي';
      case AppConstants.HEAD_REVIEW_STAGE2:
        return 'بدء مراجعة رئيس التحرير للتحكيم';
      case AppConstants.LANGUAGE_EDITING_STAGE2:
        return 'إرسال للتدقيق اللغوي';
      case AppConstants.LANGUAGE_EDITOR_COMPLETED:
        return 'انتهاء التدقيق اللغوي';
      case AppConstants.CHEF_REVIEW_LANGUAGE_EDIT:
        return 'مراجعة مدير التحرير للتدقيق اللغوي';

      case AppConstants.STAGE2_APPROVED:
        return 'الموافقة للمرحلة الثالثة';
      case AppConstants.STAGE2_REJECTED:
        return 'رفض بعد التحكيم';
      case AppConstants.STAGE2_EDIT_REQUESTED:
        return 'طلب تعديل بناءً على التحكيم';
      case AppConstants.STAGE2_WEBSITE_APPROVED:
        return 'موافقة نشر الموقع بعد التحكيم';
      default:
        return 'تحديث الحالة';
    }
  }

  String _getReviewerActionDescription(String status) {
    switch (status) {
      case AppConstants.REVIEWER_STATUS_IN_PROGRESS:
        return 'بدء مراجعة المقال';
      case AppConstants.REVIEWER_STATUS_COMPLETED:
        return 'إنهاء التحكيم';
      case AppConstants.REVIEWER_STATUS_DECLINED:
        return 'رفض التحكيم';
      default:
        return 'تحديث حالة المحكم';
    }
  }

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

  Map<String, dynamic> _getStage2StatusSpecificData(
      String status, String userName, String userId, String userPosition) {
    final data = <String, dynamic>{};
    final timestamp = FieldValue.serverTimestamp();

    switch (status) {
      case AppConstants.REVIEWERS_ASSIGNED:
        data.addAll({
          'reviewersAssignedDate': timestamp,
          'reviewersAssignedBy': userName,
          'reviewersAssignedById': userId,
          'currentStage': 'reviewers_assigned',
          'stage2StartDate': timestamp,
        });
        break;
      case AppConstants.UNDER_PEER_REVIEW:
        data.addAll({
          'peerReviewStartDate': timestamp,
          'peerReviewStartedBy': userName,
          'peerReviewStartedById': userId,
          'currentStage': 'under_peer_review',
        });
        break;
      case AppConstants.PEER_REVIEW_COMPLETED:
        data.addAll({
          'peerReviewCompletedDate': timestamp,
          'currentStage': 'peer_review_completed',
          'readyForHeadReview': true,
        });
        break;
      case AppConstants.HEAD_REVIEW_STAGE2:
        data.addAll({
          'headReviewStage2StartDate': timestamp,
          'headReviewStage2By': userName,
          'headReviewStage2ById': userId,
          'currentStage': 'head_review_stage2',
        });
        break;

      case AppConstants.LANGUAGE_EDITING_STAGE2:
        data.addAll({
          'languageEditingStartDate': timestamp,
          'languageEditingAssignedBy': userName,
          'languageEditingAssignedById': userId,
          'languageEditingAssignedDate': timestamp,
          'currentStage': 'language_editing',
        });
        break;

      case AppConstants.LANGUAGE_EDITOR_COMPLETED:
        data.addAll({
          'languageEditingCompletedDate': timestamp,
          'currentStage': 'language_editing_completed',
          'readyForChefReview': true,
        });
        break;

      case AppConstants.CHEF_REVIEW_LANGUAGE_EDIT:
        data.addAll({
          'chefReviewLanguageEditStartDate': timestamp,
          'chefReviewLanguageEditBy': userName,
          'chefReviewLanguageEditById': userId,
          'currentStage': 'chef_review_language_edit',
        });
        break;
      case AppConstants.STAGE2_APPROVED:
        data.addAll({
          'stage2CompletionDate': timestamp,
          'stage2ApprovedBy': userName,
          'stage2ApprovedById': userId,
          'stage2Decision': 'approved_for_stage3',
          'readyForStage3': true,
          'stage2Status': 'completed_approved',
        });
        break;
      case AppConstants.STAGE2_REJECTED:
        data.addAll({
          'stage2RejectionDate': timestamp,
          'stage2RejectedBy': userName,
          'stage2RejectedById': userId,
          'stage2Decision': 'rejected',
          'stage2Status': 'completed_rejected',
        });
        break;
      case AppConstants.STAGE2_EDIT_REQUESTED:
        data.addAll({
          'stage2EditRequestDate': timestamp,
          'stage2EditRequestBy': userName,
          'stage2EditRequestById': userId,
          'stage2Decision': 'edit_requested',
          'stage2Status': 'edit_requested',
        });
        break;
      case AppConstants.STAGE2_WEBSITE_APPROVED:
        data.addAll({
          'stage2WebsiteApprovalDate': timestamp,
          'stage2WebsiteApprovedBy': userName,
          'stage2WebsiteApprovedById': userId,
          'stage2Decision': 'approved_for_website',
          'stage2Status': 'completed_website',
        });
        break;
    }
    return data;
  }

  Future<List<DocumentModel>> getDocumentsForUser(
      String userId, String userPosition) async {
    try {
      List<DocumentModel> documents = [];

      if (userPosition == AppConstants.POSITION_SECRETARY) {
        documents.addAll(await getDocumentsByStatus(AppConstants.INCOMING));
        documents
            .addAll(await getDocumentsByStatus(AppConstants.SECRETARY_REVIEW));
      } else if (userPosition == AppConstants.POSITION_LANGUAGE_EDITOR) {
        documents.addAll(
            await getDocumentsByStatus(AppConstants.LANGUAGE_EDITING_STAGE2));
      } else if (userPosition == AppConstants.POSITION_MANAGING_EDITOR ||
          userPosition == AppConstants.POSITION_EDITOR_CHIEF) {
        documents.addAll(
            await getDocumentsByStatus(AppConstants.CHEF_REVIEW_LANGUAGE_EDIT));

        documents
            .addAll(await getDocumentsByStatus(AppConstants.EDITOR_REVIEW));
        documents.addAll(
            await getDocumentsByStatus(AppConstants.SECRETARY_APPROVED));
        documents.addAll(
            await getDocumentsByStatus(AppConstants.SECRETARY_REJECTED));
        documents.addAll(
            await getDocumentsByStatus(AppConstants.SECRETARY_EDIT_REQUESTED));
      } else if (userPosition == AppConstants.POSITION_HEAD_EDITOR) {
        documents.addAll(
            await getDocumentsByStatus(AppConstants.LANGUAGE_EDITOR_COMPLETED));
        documents.addAll(
            await getDocumentsByStatus(AppConstants.CHEF_REVIEW_LANGUAGE_EDIT));
        documents.addAll(await getDocumentsByStatus(AppConstants.HEAD_REVIEW));
        documents
            .addAll(await getDocumentsByStatus(AppConstants.EDITOR_APPROVED));
        documents
            .addAll(await getDocumentsByStatus(AppConstants.EDITOR_REJECTED));
        documents.addAll(await getDocumentsByStatus(
            AppConstants.EDITOR_WEBSITE_RECOMMENDED));
        documents.addAll(
            await getDocumentsByStatus(AppConstants.EDITOR_EDIT_REQUESTED));
        documents
            .addAll(await getDocumentsByStatus(AppConstants.STAGE1_APPROVED));
        documents.addAll(
            await getDocumentsByStatus(AppConstants.REVIEWERS_ASSIGNED));
        documents.addAll(
            await getDocumentsByStatus(AppConstants.PEER_REVIEW_COMPLETED));
        documents.addAll(
            await getDocumentsByStatus(AppConstants.HEAD_REVIEW_STAGE2));
      } else if (userPosition.contains('محكم') ||
          userPosition == AppConstants.POSITION_REVIEWER) {
        final snapshot = await _firestore
            .collection('sent_documents')
            .where('status', whereIn: [
          AppConstants.REVIEWERS_ASSIGNED,
          AppConstants.UNDER_PEER_REVIEW,
          AppConstants.PEER_REVIEW_COMPLETED
        ]).get();

        for (final doc in snapshot.docs) {
          final docModel = DocumentModel.fromFirestore(doc);
          final isAssignedReviewer =
              docModel.reviewers.any((reviewer) => reviewer.userId == userId);
          if (isAssignedReviewer) {
            documents.add(docModel);
          }
        }
      }

      documents.sort((a, b) {
        final aPriority = _getDocumentPriority(a.status, userPosition);
        final bPriority = _getDocumentPriority(b.status, userPosition);

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

  int _getDocumentPriority(String status, String userPosition) {
    const stage1PriorityMap = {
      AppConstants.INCOMING: 1,
      AppConstants.SECRETARY_REVIEW: 2,
      AppConstants.EDITOR_REVIEW: 3,
      AppConstants.HEAD_REVIEW: 4,
      AppConstants.SECRETARY_APPROVED: 5,
      AppConstants.SECRETARY_EDIT_REQUESTED: 6,
      AppConstants.EDITOR_APPROVED: 7,
      AppConstants.EDITOR_WEBSITE_RECOMMENDED: 8,
      AppConstants.EDITOR_EDIT_REQUESTED: 9,
      AppConstants.SECRETARY_REJECTED: 10,
      AppConstants.EDITOR_REJECTED: 11,
      AppConstants.STAGE1_APPROVED: 20,
      AppConstants.FINAL_REJECTED: 21,
      AppConstants.WEBSITE_APPROVED: 22,
    };

    const stage2PriorityMap = {
      AppConstants.STAGE1_APPROVED: 1,
      AppConstants.REVIEWERS_ASSIGNED: 2,
      AppConstants.UNDER_PEER_REVIEW: 3,
      AppConstants.PEER_REVIEW_COMPLETED: 4,
      AppConstants.HEAD_REVIEW_STAGE2: 5,
      AppConstants.LANGUAGE_EDITING_STAGE2: 6, // NEW
      AppConstants.LANGUAGE_EDITOR_COMPLETED: 7, // NEW
      AppConstants.CHEF_REVIEW_LANGUAGE_EDIT: 8, // NEW
      AppConstants.STAGE2_APPROVED: 20,
      AppConstants.STAGE2_REJECTED: 21,
      AppConstants.STAGE2_EDIT_REQUESTED: 22,
      AppConstants.STAGE2_WEBSITE_APPROVED: 23,
    };

    return stage1PriorityMap[status] ?? stage2PriorityMap[status] ?? 999;
  }

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

      if (AppStyles.isStage1Status(newStatus)) {
        updateData.addAll(_getStage1StatusSpecificData(
            newStatus, adminName, adminId, adminPosition));
      } else if (AppStyles.isStage2Status(newStatus)) {
        updateData.addAll(_getStage2StatusSpecificData(
            newStatus, adminName, adminId, adminPosition));
      }

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

  Future<List<DocumentModel>> getDocumentsByStatuses(
      List<String> statuses) async {
    try {
      if (statuses.isEmpty) return [];

      if (statuses.length <= 10) {
        final querySnapshot = await _firestore
            .collection('sent_documents')
            .where('status', whereIn: statuses)
            .orderBy('timestamp', descending: true)
            .get();

        return querySnapshot.docs
            .map((doc) => DocumentModel.fromFirestore(doc))
            .toList();
      } else {
        List<DocumentModel> allDocuments = [];
        for (String status in statuses) {
          final docs = await getDocumentsByStatus(status);
          allDocuments.addAll(docs);
        }

        allDocuments.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return allDocuments;
      }
    } catch (e) {
      debugPrint('Error getting documents by statuses: $e');
      return [];
    }
  }

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

  Map<String, dynamic> getStage1Progress(DocumentModel document) {
    final steps = AppConstants.getStage1WorkflowSteps();
    int currentStepIndex = -1;

    for (int i = 0; i < steps.length; i++) {
      if (steps[i]['status'] == document.status) {
        currentStepIndex = i;
        break;
      }
    }

    if (currentStepIndex == -1) {
      if (AppStyles.isStage1FinalStatus(document.status)) {
        currentStepIndex = steps.length;
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

  Map<String, dynamic> getStage2Progress(DocumentModel document) {
    final steps = AppConstants.getStage2WorkflowSteps();
    int currentStepIndex = -1;

    for (int i = 0; i < steps.length; i++) {
      if (steps[i]['status'] == document.status) {
        currentStepIndex = i;
        break;
      }
    }

    if (currentStepIndex == -1) {
      if (AppStyles.isStage2FinalStatus(document.status)) {
        currentStepIndex = steps.length;
      }
    }

    double progressPercentage =
        currentStepIndex >= 0 ? (currentStepIndex + 1) / steps.length : 0.0;

    return {
      'currentStepIndex': currentStepIndex,
      'totalSteps': steps.length,
      'progressPercentage': progressPercentage,
      'isCompleted': AppStyles.isStage2FinalStatus(document.status),
      'currentStep': currentStepIndex >= 0 && currentStepIndex < steps.length
          ? steps[currentStepIndex]
          : null,
    };
  }

  bool canProceedWithAction(
      DocumentModel document, String action, String userPosition) {
    switch (document.status) {
      case AppConstants.INCOMING:
        return userPosition == AppConstants.POSITION_SECRETARY;
      case AppConstants.SECRETARY_REVIEW:
        return userPosition == AppConstants.POSITION_SECRETARY;
      case AppConstants.SECRETARY_APPROVED:
      case AppConstants.SECRETARY_REJECTED:
      case AppConstants.SECRETARY_EDIT_REQUESTED:
        return userPosition == AppConstants.POSITION_MANAGING_EDITOR;
      case AppConstants.EDITOR_REVIEW:
        return userPosition == AppConstants.POSITION_MANAGING_EDITOR;
      case AppConstants.EDITOR_APPROVED:
      case AppConstants.EDITOR_REJECTED:
      case AppConstants.EDITOR_WEBSITE_RECOMMENDED:
      case AppConstants.EDITOR_EDIT_REQUESTED:
        return userPosition == AppConstants.POSITION_HEAD_EDITOR;
      case AppConstants.HEAD_REVIEW:
        return userPosition == AppConstants.POSITION_HEAD_EDITOR;
      case AppConstants.STAGE1_APPROVED:
      case AppConstants.REVIEWERS_ASSIGNED:
      case AppConstants.PEER_REVIEW_COMPLETED:
      case AppConstants.HEAD_REVIEW_STAGE2:
        if (action == AppConstants.ACTION_SEND_TO_LANGUAGE_EDITOR) {
          return userPosition == AppConstants.POSITION_HEAD_EDITOR;
        }
        return userPosition == AppConstants.POSITION_HEAD_EDITOR;
      case AppConstants.LANGUAGE_EDITING_STAGE2:
        return userPosition == AppConstants.POSITION_LANGUAGE_EDITOR;

      case AppConstants.LANGUAGE_EDITOR_COMPLETED:
        return userPosition == AppConstants.POSITION_MANAGING_EDITOR ||
            userPosition == AppConstants.POSITION_EDITOR_CHIEF;

      case AppConstants.CHEF_REVIEW_LANGUAGE_EDIT:
        return userPosition == AppConstants.POSITION_MANAGING_EDITOR ||
            userPosition == AppConstants.POSITION_EDITOR_CHIEF;
      case AppConstants.UNDER_PEER_REVIEW:
        return userPosition.contains('محكم') ||
            userPosition == AppConstants.POSITION_REVIEWER;
      default:
        return false;
    }
  }

  String getWorkflowStageName(String status) {
    if (AppConstants.stage1Statuses.contains(status)) {
      return 'المرحلة الأولى: الموافقة';
    } else if (AppConstants.stage2Statuses.contains(status)) {
      return 'المرحلة الثانية: التحكيم العلمي';
    } else if (AppConstants.stage3Statuses.contains(status)) {
      return 'المرحلة الثالثة: الإنتاج النهائي';
    }
    return 'مرحلة غير معروفة';
  }

  bool canBeOverridden(DocumentModel document, String userPosition) {
    switch (document.status) {
      case AppConstants.SECRETARY_REJECTED:
        return userPosition == AppConstants.POSITION_MANAGING_EDITOR;
      case AppConstants.EDITOR_REJECTED:
        return userPosition == AppConstants.POSITION_HEAD_EDITOR;
      default:
        return false;
    }
  }

  String? getRejectionReason(DocumentModel document) {
    final rejectionActions = document.actionLog
        .where((action) => action.action.contains('رفض'))
        .toList();

    if (rejectionActions.isNotEmpty) {
      rejectionActions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return rejectionActions.first.comment;
    }

    return null;
  }

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

// Permission service for all workflow stages
class PermissionService {
  static bool isLanguageEditor(String? position) {
    return position == AppConstants.POSITION_LANGUAGE_EDITOR;
  }

  static bool canPerformLanguageEditing(String? position) {
    return position == AppConstants.POSITION_LANGUAGE_EDITOR;
  }

  static bool canReviewLanguageEditing(String? position) {
    return position == AppConstants.POSITION_MANAGING_EDITOR ||
        position == AppConstants.POSITION_EDITOR_CHIEF;
  }

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
    return position?.contains('محكم') == true ||
        position == AppConstants.POSITION_REVIEWER;
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
    if (status == AppConstants.LANGUAGE_EDITING_STAGE2 &&
        action == AppConstants.ACTION_COMPLETE_LANGUAGE_EDITING) {
      return position == AppConstants.POSITION_LANGUAGE_EDITOR;
    }
    if (status == AppConstants.CHEF_REVIEW_LANGUAGE_EDIT &&
        (action == AppConstants.ACTION_CHEF_APPROVE_LANGUAGE_EDIT ||
            action == AppConstants.ACTION_CHEF_REJECT_LANGUAGE_EDIT)) {
      return position == AppConstants.POSITION_MANAGING_EDITOR ||
          position == AppConstants.POSITION_EDITOR_CHIEF;
    }
    final availableActions =
        AppConstants.getAvailableActions(status, position ?? '');
    return availableActions.any((actionMap) => actionMap['action'] == action);
  }

  static List<String> getAvailableActionsForUser(
      String status, String? position) {
    final actions = AppConstants.getAvailableActions(status, position ?? '');
    return actions.map<String>((action) => action['action'] as String).toList();
  }

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

  static bool canAssignReviewers(String? position) {
    return position == AppConstants.POSITION_HEAD_EDITOR;
  }

  static bool canReviewDocuments(String? position) {
    return isReviewer(position);
  }

  static bool canManageStage2Workflow(String? position) {
    return position == AppConstants.POSITION_HEAD_EDITOR;
  }

  static bool canViewReviewerFeedback(
      String? position, String? userId, DocumentModel document) {
    if (position == AppConstants.POSITION_HEAD_EDITOR) return true;

    if (isReviewer(position)) {
      return document.reviewers.any((reviewer) => reviewer.userId == userId);
    }

    return false;
  }
}

// File handling service
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
