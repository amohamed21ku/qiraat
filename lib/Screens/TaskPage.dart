import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qiraat/Classes/current_user_providerr.dart';
import 'dart:ui' as ui;

import 'package:qiraat/Screens/Document_Handling/DocumentDetails.dart';

class SecretaryTasksPage extends StatefulWidget {
  const SecretaryTasksPage({Key? key}) : super(key: key);

  @override
  State<SecretaryTasksPage> createState() => _SecretaryTasksPageState();
}

class _SecretaryTasksPageState extends State<SecretaryTasksPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'جميع الملفات';
  List<String> _filterOptions = ['جميع الملفات', 'الأحدث', 'الأقدم'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading time for demonstration purposes
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  // Sort documents based on the selected filter
  List<DocumentSnapshot> _sortDocuments(List<DocumentSnapshot> documents) {
    if (_selectedFilter == 'الأحدث') {
      documents.sort((a, b) {
        final Timestamp aTime =
            (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        final Timestamp bTime =
            (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        return bTime.compareTo(aTime);
      });
    } else if (_selectedFilter == 'الأقدم') {
      documents.sort((a, b) {
        final Timestamp aTime =
            (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        final Timestamp bTime =
            (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        return aTime.compareTo(bTime);
      });
    }
    return documents;
  }

  // Filter documents based on search query
  List<DocumentSnapshot> _filterDocuments(List<DocumentSnapshot> documents) {
    if (_searchQuery.isEmpty) return documents;

    return documents.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final fullName = (data['fullName'] ?? '').toString().toLowerCase();
      final about = (data['about'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return fullName.contains(query) || about.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Get current user to check position
    final currentUserProvider = Provider.of<CurrentUserProvider>(context);
    final currentUser = currentUserProvider.currentUser;
    final isEditorialSecretary = currentUser?.position == 'سكرتير تحرير';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xffa86418),
        title: Text(
          'إدارة المهام - سكرتير التحرير',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'ملفات بانتظار الموافقة'),
            Tab(text: 'جميع الملفات'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xffa86418)))
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'بحث عن ملف...',
                          prefixIcon:
                              Icon(Icons.search, color: Color(0xffa86418)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xffa86418)),
                          ),
                        ),
                        textDirection: ui.TextDirection.rtl,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      // Filter options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ترتيب حسب:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          DropdownButton<String>(
                            value: _selectedFilter,
                            icon: Icon(Icons.arrow_drop_down,
                                color: Color(0xffa86418)),
                            elevation: 16,
                            underline: Container(
                              height: 2,
                              color: Color(0xffa86418),
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedFilter = newValue;
                                });
                              }
                            },
                            items: _filterOptions
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Pending files tab
                      _buildFilesList(
                          status: 'ملف مرسل',
                          isEditorialSecretary: isEditorialSecretary),

                      // All files tab
                      _buildFilesList(
                          status: null,
                          isEditorialSecretary: isEditorialSecretary),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilesList({String? status, required bool isEditorialSecretary}) {
    Query query = FirebaseFirestore.instance.collection('sent_documents');

    // Filter by status if specified
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: Color(0xffa86418)));
        }

        List<DocumentSnapshot> documents = snapshot.data!.docs;

        // Apply search filter and sorting
        documents = _filterDocuments(documents);
        documents = _sortDocuments(documents);

        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'لا توجد ملفات متاحة',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            final data = doc.data() as Map<String, dynamic>;
            final docStatus = data['status'] ?? 'غير معروف';
            final timestamp = (data['timestamp'] as Timestamp).toDate();
            final formattedDate =
                DateFormat('yyyy-MM-dd • HH:mm').format(timestamp);

            // Determine card color based on status
            Color cardColor = Colors.white;
            Color statusColor = Colors.grey;
            IconData statusIcon = Icons.circle;

            switch (docStatus) {
              case 'ملف مرسل':
                statusColor = Colors.blue;
                statusIcon = Icons.pending_actions;
                break;
              case 'قبول الملف':
                statusColor = Colors.green[700]!;
                statusIcon = Icons.check_circle;
                break;
              case 'تم الرفض':
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
                break;
              case 'الي المحكمين':
                statusColor = Colors.purple;
                statusIcon = Icons.people;
                break;
              case 'تم التحكيم':
                statusColor = Colors.teal;
                statusIcon = Icons.rate_review;
                break;
              case 'تمت الموافقه':
                statusColor = Colors.green;
                statusIcon = Icons.thumb_up;
                break;
              case 'مرسل للتعديل':
                statusColor = Colors.orange;
                statusIcon = Icons.edit;
                break;
            }

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentDetailsPage(document: doc),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: ui.TextDirection.rtl,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              textDirection: ui.TextDirection.rtl,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person,
                                        size: 16, color: Color(0xffa86418)),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        data['fullName'] ?? 'غير معروف',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        textDirection: ui.TextDirection.rtl,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 14, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  size: 14,
                                  color: statusColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  docStatus,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        data['about'] ?? 'لا يوجد وصف',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                        textDirection: ui.TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 16),
                      // Quick action buttons only for "ملف مرسل" status and for editorial secretary
                      if (docStatus == 'ملف مرسل' && isEditorialSecretary)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to details page to handle rejection
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DocumentDetailsPage(document: doc),
                                  ),
                                );
                              },
                              icon: Icon(Icons.close,
                                  color: Colors.white, size: 16),
                              label: Text('رفض',
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to details page to handle acceptance
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DocumentDetailsPage(document: doc),
                                  ),
                                );
                              },
                              icon: Icon(Icons.check,
                                  color: Colors.white, size: 16),
                              label: Text('قبول',
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xffa86418),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class EditorChiefTasksPage extends StatefulWidget {
  const EditorChiefTasksPage({Key? key}) : super(key: key);

  @override
  State<EditorChiefTasksPage> createState() => _EditorChiefTasksPageState();
}

