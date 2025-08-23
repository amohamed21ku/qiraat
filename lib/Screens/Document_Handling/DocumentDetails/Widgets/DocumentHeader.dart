// widgets/document_header.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../App_Constants.dart';

class DocumentHeader extends StatelessWidget {
  final DateTime timestamp;
  final VoidCallback onBack;
  final bool isDesktop;

  const DocumentHeader({
    Key? key,
    required this.timestamp,
    required this.onBack,
    required this.isDesktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 20,
        vertical: isDesktop ? 40 : 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.secondaryColor,
            AppConstants.primaryColor,
            Color(0xff8b5a2b),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  onPressed: onBack,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.documentDetails,
                      style: AppStyles.headerStyle.copyWith(
                        fontSize: isDesktop ? 32 : 24,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      AppConstants.reviewAndManage,
                      style: AppStyles.subHeaderStyle.copyWith(
                        fontSize: isDesktop ? 18 : 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'تاريخ الإرسال: $formattedDate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
