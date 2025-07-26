import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  // Define the theme color
  final Color themeColor = const Color(0xffa86418);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Generate fallback avatar URL based on user name
  String _getGeneratedAvatarUrl(String userName) {
    String initials = userName.isNotEmpty
        ? Uri.encodeComponent(userName
            .split(' ')
            .take(2)
            .map((n) => n.isNotEmpty ? n[0] : '')
            .join(''))
        : 'U';
    return 'https://ui-avatars.com/api/?name=$initials&background=a86418&color=fff&size=120&font-size=0.6';
  }

  // Improved profile image widget with better web support
  Widget _buildProfileImage(String? imageUrl, String userName, String userId,
      {double size = 60}) {
    // Debug: Print the image URL
    print('Loading image for $userName: $imageUrl');

    return Hero(
      tag: 'user-$userId',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: themeColor.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: _buildImageWithFallback(imageUrl, userName, size),
        ),
      ),
    );
  }

  Widget _buildImageWithFallback(
      String? imageUrl, String userName, double size) {
    // If no image URL or it's empty, use generated avatar directly
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.network(
        _getGeneratedAvatarUrl(userName),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading generated avatar for $userName: $error');
          return _buildDefaultAvatar(size);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingAvatar(size, loadingProgress);
        },
      );
    }

    // Try to load the actual profile picture first
    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child; // Image loaded successfully
        }
        // Show loading indicator while image is loading
        return _buildLoadingAvatar(size, loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        print('Error loading profile image for $userName ($imageUrl): $error');
        // Fallback to generated avatar
        return Image.network(
          _getGeneratedAvatarUrl(userName),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error2, stackTrace2) {
            print('Error loading generated avatar for $userName: $error2');
            // Final fallback to default icon
            return _buildDefaultAvatar(size);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingAvatar(size, loadingProgress);
          },
        );
      },
    );
  }

  Widget _buildLoadingAvatar(double size, ImageChunkEvent? loadingProgress) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: themeColor.withOpacity(0.1),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            strokeWidth: 2,
            value: loadingProgress?.expectedTotalBytes != null
                ? loadingProgress!.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: themeColor.withOpacity(0.1),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: themeColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Set RTL direction
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'المستخدمين',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            // Add refresh button
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  // This will trigger a rebuild and refresh the StreamBuilder
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: themeColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: TextField(
                controller: _searchController,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'البحث عن مستخدمين...',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: _searchTerm.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                          color: Colors.grey.shade600,
                        )
                      : null,
                  suffixIcon: Icon(Icons.search, color: themeColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: themeColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: themeColor, width: 1.5),
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: themeColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'جاري تحميل المستخدمين...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'خطأ في تحميل البيانات',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'برجاء المحاولة مرة أخرى',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                // Refresh the page
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا يوجد مستخدمين',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'لم يتم العثور على أي مستخدمين في النظام',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter users based on search term
                  var users = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final fullName =
                        (data['fullName'] ?? '').toString().toLowerCase();
                    final position =
                        (data['position'] ?? '').toString().toLowerCase();
                    final email =
                        (data['email'] ?? '').toString().toLowerCase();
                    final username =
                        (data['username'] ?? '').toString().toLowerCase();
                    final searchLower = _searchTerm.toLowerCase();

                    return fullName.contains(searchLower) ||
                        position.contains(searchLower) ||
                        email.contains(searchLower) ||
                        username.contains(searchLower);
                  }).toList();

                  if (users.isEmpty && _searchTerm.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد نتائج لـ "$_searchTerm"',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'جرب البحث بكلمات مختلفة',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                            },
                            child: Text(
                              'مسح البحث',
                              style: TextStyle(color: themeColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: users.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final userData =
                          users[index].data() as Map<String, dynamic>;
                      final userId = users[index].id;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            // Navigate to user details or show user info dialog
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  _buildUserDetailsDialog(userData, userId),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // Profile Image with improved error handling
                                _buildProfileImage(
                                  userData['profileImageUrl'],
                                  userData['fullName'] ?? 'مستخدم',
                                  userId,
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userData['fullName'] ?? 'بدون اسم',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: themeColor.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            userData['position'] ?? 'بدون منصب',
                                            style: TextStyle(
                                              color:
                                                  themeColor.withOpacity(0.8),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.email_outlined,
                                              size: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                userData['email'] ??
                                                    'بدون بريد إلكتروني',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (userData['username'] != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.alternate_email,
                                                size: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  userData['username'],
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 14,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                PopupMenuButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: Colors.grey.shade700,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: Row(
                                        textDirection: TextDirection.rtl,
                                        children: [
                                          Icon(Icons.info_outline,
                                              color: themeColor, size: 20),
                                          const SizedBox(width: 12),
                                          const Text('التفاصيل'),
                                        ],
                                      ),
                                      onTap: () {
                                        // Show user details
                                        Future.delayed(
                                          Duration(milliseconds: 100),
                                          () => showDialog(
                                            context: context,
                                            builder: (context) =>
                                                _buildUserDetailsDialog(
                                                    userData, userId),
                                          ),
                                        );
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: Row(
                                        textDirection: TextDirection.rtl,
                                        children: [
                                          Icon(Icons.edit,
                                              color: themeColor, size: 20),
                                          const SizedBox(width: 12),
                                          const Text('تعديل'),
                                        ],
                                      ),
                                      onTap: () {
                                        // Edit user
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'ميزة التعديل قيد التطوير'),
                                            backgroundColor: themeColor,
                                          ),
                                        );
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: Row(
                                        textDirection: TextDirection.rtl,
                                        children: [
                                          Icon(Icons.message_outlined,
                                              color: themeColor, size: 20),
                                          const SizedBox(width: 12),
                                          const Text('مراسلة'),
                                        ],
                                      ),
                                      onTap: () {
                                        // Message user
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'ميزة المراسلة قيد التطوير'),
                                            backgroundColor: themeColor,
                                          ),
                                        );
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: Row(
                                        textDirection: TextDirection.rtl,
                                        children: const [
                                          Icon(Icons.delete_outline,
                                              color: Colors.red, size: 20),
                                          SizedBox(width: 12),
                                          Text('حذف',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                      onTap: () {
                                        // Delete user with confirmation
                                        Future.delayed(
                                          Duration(milliseconds: 100),
                                          () => _showDeleteConfirmation(
                                              userData, userId),
                                        );
                                      },
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // User details dialog with improved profile image
  Widget _buildUserDetailsDialog(Map<String, dynamic> userData, String userId) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large profile image with improved loading
              _buildProfileImage(
                userData['profileImageUrl'],
                userData['fullName'] ?? 'مستخدم',
                userId,
                size: 80,
              ),
              SizedBox(height: 16),
              Text(
                userData['fullName'] ?? 'بدون اسم',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              _buildDetailRow(Icons.work_outline, 'المنصب',
                  userData['position'] ?? 'بدون منصب'),
              _buildDetailRow(Icons.email_outlined, 'البريد الإلكتروني',
                  userData['email'] ?? 'بدون بريد'),
              if (userData['username'] != null)
                _buildDetailRow(Icons.alternate_email, 'اسم المستخدم',
                    userData['username']),
              if (userData['createdAt'] != null)
                _buildDetailRow(Icons.schedule, 'تاريخ التسجيل',
                    _formatDate(userData['createdAt'])),
              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'إغلاق',
                  style: TextStyle(color: themeColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: themeColor),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'غير محدد';
    try {
      if (timestamp is Timestamp) {
        DateTime date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'غير محدد';
    } catch (e) {
      return 'غير محدد';
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> userData, String userId) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تأكيد الحذف'),
          content: Text(
              'هل أنت متأكد من حذف المستخدم "${userData['fullName'] ?? 'هذا المستخدم'}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Implement delete functionality here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ميزة الحذف قيد التطوير'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: Text(
                'حذف',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
