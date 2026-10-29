import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../models/hackathon.dart';
import '../views/hackathon_detail_view.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage msg) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message received');
  print(msg.notification?.title);

  // Show local notification in background
  NotificationService._showLocalNotification(msg);
}

class NotificationService {
  // Firebase Messaging instance for handling push notifications from Firebase Cloud Messaging
  static final FirebaseMessaging notificationMsg = FirebaseMessaging.instance;
  // Flutter Local Notifications plugin instance for showing local notifications on device
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initializes all notification handlers: local notification setup, permissions, and Firebase listeners
  static Future<void> initializeNotification() async {
    print("🔔 Initializing notifications...");
    // Initialize local notifications
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    // Initialize local notifications plugin with platform-specific settings and tap handler
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handleNotificationTap(response.payload!);
        }
      },
    );
    print("🔔 Local notifications initialized");

    // Request user permission for notifications and handle permission response
    print("🔔 Requesting notification permissions...");
    final settings = await notificationMsg.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print("🔔 Permission status: ${settings.authorizationStatus}");

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print("❌ Notification permission denied");
      return;
    }
    final fcmToken = await notificationMsg.getToken();

    print('FCM Token: $fcmToken');
    print("✅ Notification permission granted");
    // Subscribe to 'students' topic to receive targeted notifications for students
    await notificationMsg.subscribeToTopic("students");
    print("🔔 Subscribed to 'students' topic");

    // Handles notifications received while the app is in foreground - shows popup notification
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
      print("Title :${msg.notification?.title}");
      print("message body: ${msg.notification?.body}");
        // Show any notification, including manual announcements.
        if (msg.notification != null) {
          await _showLocalNotification(msg);
        }
      });


    // Handles notification taps when app is terminated/background - navigates to hackathon details
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) async {
        print('Student tapped a notification');

        final hackathonId = message.data['hackathonId'];

        print('Open hackathon: $hackathonId');

        if (hackathonId != null) {
          try {
            final doc = await FirebaseFirestore.instance
                .collection('hackthons')
                .doc(hackathonId)
                .get();

            if (doc.exists) {
              final hackathon = Hackathon.fromFirestore(doc);
              Get.to(
                const HackathonDetailView(),
                arguments: hackathon,
              );
            }
          } catch (e) {
            print('Error fetching hackathon: $e');
          }
        }
      },
    );
  }

  // Displays a platform-native local notification for background messages with proper Android/iOS formatting
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'hackathon_channel',
        'Hackathon Notifications',
        channelDescription: 'Notifications for hackathon updates',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      final hackathonId = message.data['hackathonId'] ?? '';

      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title ?? 'New Hackathon',
        message.notification?.body ?? 'Check out this hackathon!',
        notificationDetails,
        payload: hackathonId,
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  // Handles notification tap by fetching hackathon data and navigating to the hackathon detail view
  static Future<void> _handleNotificationTap(String hackathonId) async {
    if (hackathonId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('hackthons')
            .doc(hackathonId)
            .get();

        if (doc.exists) {
          final hackathon = Hackathon.fromFirestore(doc);
          Get.to(
            const HackathonDetailView(),
            arguments: hackathon,
          );
        }
      } catch (e) {
        print('Error handling notification tap: $e');
      }
    }
  }
}