// Update your ReviewerModel class in document_model.dart with these additional properties
// Make sure to import cloud_firestore for Timestamp:
// import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../Constants/App_Constants.dart';

class ReviewerModel {
  final String userId;
  final String name;
  final String email;
  final String position;
  final String reviewStatus;
  final DateTime? assignedDate;
  final DateTime? reviewedDate;
  final DateTime? submittedDate; // Added missing property
  final String? comment;
  final String? recommendation;
  final double? rating; // Added missing property
  final String? strengths; // Added for detailed feedback
  final String? weaknesses; // Added for detailed feedback
  final String? recommendations; // Added for recommendations
  final String? attachedFileUrl; // Added for file attachments
  final String? attachedFileName; // Added for file attachments
  final Map<String, dynamic>?
      reviewData; // Added for storing complete review data

  ReviewerModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.position,
    required this.reviewStatus,
    required this.assignedDate,
    this.reviewedDate,
    this.submittedDate,
    this.comment,
    this.recommendation,
    this.rating,
    this.strengths,
    this.weaknesses,
    this.recommendations,
    this.attachedFileUrl,
    this.attachedFileName,
    this.reviewData,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'position': position,
      'reviewStatus': reviewStatus,
      'assignedDate':
          assignedDate != null ? Timestamp.fromDate(assignedDate!) : null,
      'reviewedDate':
          reviewedDate != null ? Timestamp.fromDate(reviewedDate!) : null,
      'submittedDate':
          submittedDate != null ? Timestamp.fromDate(submittedDate!) : null,
      'comment': comment,
      'recommendation': recommendation,
      'rating': rating,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'recommendations': recommendations,
      'attachedFileUrl': attachedFileUrl,
      'attachedFileName': attachedFileName,
      'reviewData': reviewData,
    };
  }

  // Create from Firestore data
  factory ReviewerModel.fromMap(Map<String, dynamic> map) {
    return ReviewerModel(
      userId: map['userId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      position: map['position']?.toString() ?? '',
      reviewStatus: map['reviewStatus']?.toString() ??
          AppConstants.REVIEWER_STATUS_PENDING,
      assignedDate: map['assignedDate'] is Timestamp
          ? (map['assignedDate'] as Timestamp).toDate()
          : null,
      reviewedDate: map['reviewedDate'] is Timestamp
          ? (map['reviewedDate'] as Timestamp).toDate()
          : null,
      submittedDate: map['submittedDate'] is Timestamp
          ? (map['submittedDate'] as Timestamp).toDate()
          : null,
      comment: map['comment']?.toString(),
      recommendation: map['recommendation']?.toString(),
      rating: map['rating'] != null
          ? double.tryParse(map['rating'].toString())
          : null,
      strengths: map['strengths']?.toString(),
      weaknesses: map['weaknesses']?.toString(),
      recommendations: map['recommendations']?.toString(),
      attachedFileUrl: map['attachedFileUrl']?.toString(),
      attachedFileName: map['attachedFileName']?.toString(),
      reviewData: map['reviewData'] as Map<String, dynamic>?,
    );
  }

  // Create a copy with updated values
  ReviewerModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? position,
    String? reviewStatus,
    DateTime? assignedDate,
    DateTime? reviewedDate,
    DateTime? submittedDate,
    String? comment,
    String? recommendation,
    double? rating,
    String? strengths,
    String? weaknesses,
    String? recommendations,
    String? attachedFileUrl,
    String? attachedFileName,
    Map<String, dynamic>? reviewData,
  }) {
    return ReviewerModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      position: position ?? this.position,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      assignedDate: assignedDate ?? this.assignedDate,
      reviewedDate: reviewedDate ?? this.reviewedDate,
      submittedDate: submittedDate ?? this.submittedDate,
      comment: comment ?? this.comment,
      recommendation: recommendation ?? this.recommendation,
      rating: rating ?? this.rating,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      recommendations: recommendations ?? this.recommendations,
      attachedFileUrl: attachedFileUrl ?? this.attachedFileUrl,
      attachedFileName: attachedFileName ?? this.attachedFileName,
      reviewData: reviewData ?? this.reviewData,
    );
  }

  @override
  String toString() {
    return 'ReviewerModel(userId: $userId, name: $name, reviewStatus: $reviewStatus, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReviewerModel &&
        other.userId == userId &&
        other.name == name &&
        other.email == email &&
        other.position == position;
  }

  @override
  int get hashCode {
    return userId.hashCode ^ name.hashCode ^ email.hashCode ^ position.hashCode;
  }
}
