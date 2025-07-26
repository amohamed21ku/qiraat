// widgets/sender_info_card.dart
import 'package:flutter/material.dart';
import '../Constants/App_Constants.dart';
import '../models/document_model.dart';

class SenderInfoCard extends StatelessWidget {
  final DocumentModel document;
  final bool isDesktop;

  const SenderInfoCard({
    Key? key,
    required this.document,
    required this.isDesktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      margin: EdgeInsets.only(top: 20),
      decoration: AppStyles.simpleCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 20),
          _buildSenderInfoGrid(),
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
              colors: [Colors.blue.shade100, Colors.blue.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.person, color: Colors.blue.shade700, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بيانات المرسل',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'معلومات الشخص الذي أرسل المستند',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSenderInfoGrid() {
    final List<Map<String, String>> infoItems = [
      {
        'label': 'الاسم الكامل',
        'value': document.fullName.isNotEmpty ? document.fullName : 'غير متوفر',
        'icon': 'person'
      },
      {
        'label': 'البريد الإلكتروني',
        'value': document.email.isNotEmpty ? document.email : 'غير متوفر',
        'icon': 'email'
      },
      {
        'label': 'حول',
        'value':
            document.about?.isNotEmpty == true ? document.about! : 'غير متوفر',
        'icon': 'info'
      },
      {
        'label': 'التعليم',
        'value': document.education?.isNotEmpty == true
            ? document.education!
            : 'غير متوفر',
        'icon': 'school'
      },
      {
        'label': 'الحالة',
        'value': document.status.isNotEmpty ? document.status : 'غير متوفر',
        'icon': 'status'
      },
      {
        'label': 'المنصب',
        'value': document.position?.isNotEmpty == true
            ? document.position!
            : 'غير متوفر',
        'icon': 'work'
      },
    ];

    if (isDesktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 4,
        ),
        itemCount: infoItems.length,
        itemBuilder: (context, index) {
          return _buildInfoCard(infoItems[index]);
        },
      );
    } else {
      return Column(
        children: infoItems
            .map((item) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _buildInfoCard(item),
                ))
            .toList(),
      );
    }
  }

  Widget _buildInfoCard(Map<String, String> item) {
    IconData icon = Icons.info;
    Color iconColor = Colors.grey.shade600;

    switch (item['icon']) {
      case 'person':
        icon = Icons.person;
        iconColor = Colors.blue.shade600;
        break;
      case 'email':
        icon = Icons.email;
        iconColor = Colors.green.shade600;
        break;
      case 'info':
        icon = Icons.info;
        iconColor = Colors.orange.shade600;
        break;
      case 'school':
        icon = Icons.school;
        iconColor = Colors.purple.shade600;
        break;
      case 'status':
        icon = Icons.check_circle;
        iconColor = Colors.red.shade600;
        break;
      case 'work':
        icon = Icons.work;
        iconColor = Colors.indigo.shade600;
        break;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  item['value']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xff2d3748),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
