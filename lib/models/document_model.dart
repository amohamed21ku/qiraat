// models/document_model.dart - Updated with complete fields from web form and Flutter app
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qiraat/models/reviewerModel.dart';

class DocumentModel {
  final String id;
  final String fullName;
  final String email;
  final String status;
  final String? documentUrl;
  final String? originalFileName;
  final int? fileSize;
  final String? documentType;
  final String? documentTypeName;
  final String? file_type; // Standardized file type field
  final DateTime timestamp;
  final List<ReviewerModel> reviewers;
  final List<ActionLogModel> actionLog;

  // Core submission fields
  final String? about; // Research summary
  final String? education; // Education degree
  final String? position;

  // Co-authors and CV fields (from updated web form)
  final List<String>? coAuthors; // List of co-author names
  final String? cvUrl; // CV file URL
  final String? cvFileName; // CV file name
  final int? cvFileSize; // CV file size
  final String? cvFileType; // CV file type
  final String? notes; // Additional notes field

  // Language editing fields
  final Map<String, dynamic>? languageEditingData;
  final bool? languageEditingApproved;
  final String? languageEditingCompletedBy;
  final DateTime? languageEditingCompletedDate;
  final String? chefReviewLanguageEditComment;
  final String? chefReviewLanguageEditDecision;

  // Secretary evaluation fields (from comprehensive evaluation form)
  final Map<String, dynamic>? secretaryEvaluationData;
  final String? secretaryEvaluationReport;
  final DateTime? secretaryEvaluationDate;
  final String? secretaryEvaluationBy;

  // Stage 2 peer review fields
  final Map<String, dynamic>? reviewStatistics;
  final Map<String, dynamic>? reviewSummary;
  final DateTime? allReviewsCompletedDate;
  final bool? readyForHeadReview;

  // Stage 3 production fields
  final Map<String, dynamic>? layoutDesignData;
  final DateTime? layoutDesignCompletedDate;
  final String? layoutDesignCompletedBy;
  final Map<String, dynamic>? finalReviewData;
  final DateTime? finalReviewCompletedDate;
  final String? finalReviewCompletedBy;
  final Map<String, dynamic>? finalModificationsData;
  final DateTime? publicationDate;
  final bool? isPublished;

  DocumentModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.status,
    this.documentUrl,
    this.originalFileName,
    this.fileSize,
    this.documentType,
    this.documentTypeName,
    this.file_type,
    required this.timestamp,
    required this.reviewers,
    required this.actionLog,
    this.about,
    this.education,
    this.position,
    // New fields from web form
    this.coAuthors,
    this.cvUrl,
    this.cvFileName,
    this.cvFileSize,
    this.cvFileType,
    this.notes,
    // Language editing fields
    this.languageEditingData,
    this.languageEditingApproved,
    this.languageEditingCompletedBy,
    this.languageEditingCompletedDate,
    this.chefReviewLanguageEditComment,
    this.chefReviewLanguageEditDecision,
    // Secretary evaluation fields
    this.secretaryEvaluationData,
    this.secretaryEvaluationReport,
    this.secretaryEvaluationDate,
    this.secretaryEvaluationBy,
    // Stage 2 fields
    this.reviewStatistics,
    this.reviewSummary,
    this.allReviewsCompletedDate,
    this.readyForHeadReview,
    // Stage 3 fields
    this.layoutDesignData,
    this.layoutDesignCompletedDate,
    this.layoutDesignCompletedBy,
    this.finalReviewData,
    this.finalReviewCompletedDate,
    this.finalReviewCompletedBy,
    this.finalModificationsData,
    this.publicationDate,
    this.isPublished,
  });

  factory DocumentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DocumentModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      status: data['status'] ?? '',
      documentUrl: data['documentUrl'],
      originalFileName: data['originalFileName'],
      fileSize: data['fileSize'],
      documentType: data['documentType'],
      documentTypeName: data['documentTypeName'],
      file_type: data['file_type'], // Standardized field
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      reviewers: (data['reviewers'] as List<dynamic>? ?? [])
          .map((r) => ReviewerModel.fromMap(r))
          .toList(),
      actionLog: (data['actionLog'] as List<dynamic>? ?? [])
          .map((a) => ActionLogModel.fromMap(a))
          .toList(),
      about: data['about'],
      education: data['education'],
      position: data['position'],

      // New fields from web form
      coAuthors: data['coAuthors'] != null
          ? List<String>.from(data['coAuthors'] as List)
          : null,
      cvUrl: data['cvUrl'],
      cvFileName: data['cvFileName'],
      cvFileSize: data['cvFileSize'],
      cvFileType: data['cv_file_type'], // Consistent with file_type pattern
      notes: data['notes'],

      // Language editing fields
      languageEditingData: data['languageEditingData'] as Map<String, dynamic>?,
      languageEditingApproved: data['languageEditingApproved'] as bool?,
      languageEditingCompletedBy: data['languageEditingCompletedBy'] as String?,
      languageEditingCompletedDate: data['languageEditingCompletedDate'] != null
          ? (data['languageEditingCompletedDate'] as Timestamp).toDate()
          : null,
      chefReviewLanguageEditComment:
          data['chefReviewLanguageEditComment'] as String?,
      chefReviewLanguageEditDecision:
          data['chefReviewLanguageEditDecision'] as String?,

      // Secretary evaluation fields
      secretaryEvaluationData:
          data['secretaryEvaluationData'] as Map<String, dynamic>?,
      secretaryEvaluationReport: data['secretaryEvaluationReport'] as String?,
      secretaryEvaluationDate: data['secretaryEvaluationDate'] != null
          ? (data['secretaryEvaluationDate'] as Timestamp).toDate()
          : null,
      secretaryEvaluationBy: data['secretaryEvaluationBy'] as String?,

      // Stage 2 fields
      reviewStatistics: data['reviewStatistics'] as Map<String, dynamic>?,
      reviewSummary: data['reviewSummary'] as Map<String, dynamic>?,
      allReviewsCompletedDate: data['allReviewsCompletedDate'] != null
          ? (data['allReviewsCompletedDate'] as Timestamp).toDate()
          : null,
      readyForHeadReview: data['readyForHeadReview'] as bool?,

      // Stage 3 fields
      layoutDesignData: data['layoutDesignData'] as Map<String, dynamic>?,
      layoutDesignCompletedDate: data['layoutDesignCompletedDate'] != null
          ? (data['layoutDesignCompletedDate'] as Timestamp).toDate()
          : null,
      layoutDesignCompletedBy: data['layoutDesignCompletedBy'] as String?,
      finalReviewData: data['finalReviewData'] as Map<String, dynamic>?,
      finalReviewCompletedDate: data['finalReviewCompletedDate'] != null
          ? (data['finalReviewCompletedDate'] as Timestamp).toDate()
          : null,
      finalReviewCompletedBy: data['finalReviewCompletedBy'] as String?,
      finalModificationsData:
          data['finalModificationsData'] as Map<String, dynamic>?,
      publicationDate: data['publicationDate'] != null
          ? (data['publicationDate'] as Timestamp).toDate()
          : null,
      isPublished: data['isPublished'] as bool?,
    );
  }

  // Convenience getter for title (for backward compatibility)
  String? get title => about?.isNotEmpty == true
      ? (about!.length > 50 ? '${about!.substring(0, 50)}...' : about!)
      : null;

  DocumentModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? status,
    String? documentUrl,
    String? originalFileName,
    int? fileSize,
    String? documentType,
    String? documentTypeName,
    String? file_type,
    DateTime? timestamp,
    List<ReviewerModel>? reviewers,
    List<ActionLogModel>? actionLog,
    String? about,
    String? education,
    String? position,
    List<String>? coAuthors,
    String? cvUrl,
    String? cvFileName,
    int? cvFileSize,
    String? cvFileType,
    String? notes,
    Map<String, dynamic>? languageEditingData,
    bool? languageEditingApproved,
    String? languageEditingCompletedBy,
    DateTime? languageEditingCompletedDate,
    String? chefReviewLanguageEditComment,
    String? chefReviewLanguageEditDecision,
    Map<String, dynamic>? secretaryEvaluationData,
    String? secretaryEvaluationReport,
    DateTime? secretaryEvaluationDate,
    String? secretaryEvaluationBy,
    Map<String, dynamic>? reviewStatistics,
    Map<String, dynamic>? reviewSummary,
    DateTime? allReviewsCompletedDate,
    bool? readyForHeadReview,
    Map<String, dynamic>? layoutDesignData,
    DateTime? layoutDesignCompletedDate,
    String? layoutDesignCompletedBy,
    Map<String, dynamic>? finalReviewData,
    DateTime? finalReviewCompletedDate,
    String? finalReviewCompletedBy,
    Map<String, dynamic>? finalModificationsData,
    DateTime? publicationDate,
    bool? isPublished,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      status: status ?? this.status,
      documentUrl: documentUrl ?? this.documentUrl,
      originalFileName: originalFileName ?? this.originalFileName,
      fileSize: fileSize ?? this.fileSize,
      documentType: documentType ?? this.documentType,
      documentTypeName: documentTypeName ?? this.documentTypeName,
      file_type: file_type ?? this.file_type,
      timestamp: timestamp ?? this.timestamp,
      reviewers: reviewers ?? this.reviewers,
      actionLog: actionLog ?? this.actionLog,
      about: about ?? this.about,
      education: education ?? this.education,
      position: position ?? this.position,
      coAuthors: coAuthors ?? this.coAuthors,
      cvUrl: cvUrl ?? this.cvUrl,
      cvFileName: cvFileName ?? this.cvFileName,
      cvFileSize: cvFileSize ?? this.cvFileSize,
      cvFileType: cvFileType ?? this.cvFileType,
      notes: notes ?? this.notes,
      languageEditingData: languageEditingData ?? this.languageEditingData,
      languageEditingApproved:
          languageEditingApproved ?? this.languageEditingApproved,
      languageEditingCompletedBy:
          languageEditingCompletedBy ?? this.languageEditingCompletedBy,
      languageEditingCompletedDate:
          languageEditingCompletedDate ?? this.languageEditingCompletedDate,
      chefReviewLanguageEditComment:
          chefReviewLanguageEditComment ?? this.chefReviewLanguageEditComment,
      chefReviewLanguageEditDecision:
          chefReviewLanguageEditDecision ?? this.chefReviewLanguageEditDecision,
      secretaryEvaluationData:
          secretaryEvaluationData ?? this.secretaryEvaluationData,
      secretaryEvaluationReport:
          secretaryEvaluationReport ?? this.secretaryEvaluationReport,
      secretaryEvaluationDate:
          secretaryEvaluationDate ?? this.secretaryEvaluationDate,
      secretaryEvaluationBy:
          secretaryEvaluationBy ?? this.secretaryEvaluationBy,
      reviewStatistics: reviewStatistics ?? this.reviewStatistics,
      reviewSummary: reviewSummary ?? this.reviewSummary,
      allReviewsCompletedDate:
          allReviewsCompletedDate ?? this.allReviewsCompletedDate,
      readyForHeadReview: readyForHeadReview ?? this.readyForHeadReview,
      layoutDesignData: layoutDesignData ?? this.layoutDesignData,
      layoutDesignCompletedDate:
          layoutDesignCompletedDate ?? this.layoutDesignCompletedDate,
      layoutDesignCompletedBy:
          layoutDesignCompletedBy ?? this.layoutDesignCompletedBy,
      finalReviewData: finalReviewData ?? this.finalReviewData,
      finalReviewCompletedDate:
          finalReviewCompletedDate ?? this.finalReviewCompletedDate,
      finalReviewCompletedBy:
          finalReviewCompletedBy ?? this.finalReviewCompletedBy,
      finalModificationsData:
          finalModificationsData ?? this.finalModificationsData,
      publicationDate: publicationDate ?? this.publicationDate,
      isPublished: isPublished ?? this.isPublished,
    );
  }

  // Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'fullName': fullName,
      'email': email,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'reviewers': reviewers.map((r) => r.toMap()).toList(),
      'actionLog': actionLog.map((a) => a.toMap()).toList(),
    };

    // Add optional fields only if they have values
    if (documentUrl != null) data['documentUrl'] = documentUrl;
    if (originalFileName != null) data['originalFileName'] = originalFileName;
    if (fileSize != null) data['fileSize'] = fileSize;
    if (documentType != null) data['documentType'] = documentType;
    if (documentTypeName != null) data['documentTypeName'] = documentTypeName;
    if (file_type != null) data['file_type'] = file_type;
    if (about != null) data['about'] = about;
    if (education != null) data['education'] = education;
    if (position != null) data['position'] = position;

    // New fields from web form
    if (coAuthors != null && coAuthors!.isNotEmpty)
      data['coAuthors'] = coAuthors;
    if (cvUrl != null) data['cvUrl'] = cvUrl;
    if (cvFileName != null) data['cvFileName'] = cvFileName;
    if (cvFileSize != null) data['cvFileSize'] = cvFileSize;
    if (cvFileType != null) data['cv_file_type'] = cvFileType;
    if (notes != null) data['notes'] = notes;

    // Language editing fields
    if (languageEditingData != null)
      data['languageEditingData'] = languageEditingData;
    if (languageEditingApproved != null)
      data['languageEditingApproved'] = languageEditingApproved;
    if (languageEditingCompletedBy != null)
      data['languageEditingCompletedBy'] = languageEditingCompletedBy;
    if (languageEditingCompletedDate != null) {
      data['languageEditingCompletedDate'] =
          Timestamp.fromDate(languageEditingCompletedDate!);
    }
    if (chefReviewLanguageEditComment != null) {
      data['chefReviewLanguageEditComment'] = chefReviewLanguageEditComment;
    }
    if (chefReviewLanguageEditDecision != null) {
      data['chefReviewLanguageEditDecision'] = chefReviewLanguageEditDecision;
    }

    // Secretary evaluation fields
    if (secretaryEvaluationData != null)
      data['secretaryEvaluationData'] = secretaryEvaluationData;
    if (secretaryEvaluationReport != null)
      data['secretaryEvaluationReport'] = secretaryEvaluationReport;
    if (secretaryEvaluationDate != null) {
      data['secretaryEvaluationDate'] =
          Timestamp.fromDate(secretaryEvaluationDate!);
    }
    if (secretaryEvaluationBy != null)
      data['secretaryEvaluationBy'] = secretaryEvaluationBy;

    // Stage 2 fields
    if (reviewStatistics != null) data['reviewStatistics'] = reviewStatistics;
    if (reviewSummary != null) data['reviewSummary'] = reviewSummary;
    if (allReviewsCompletedDate != null) {
      data['allReviewsCompletedDate'] =
          Timestamp.fromDate(allReviewsCompletedDate!);
    }
    if (readyForHeadReview != null)
      data['readyForHeadReview'] = readyForHeadReview;

    // Stage 3 fields
    if (layoutDesignData != null) data['layoutDesignData'] = layoutDesignData;
    if (layoutDesignCompletedDate != null) {
      data['layoutDesignCompletedDate'] =
          Timestamp.fromDate(layoutDesignCompletedDate!);
    }
    if (layoutDesignCompletedBy != null)
      data['layoutDesignCompletedBy'] = layoutDesignCompletedBy;
    if (finalReviewData != null) data['finalReviewData'] = finalReviewData;
    if (finalReviewCompletedDate != null) {
      data['finalReviewCompletedDate'] =
          Timestamp.fromDate(finalReviewCompletedDate!);
    }
    if (finalReviewCompletedBy != null)
      data['finalReviewCompletedBy'] = finalReviewCompletedBy;
    if (finalModificationsData != null)
      data['finalModificationsData'] = finalModificationsData;
    if (publicationDate != null)
      data['publicationDate'] = Timestamp.fromDate(publicationDate!);
    if (isPublished != null) data['isPublished'] = isPublished;

    return data;
  }

  @override
  String toString() {
    return 'DocumentModel(id: $id, fullName: $fullName, status: $status, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentModel &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^ fullName.hashCode ^ email.hashCode ^ status.hashCode;
  }
}

