import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:qiraat/Classes/current_user_providerr.dart';
import 'package:qiraat/Classes/myUser.dart';
import 'package:qiraat/Screens/Userspage.dart';
import 'package:qiraat/Screens/mainscreens/AddPage.dart';
import 'package:qiraat/Screens/mainscreens/HomePage.dart';
import 'package:qiraat/Screens/mainscreens/SearchPage.dart';
import 'package:qiraat/Screens/mainscreens/menuPage.dart';
import 'package:qiraat/Screens/mainscreens/profilePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Widget> _pages = [];
  late SharedPreferences logindata;
  bool _isHoveringOnSidebar = false;

  // Constants for sidebar width to prevent pixel errors
  final double _collapsedWidth = 70;
  final double _expandedWidth = 260;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(),
      UsersPage(),
      AddPage(),
      MenuPage(),
      ProfilePage(),
    ];
    initial();
  }

  void initial() async {
    logindata = await SharedPreferences.getInstance();

    setState(() {
      final currentUserProvider =
          Provider.of<CurrentUserProvider>(context, listen: false);
      currentUserProvider.setCurrentUser(
        myUser(
          username: logindata.getString('username') ?? '',
          password: logindata.getString('password') ?? '',
          name: logindata.getString('name') ?? '',
          email: logindata.getString('email') ?? '',
          id: logindata.getString('id') ?? '',
          profilePicture: logindata.getString('profilePic') ?? '',
          position: logindata.getString('position') ?? '',
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
                  )
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main Content - Always shows with sidebar
          Expanded(
            child: _pages[_selectedIndex],
          ),
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
                    right: BorderSide(
                      color: Color(0xffa86418),
                      width: 3,
                    ),
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
              Icon(
                icon,
                color: isSelected ? Color(0xffa86418) : Colors.grey,
              )
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
}
