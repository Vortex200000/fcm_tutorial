import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class NotificationServices {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  NotificationServices() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  Future<void> requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        carPlay: true,
        sound: true,
        criticalAlert: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('user granted permission');
    } else {
      log('user denied permission');
    }
  }

  Future<void> fetchFcm() async {
    String? token = await _firebaseMessaging.getToken();
    print('your fcm token : $token');
  }

  Future<void> initializeLocalNotifications() async {
    AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
    );
  }

  void setUpFcmListenr() {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        _handleForegroundMessage(message);
      },
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    log(message.data.toString());
    _showIncomingNotification(message.data);
  }

  void _showIncomingNotification(Map<String, dynamic> message) {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('call_channel', 'Incoming calls',
            priority: Priority.high,
            playSound: true,
            importance: Importance.max);

    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    _flutterLocalNotificationsPlugin.show(0, 'Incoming Message',
        "sender :  ${message['body']}", notificationDetails);
  }

  Future<void> initialize() async {
    await requestPermissions();
    await fetchFcm();
    await initializeLocalNotifications();
    setUpFcmListenr();
  }

  Future<String?> getAccssToken() async {
    final adminSdkKey = {"YOUR-ADMIN-KEY"};

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    try {
      http.Client client = await auth.clientViaServiceAccount(
          auth.ServiceAccountCredentials.fromJson(adminSdkKey), scopes);

      auth.AccessCredentials credentials =
          await auth.obtainAccessCredentialsViaServiceAccount(
              auth.ServiceAccountCredentials.fromJson(adminSdkKey),
              scopes,
              client);

      client.close();
      log('Access Token => ${credentials.accessToken.data}');
      return credentials.accessToken.data;
    } catch (e) {
      log('Error occured while getting the access token $e');
      return null;
    }
  }

  Map<String, dynamic> getBody({
    required String fcmToken,
    required String title,
    required String body,
    required String userId,
    String? type,
  }) {
    return {
      "message": {
        "token": fcmToken,
        "notification": {"title": title, "body": body},
        "android": {
          "notification": {
            "notification_priority": "PRIORITY_MAX",
            "sound": "default",
          }
        },
        "apns": {
          "payload": {
            "aps": {"content_available": true}
          }
        },
        "data": {
          "type": type,
          "id": userId,
          "body": body,
          "click_action": "FLUTTER_NOTIFICATION_CLICK"
        }
      }
    };
  }

  Future<void> sendNotifications({
    required String fcmToken,
    required String title,
    required String body,
    required String userId,
    String? type,
  }) async {
    try {
      var serverKeyAuthorization = await getAccssToken();

      // change your project id
      const String urlEndPoint =
          "https://fcm.googleapis.com/v1/projects/YOUR-PROJECT-ID/messages:send";

      Dio dio = Dio();
      dio.options.headers['Content-Type'] = 'application/json';
      dio.options.headers['Authorization'] = 'Bearer $serverKeyAuthorization';

      var response = await dio.post(
        urlEndPoint,
        data: getBody(
          userId: userId,
          fcmToken: fcmToken,
          title: title,
          body: body,
          type: type ?? "message",
        ),
      );

      // Print response status code and body for debugging
      log('Response Status Code: ${response.statusCode}');
      log('Response Data: ${response.data}');
    } catch (e) {
      log("Error sending notification: $e");
    }
  }
}
