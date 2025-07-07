import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qiraat/Screens/LoginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String name = '';
  String email = '';
  String username = '';
  String position = '';
  String id = '';
  bool isLoading = true;
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;

  // App theme colors
  final Color primaryColor = const Color(0xffa86418);
  final Color backgroundColor = const Color(0xfffaf6f0);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final SharedPreferences logindata = await SharedPreferences.getInstance();
    setState(() {
      name = logindata.getString('name') ?? 'المستخدم';
      email = logindata.getString('email') ?? '';
      username = logindata.getString('username') ?? '';
      position = logindata.getString('position') ?? '';
      id = logindata.getString('id') ?? '';
      notificationsEnabled = logindata.getBool('notifications') ?? true;
      darkModeEnabled = logindata.getBool('darkMode') ?? false;
      isLoading = false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'تسجيل الخروج',
            textDirection: ui.TextDirection.rtl,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'هل أنت متأكد من أنك تريد تسجيل الخروج؟',
            textDirection: ui.TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'إلغاء',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('تسجيل الخروج'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primaryColor),
                SizedBox(height: 16),
                Text(
                  'جاري تسجيل الخروج...',
                  textDirection: ui.TextDirection.rtl,
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();

      // Clear all stored data
      final SharedPreferences logindata = await SharedPreferences.getInstance();
      await logindata.clear();

      // Close the loading indicator
      Navigator.pop(context);

      // Navigate to LoginScreen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      // Close the loading indicator
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تسجيل الخروج: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            'الإعدادات',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: primaryColor,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User information section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'معلومات الحساب',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                              textDirection: ui.TextDirection.rtl,
                            ),
                            SizedBox(height: 16),

                            // Name
                            ListTile(
                              leading: Icon(Icons.person, color: primaryColor),
                              title: Text(
                                'الاسم',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(name),
                              dense: true,
                            ),
                            Divider(color: Colors.grey[300]),

                            // Username
                            if (username.isNotEmpty) ...[
                              ListTile(
                                leading: Icon(Icons.alternate_email,
                                    color: primaryColor),
                                title: Text(
                                  'اسم المستخدم',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(username),
                                dense: true,
                              ),
                              Divider(color: Colors.grey[300]),
                            ],

                            // Email
                            ListTile(
                              leading: Icon(Icons.email, color: primaryColor),
                              title: Text(
                                'البريد الإلكتروني',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(email),
                              dense: true,
                            ),

                            // Position
                            if (position.isNotEmpty) ...[
                              Divider(color: Colors.grey[300]),
                              ListTile(
                                leading: Icon(Icons.work, color: primaryColor),
                                title: Text(
                                  'المنصب',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(position),
                                dense: true,
                              ),
                            ],

                            // User ID
                            if (id.isNotEmpty) ...[
                              Divider(color: Colors.grey[300]),
                              ListTile(
                                leading: Icon(Icons.badge, color: primaryColor),
                                title: Text(
                                  'معرف المستخدم',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(id),
                                dense: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // App preferences section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تفضيلات التطبيق',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                              textDirection: ui.TextDirection.rtl,
                            ),
                            SizedBox(height: 8),

                            // Notifications
                            SwitchListTile(
                              title: Text(
                                'الإشعارات',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                'تفعيل أو إلغاء تفعيل الإشعارات',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                              secondary: Icon(Icons.notifications,
                                  color: primaryColor),
                              value: notificationsEnabled,
                              activeColor: primaryColor,
                              onChanged: (value) {
                                setState(() {
                                  notificationsEnabled = value;
                                });
                                _savePreference('notifications', value);
                              },
                            ),

                            // Dark Mode
                            SwitchListTile(
                              title: Text(
                                'الوضع الليلي',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                'تفعيل أو إلغاء تفعيل الوضع الليلي',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                              secondary:
                                  Icon(Icons.dark_mode, color: primaryColor),
                              value: darkModeEnabled,
                              activeColor: primaryColor,
                              onChanged: (value) {
                                setState(() {
                                  darkModeEnabled = value;
                                });
                                _savePreference('darkMode', value);

                                // Show snackbar for future implementation
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'سيتم تطبيق الوضع الليلي في التحديث القادم',
                                      textDirection: ui.TextDirection.rtl,
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // App info section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'معلومات التطبيق',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                              textDirection: ui.TextDirection.rtl,
                            ),
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.info, color: primaryColor),
                              title: Text(
                                'نسخة التطبيق',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text('1.0.0'),
                              dense: true,
                            ),
                            Divider(color: Colors.grey[300]),
                            ListTile(
                              leading: Icon(Icons.help, color: primaryColor),
                              title: Text(
                                'المساعدة والدعم',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'قريباً - صفحة المساعدة والدعم',
                                      textDirection: ui.TextDirection.rtl,
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              dense: true,
                            ),
                            Divider(color: Colors.grey[300]),
                            ListTile(
                              leading:
                                  Icon(Icons.privacy_tip, color: primaryColor),
                              title: Text(
                                'سياسة الخصوصية',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'قريباً - سياسة الخصوصية',
                                      textDirection: ui.TextDirection.rtl,
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              dense: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32),

                    // Logout button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: Icon(Icons.logout, color: Colors.white),
                        label: Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}