class _EditorChiefTasksPageState extends State<EditorChiefTasksPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'جميع الملفات';
  List<String> _filterOptions = ['جميع الملفات', 'الأحدث', 'الأقدم'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading time for demonstration purposes
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  // Sort documents based on the selected filter
  List<DocumentSnapshot> _sortDocuments(List<DocumentSnapshot> documents) {
    if (_selectedFilter == 'الأحدث') {
      documents.sort((a, b) {
        final Timestamp aTime =
            (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        final Timestamp bTime =
            (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        return bTime.compareTo(aTime);
      });
    } else if (_selectedFilter == 'الأقدم') {
      documents.sort((a, b) {
        final Timestamp aTime =
            (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        final Timestamp bTime =
            (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        return aTime.compareTo(bTime);
      });
    }
    return documents;
  }

  // Filter documents based on search query
  List<DocumentSnapshot> _filterDocuments(List<DocumentSnapshot> documents) {
    if (_searchQuery.isEmpty) return documents;

    return documents.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final fullName = (data['fullName'] ?? '').toString().toLowerCase();
      final about = (data['about'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return fullName.contains(query) || about.contains(query);
    }).toList();
  }

  Future<void> _assignReviewers(DocumentSnapshot document) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentDetailsPage(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current user to check position
    final currentUserProvider = Provider.of<CurrentUserProvider>(context);
    final currentUser = currentUserProvider.currentUser;
    final isEditorChief = currentUser?.position == 'مدير التحرير';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xffa86418),
        title: Text(
          'إدارة المهام - مدير التحرير',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'بانتظار التعيين'),
            Tab(text: 'قيد التحكيم'),
            Tab(text: 'جميع الملفات'),
          ],
          onTap: (index) {
            setState(() {});
          },
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xffa86418)))
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'بحث عن ملف...',
                          prefixIcon:
                              Icon(Icons.search, color: Color(0xffa86418)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xffa86418)),
                          ),
                        ),
                        textDirection: ui.TextDirection.rtl,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      // Filter options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ترتيب حسب:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          DropdownButton<String>(
                            value: _selectedFilter,
                            icon: Icon(Icons.arrow_drop_down,
                                color: Color(0xffa86418)),
                            elevation: 16,
                            underline: Container(
                              height: 2,
                              color: Color(0xffa86418),
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedFilter = newValue;
                                });
                              }
                            },
                            items: _filterOptions
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Waiting for assignment tab (files with status "قبول الملف")
                      _buildFilesList(
                          status: 'قبول الملف',
                          isEditorChief: isEditorChief,
                          actionLabel: 'تعيين المحكمين',
                          actionIcon: Icons.person_add),

                      // In review tab (files with status "الي المحكمين")
                      _buildFilesList(
                          status: 'الي المحكمين',
                          isEditorChief: isEditorChief,
                          actionLabel: 'متابعة',
                          actionIcon: Icons.visibility),

                      // All files tab
                      _buildFilesList(
                          status: null, isEditorChief: isEditorChief),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilesList(
      {String? status,
      required bool isEditorChief,
      String? actionLabel,
      IconData? actionIcon}) {
    Query query = FirebaseFirestore.instance.collection('sent_documents');

    // Filter by status if specified
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: Color(0xffa86418)));
        }

        List<DocumentSnapshot> documents = snapshot.data!.docs;

        // Apply search filter and sorting
        documents = _filterDocuments(documents);
        documents = _sortDocuments(documents);

        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'لا توجد ملفات متاحة',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            final data = doc.data() as Map<String, dynamic>;
            final docStatus = data['status'] ?? 'غير معروف';
            final timestamp = (data['timestamp'] as Timestamp).toDate();
            final formattedDate =
                DateFormat('yyyy-MM-dd • HH:mm').format(timestamp);

            // Get reviewers information if available
            List<dynamic> actionLog = data['actionLog'] ?? [];
            List<String> assignedReviewers = [];

            // Find the most recent 'الي المحكمين' action to get assigned reviewers
            if (actionLog.isNotEmpty) {
              for (var i = actionLog.length - 1; i >= 0; i--) {
                if (actionLog[i]['action'] == 'الي المحكمين' &&
                    actionLog[i]['reviewers'] != null) {
                  assignedReviewers =
                      List<String>.from(actionLog[i]['reviewers']);
                  break;
                }
              }
            }

            // Determine card color based on status
            Color statusColor = Colors.grey;
            IconData statusIcon = Icons.circle;

            switch (docStatus) {
              case 'ملف مرسل':
                statusColor = Colors.blue;
                statusIcon = Icons.pending_actions;
                break;
              case 'قبول الملف':
                statusColor = Colors.green[700]!;
                statusIcon = Icons.check_circle;
                break;
              case 'تم الرفض':
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
                break;
              case 'الي المحكمين':
                statusColor = Colors.purple;
                statusIcon = Icons.people;
                break;
              case 'تم التحكيم':
                statusColor = Colors.teal;
                statusIcon = Icons.rate_review;
                break;
              case 'تمت الموافقه':
                statusColor = Colors.green;
                statusIcon = Icons.thumb_up;
                break;
              case 'مرسل للتعديل':
                statusColor = Colors.orange;
                statusIcon = Icons.edit;
                break;
            }

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentDetailsPage(document: doc),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: ui.TextDirection.rtl,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              textDirection: ui.TextDirection.rtl,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person,
                                        size: 16, color: Color(0xffa86418)),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        data['fullName'] ?? 'غير معروف',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        textDirection: ui.TextDirection.rtl,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 14, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  size: 14,
                                  color: statusColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  docStatus,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        data['about'] ?? 'لا يوجد وصف',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                        textDirection: ui.TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Show assigned reviewers if any
                      if (assignedReviewers.isNotEmpty &&
                          docStatus == 'الي المحكمين')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          textDirection: ui.TextDirection.rtl,
                          children: [
                            SizedBox(height: 12),
                            Text(
                              'المحكمون المعينون:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xffa86418),
                              ),
                              textDirection: ui.TextDirection.rtl,
                            ),
                            SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: assignedReviewers.map((reviewer) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.purple, width: 1),
                                  ),
                                  child: Text(
                                    reviewer,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.purple,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                      SizedBox(height: 16),
                      // Action button if applicable
                      if ((docStatus == 'قبول الملف' ||
                              docStatus == 'الي المحكمين') &&
                          isEditorChief &&
                          actionLabel != null &&
                          actionIcon != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _assignReviewers(doc),
                              icon: Icon(actionIcon,
                                  color: Colors.white, size: 16),
                              label: Text(actionLabel,
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xffa86418),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ReviewerTasksPage extends StatefulWidget {
  const ReviewerTasksPage({Key? key}) : super(key: key);

  @override
  State<ReviewerTasksPage> createState() => _ReviewerTasksPageState();
}

class _ReviewerTasksPageState extends State<ReviewerTasksPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'جميع الملفات';
  List<String> _filterOptions = ['جميع الملفات', 'الأحدث', 'الأقدم'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading time for demonstration purposes
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  // Sort documents based on the selected filter
  List<DocumentSnapshot> _sortDocuments(List<DocumentSnapshot> documents) {
    if (_selectedFilter == 'الأحدث') {
      documents.sort((a, b) {
        final Timestamp aTime =
            (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        final Timestamp bTime =
            (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        return bTime.compareTo(aTime);
      });
    } else if (_selectedFilter == 'الأقدم') {
      documents.sort((a, b) {
        final Timestamp aTime =
            (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        final Timestamp bTime =
            (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
        return aTime.compareTo(bTime);
      });
    }
    return documents;
  }

  // Filter documents based on search query
  List<DocumentSnapshot> _filterDocuments(List<DocumentSnapshot> documents) {
    if (_searchQuery.isEmpty) return documents;

    return documents.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final fullName = (data['fullName'] ?? '').toString().toLowerCase();
      final about = (data['about'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return fullName.contains(query) || about.contains(query);
    }).toList();
  }

  // Function to start review process
  Future<void> _startReview(DocumentSnapshot document) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentDetailsPage(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current user to check position and name
    final currentUserProvider = Provider.of<CurrentUserProvider>(context);
    final currentUser = currentUserProvider.currentUser;
    final isReviewer = currentUser?.position == 'محكم';
    final reviewerName = currentUser?.name ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xffa86418),
        title: Text(
          'قائمة التحكيم',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'بإنتظار التحكيم'),
            Tab(text: 'تم التحكيم'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xffa86418)))
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'بحث عن ملف...',
                          prefixIcon:
                              Icon(Icons.search, color: Color(0xffa86418)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xffa86418)),
                          ),
                        ),
                        textDirection: ui.TextDirection.rtl,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      // Filter options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ترتيب حسب:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          DropdownButton<String>(
                            value: _selectedFilter,
                            icon: Icon(Icons.arrow_drop_down,
                                color: Color(0xffa86418)),
                            elevation: 16,
                            underline: Container(
                              height: 2,
                              color: Color(0xffa86418),
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedFilter = newValue;
                                });
                              }
                            },
                            items: _filterOptions
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Pending review tab
                      _buildReviewerFilesList(
                        reviewerName: reviewerName,
                        completed: false,
                        actionLabel: 'بدء التحكيم',
                        actionIcon: Icons.rate_review,
                      ),

                      // Completed review tab
                      _buildReviewerFilesList(
                        reviewerName: reviewerName,
                        completed: true,
                        actionLabel: 'عرض التقييم',
                        actionIcon: Icons.visibility,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildReviewerFilesList({
    required String reviewerName,
    required bool completed,
    String? actionLabel,
    IconData? actionIcon,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sent_documents')
          .where('status', isEqualTo: 'الي المحكمين')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: Color(0xffa86418)));
        }

        // First filter documents assigned to this reviewer
        List<DocumentSnapshot> allDocuments = snapshot.data!.docs;

        // Find documents where this reviewer is assigned
        List<DocumentSnapshot> assignedDocuments = allDocuments.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final List<dynamic> actionLog = data['actionLog'] ?? [];

          // Check if reviewer is assigned in any action log entry
          for (var action in actionLog) {
            if (action['action'] == 'الي المحكمين' &&
                action['reviewers'] != null) {
              List<Map<String, dynamic>> reviewers =
                  List<Map<String, dynamic>>.from(action['reviewers']);
              for (var reviewer in reviewers) {
                if (reviewer['username'] == reviewerName) {
                  return true;
                }
              }
            }
          }
          return false;
        }).toList();

        // Now filter based on whether the review is completed or not
        List<DocumentSnapshot> filteredDocuments =
            assignedDocuments.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final List<dynamic> actionLog = data['actionLog'] ?? [];

          // Check if this reviewer has submitted a review
          bool hasReviewed = false;
          for (var action in actionLog) {
            if (action['action'] == 'موافقة المحكم' &&
                action['userName'] == reviewerName) {
              hasReviewed = true;
              break;
            }
          }

          return hasReviewed == completed;
        }).toList();

        // Apply search filter and sorting
        filteredDocuments = _filterDocuments(filteredDocuments);
        filteredDocuments = _sortDocuments(filteredDocuments);

        if (filteredDocuments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined,
                    size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  completed
                      ? 'لا توجد ملفات تم تحكيمها'
                      : 'لا توجد ملفات بإنتظار التحكيم',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: filteredDocuments.length,
          itemBuilder: (context, index) {
            final doc = filteredDocuments[index];
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp).toDate();
            final formattedDate =
                DateFormat('yyyy-MM-dd • HH:mm').format(timestamp);

            // Find assignment date
            String assignmentDate = '';
            final List<dynamic> actionLog = data['actionLog'] ?? [];
            for (var i = actionLog.length - 1; i >= 0; i--) {
              if (actionLog[i]['action'] == 'الي المحكمين') {
                final assignTimestamp =
                    (actionLog[i]['timestamp'] as Timestamp).toDate();
                assignmentDate =
                    DateFormat('yyyy-MM-dd').format(assignTimestamp);
                break;
              }
            }

            // Find reviewer's status
            String reviewerStatus = 'في انتظار الموافقة';
            for (var action in actionLog) {
              if (action['action'] == 'الي المحكمين' &&
                  action['reviewers'] != null) {
                List<Map<String, dynamic>> reviewers =
                    List<Map<String, dynamic>>.from(action['reviewers']);
                for (var reviewer in reviewers) {
                  if (reviewer['username'] == reviewerName) {
                    reviewerStatus = reviewer['status'] ?? 'في انتظار الموافقة';
                    break;
                  }
                }
              }
            }

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _startReview(doc),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: ui.TextDirection.rtl,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              textDirection: ui.TextDirection.rtl,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person,
                                        size: 16, color: Color(0xffa86418)),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        data['fullName'] ?? 'غير معروف',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        textDirection: ui.TextDirection.rtl,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 14, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.purple, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 14,
                                  color: Colors.purple,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'الي المحكمين',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        data['about'] ?? 'لا يوجد وصف',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                        textDirection: ui.TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 12),
                      if (assignmentDate.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.assignment_turned_in,
                                size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              'تم التعيين في: $assignmentDate',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      if (completed)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 14, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'حالة التحكيم: $reviewerStatus',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      SizedBox(height: 16),
                      if (!completed &&
                          actionLabel != null &&
                          actionIcon != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _startReview(doc),
                              icon: Icon(actionIcon,
                                  color: Colors.white, size: 16),
                              label: Text(actionLabel,
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xffa86418),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
