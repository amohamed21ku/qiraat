import 'dart:ui';
import 'package:arabic_font/arabic_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qiraat/Screens/reviewerFirstPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../App_Constants.dart';
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
  bool _obscureText = true;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkIfAlreadyLogin();
  }

  Future<void> checkIfAlreadyLogin() async {
    logindata = await SharedPreferences.getInstance();

    // Check if user is already signed in with Firebase Auth
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      // User is signed in, navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
      return;
    }

    // Check legacy SharedPreferences method (for backwards compatibility)
    isnew = (logindata.getBool('login') ?? true);
    if (isnew == false) {
      // Legacy login found, but verify with Firebase Auth
      String? storedEmail = logindata.getString('email');
      if (storedEmail != null && currentUser == null) {
        // Clear legacy data and require re-login
        await logindata.clear();
      }
    }
  }

  Future<String?> getEmailFromUsername(String username) async {
    try {
      print("Looking up email for username: $username");
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String email = querySnapshot.docs.first.data()['email'];
        print("Found email: $email");
        return email;
      } else {
        print("No user found with username: $username");
        return null;
      }
    } catch (e) {
      print("Error looking up username: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserDataByUID(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  Future<void> loginUser() async {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برجاء إدخال اسم المستخدم وكلمة المرور'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      showSpinner = true;
    });

    try {
      print("Starting login process for username: $username");

      // First, get the email associated with this username
      String? email = await getEmailFromUsername(username);

      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اسم المستخدم غير موجود'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          showSpinner = false;
        });
        return;
      }

      print("Attempting Firebase Auth login with email: $email");

      // Sign in with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(
          "Firebase Auth login successful for UID: ${userCredential.user?.uid}");

      // Get user data from Firestore
      Map<String, dynamic>? userData =
          await getUserDataByUID(userCredential.user!.uid);

      if (userData != null) {
        await logindata.setBool('login', false);
        await logindata.setString('username', userData['username'] ?? '');
        await logindata.setString('name', userData['fullName'] ?? '');
        await logindata.setString('email', userData['email'] ?? '');
        await logindata.setString('id', userCredential.user!.uid);
        await logindata.setString(
            'profilePicture', userData['profileImageUrl'] ?? '');
        await logindata.setString('position', userData['position'] ?? '');

        final position = (userData['position'] ?? '').toString();

        final bool isReviewer = position == AppConstants.POSITION_REVIEWER ||
            position.contains('محكم');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                isReviewer ? const ReviewerTasksPage() : HomeScreen(),
          ),
        );
        return;
      } else {
        // This shouldn't happen, but handle it just in case
        await _auth.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في استرجاع بيانات المستخدم'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");
      String errorMessage = 'خطأ في تسجيل الدخول';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'لا يوجد مستخدم بهذا البريد الإلكتروني';
          break;
        case 'wrong-password':
          errorMessage = 'كلمة المرور غير صحيحة';
          break;
        case 'invalid-email':
          errorMessage = 'البريد الإلكتروني غير صحيح';
          break;
        case 'user-disabled':
          errorMessage = 'تم تعطيل هذا الحساب';
          break;
        case 'too-many-requests':
          errorMessage = 'محاولات كثيرة جداً، حاول مرة أخرى لاحقاً';
          break;
        case 'network-request-failed':
          errorMessage = 'خطأ في الاتصال بالإنترنت';
          break;
        case 'invalid-credential':
          errorMessage = 'اسم المستخدم أو كلمة المرور غير صحيحة';
          break;
        default:
          errorMessage = 'خطأ: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print("General error during login: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ غير متوقع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        showSpinner = false;
      });
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
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
                                          color: Colors.white,
                                        ),
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
                                        textInputAction: TextInputAction.next,
                                      ),
                                      const SizedBox(height: 15),
                                      TextField(
                                        controller: passwordController,
                                        textAlign: TextAlign.right,
                                        obscureText: _obscureText,
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
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureText
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureText = !_obscureText;
                                              });
                                            },
                                          ),
                                        ),
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) => loginUser(),
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed:
                                            showSpinner ? null : loginUser,
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
                                          elevation: 2,
                                        ),
                                        child: showSpinner
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Color(0xFFDD9C26),
                                                  strokeWidth: 3,
                                                ),
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
                                        onTap: showSpinner
                                            ? null
                                            : () {
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
