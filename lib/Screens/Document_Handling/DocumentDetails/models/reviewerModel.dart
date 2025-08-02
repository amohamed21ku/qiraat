// Enhanced ReviewerModel - update your existing reviewerModel.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewerModel {
  final String userId;
  final String name;
  final String email;
  final String position;
  final String reviewStatus;
  final DateTime? assignedDate;
  final DateTime? submittedDate;
  final String? comment;
  final String? attachedFileUrl;
  final String? attachedFileName;

  // Enhanced review fields
  final int? rating; // 1-5 stars
  final String?
      recommendation; // accept, minor_revision, major_revision, reject
  final String? strengths; // Reviewer's assessment of paper strengths
  final String? weaknesses; // Reviewer's assessment of paper weaknesses
  final String? recommendations; // Reviewer's recommendations for improvement
  final Map<String, dynamic>? reviewData; // Additional review data
  final String? specialization; // Reviewer's area of specialization

  ReviewerModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.position,
    required this.reviewStatus,
    required this.assignedDate,
    this.submittedDate,
    this.comment,
    this.attachedFileUrl,
    this.attachedFileName,
    this.rating,
    this.recommendation,
    this.strengths,
    this.weaknesses,
    this.recommendations,
    this.reviewData,
    this.specialization,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'position': position,
      'reviewStatus': reviewStatus,
      'assignedDate':
          assignedDate != null ? Timestamp.fromDate(assignedDate!) : null,
      'submittedDate':
          submittedDate != null ? Timestamp.fromDate(submittedDate!) : null,
      'comment': comment,
      'attachedFileUrl': attachedFileUrl,
      'attachedFileName': attachedFileName,
      'rating': rating,
      'recommendation': recommendation,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'recommendations': recommendations,
      'reviewData': reviewData,
      'specialization': specialization,
    };
  }

  factory ReviewerModel.fromMap(Map<String, dynamic> map) {
    return ReviewerModel(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      position: map['position'] ?? '',
      reviewStatus: map['reviewStatus'] ?? '',
      assignedDate: map['assignedDate'] != null
          ? (map['assignedDate'] as Timestamp).toDate()
          : null,
      submittedDate: map['submittedDate'] != null
          ? (map['submittedDate'] as Timestamp).toDate()
          : null,
      comment: map['comment'],
      attachedFileUrl: map['attachedFileUrl'],
      attachedFileName: map['attachedFileName'],
      rating: map['rating'] != null ? (map['rating'] as num).toInt() : null,
      recommendation: map['recommendation'],
      strengths: map['strengths'],
      weaknesses: map['weaknesses'],
      recommendations: map['recommendations'],
      reviewData: map['reviewData'] != null
          ? Map<String, dynamic>.from(map['reviewData'])
          : null,
      specialization: map['specialization'],
    );
  }

  ReviewerModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? position,
    String? reviewStatus,
    DateTime? assignedDate,
    DateTime? submittedDate,
    String? comment,
    String? attachedFileUrl,
    String? attachedFileName,
    int? rating,
    String? recommendation,
    String? strengths,
    String? weaknesses,
    String? recommendations,
    Map<String, dynamic>? reviewData,
    String? specialization,
  }) {
    return ReviewerModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      position: position ?? this.position,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      assignedDate: assignedDate ?? this.assignedDate,
      submittedDate: submittedDate ?? this.submittedDate,
      comment: comment ?? this.comment,
      attachedFileUrl: attachedFileUrl ?? this.attachedFileUrl,
      attachedFileName: attachedFileName ?? this.attachedFileName,
      rating: rating ?? this.rating,
      recommendation: recommendation ?? this.recommendation,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      recommendations: recommendations ?? this.recommendations,
      reviewData: reviewData ?? this.reviewData,
      specialization: specialization ?? this.specialization,
    );
  }

  @override
  String toString() {
    return 'ReviewerModel(userId: $userId, name: $name, reviewStatus: $reviewStatus, rating: $rating, recommendation: $recommendation)';
  }
}

// Helper class for review analytics
class ReviewAnalytics {
  final List<ReviewerModel> reviews;

  ReviewAnalytics(this.reviews);

  double get averageRating {
    final ratings = reviews
        .where((r) => r.rating != null && r.rating! > 0)
        .map((r) => r.rating!.toDouble())
        .toList();

    return ratings.isNotEmpty
        ? ratings.reduce((a, b) => a + b) / ratings.length
        : 0.0;
  }

  Map<String, int> get recommendationCounts {
    final counts = <String, int>{
      'accept': 0,
      'minor_revision': 0,
      'major_revision': 0,
      'reject': 0,
    };

    for (var review in reviews) {
      final rec = review.recommendation ?? 'unknown';
      if (counts.containsKey(rec)) {
        counts[rec] = counts[rec]! + 1;
      }
    }

    return counts;
  }

  Map<int, int> get ratingDistribution {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var review in reviews) {
      if (review.rating != null && review.rating! > 0) {
        distribution[review.rating!] = distribution[review.rating!]! + 1;
      }
    }

    return distribution;
  }

  String get overallRecommendation {
    final counts = recommendationCounts;
    final total = counts.values.reduce((a, b) => a + b);

    if (total == 0) return 'لا توجد توصيات';

    // Calculate percentages
    final acceptPercentage = (counts['accept']! / total * 100);
    final rejectPercentage = (counts['reject']! / total * 100);
    final majorRevisionPercentage = (counts['major_revision']! / total * 100);

    if (acceptPercentage >= 60) {
      return 'موصى بالقبول';
    } else if (rejectPercentage >= 50) {
      return 'موصى بالرفض';
    } else if (majorRevisionPercentage >= 50) {
      return 'يحتاج تعديلات كبيرة';
    } else {
      return 'آراء متباينة - يحتاج مراجعة دقيقة';
    }
  }

  List<String> get commonStrengths {
    final strengths = <String>[];
    for (var review in reviews) {
      if (review.strengths != null && review.strengths!.isNotEmpty) {
        strengths.add(review.strengths!);
      }
    }
    return strengths;
  }

  List<String> get commonWeaknesses {
    final weaknesses = <String>[];
    for (var review in reviews) {
      if (review.weaknesses != null && review.weaknesses!.isNotEmpty) {
        weaknesses.add(review.weaknesses!);
      }
    }
    return weaknesses;
  }

  int get completedReviewsCount {
    return reviews.where((r) => r.reviewStatus == 'Completed').length;
  }

  bool get isComplete {
    return reviews.every((r) => r.reviewStatus == 'Completed');
  }

  String get completionStatus {
    return '$completedReviewsCount من ${reviews.length}';
  }
}
