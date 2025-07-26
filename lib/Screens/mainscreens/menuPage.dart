import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../Document_Handling/Sent_documents.dart';
import '../Userspage.dart';
import 'IncomingFilesScreen.dart';
import 'SettingsPage.dart';
import 'Tasks/EditorChef_TaskPage.dart';
import 'Tasks/HeadOfEditors.dart';
import 'Tasks/Reviewer_TaskPage.dart';
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
  int incomingFilesCount = 0;

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

    // Load incoming files count after user data is loaded
    if (_canViewIncomingFiles()) {
      _loadIncomingFilesCount();
    }
  }

  // Check if user can view incoming files
  bool _canViewIncomingFiles() {
    return position == 'سكرتير تحرير' ||
        position == 'مدير التحرير' ||
        position == 'رئيس التحرير';
  }

  // Load count of incoming files
  Future<void> _loadIncomingFilesCount() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('sent_documents')
          .where('status', isEqualTo: 'ملف مرسل')
          .get();

      if (mounted) {
        setState(() {
          incomingFilesCount = snapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error loading incoming files count: $e');
    }
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
              bool isSmall = constraints.maxHeight < 600;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 80 : 20,
                        vertical: isDesktop ? 40 : (isSmall ? 15 : 20),
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
                                      fontSize: isSmall ? 12 : 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
                                    size: isSmall ? 20 : 24,
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
                              height: isDesktop ? 40 : (isSmall ? 20 : 30)),
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
                                            : (isSmall ? 14 : 16),
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
                                            : (isSmall ? 20 : 24),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                                                : (isSmall ? 12 : 14),
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!isDesktop) SizedBox(width: 20),
                              Container(
                                width: isDesktop ? 120 : (isSmall ? 70 : 88),
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
                                  radius: isDesktop ? 56 : (isSmall ? 31 : 40),
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
                      padding:
                          EdgeInsets.all(isDesktop ? 80 : (isSmall ? 12 : 20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick actions section
                          Text(
                            "الإجراءات السريعة",
                            style: TextStyle(
                              fontSize: isDesktop ? 24 : (isSmall ? 18 : 20),
                              fontWeight: FontWeight.bold,
                              color: Color(0xff2d3748),
                            ),
                          ),
                          SizedBox(height: isSmall ? 12 : 20),

                          // Grid layout for action cards
                          LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount =
                                  isDesktop ? 4 : (isTablet ? 3 : 2);

                              double cardWidth =
                                  constraints.maxWidth / crossAxisCount;
                              double cardHeight =
                                  isDesktop ? 160 : (isSmall ? 110 : 140);
                              double aspectRatio = cardWidth / cardHeight;

                              List<Widget> actionCards = [
                                ModernActionCard(
                                  title: "المهام",
                                  icon: Icons.task_alt,
                                  color: Color(0xff4299e1),
                                  onTap: navigateToTasksPage,
                                  isSmall: isSmall,
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
                                    final Uri url =
                                        Uri.parse('https://qiraatafrican.com/');
                                    await launchUrl(url);
                                  },
                                  isSmall: isSmall,
                                ),
                              ];

                              // Add incoming files card if user has permission
                              if (_canViewIncomingFiles()) {
                                actionCards.insert(
                                    0,
                                    ModernActionCard(
                                      title: "الملفات الواردة",
                                      icon: Icons.inbox,
                                      color: Color(0xffe53e3e),
                                      onTap: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                IncomingFilesPage(),
                                          ),
                                        );
                                        // Refresh count when returning from incoming files page
                                        if (result == true) {
                                          _loadIncomingFilesCount();
                                        }
                                      },
                                      isSmall: isSmall,
                                      notificationCount: incomingFilesCount,
                                    ));
                              }

                              return GridView.count(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: isSmall ? 8 : 16,
                                mainAxisSpacing: isSmall ? 8 : 16,
                                childAspectRatio: aspectRatio.clamp(0.7, 1.5),
                                children: actionCards,
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

// Modern Action Card Widget - Updated to support notification badge
class ModernActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isSmall;
  final int? notificationCount;

  const ModernActionCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isSmall = false,
    this.notificationCount,
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
              child: Stack(
                children: [
                  AnimatedContainer(
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
                      padding: EdgeInsets.all(widget.isSmall ? 8 : 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(widget.isSmall ? 8 : 16),
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              widget.icon,
                              size: widget.isSmall ? 20 : 32,
                              color: widget.color,
                            ),
                          ),
                          SizedBox(height: widget.isSmall ? 8 : 16),
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: widget.isSmall ? 4 : 8),
                              child: Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: widget.isSmall ? 11 : 14,
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
                  // Notification badge
                  if (widget.notificationCount != null &&
                      widget.notificationCount! > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          widget.notificationCount! > 99
                              ? '99+'
                              : widget.notificationCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
