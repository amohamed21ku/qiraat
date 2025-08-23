// widgets/reviewers_status_widget.dart
import 'package:flutter/material.dart';
import '../../../../App_Constants.dart';
import '../../../../models/reviewerModel.dart';

class ReviewersStatusWidget extends StatelessWidget {
  final List<ReviewerModel> reviewers;

  const ReviewersStatusWidget({
    Key? key,
    required this.reviewers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reviewers.isEmpty) {
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
          _buildReviewersList(),
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
              colors: [
                AppStyles.primaryColor.withOpacity(0.1),
                AppStyles.primaryColor.withOpacity(0.2)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Icon(Icons.people_alt, color: AppStyles.primaryColor, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حالة المحكمين',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.primaryColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'تتبع تقدم المراجعة',
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
            color: AppStyles.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${reviewers.length}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppStyles.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewersList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: reviewers.length,
      itemBuilder: (context, index) {
        return ReviewerCard(reviewer: reviewers[index]);
      },
    );
  }
}

class ReviewerCard extends StatelessWidget {
  final ReviewerModel reviewer;

  const ReviewerCard({Key? key, required this.reviewer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
        reviewer.reviewStatus == 'Approved' ? Colors.green : Colors.orange;

    final IconData statusIcon = reviewer.reviewStatus == 'Approved'
        ? Icons.check_circle
        : Icons.schedule;

    final String statusText = reviewer.reviewStatus == 'Approved'
        ? 'تمت الموافقة'
        : 'في انتظار المراجعة';

    // Get reviewer type for styling
    final reviewerTypeInfo = _getReviewerTypeInfo(reviewer.position);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            statusColor.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewer.name.isNotEmpty ? reviewer.name : 'غير معروف',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xff2d3748),
                        ),
                      ),
                      SizedBox(height: 4),
                      if (reviewer.email.isNotEmpty)
                        Text(
                          reviewer.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          if (reviewer.position.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    reviewerTypeInfo['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    reviewerTypeInfo['icon'],
                                    size: 12,
                                    color: reviewerTypeInfo['color'],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    reviewerTypeInfo['type'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: reviewerTypeInfo['color'],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (reviewer.comment?.isNotEmpty == true &&
                reviewer.reviewStatus == 'Approved') ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade50, Colors.green.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.comment,
                            color: Colors.green.shade600, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'تعليق المحكم:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      reviewer.comment!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade800,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getReviewerTypeInfo(String position) {
    if (position.contains('سياسي')) {
      return {
        'type': 'محكم سياسي',
        'color': Colors.blue,
        'icon': Icons.account_balance,
      };
    } else if (position.contains('اقتصادي')) {
      return {
        'type': 'محكم اقتصادي',
        'color': Colors.green,
        'icon': Icons.trending_up,
      };
    } else if (position.contains('اجتماعي')) {
      return {
        'type': 'محكم اجتماعي',
        'color': Colors.purple,
        'icon': Icons.people,
      };
    } else {
      return {
        'type': 'محكم',
        'color': Colors.grey,
        'icon': Icons.person,
      };
    }
  }
}
