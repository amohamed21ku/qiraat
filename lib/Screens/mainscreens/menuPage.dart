import 'package:flutter/material.dart';
import 'package:qiraat/Screens/Document_Handling/Sent_documents.dart';
import 'package:qiraat/Screens/TaskPage.dart';

import 'package:qiraat/Screens/mainscreens/SettingsPage.dart';
import 'package:qiraat/Screens/Userspage.dart';
import 'package:qiraat/Screens/widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Import the task pages

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // User data from shared preferences
  String name = '';
  String profilePicture = '';
  String id = '';
  String email = '';
  String position = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
        MaterialPageRoute(
          builder: (context) => SecretaryTasksPage(),
        ),
      );
    } else if (position == 'مدير التحرير') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditorChiefTasksPage(),
        ),
      );
    } else if (position == 'محكم') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewerTasksPage(),
        ),
      );
    } else {
      // Default page or error handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا توجد صفحة مهام لهذا المستخدم')),
      );
    }
  }

  // Format time as "14:00"
  String formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  // Format date as "Friday 7 March"
  String formatDate(DateTime dateTime) {
    String day = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ][dateTime.weekday % 7];
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
    ][dateTime.month - 1];
    return "$day ${dateTime.day} $month";
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
      return Center(child: CircularProgressIndicator());
    }

    // Mock events data (since we're not using Firebase)
    List<Map<String, dynamic>> events = [
      {
        'name': 'اجتماع مجلس الطلاب',
        'time': '14:00',
        'location': 'القاعة الرئيسية',
        'date': 'اليوم'
      },
      {
        'name': 'معرض المهن',
        'time': '10:00',
        'location': 'المبنى أ',
        'date': 'غداً'
      },
      {
        'name': 'ورشة عمل: تطوير فلاتر',
        'time': '15:30',
        'location': 'المعمل 342',
        'date': 'الجمعة 22 مارس'
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xffcc9657), Color(0xffa86418)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getFormattedDate(),
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SettingPage()),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "مرحباً بعودتك،",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (position.isNotEmpty)
                            Text(
                              position,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.purple, Colors.orange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(profilePicture),
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 20),
                  // Events list
                  Container(
                    height: 115,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        var event = events[index];
                        return EventContainer(
                          eventName: event["name"],
                          eventTime: event["time"],
                          eventPlace: event["location"],
                          eventDate: event["date"],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomCardButton(
                              title: "جميع الملفات المرسله",
                              icon: Icons.document_scanner,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          SentDocumentsPage()),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: CustomCardButton(
                              title: "الموقع",
                              icon: Icons.web,
                              onTap: () async {
                                final Uri url =
                                    Uri.parse('https://qiraatafrican.com/');
                                await launchUrl(url);
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CustomCardButton(
                              title: "المستخدمون",
                              icon: Icons.supervised_user_circle_sharp,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => UsersPage()),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: CustomCardButton(
                              title: "المهام",
                              icon: Icons.task,
                              onTap:
                                  navigateToTasksPage, // Use the function here
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