// models/Actionlog_model.dart - Keep existing implementation
class ActionLogModel {
  final String action;
  final String userName;
  final String userPosition;
  final String? performedById;
  final DateTime timestamp;
  final String? comment;
  final String? attachedFileUrl;
  final String? attachedFileName;
  final List<ReviewerInfo>? reviewers;
  final String? reviewerType;

  ActionLogModel({
    required this.action,
    required this.userName,
    required this.userPosition,
    this.performedById,
    required this.timestamp,
    this.comment,
    this.attachedFileUrl,
    this.attachedFileName,
    this.reviewers,
    this.reviewerType,
  });

  factory ActionLogModel.fromMap(Map<String, dynamic> map) {
    return ActionLogModel(
      action: map['action'] ?? '',
      userName: map['userName'] ?? map['performedBy'] ?? '',
      userPosition: map['userPosition'] ?? map['performedByPosition'] ?? '',
      performedById: map['performedById'] ?? map['performedBy_id'],
      timestamp: _parseTimestamp(map['timestamp']),
      comment: map['comment'],
      attachedFileUrl: map['attachedFileUrl'],
      attachedFileName: map['attachedFileName'],
      reviewers: _parseReviewers(map['reviewers']),
      reviewerType: map['reviewerType'],
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'action': action,
      'userName': userName,
      'userPosition': userPosition,
      'timestamp': Timestamp.fromDate(timestamp),
    };

    // Add optional fields only if they have values
    if (performedById != null) data['performedById'] = performedById;
    if (comment != null && comment!.isNotEmpty) data['comment'] = comment;
    if (attachedFileUrl != null) data['attachedFileUrl'] = attachedFileUrl;
    if (attachedFileName != null) data['attachedFileName'] = attachedFileName;
    if (reviewerType != null) data['reviewerType'] = reviewerType;

    if (reviewers != null && reviewers!.isNotEmpty) {
      data['reviewers'] = reviewers!.map((r) => r.toMap()).toList();
    }

    return data;
  }

