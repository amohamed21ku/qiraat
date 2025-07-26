// models/document_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final DateTime timestamp;
  final List<ReviewerModel> reviewers;
  final List<ActionLogModel> actionLog;
  final String? about;
  final String? education;
  final String? position;

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
    required this.timestamp,
    required this.reviewers,
    required this.actionLog,
    this.about,
    this.education,
    this.position,
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
    );
  }

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
    DateTime? timestamp,
    List<ReviewerModel>? reviewers,
    List<ActionLogModel>? actionLog,
    String? about,
    String? education,
    String? position,
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
      timestamp: timestamp ?? this.timestamp,
      reviewers: reviewers ?? this.reviewers,
      actionLog: actionLog ?? this.actionLog,
      about: about ?? this.about,
      education: education ?? this.education,
      position: position ?? this.position,
    );
  }
}

class ReviewerModel {
  final String userId;
  final String name;
  final String email;
  final String position;
  final String reviewStatus;
  final String? comment;
  final DateTime? assignedDate;

  ReviewerModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.position,
    required this.reviewStatus,
    this.comment,
    this.assignedDate,
  });

  factory ReviewerModel.fromMap(Map<String, dynamic> map) {
    return ReviewerModel(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      position: map['position'] ?? '',
      reviewStatus: map['review_status'] ?? 'Pending',
      comment: map['comment'],
      assignedDate: map['assigned_date'] != null
          ? (map['assigned_date'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'position': position,
      'review_status': reviewStatus,
      'comment': comment,
      'assigned_date':
          assignedDate != null ? Timestamp.fromDate(assignedDate!) : null,
    };
  }
}
// models/Actionlog_model.dart

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
