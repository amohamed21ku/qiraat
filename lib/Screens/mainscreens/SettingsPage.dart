import 'package:flutter/material.dart';
import 'package:qiraat/Screens/LoginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String name = '';
  String email = '';
  String id = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final SharedPreferences logindata = await SharedPreferences.getInstance();
    setState(() {
      name = logindata.getString('name') ?? 'User';
      email = logindata.getString('email') ?? '';
      id = logindata.getString('id') ?? '';
      isLoading = false;
    });
  }

  Future<void> _logout() async {
    final SharedPreferences logindata = await SharedPreferences.getInstance();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Clear all stored data
    await logindata.clear();

    // Close the loading indicator
    Navigator.pop(context);

    // Navigate to the LoginScreen and remove all previous routes
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Color(0xFF234D67),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
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
                            'Account Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          ListTile(
                            leading:
                                Icon(Icons.person, color: Color(0xFF234D67)),
                            title: Text('Name'),
                            subtitle: Text(name),
                            dense: true,
                          ),
                          Divider(),
                          ListTile(
                            leading:
                                Icon(Icons.email, color: Color(0xFF234D67)),
                            title: Text('Email'),
                            subtitle: Text(email),
                            dense: true,
                          ),
                          if (id.isNotEmpty) ...[
                            Divider(),
                            ListTile(
                              leading:
                                  Icon(Icons.badge, color: Color(0xFF234D67)),
                              title: Text('ID'),
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
                            'App Preferences',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SwitchListTile(
                            title: Text('Notifications'),
                            secondary: Icon(Icons.notifications,
                                color: Color(0xFF234D67)),
                            value: true,
                            onChanged: (value) {
                              // Implement notification settings
                            },
                          ),
                          SwitchListTile(
                            title: Text('Dark Mode'),
                            secondary:
                                Icon(Icons.dark_mode, color: Color(0xFF234D67)),
                            value: false,
                            onChanged: (value) {
                              // Implement dark mode
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Spacing
                  Spacer(),

                  // Logout button
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
