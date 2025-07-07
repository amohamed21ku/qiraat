import 'package:flutter/material.dart';
import 'package:qiraat/Screens/Document_Handling/Sent_documents.dart';
import 'package:qiraat/Screens/mainscreens/Tasks/Reviewer_TaskPage.dart';
import 'package:qiraat/Screens/mainscreens/SettingsPage.dart';
import 'package:qiraat/Screens/Userspage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Tasks/EditorChef_TaskPage.dart';
import 'Tasks/HeadOfEditors.dart';
import 'Tasks/Secertery_TaskPage.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  // User data from shared preferences
  String name = '';
  String profilePicture = '';
  String id = '';
  String email = '';
  String position = '';
  bool isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Load user data from shared preferences
  Future<void> _loadUserData() async {
    final SharedPreferences logindata = await SharedPreferences.getInstance();
    setState(() {
      name = logindata.getString('name') ?? 'مستخدم';
      profilePicture = logindata.getString('profilePicture') ??
          'https://via.placeholder.com/150';
      id = logindata.getString('id') ?? '';
      email = logindata.getString('email') ?? '';
      position = logindata.getString('position') ?? '';
      isLoading = false;
    });
  }

  // Navigate to the appropriate tasks page based on the user's position
  void navigateToTasksPage() {
    if (position == 'سكرتير تحرير') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SecretaryTasksPage()),
      );
    } else if (position == 'مدير التحرير') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditorChiefTasksPage()),
      );
    } else if (position.contains('محكم')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReviewerTasksPage()),
      );
    } else if (position == 'رئيس التحرير') {
      // Updated: Navigate to Head of Editors task page instead of reviewer page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HeadOfEditorsTasksPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا توجد صفحة مهام لهذا المستخدم'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String getFormattedDate() {
    DateTime now = DateTime.now();
    String day = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ][now.weekday % 7];
    String month = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ][now.month - 1];
    return "$day ${now.day} $month ${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xffcc9657)),
              ),
              SizedBox(height: 20),
              Text(
                'جاري التحميل...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mock events data
    List<Map<String, dynamic>> events = [
      {
        'name': 'اجتماع المجلة',
        'time': '14:00',
        'location': 'القاعة الرئيسية',
        'date': 'اليوم',
        'color': Colors.blue.shade400,
        'icon': Icons.meeting_room,
      },
      {
        'name': 'معرض الكتاب',
        'time': '10:00',
        'location': 'المبنى أ',
        'date': 'غداً',
        'color': Colors.green.shade400,
        'icon': Icons.menu_book,
      },
      {
        'name': 'إخراج النسخة الجديدة',
        'time': '15:30',
        'location': 'المعمل 342',
        'date': 'الجمعة 22 مارس',
        'color': Colors.purple.shade400,
        'icon': Icons.publish,
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xfff8f9fa),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 1024;
              bool isTablet = constraints.maxWidth > 768;
              bool isSmall =
                  constraints.maxHeight < 600; // Added small screen detection

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 80 : 20,
                        vertical: isDesktop
                            ? 40
                            : (isSmall
                                ? 15
                                : 20), // Reduced padding on small screens
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xffcc9657),
                            Color(0xffa86418),
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
                        children: [
                          // Top bar with date and settings
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                // Added Flexible wrapper
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    getFormattedDate(),
                                    style: TextStyle(
                                      fontSize: isSmall
                                          ? 12
                                          : 14, // Reduced font size on small screens
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow
                                        .ellipsis, // Added overflow handling
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.settings_outlined,
                                    color: Colors.white,
                                    size: isSmall
                                        ? 20
                                        : 24, // Reduced icon size on small screens
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SettingPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height: isDesktop
                                  ? 40
                                  : (isSmall
                                      ? 20
                                      : 30)), // Reduced spacing on small screens
                          // User profile section
                          Row(
                            mainAxisAlignment: isDesktop
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: isDesktop ? 0 : 1,
                                child: Column(
                                  crossAxisAlignment: isDesktop
                                      ? CrossAxisAlignment.center
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "مرحباً بعودتك،",
                                      style: TextStyle(
                                        fontSize: isDesktop
                                            ? 20
                                            : (isSmall
                                                ? 14
                                                : 16), // Responsive font size
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: isDesktop
                                            ? 32
                                            : (isSmall
                                                ? 20
                                                : 24), // Responsive font size
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                      overflow: TextOverflow
                                          .ellipsis, // Added overflow handling
                                    ),
                                    if (position.isNotEmpty) ...[
                                      SizedBox(height: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          position,
                                          style: TextStyle(
                                            fontSize: isDesktop
                                                ? 16
                                                : (isSmall
                                                    ? 12
                                                    : 14), // Responsive font size
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow
                                              .ellipsis, // Added overflow handling
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!isDesktop) SizedBox(width: 20),
                              Container(
                                width: isDesktop
                                    ? 120
                                    : (isSmall
                                        ? 70
                                        : 88), // Responsive avatar size
                                height: isDesktop ? 120 : (isSmall ? 70 : 88),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 0,
                                      blurRadius: 15,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(4),
                                child: CircleAvatar(
                                  radius: isDesktop
                                      ? 56
                                      : (isSmall
                                          ? 31
                                          : 40), // Responsive radius
                                  backgroundImage: NetworkImage(profilePicture),
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Main content
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isDesktop
                          ? 80
                          : (isSmall ? 12 : 20)), // Responsive padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Events section
                          if (events.isNotEmpty) ...[
                            Text(
                              "الأحداث القادمة",
                              style: TextStyle(
                                fontSize: isDesktop
                                    ? 24
                                    : (isSmall
                                        ? 18
                                        : 20), // Responsive font size
                                fontWeight: FontWeight.bold,
                                color: Color(0xff2d3748),
                              ),
                            ),
                            SizedBox(
                                height:
                                    isSmall ? 12 : 20), // Responsive spacing
                            Container(
                              height: isDesktop
                                  ? 160
                                  : (isSmall ? 120 : 140), // Responsive height
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: events.length,
                                itemBuilder: (context, index) {
                                  var event = events[index];
                                  return Container(
                                    width: isDesktop
                                        ? 300
                                        : (isSmall
                                            ? 200
                                            : 250), // Responsive width
                                    margin: EdgeInsets.only(left: 16),
                                    child: ModernEventCard(
                                      eventName: event["name"],
                                      eventTime: event["time"],
                                      eventPlace: event["location"],
                                      eventDate: event["date"],
                                      color: event["color"],
                                      icon: event["icon"],
                                      isSmall:
                                          isSmall, // Pass small screen flag
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                                height: isDesktop
                                    ? 60
                                    : (isSmall
                                        ? 24
                                        : 40)), // Responsive spacing
                          ],

                          // Quick actions section
                          Text(
                            "الإجراءات السريعة",
                            style: TextStyle(
                              fontSize: isDesktop
                                  ? 24
                                  : (isSmall ? 18 : 20), // Responsive font size
                              fontWeight: FontWeight.bold,
                              color: Color(0xff2d3748),
                            ),
                          ),
                          SizedBox(
                              height: isSmall ? 12 : 20), // Responsive spacing

                          // Grid layout for action cards
                          LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount =
                                  isDesktop ? 4 : (isTablet ? 3 : 2);

                              // Better aspect ratio calculation that considers screen height
                              double cardWidth =
                                  constraints.maxWidth / crossAxisCount;
                              double cardHeight = isDesktop
                                  ? 160
                                  : (isSmall ? 110 : 140); // Responsive height
                              double aspectRatio = cardWidth / cardHeight;

                              return GridView.count(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing:
                                    isSmall ? 8 : 16, // Responsive spacing
                                mainAxisSpacing: isSmall ? 8 : 16,
                                childAspectRatio: aspectRatio.clamp(
                                    0.7, 1.5), // Clamp aspect ratio for safety
                                children: [
                                  ModernActionCard(
                                    title: "المهام",
                                    icon: Icons.task_alt,
                                    color: Color(0xff4299e1),
                                    onTap: navigateToTasksPage,
                                    isSmall: isSmall, // Pass small screen flag
                                  ),
                                  ModernActionCard(
                                    title: "جميع الملفات المرسلة",
                                    icon: Icons.folder_copy_outlined,
                                    color: Color(0xff48bb78),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SentDocumentsPage(),
                                        ),
                                      );
                                    },
                                    isSmall: isSmall,
                                  ),
                                  ModernActionCard(
                                    title: "المستخدمون",
                                    icon: Icons.people_outline,
                                    color: Color(0xff9f7aea),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => UsersPage(),
                                        ),
                                      );
                                    },
                                    isSmall: isSmall,
                                  ),
                                  ModernActionCard(
                                    title: "الموقع",
                                    icon: Icons.language,
                                    color: Color(0xffed8936),
                                    onTap: () async {
                                      final Uri url = Uri.parse(
                                        'https://qiraatafrican.com/',
                                      );
                                      await launchUrl(url);
                                    },
                                    isSmall: isSmall,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Modern Event Card Widget
class ModernEventCard extends StatelessWidget {
  final String eventName;
  final String eventTime;
  final String eventPlace;
  final String eventDate;
  final Color color;
  final IconData icon;
  final bool isSmall; // Added small screen flag

  const ModernEventCard({
    Key? key,
    required this.eventName,
    required this.eventTime,
    required this.eventPlace,
    required this.eventDate,
    required this.color,
    required this.icon,
    this.isSmall = false, // Default to false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: isSmall ? 40 : 60, // Responsive header height
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: isSmall ? 24 : 32, // Responsive icon size
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isSmall ? 8 : 16), // Responsive padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    // Added Flexible wrapper
                    child: Text(
                      eventName,
                      style: TextStyle(
                        fontSize: isSmall ? 12 : 16, // Responsive font size
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2d3748),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: isSmall ? 4 : 8), // Responsive spacing
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: isSmall ? 12 : 14, // Responsive icon size
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            // Added Flexible wrapper
                            child: Text(
                              "$eventTime • $eventDate",
                              style: TextStyle(
                                fontSize:
                                    isSmall ? 10 : 12, // Responsive font size
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow
                                  .ellipsis, // Added overflow handling
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: isSmall ? 12 : 14, // Responsive icon size
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              eventPlace,
                              style: TextStyle(
                                fontSize:
                                    isSmall ? 10 : 12, // Responsive font size
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Action Card Widget
class ModernActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isSmall; // Added small screen flag

  const ModernActionCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isSmall = false, // Default to false
  }) : super(key: key);

  @override
  _ModernActionCardState createState() => _ModernActionCardState();
}

class _ModernActionCardState extends State<ModernActionCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? widget.color.withOpacity(0.3)
                          : Colors.black.withOpacity(0.05),
                      spreadRadius: _isHovered ? 2 : 0,
                      blurRadius: _isHovered ? 20 : 10,
                      offset: Offset(0, _isHovered ? 8 : 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                      widget.isSmall ? 8 : 16), // Responsive padding
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Added to prevent overflow
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                            widget.isSmall ? 8 : 16), // Responsive padding
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          size:
                              widget.isSmall ? 20 : 32, // Responsive icon size
                          color: widget.color,
                        ),
                      ),
                      SizedBox(
                          height:
                              widget.isSmall ? 8 : 16), // Responsive spacing
                      Flexible(
                        // Added Flexible wrapper
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  widget.isSmall ? 4 : 8), // Responsive padding
                          child: Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: widget.isSmall
                                  ? 11
                                  : 14, // Responsive font size
                              fontWeight: FontWeight.w600,
                              color: Color(0xff2d3748),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
