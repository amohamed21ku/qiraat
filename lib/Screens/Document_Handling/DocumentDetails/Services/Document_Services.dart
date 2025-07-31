// Services/Document_Services.dart - Updated with complete Stage 2 functionality
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../Constants/App_Constants.dart';
import '../models/document_model.dart';
import '../models/reviewerModel.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== STAGE 1 METHODS ====================

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
      return Stream.value([]);
    }
  }

  // Optimized method to get all Stage 1 documents at once
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

  // Stream for Stage 2 documents
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

  // Get all Stage 2 documents
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

  // Get documents ready for Stage 2 (approved in Stage 1)
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

// 1. Fixed getAvailableReviewers method with proper validation
// Fixed getAvailableReviewers method in Document_Services.dart
  Future<List<Map<String, dynamic>>> getAvailableReviewers() async {
    try {
      // Get all users first, then filter by position
      QuerySnapshot snapshot = await _firestore.collection('users').get();

      List<Map<String, dynamic>> reviewers = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Get name from either 'name' or 'fullName' field
        String name =
            (data['name']?.toString() ?? data['fullName']?.toString() ?? '')
                .trim();
        String email = (data['email']?.toString() ?? '').trim();
        String position = (data['position']?.toString() ?? '').trim();

        // Skip if no name or email
        if (name.isEmpty || email.isEmpty) {
          debugPrint('Skipping user with missing data: ${doc.id}');
          continue;
        }

        // Check if position contains reviewer-related keywords (more flexible)
        bool isReviewer = position.contains('محكم') ||
            position.contains('reviewer') ||
            position.contains('Reviewer') ||
            position == AppConstants.POSITION_REVIEWER ||
            position == AppConstants.REVIEWER_POLITICAL ||
            position == AppConstants.REVIEWER_ECONOMIC ||
            position == AppConstants.REVIEWER_SOCIAL ||
            position == AppConstants.REVIEWER_GENERAL;

        if (isReviewer) {
          // Determine specialization based on position
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

// 2. Fixed assignReviewersToDocument with validation
  Future<void> assignReviewersToDocument(
    String documentId,
    List<Map<String, dynamic>> selectedReviewers,
    String assignedBy,
    String assignedByName,
    String assignedByPosition,
  ) async {
    try {
      // Validate reviewer data before creating ReviewerModel
      final validatedReviewers = selectedReviewers.where((reviewer) {
        return reviewer['name'] != null &&
            reviewer['name'].toString().trim().isNotEmpty &&
            reviewer['email'] != null &&
            reviewer['position'] != null;
      }).toList();

      if (validatedReviewers.isEmpty) {
        throw Exception('No valid reviewers found in selection');
      }

      final reviewers = validatedReviewers.map((reviewer) {
        return ReviewerModel(
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

//

// 4. Add data validation helper method
  Map<String, dynamic> _validateReviewerData(Map<String, dynamic> data) {
    return {
      'id': data['id']?.toString() ?? '',
      'userId': data['userId']?.toString() ?? data['id']?.toString() ?? '',
      'name': (data['name']?.toString() ?? '').trim(),
      'email': (data['email']?.toString() ?? '').trim(),
      'position': (data['position']?.toString() ?? '').trim(),
      'specialization': (data['specialization']?.toString() ?? 'عام').trim(),
      'isActive': data['isActive'] ?? true,
      'reviewStatus': data['reviewStatus']?.toString() ??
          AppConstants.REVIEWER_STATUS_PENDING,
      'comment': data['comment']?.toString() ?? '',
    };
  }

// 5. Enhanced getReviewerStatistics with safety checks
  Future<Map<String, dynamic>> getReviewerStatistics(String reviewerId) async {
    try {
      if (reviewerId.isEmpty) {
        return _getEmptyStatistics();
      }

      // Get all documents where this reviewer is assigned
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

// 6. Helper method for empty statistics
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

// 7. Enhanced submitReviewerReview with validation
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
            // Ensure reviewer name is not empty
            String safeName = reviewerName.isNotEmpty
                ? reviewerName
                : (reviewer['name']?.toString().isNotEmpty == true
                    ? reviewer['name']
                    : 'Unknown Reviewer');

            reviewers[i] = {
              ...reviewer,
              'name': safeName, // Ensure name is set
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
      };

      if (allCompleted) {
        updateData['allReviewsCompletedDate'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('sent_documents')
          .doc(documentId)
          .update(updateData);

      debugPrint('Review submitted by $reviewerId successfully');
    } catch (e) {
      debugPrint('Error submitting reviewer review: $e');
      rethrow;
    }
  }

  // Save reviewer draft
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

  // Get reviewer draft
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

  // Get Stage 2 statistics
  Future<Map<String, dynamic>> getStage2Statistics() async {
    try {
      final statistics = <String, dynamic>{};

      // Get counts for each Stage 2 status
      for (String status in AppConstants.stage2Statuses) {
        final count = await _getDocumentCountByStatus(status);
        statistics[status] = count;
      }

      // Calculate Stage 2 workflow efficiency metrics
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

  // ====================Reviewer ================================

  /// Update reviewer status with enhanced security
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

      // Verify that the reviewer is actually assigned to this document
      bool reviewerFound = false;
      for (int i = 0; i < reviewers.length; i++) {
        if (reviewers[i] is Map<String, dynamic>) {
          final reviewer = reviewers[i] as Map<String, dynamic>;

          if (reviewer['userId'] == reviewerId) {
            // Verify the reviewer name matches (additional security)
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

      // Check if all reviews are completed
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

      // Update document status if all reviews are completed
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

  /// Submit reviewer review with enhanced validation
  Future<void> submitReviewerReviewSecure(
    String documentId,
    String reviewerId,
    Map<String, dynamic> reviewData,
    String reviewerName,
  ) async {
    try {
      if (documentId.isEmpty || reviewerId.isEmpty) {
        throw Exception('Document ID and Reviewer ID cannot be empty');
      }

      // Validate review data
      if (!_validateReviewData(reviewData)) {
        throw Exception('Invalid review data provided');
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
            // Security check: verify reviewer name
            String storedName = reviewer['name']?.toString() ?? '';
            if (storedName != reviewerName) {
              throw Exception('Reviewer authentication failed');
            }

            // Ensure required fields are present
            reviewers[i] = {
              ...reviewer,
              'name': reviewerName,
              'reviewStatus': AppConstants.REVIEWER_STATUS_COMPLETED,
              'rating': reviewData['rating'] ?? 0,
              'recommendation': reviewData['recommendation'] ?? '',
              'comment': reviewData['comment'] ?? '',
              'strengths': reviewData['strengths'] ?? '',
              'weaknesses': reviewData['weaknesses'] ?? '',
              'recommendations': reviewData['recommendations'] ?? '',
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
        throw Exception('Reviewer not authorized for this document');
      }

      final actionLog = ActionLogModel(
        action: 'إرسال التحكيم النهائي',
        userName: reviewerName,
        userPosition: 'محكم',
        performedById: reviewerId,
        timestamp: DateTime.now(),
        comment: reviewData['comment']?.toString() ?? '',
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
        'lastUpdatedBy': reviewerName,
      };

      if (allCompleted) {
        updateData['allReviewsCompletedDate'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('sent_documents')
          .doc(documentId)
          .update(updateData);

      debugPrint(
          'Review submitted by $reviewerId successfully with security validation');
    } catch (e) {
      debugPrint('Error submitting reviewer review securely: $e');
      rethrow;
    }
  }

  /// Validate review data to ensure all required fields are present
  bool _validateReviewData(Map<String, dynamic> reviewData) {
    // Check for required fields
    final requiredFields = [
      'rating',
      'recommendation',
      'comment',
      'strengths',
      'weaknesses'
    ];

    for (String field in requiredFields) {
      if (!reviewData.containsKey(field) ||
          reviewData[field] == null ||
          reviewData[field].toString().trim().isEmpty) {
        debugPrint('Missing or empty required field: $field');
        return false;
      }
    }

    // Validate rating is within acceptable range
    final rating = reviewData['rating'];
    if (rating is! num || rating < 1.0 || rating > 5.0) {
      debugPrint('Invalid rating value: $rating');
      return false;
    }

    return true;
  }

  /// Get reviewer statistics with privacy protection
  Future<Map<String, dynamic>> getReviewerStatisticsSecure(
      String reviewerId) async {
    try {
      if (reviewerId.isEmpty) {
        return _getEmptyStatistics();
      }

      // Get documents where this reviewer is assigned (without sensitive data)
      final assignedDocuments = await getDocumentsForReviewer(reviewerId);

      int totalAssigned = assignedDocuments.length;
      int completed = 0;
      int pending = 0;
      int inProgress = 0;
      List<double> ratings = [];
      int totalDays = 0;

      for (final document in assignedDocuments) {
        final reviewerData = document.reviewers.firstWhere(
          (reviewer) => reviewer.userId == reviewerId,
          orElse: () => ReviewerModel(
            userId: '',
            name: '',
            email: '',
            position: '',
            reviewStatus: AppConstants.REVIEWER_STATUS_PENDING,
            assignedDate: DateTime.now(),
          ),
        );

        switch (reviewerData.reviewStatus) {
          case AppConstants.REVIEWER_STATUS_COMPLETED:
            completed++;
            // Add rating if available
            if (reviewerData.rating != null && reviewerData.rating! > 0) {
              ratings.add(reviewerData.rating!.toDouble());
            }
            // Calculate review duration
            if (reviewerData.assignedDate != null &&
                reviewerData.submittedDate != null) {
              totalDays += reviewerData.submittedDate!
                  .difference(reviewerData.assignedDate!)
                  .inDays;
            }
            break;
          case AppConstants.REVIEWER_STATUS_IN_PROGRESS:
            inProgress++;
            break;
          case AppConstants.REVIEWER_STATUS_PENDING:
            pending++;
            break;
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
      debugPrint('Error getting reviewer statistics securely: $e');
      return _getEmptyStatistics();
    }
  }

  /// Get documents assigned to a specific reviewer (secure method)
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

        // Check if the current user is assigned as a reviewer
        final isAssignedReviewer = docModel.reviewers.any(
          (reviewer) => reviewer.userId == reviewerId,
        );

        if (isAssignedReviewer) {
          // Create a sanitized version of the document for the reviewer
          // Remove sensitive information that reviewers shouldn't see
          final sanitizedDoc =
              _sanitizeDocumentForReviewer(docModel, reviewerId);
          assignedDocuments.add(sanitizedDoc);
        }
      }

      // Sort by assignment date (most recent first)
      assignedDocuments.sort((a, b) {
        final aReviewer = a.reviewers.firstWhere(
          (reviewer) => reviewer.userId == reviewerId,
          orElse: () => ReviewerModel(
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
          orElse: () => ReviewerModel(
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

  /// Sanitize document data for reviewer view (remove sensitive information)
  DocumentModel _sanitizeDocumentForReviewer(
      DocumentModel document, String reviewerId) {
    // Create a copy of reviewers list with only the current reviewer's data
    final currentReviewerData = document.reviewers
        .where((reviewer) => reviewer.userId == reviewerId)
        .toList();

    // Remove sensitive action log entries that reviewers shouldn't see
    final sanitizedActionLog = document.actionLog
        .where((action) => _isActionVisibleToReviewer(action))
        .toList();

    // Create sanitized document
    return DocumentModel(
      id: document.id,
      documentUrl:
          document.documentUrl, // Reviewers need access to the document
      status: document.status,
      timestamp: document.timestamp,
      reviewers: currentReviewerData, // Only their own reviewer data
      actionLog: sanitizedActionLog, // Filtered action log
      // Remove other sensitive fields
      fullName: '', email: '', // Hide sender information
    );
  }

  /// Check if an action log entry should be visible to reviewers
  bool _isActionVisibleToReviewer(ActionLogModel action) {
    // Hide internal decisions and sensitive actions
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

  /// Update document status for any workflow stage
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

      // Add status-specific data and timestamps
      if (AppStyles.isStage1Status(newStatus)) {
        updateData.addAll(_getStage1StatusSpecificData(
            newStatus, userName, userId, userPosition));
      } else if (AppStyles.isStage2Status(newStatus)) {
        updateData.addAll(_getStage2StatusSpecificData(
            newStatus, userName, userId, userPosition));
      }

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

  /// Get action description for all statuses
  String _getActionDescription(String status) {
    // Stage 1 descriptions
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

      // Stage 2 descriptions
      case AppConstants.REVIEWERS_ASSIGNED:
        return 'تعيين المحكمين';
      case AppConstants.UNDER_PEER_REVIEW:
        return 'بدء التحكيم العلمي';
      case AppConstants.PEER_REVIEW_COMPLETED:
        return 'انتهاء التحكيم العلمي';
      case AppConstants.HEAD_REVIEW_STAGE2:
        return 'بدء مراجعة رئيس التحرير للتحكيم';
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

  /// Get status-specific data for Stage 2 workflow
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

  /// Get documents for Stage 1 and Stage 2 workflow based on user position
  Future<List<DocumentModel>> getDocumentsForUser(
      String userId, String userPosition) async {
    try {
      List<DocumentModel> documents = [];

      // Stage 1 documents based on user position
      if (userPosition == AppConstants.POSITION_SECRETARY) {
        documents.addAll(await getDocumentsByStatus(AppConstants.INCOMING));
        documents
            .addAll(await getDocumentsByStatus(AppConstants.SECRETARY_REVIEW));
      } else if (userPosition == AppConstants.POSITION_MANAGING_EDITOR) {
        documents
            .addAll(await getDocumentsByStatus(AppConstants.EDITOR_REVIEW));
        documents.addAll(
            await getDocumentsByStatus(AppConstants.SECRETARY_APPROVED));
        documents.addAll(
            await getDocumentsByStatus(AppConstants.SECRETARY_REJECTED));
        documents.addAll(
            await getDocumentsByStatus(AppConstants.SECRETARY_EDIT_REQUESTED));
      } else if (userPosition == AppConstants.POSITION_HEAD_EDITOR) {
        // Stage 1 documents
        documents.addAll(await getDocumentsByStatus(AppConstants.HEAD_REVIEW));
        documents
            .addAll(await getDocumentsByStatus(AppConstants.EDITOR_APPROVED));
        documents
            .addAll(await getDocumentsByStatus(AppConstants.EDITOR_REJECTED));
        documents.addAll(await getDocumentsByStatus(
            AppConstants.EDITOR_WEBSITE_RECOMMENDED));
        documents.addAll(
            await getDocumentsByStatus(AppConstants.EDITOR_EDIT_REQUESTED));

        // Stage 2 documents for head editor
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
        // Get documents where this user is assigned as a reviewer
        final snapshot = await _firestore
            .collection('sent_documents')
            .where('status', whereIn: [
          AppConstants.REVIEWERS_ASSIGNED,
          AppConstants.UNDER_PEER_REVIEW,
          AppConstants.PEER_REVIEW_COMPLETED
        ]).get();

        for (final doc in snapshot.docs) {
          final docModel = DocumentModel.fromFirestore(doc);
          // Check if the current user is assigned as a reviewer
          final isAssignedReviewer =
              docModel.reviewers.any((reviewer) => reviewer.userId == userId);
          if (isAssignedReviewer) {
            documents.add(docModel);
          }
        }
      }

      // Sort by priority and date
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

  /// Get document priority based on status and user position
  int _getDocumentPriority(String status, String userPosition) {
    // Higher priority (lower number) for urgent items
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
      AppConstants.STAGE2_APPROVED: 20,
      AppConstants.STAGE2_REJECTED: 21,
      AppConstants.STAGE2_EDIT_REQUESTED: 22,
      AppConstants.STAGE2_WEBSITE_APPROVED: 23,
    };

    return stage1PriorityMap[status] ?? stage2PriorityMap[status] ?? 999;
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

  /// Get documents by multiple statuses
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

  /// Get Stage 2 workflow progress for a document
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

  /// Check if document can proceed to action based on previous decisions
  bool canProceedWithAction(
      DocumentModel document, String action, String userPosition) {
    // Stage 1 permissions
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

      // Stage 2 permissions
      case AppConstants.STAGE1_APPROVED:
      case AppConstants.REVIEWERS_ASSIGNED:
      case AppConstants.PEER_REVIEW_COMPLETED:
      case AppConstants.HEAD_REVIEW_STAGE2:
        return userPosition == AppConstants.POSITION_HEAD_EDITOR;

      case AppConstants.UNDER_PEER_REVIEW:
        return userPosition.contains('محكم') ||
            userPosition == AppConstants.POSITION_REVIEWER;

      default:
        return false;
    }
  }

  /// Get workflow stage name
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

  /// Check if a document was rejected at any stage and can be overridden
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

  /// Get rejection reason from action log
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

// Permission service for all workflow stages
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
    return position?.contains('محكم') == true ||
        position == AppConstants.POSITION_REVIEWER;
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

  /// Stage 2 specific permissions
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
    // Head editor can view all feedback
    if (position == AppConstants.POSITION_HEAD_EDITOR) return true;

    // Reviewer can view their own feedback
    if (isReviewer(position)) {
      return document.reviewers.any((reviewer) => reviewer.userId == userId);
    }

    return false;
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
