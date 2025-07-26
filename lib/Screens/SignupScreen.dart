import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';

import '../Widgets/SnackBar.dart';

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

  // Image handling for both web and mobile
  File? profileImageFile; // For mobile
  Uint8List? profileImageBytes; // For web
  String? profileImageName; // Image name for both platforms
  bool showSpinner = false;
  bool _obscureText = true;

  // Color theme
  final Color primaryColor = const Color(0xffa86418);
  final Color accentColor = const Color(0xffd7a45d);
  final Color backgroundColor = const Color(0xfffaf6f0);

  // Updated positions list with new roles
  final List<String> positions = [
    'سكرتير تحرير',
    'مدير التحرير',
    'رئيس التحرير',
    'محكم',
    'المدقق اللغوي',
    'الاخراج الفني والتصميم',
  ];

  final List<String> mohakkemTypes = [
    'سياسي',
    'اقتصادي',
    'اجتماعي',
  ];

  // Position descriptions for better UX
  final Map<String, String> positionDescriptions = {
    'سكرتير تحرير': 'يراجع ويدير المستندات في المراحل الأولية والنهائية',
    'مدير التحرير': 'يشرف على عملية التحرير وتعيين المحكمين',
    'رئيس التحرير': 'يتخذ القرارات النهائية للموافقة على النشر',
    'محكم': 'يراجع ويقيم المحتوى الأكاديمي للمستندات',
    'المدقق اللغوي': 'يراجع ويصحح الأخطاء اللغوية والنحوية',
    'الاخراج الفني والتصميم': 'يتولى التصميم والإخراج الفني للمستندات',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Any Firebase operations after the frame is built
    });
  }

  // Generate fallback avatar URL based on user name
  String _getGeneratedAvatarUrl(String userName) {
    String initials = userName.isNotEmpty
        ? Uri.encodeComponent(userName
            .split(' ')
            .take(2)
            .map((n) => n.isNotEmpty ? n[0] : '')
            .join(''))
        : 'U';
    return 'https://ui-avatars.com/api/?name=$initials&background=a86418&color=fff&size=200&font-size=0.6';
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          profileImageName = pickedFile.name;
        });

        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            profileImageBytes = bytes;
            profileImageFile = null;
          });
        } else {
          setState(() {
            profileImageFile = File(pickedFile.path);
            profileImageBytes = null;
          });
        }
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
      if (profileImageFile == null && profileImageBytes == null) return null;

      print("Starting image upload for user: $userId");
      final ref = _storage.ref().child('profile_pictures/$userId.jpg');

      UploadTask uploadTask;

      if (kIsWeb && profileImageBytes != null) {
        uploadTask = ref.putData(
          profileImageBytes!,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'uploaded-by': userId},
          ),
        );
      } else if (profileImageFile != null) {
        uploadTask = ref.putFile(
          profileImageFile!,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'uploaded-by': userId},
          ),
        );
      } else {
        throw Exception('No image data available for upload');
      }

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: "خطأ في رفع الصورة: ${e.toString()}"),
        );
      }
      return null;
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print("Error checking username: $e");
      return false;
    }
  }

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
  }

  Widget _buildProfileImageWidget() {
    if (kIsWeb && profileImageBytes != null) {
      return ClipOval(
        child: Image.memory(
          profileImageBytes!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else if (!kIsWeb && profileImageFile != null) {
      return ClipOval(
        child: Image.file(
          profileImageFile!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Icon(Icons.person, size: 60, color: primaryColor);
    }
  }

  Future<void> signUpUser() async {
    if (_formKey.currentState!.validate()) {
      if (profileImageFile == null && profileImageBytes == null) {
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
        bool usernameAvailable =
            await isUsernameAvailable(usernameController.text.trim());

        if (!usernameAvailable) {
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

        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final String userId = userCredential.user!.uid;

        String? profileImageUrl;
        if (profileImageFile != null || profileImageBytes != null) {
          profileImageUrl = await uploadImage(userId);
          if (profileImageUrl == null) {
            profileImageUrl =
                _getGeneratedAvatarUrl(fullNameController.text.trim());
          }
        }

        updateFinalPosition();

        await _firestore.collection('users').doc(userId).set({
          'email': emailController.text.trim(),
          'username': usernameController.text.trim(),
          'fullName': fullNameController.text.trim(),
          'position': finalPosition,
          'profileImageUrl': profileImageUrl,
          'uid': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        await userCredential.user!
            .updateDisplayName(fullNameController.text.trim());

        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(message: "تم التسجيل بنجاح"),
        );

        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
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
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: "خطأ غير متوقع: $e"),
        );
      } finally {
        setState(() {
          showSpinner = false;
        });
      }
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
      textDirection: TextDirection.rtl,
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

                    // Profile Image Section
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: pickImage,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: profileImageFile != null ||
                                      profileImageBytes != null
                                  ? _buildProfileImageWidget()
                                  : Icon(Icons.person,
                                      size: 60, color: primaryColor),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: backgroundColor, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (profileImageName != null)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            profileImageName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

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

                    // Position Selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المنصب',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
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
                              items: positions.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        value,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                      if (positionDescriptions
                                          .containsKey(value))
                                        Text(
                                          positionDescriptions[value]!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              isExpanded: true,
                              hint: const Text("اختر المنصب"),
                              icon: Icon(Icons.arrow_drop_down,
                                  color: primaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // محكم Type Selection (only shown when محكم is selected)
                    if (selectedPosition == 'محكم')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نوع المحكم',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
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
                                    child: Text(value),
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
                        const Text('لديك حساب بالفعل؟',
                            style: TextStyle(color: Colors.black87)),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold),
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
