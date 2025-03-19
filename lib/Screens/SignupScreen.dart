import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();

  String selectedPosition = 'سكرتير تحرير'; // Default position
  File? profileImage; // Selected image file
  bool showSpinner = false;

  final List<String> positions = [
    'سكرتير تحرير',
    'مدير التحرير',
    'محكم',
    'رئيس التحرير',
  ];

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          profileImage = File(pickedFile.path);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected.')),
        );
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error selecting image.')),
      );
    }
  }

  Future<String?> uploadImage(String userId) async {
    try {
      final ref = _storage.ref().child('profile_pictures/$userId.jpg');
      await ref.putFile(profileImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    return querySnapshot.docs.isEmpty;
  }

  Future<void> signUpUser() async {
    if (emailController.text.isEmpty ||
        usernameController.text.isEmpty ||
        fullNameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: "برجاء تعبئه كل المعلومات"),
      );
      return;
    }

    if (profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile image.')),
      );
      return;
    }

    setState(() {
      showSpinner = true;
    });

    try {
      // Check if username already exists
      bool usernameAvailable =
          await isUsernameAvailable(usernameController.text.trim());

      if (!usernameAvailable) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
              message:
                  "اسم المستخدم مسجل لحساب آخر، برجاء ادخال اسم مستخدم آخر "),
        );
        setState(() {
          showSpinner = false;
        });
        return;
      }

      // Generate a unique user ID
      final String userId = _firestore.collection('users').doc().id;

      // Upload profile image
      String? profileImageUrl;
      if (profileImage != null) {
        profileImageUrl = await uploadImage(userId);
      }

      // Save user data to Firestore
      await _firestore.collection('users').doc(userId).set({
        'email': emailController.text.trim(),
        'username': usernameController.text.trim(),
        'password': passwordController.text
            .trim(), // Note: storing passwords in plaintext is not secure
        'fullName': fullNameController.text.trim(),
        'position': selectedPosition,
        'profileImageUrl': profileImageUrl,
        'uid': userId,
      });

      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.success(message: "تم التسجيل بنجاح"),
      );

      Navigator.pop(context); // Navigate back
    } catch (e) {
      print("Error creating user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        showSpinner = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const SizedBox(height: 40),
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    profileImage != null ? FileImage(profileImage!) : null,
                child: profileImage == null
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Email',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                hintText: 'Username',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(
                hintText: 'Full Name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedPosition,
              onChanged: (String? newValue) {
                setState(() {
                  selectedPosition = newValue!;
                });
              },
              items: positions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              isExpanded: true,
              hint: const Text("Select Position"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: signUpUser,
              child: showSpinner
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Sign Up'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
