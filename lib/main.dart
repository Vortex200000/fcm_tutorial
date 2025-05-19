import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebasemessaging/firebase_options.dart';
import 'package:firebasemessaging/notifications.dart';
import 'package:firebasemessaging/test.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _fireBackGroundHnadler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log(message.data.toString());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_fireBackGroundHnadler);

  NotificationServices notificationServices = NotificationServices();
  notificationServices.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fcm Demop',
      debugShowCheckedModeBanner: false,
      home: HomeFcmTest(),
    );
  }
}
