import 'dart:ui';
import 'package:arabic_font/arabic_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qiraat/Widgets/SnackBar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mainscreens/HomeScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late bool isnew;

  late SharedPreferences logindata;

  bool showSpinner = false;
  final _firestore = FirebaseFirestore.instance;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkIfAlreadyLogin();
  }

  Future<void> checkIfAlreadyLogin() async {
    logindata = await SharedPreferences.getInstance();
    isnew = (logindata.getBool('login') ?? true);
    if (isnew == false) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: const Color(0xffca791e),
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 70),
                    SizedBox(
                      height: 130,
                      child: Hero(
                        tag: 'logo',
                        child: Image.asset(
                          'images/logo2.png',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 20),
                                      const Text(
                                        'تسجيل الدخول',
                                        textAlign: TextAlign.center,
                                        style: ArabicTextStyle(
                                            arabicFont: ArabicFont.dubai,
                                            fontSize: 25,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(height: 20),
                                      TextField(
                                        controller: usernameController,
                                        textAlign: TextAlign.right,
                                        decoration: InputDecoration(
                                          hintText: 'اسم المستخدم',
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide.none,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.perm_identity,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      TextField(
                                        controller: passwordController,
                                        textAlign: TextAlign.right,
                                        obscureText: true,
                                        decoration: InputDecoration(
                                          hintText: 'كلمة المرور',
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide.none,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.lock,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () async {
                                          setState(() {
                                            showSpinner = true;
                                          });
                                          try {
                                            // Query Firestore to check credentials
                                            final querySnapshot =
                                                await _firestore
                                                    .collection('users')
                                                    .where('username',
                                                        isEqualTo:
                                                            usernameController
                                                                .text
                                                                .trim())
                                                    .where('password',
                                                        isEqualTo:
                                                            passwordController
                                                                .text
                                                                .trim())
                                                    .get();

                                            if (querySnapshot.docs.isNotEmpty) {
                                              // Successfully authenticated
                                              // Store user info in shared preferences or similar if needed
                                              final userData = querySnapshot
                                                  .docs.first
                                                  .data();

                                              logindata.setBool('login', false);
                                              logindata.setString('username',
                                                  userData['username']);
                                              logindata.setString('password',
                                                  userData['password']);
                                              logindata.setString(
                                                  'name', userData['fullName']);
                                              logindata.setString(
                                                  'email', userData['email']);
                                              logindata.setString("id",
                                                  querySnapshot.docs.first.id);
                                              logindata.setString(
                                                  'profilePicture',
                                                  userData['profileImageUrl']);
                                              logindata.setString('position',
                                                  userData['position']);

                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        HomeScreen()),
                                              );
                                            } else {
                                              showTopSnackBar(
                                                Overlay.of(context),
                                                CustomSnackBar.error(
                                                    message:
                                                        "اسم المستخدم او كلمة المرور غير صحيحه"),
                                              );
                                            }
                                          } catch (e) {
                                            showTopSnackBar(
                                              Overlay.of(context),
                                              CustomSnackBar.error(
                                                  message:
                                                      "Login Failed: ${e.toString()}"),
                                            );
                                          } finally {
                                            setState(() {
                                              showSpinner = false;
                                            });
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor:
                                              const Color(0xFFDD9C26),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 15),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: showSpinner
                                            ? const CircularProgressIndicator(
                                                color: Color(0xFFDD9C26),
                                              )
                                            : const Text(
                                                'تسجيل الدخول',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(height: 20),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context, "signup");
                                        },
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'تسجيل',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'ليس لديك حساب؟ ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
