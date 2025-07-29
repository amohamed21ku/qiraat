// Updated HomeScreen.dart - Stage 1 Workflow Navigation
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:qiraat/Screens/mainscreens/profilePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Classes/current_user_providerr.dart';
import '../../Classes/myUser.dart';
import '../Userspage.dart';
import 'AddPage.dart';
import 'HomePage.dart';
import 'menuPage.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 3;
  List<Widget> _pages = [];
  late SharedPreferences logindata;
  bool _isHoveringOnSidebar = false;
  String userPosition = '';

  // Constants for sidebar width to prevent pixel errors
  final double _collapsedWidth = 70;
  final double _expandedWidth = 260;

  @override
  void initState() {
    super.initState();
    _pages = [HomePage(), UsersPage(), AddPage(), MenuPage(), ProfilePage()];
    initial();
  }

  void initial() async {
    logindata = await SharedPreferences.getInstance();

    setState(() {
      userPosition = logindata.getString('position') ?? '';

      final currentUserProvider = Provider.of<CurrentUserProvider>(
        context,
        listen: false,
      );
      currentUserProvider.setCurrentUser(
        myUser(
          username: logindata.getString('username') ?? '',
          password: logindata.getString('password') ?? '',
          name: logindata.getString('name') ?? '',
          email: logindata.getString('email') ?? '',
          id: logindata.getString('id') ?? '',
          profilePicture: logindata.getString('profilePic') ?? '',
          position: userPosition,
        ),
      );
    });
  }

  void _changeIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Persistent Sidebar
          MouseRegion(
            onEnter: (_) => setState(() => _isHoveringOnSidebar = true),
            onExit: (_) => setState(() => _isHoveringOnSidebar = false),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: _isHoveringOnSidebar ? _expandedWidth : _collapsedWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // App Logo
                  Container(
                    color: _isHoveringOnSidebar
                        ? Color(0xeea86418)
                        : Colors.transparent,
                    height: 70,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: _isHoveringOnSidebar
                        ? Image.asset(
                      'images/logo2.png',
                    ).animate().fadeIn(duration: 200.ms)
                        : Icon(
                      Icons.menu_book,
                      color: Color(0xffa86418),
                      size: 30,
                    ),
                  ),
                  Divider(height: 1),

                  // Sidebar Items
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      children: [
                        _buildSidebarItem(0, Icons.home, "الرئيسية"),
                        _buildSidebarItem(1, Icons.search, "البحث"),
                        _buildSidebarItem(2, Icons.add_circle_outline, "إضافة"),
                        _buildSidebarItem(3, Icons.list_alt, "القائمة"),
                        _buildSidebarItem(4, Icons.person, "الملف"),

                        // Stage 1 Workflow Section (if expanded)
                        if (_isHoveringOnSidebar && _hasWorkflowAccess()) ...[
                          Divider(height: 20),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Text(
                              'المرحلة الأولى: الموافقة',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          _buildWorkflowSidebarItem(
                            Icons.assignment_ind,
                            "مهام السكرتير",
                            _canAccessSecretaryTasks(),
                          ),
                          _buildWorkflowSidebarItem(
                            Icons.supervisor_account,
                            "مهام مدير التحرير",
                            _canAccessEditorTasks(),
                          ),
                          _buildWorkflowSidebarItem(
                            Icons.admin_panel_settings,
                            "مهام رئيس التحرير",
                            _canAccessHeadEditorTasks(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // User role indicator (if expanded)
                  if (_isHoveringOnSidebar && userPosition.isNotEmpty)
                    Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xffa86418).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xffa86418).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getUserRoleIcon(),
                            color: Color(0xffa86418),
                            size: 24,
                          ),
                          SizedBox(height: 8),
                          Text(
                            userPosition,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xffa86418),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                ],
              ),
            ),
          ),
          // Main Content - Always shows with sidebar
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _changeIndex(index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          height: 50,
          decoration: BoxDecoration(
            color: isSelected
                ? Color(0xffa86418).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border(
              right: BorderSide(color: Color(0xffa86418), width: 3),
            )
                : null,
          ),
          padding: EdgeInsets.symmetric(horizontal: 20),
          alignment:
          _isHoveringOnSidebar ? Alignment.centerRight : Alignment.center,
          child: Row(
            mainAxisSize:
            _isHoveringOnSidebar ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? Color(0xffa86418) : Colors.grey)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .then()
                  .scale(duration: 300.ms),
              if (_isHoveringOnSidebar) SizedBox(width: 0),
              if (_isHoveringOnSidebar)
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Color(0xffa86418) : Colors.grey,
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ).animate().fadeIn(duration: 200.ms),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowSidebarItem(IconData icon, String label, bool canAccess) {
    if (!_isHoveringOnSidebar) return SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canAccess ? () => _navigateToWorkflowTask(label) : null,
        child: Container(
          height: 45,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                icon,
                color: canAccess ? Color(0xffa86418) : Colors.grey.shade400,
                size: 18,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: canAccess ? Color(0xffa86418) : Colors.grey.shade400,
                    fontWeight: canAccess ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!canAccess)
                Icon(
                  Icons.lock_outline,
                  color: Colors.grey.shade400,
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  bool _hasWorkflowAccess() {
    return userPosition == 'سكرتير تحرير' ||
        userPosition == 'مدير التحرير' ||
        userPosition == 'رئيس التحرير';
  }

  bool _canAccessSecretaryTasks() {
    return userPosition == 'سكرتير تحرير';
  }

  bool _canAccessEditorTasks() {
    return userPosition == 'مدير التحرير';
  }

  bool _canAccessHeadEditorTasks() {
    return userPosition == 'رئيس التحرير';
  }

  IconData _getUserRoleIcon() {
    switch (userPosition) {
      case 'سكرتير تحرير':
        return Icons.assignment_ind;
      case 'مدير التحرير':
        return Icons.supervisor_account;
      case 'رئيس التحرير':
        return Icons.admin_panel_settings;
      case 'محكم سياسي':
      case 'محكم اقتصادي':
      case 'محكم اجتماعي':
        return Icons.rate_review;
      case 'محرر لغوي':
        return Icons.spellcheck;
      case 'مصمم إخراج':
        return Icons.design_services;
      case 'مراجع نهائي':
        return Icons.fact_check;
      default:
        return Icons.person;
    }
  }

  void _navigateToWorkflowTask(String taskType) {
    // This would navigate to the appropriate task page
    // For now, just switch to the menu page which handles task navigation
    _changeIndex(3);

    // Show a snackbar indicating the task type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('الانتقال إلى $taskType'),
        backgroundColor: Color(0xffa86418),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }
}