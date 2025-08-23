import 'package:flutter/material.dart';
import 'package:qiraat/Screens/mainscreens/SettingsPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomHeader extends StatefulWidget {
  final bool isDesktop;
  final bool isSmall;

  const CustomHeader({
    super.key,
    this.isDesktop = false,
    this.isSmall = false,
  });

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> {
  String name = '';
  String position = '';
  String today = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final uname = prefs.getString('name') ?? 'مستخدم';
    final pos = prefs.getString('position') ?? '';

    final now = DateTime.now();
    today =
        "${now.year}-${now.month}-${now.day}"; // or use intl package for nicer format

    setState(() {
      name = uname;
      position = pos;
    });
  }

  String getFormattedDate() {
    final now = DateTime.now();
    return "${now.day}/${now.month}/${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = widget.isDesktop;
    final isSmall = widget.isSmall;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 20,
        vertical: isDesktop ? 50 : (isSmall ? 25 : 35),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
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
            color: Colors.black.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top bar with date + settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    getFormattedDate(),
                    style: TextStyle(
                      fontSize: isSmall ? 14 : 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: isSmall ? 22 : 26,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SettingPage()),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 50 : (isSmall ? 30 : 40)),

          // Welcome section
          Column(
            children: [
              Text(
                "مرحباً بعودتك،",
                style: TextStyle(
                  fontSize: isDesktop ? 24 : (isSmall ? 16 : 20),
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: TextStyle(
                  fontSize: isDesktop ? 40 : (isSmall ? 24 : 30),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(2.0, 2.0),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              if (position.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    position,
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : (isSmall ? 14 : 16),
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
