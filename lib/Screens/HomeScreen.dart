import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
        _pageController.jumpToPage(0);
      });
      return false;
    }
    return true;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Directionality(
        textDirection: TextDirection.rtl, // Set text direction to right-to-left
        child: Scaffold(
          backgroundColor: Colors.white,
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              buildHomePage(currentUser),
              buildTodoPage(),
              buildCalendarPage(),
              buildProfilePage(currentUser),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xffca791e),
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.task_alt),
                label: 'المهام',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.today),
                label: 'التقويم',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'الملف الشخصي',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white60,
            selectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
            unselectedLabelStyle: GoogleFonts.aBeeZee(fontSize: 12),
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }

  Widget buildHomePage(User? user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً بك،',
                    style: GoogleFonts.poppins(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.black38,
                    ),
                  ),
                  Text(
                    user?.displayName ?? "المستخدم",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  _onItemTapped(3);
                },
                child: Container(
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xffca791e),
                      width: 3.0,
                    ),
                  ),
                  alignment: Alignment.topRight,
                  child: CircleAvatar(
                    radius: 30.0,
                    backgroundColor: const Color(0xffca791e),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          buildQuickActions(),
          const SizedBox(height: 20),
          buildSectionDivider(),
          const SizedBox(height: 20),
          buildTodoPreview(),
        ],
      ),
    );
  }

  Widget buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: buildActionButton(
            title: 'العناصر',
            icon: Icons.list_alt,
            onPressed: () {
              // Navigate to Items page
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: buildActionButton(
            title: 'العملاء',
            icon: Icons.person,
            onPressed: () {
              // Navigate to Customers page
            },
          ),
        ),
      ],
    );
  }

  Widget buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xffa4392f), size: 36),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 2, color: Colors.black26)),
      ],
    );
  }

  Widget buildTodoPreview() {
    return GestureDetector(
      onTap: () {
        _onItemTapped(1);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "قائمة المهام",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "عرض وإدارة مهامك لهذا اليوم.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTodoPage() {
    return const Center(child: Text("صفحة المهام"));
  }

  Widget buildCalendarPage() {
    return const Center(child: Text("صفحة التقويم"));
  }

  Widget buildProfilePage(User? user) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "الملف الشخصي لـ ${user?.email ?? "المستخدم"}",
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, 'loginscreen');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.red, // Set the button color to red for logout
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            ),
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
