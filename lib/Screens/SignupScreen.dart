import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:qiraat/Widgets/SnackBar.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();

  String selectedPosition = 'سكرتير تحرير'; // Default position
  String selectedMohakkemType = 'سياسي'; // Default محكم type
  String finalPosition = 'سكرتير تحرير'; // Final position to be saved
  File? profileImage; // Selected image file
  bool showSpinner = false;
  bool _obscureText = true;

  // Color theme
  final Color primaryColor = const Color(0xffa86418);
  final Color accentColor = const Color(0xffd7a45d);
  final Color backgroundColor = const Color(0xfffaf6f0);

  final List<String> positions = [
    'سكرتير تحرير',
    'مدير التحرير',
    'محكم',
    'رئيس التحرير',
  ];

  final List<String> mohakkemTypes = [
    'سياسي',
    'اقتصادي',
    'اجتماعي',
  ];

  @override
  void initState() {
    super.initState();
    // Ensure Firebase is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Any Firebase operations after the frame is built
    });
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70, // Compress image
      );

      if (pickedFile != null) {
        setState(() {
          profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: "خطأ في اختيار الصورة."),
        );
      }
    }
  }

  Future<String?> uploadImage(String userId) async {
    try {
      if (profileImage == null) return null;

      print("Starting image upload for user: $userId");
      final ref = _storage.ref().child('profile_pictures/$userId.jpg');

      // Add upload task monitoring
      UploadTask uploadTask = ref.putFile(profileImage!);

      // Monitor upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print(
            'Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      });

      // Wait for completion
      TaskSnapshot snapshot = await uploadTask;
      print("Image upload completed");

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print("Download URL obtained: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: "خطأ في رفع الصورة"),
        );
      }
      return null;
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      print("Checking username availability for: $username");
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      bool available = querySnapshot.docs.isEmpty;
      print("Username available: $available");
      return available;
    } catch (e) {
      print("Error checking username: $e");
      return false;
    }
  }

  // Update finalPosition based on selections
  void updateFinalPosition() {
    if (selectedPosition == 'محكم') {
      setState(() {
        finalPosition = 'محكم $selectedMohakkemType';
      });
    } else {
      setState(() {
        finalPosition = selectedPosition;
      });
    }
    print("Final position updated to: $finalPosition");
  }

  Future<void> signUpUser() async {
    print("Starting signup process...");

    if (_formKey.currentState!.validate()) {
      print("Form validation passed");

      if (profileImage == null) {
        print("No profile image selected");
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: "برجاء اختيار صورة شخصية"),
        );
        return;
      }

      setState(() {
        showSpinner = true;
      });

      try {
        print("Checking username availability...");
        bool usernameAvailable =
            await isUsernameAvailable(usernameController.text.trim());

        if (!usernameAvailable) {
          print("Username not available");
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(
                message:
                    "اسم المستخدم مسجل لحساب آخر، برجاء ادخال اسم مستخدم آخر"),
          );
          setState(() {
            showSpinner = false;
          });
          return;
        }

        print("Creating Firebase Auth user...");
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        print("Firebase Auth user created: ${userCredential.user?.uid}");

        final String userId = userCredential.user!.uid;

        print("Uploading profile image...");
        String? profileImageUrl;
        if (profileImage != null) {
          profileImageUrl = await uploadImage(userId);
          if (profileImageUrl == null) {
            print("Image upload failed, but continuing...");
          }
        }

        // Make sure finalPosition is updated
        updateFinalPosition();

        print("Saving user data to Firestore...");
        await _firestore.collection('users').doc(userId).set({
          'email': emailController.text.trim(),
          'username': usernameController.text.trim(),
          'fullName': fullNameController.text.trim(),
          'position': finalPosition,
          'profileImageUrl': profileImageUrl,
          'uid': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print("User data saved successfully");

        // Update display name in Firebase Auth
        await userCredential.user!
            .updateDisplayName(fullNameController.text.trim());
        print("Display name updated");

        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(message: "تم التسجيل بنجاح"),
        );

        print("Signup completed successfully");
        Navigator.pop(context); // Navigate back
      } on FirebaseAuthException catch (e) {
        print("FirebaseAuthException: ${e.code} - ${e.message}");
        String errorMessage = "خطأ في التسجيل";

        switch (e.code) {
          case 'weak-password':
            errorMessage = "كلمة المرور ضعيفة جداً";
            break;
          case 'email-already-in-use':
            errorMessage = "البريد الإلكتروني مستخدم بالفعل";
            break;
          case 'invalid-email':
            errorMessage = "البريد الإلكتروني غير صحيح";
            break;
          case 'operation-not-allowed':
            errorMessage = "التسجيل غير مسموح حالياً";
            break;
          case 'network-request-failed':
            errorMessage = "خطأ في الاتصال بالإنترنت";
            break;
          default:
            errorMessage = "خطأ: ${e.message}";
        }

        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: errorMessage),
        );
      } catch (e) {
        print("General error creating user: $e");
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: "خطأ غير متوقع: $e"),
        );
      } finally {
        setState(() {
          showSpinner = false;
        });
        print("Signup process finished");
      }
    } else {
      print("Form validation failed");
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          TextDirection.rtl, // Set RTL direction for the entire screen
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('إنشاء حساب جديد',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: primaryColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryColor.withOpacity(0.1), backgroundColor],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 30),
                    // Profile Image Selection
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: pickImage,
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: profileImage != null
                                  ? FileImage(profileImage!)
                                  : null,
                              child: profileImage == null
                                  ? Icon(Icons.person,
                                      size: 60, color: primaryColor)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0, // Changed from right to left for RTL
                            child: GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: backgroundColor,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Full Name Field
                    TextFormField(
                      controller: fullNameController,
                      decoration: InputDecoration(
                        labelText: 'الاسم الكامل',
                        suffixIcon: Icon(Icons.person, color: primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'برجاء إدخال الاسم الكامل';
                        }
                        if (value.trim().length < 2) {
                          return 'الاسم يجب أن يكون حرفين على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Username Field
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'اسم المستخدم',
                        suffixIcon:
                            Icon(Icons.alternate_email, color: primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'برجاء إدخال اسم المستخدم';
                        }
                        if (value.trim().length < 3) {
                          return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
                        }
                        // Check for valid characters
                        if (!RegExp(r'^[a-zA-Z0-9_]+$')
                            .hasMatch(value.trim())) {
                          return 'اسم المستخدم يجب أن يحتوي على أحرف وأرقام فقط';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        suffixIcon: Icon(Icons.email, color: primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'برجاء إدخال البريد الإلكتروني';
                        }
                        // Better email validation
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value.trim())) {
                          return 'برجاء إدخال بريد إلكتروني صحيح';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        suffixIcon: Icon(Icons.lock, color: primaryColor),
                        prefixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: primaryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'برجاء إدخال كلمة المرور';
                        }
                        if (value.length < 6) {
                          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Position Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPosition,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedPosition = newValue!;
                              updateFinalPosition();
                            });
                          },
                          items: positions
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(value),
                              ),
                            );
                          }).toList(),
                          isExpanded: true,
                          hint: const Text("اختر المنصب"),
                          icon:
                              Icon(Icons.arrow_drop_down, color: primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // محكم Type Dropdown (only shown when محكم is selected)
                    if (selectedPosition == 'محكم')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(right: 8.0, bottom: 4.0),
                            child: Text(
                              'اختر نوع المحكم',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedMohakkemType,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedMohakkemType = newValue!;
                                    updateFinalPosition();
                                  });
                                },
                                items: mohakkemTypes
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(value),
                                    ),
                                  );
                                }).toList(),
                                isExpanded: true,
                                hint: const Text("اختر نوع المحكم"),
                                icon: Icon(Icons.arrow_drop_down,
                                    color: primaryColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 30),

                    // Sign Up Button
                    ElevatedButton(
                      onPressed: showSpinner ? null : signUpUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: showSpinner
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'تسجيل حساب جديد',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Login Redirect
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'لديك حساب بالفعل؟',
                          style: TextStyle(color: Colors.black87),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
