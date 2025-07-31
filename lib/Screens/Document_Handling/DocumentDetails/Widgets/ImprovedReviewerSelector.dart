// Improved Reviewer Selection Dialog
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ImprovedReviewerSelectionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableReviewers;
  final Color themeColor;
  final String userRole;
  final Function(List<Map<String, dynamic>>) onReviewersSelected;

  const ImprovedReviewerSelectionDialog({
    Key? key,
    required this.availableReviewers,
    required this.themeColor,
    required this.userRole,
    required this.onReviewersSelected,
  }) : super(key: key);

  @override
  _ImprovedReviewerSelectionDialogState createState() =>
      _ImprovedReviewerSelectionDialogState();
}

class _ImprovedReviewerSelectionDialogState
    extends State<ImprovedReviewerSelectionDialog> {
  List<Map<String, dynamic>> selectedReviewers = [];
  String searchQuery = '';
  String selectedSpecialization = 'الكل';
  List<String> specializations = ['الكل'];

  @override
  void initState() {
    super.initState();
    _extractSpecializations();
    // Debug print to see what reviewers we have
    print('Available reviewers: ${widget.availableReviewers.length}');
    for (var reviewer in widget.availableReviewers) {
      print(
          'Reviewer: ${reviewer['name']} - ${reviewer['position']} - ${reviewer['specialization']}');
    }
  }

  void _extractSpecializations() {
    Set<String> specs = {'الكل'};
    for (var reviewer in widget.availableReviewers) {
      if (reviewer['specialization'] != null &&
          reviewer['specialization'].toString().isNotEmpty) {
        specs.add(reviewer['specialization']);
      }
    }
    setState(() {
      specializations = specs.toList();
    });
  }

  List<Map<String, dynamic>> get filteredReviewers {
    return widget.availableReviewers.where((reviewer) {
      // Search filter
      bool matchesSearch = true;
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        matchesSearch = reviewer['name'].toLowerCase().contains(query) ||
            reviewer['position'].toLowerCase().contains(query) ||
            (reviewer['specialization']?.toLowerCase().contains(query) ??
                false) ||
            (reviewer['email']?.toLowerCase().contains(query) ?? false);
      }

      // Specialization filter
      bool matchesSpecialization = selectedSpecialization == 'الكل' ||
          reviewer['specialization'] == selectedSpecialization;

      return matchesSearch && matchesSpecialization;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              _buildHeader(),
              _buildFiltersSection(),
              _buildResultsCount(),
              _buildReviewersList(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.themeColor, widget.themeColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.people_alt, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اختيار المحكمين',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'اختر المحكمين المناسبين للمقال',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'تم اختيار: ${selectedReviewers.length}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'البحث بالاسم أو المنصب أو التخصص...',
              prefixIcon: Icon(Icons.search, color: widget.themeColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.themeColor),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 12),

          // Specialization filter chips
          Row(
            children: [
              Text(
                'التخصص:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: specializations.map((spec) {
                    bool isSelected = selectedSpecialization == spec;
                    return FilterChip(
                      label: Text(spec),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => selectedSpecialization = spec);
                      },
                      selectedColor: widget.themeColor.withOpacity(0.2),
                      checkmarkColor: widget.themeColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? widget.themeColor
                            : Colors.grey.shade700,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCount() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.people, color: widget.themeColor, size: 20),
          SizedBox(width: 8),
          Text(
            'المحكمون المتاحون: ${filteredReviewers.length}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          Spacer(),
          if (selectedReviewers.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() => selectedReviewers.clear()),
              icon: Icon(Icons.clear, size: 16, color: Colors.red),
              label: Text('مسح الكل', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewersList() {
    if (filteredReviewers.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              SizedBox(height: 16),
              Text(
                'لا توجد محكمين متاحين',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'جرب تغيير معايير البحث',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredReviewers.length,
        itemBuilder: (context, index) {
          final reviewer = filteredReviewers[index];
          final isSelected =
              selectedReviewers.any((r) => r['id'] == reviewer['id']);

          return Card(
            margin: EdgeInsets.only(bottom: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? widget.themeColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    isSelected ? widget.themeColor : Colors.grey.shade600,
                child: Text(
                  reviewer['name'][0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                reviewer['name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? widget.themeColor : Colors.black,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reviewer['position'],
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  if (reviewer['specialization'] != null &&
                      reviewer['specialization'].toString().isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reviewer['specialization'],
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.themeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Checkbox(
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      selectedReviewers.add(reviewer);
                    } else {
                      selectedReviewers
                          .removeWhere((r) => r['id'] == reviewer['id']);
                    }
                  });
                },
                activeColor: widget.themeColor,
              ),
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedReviewers
                        .removeWhere((r) => r['id'] == reviewer['id']);
                  } else {
                    selectedReviewers.add(reviewer);
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('إلغاء'),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: selectedReviewers.isNotEmpty
                  ? () {
                      Navigator.pop(context);
                      widget.onReviewersSelected(selectedReviewers);
                    }
                  : null,
              icon: Icon(Icons.assignment_ind, size: 20),
              label: Text(
                selectedReviewers.isEmpty
                    ? 'اختر محكمين'
                    : 'تعيين ${selectedReviewers.length} محكم',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
