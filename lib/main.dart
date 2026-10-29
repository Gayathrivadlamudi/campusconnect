import 'package:campusconnect/firebase_options.dart';
import 'package:campusconnect/utils/constants.dart';
import 'package:campusconnect/utils/init_routes.dart';
import 'package:campusconnect/utils/notification_service.dart';
import 'package:campusconnect/views/admin_home_view.dart';
import 'package:campusconnect/views/login_view.dart';
import 'package:campusconnect/views/student_home_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.initializeNotification();
  print("🔥 Firebase initialized successfully");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      getPages: routes,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              color: Colors.grey,
              child: SafeArea(
                child: Image.asset(
                  Constants.ImagePath + 'splashscreen.png',
                  fit: BoxFit.fill,
                  width: Get.width,
                  height: Get.height,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return RoleBasedHome(user: snapshot.data!);
        }

        return const LoginView();
      },
    );
  }
}

class RoleBasedHome extends StatelessWidget {
  final User user;

  const RoleBasedHome({required this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('userProfiles')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              color: Colors.grey,
              child: SafeArea(
                child: Image.asset(
                  Constants.ImagePath + 'splashscreen.png',
                  fit: BoxFit.fill,
                  width: Get.width,
                  height: Get.height,
                ),
              ),
            ),
          );
        }

        // If found in userProfiles → Student
        if (snapshot.hasData && snapshot.data!.exists) {
          return const StudentHomeView();
        }

        // Check adminProfiles collection
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('adminProfiles')
              .doc(user.uid)
              .get(),
          builder: (context, adminSnapshot) {
            if (adminSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Container(
                  color: Colors.grey,
                  child: SafeArea(
                    child: Image.asset(
                      Constants.ImagePath + 'splashscreen.png',
                      fit: BoxFit.fill,
                      width: Get.width,
                      height: Get.height,
                    ),
                  ),
                ),
              );
            }

            // If found in adminProfiles → Admin
            if (adminSnapshot.hasData && adminSnapshot.data!.exists) {
              return const AdminHomeView();
            }

            // Not found in either → Back to login
            return const LoginView();
          },
        );
      },
    );
  }
}