  static DateTime _parseTimestamp(dynamic timestampData) {
    if (timestampData is Timestamp) {
      return timestampData.toDate();
    } else if (timestampData is DateTime) {
      return timestampData;
    } else if (timestampData is String) {
      return DateTime.tryParse(timestampData) ?? DateTime.now();
    } else {
      return DateTime.now();
    }
  }

  static List<ReviewerInfo>? _parseReviewers(dynamic reviewersData) {
    if (reviewersData is List) {
      return reviewersData
          .map((r) => ReviewerInfo.fromMap(r as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  ActionLogModel copyWith({
    String? action,
    String? userName,
    String? userPosition,
    String? performedById,
    DateTime? timestamp,
    String? comment,
    String? attachedFileUrl,
    String? attachedFileName,
    List<ReviewerInfo>? reviewers,
    String? reviewerType,
  }) {
    return ActionLogModel(
      action: action ?? this.action,
      userName: userName ?? this.userName,
      userPosition: userPosition ?? this.userPosition,
      performedById: performedById ?? this.performedById,
      timestamp: timestamp ?? this.timestamp,
      comment: comment ?? this.comment,
      attachedFileUrl: attachedFileUrl ?? this.attachedFileUrl,
      attachedFileName: attachedFileName ?? this.attachedFileName,
      reviewers: reviewers ?? this.reviewers,
      reviewerType: reviewerType ?? this.reviewerType,
    );
  }

  @override
  String toString() {
    return 'ActionLogModel(action: $action, userName: $userName, userPosition: $userPosition, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActionLogModel &&
        other.action == action &&
        other.userName == userName &&
        other.userPosition == userPosition &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return action.hashCode ^
        userName.hashCode ^
        userPosition.hashCode ^
        timestamp.hashCode;
  }
}

/// Helper class for reviewer information in action logs
class ReviewerInfo {
  final String userId;
  final String name;
  final String email;
  final String position;

  ReviewerInfo({
    required this.userId,
    required this.name,
    required this.email,
    required this.position,
  });

  factory ReviewerInfo.fromMap(Map<String, dynamic> map) {
    return ReviewerInfo(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      position: map['position'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'position': position,
    };
  }

  @override
  String toString() {
    return 'ReviewerInfo(userId: $userId, name: $name, email: $email, position: $position)';
  }
}
