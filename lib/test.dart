import 'package:firebasemessaging/notifications.dart';
import 'package:flutter/material.dart';

class HomeFcmTest extends StatelessWidget {
  const HomeFcmTest({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();
    NotificationServices notificationServices = NotificationServices();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        spacing: 50,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: controller,
          ),
          ElevatedButton(
              onPressed: () async {
                await notificationServices.sendNotifications(
                  userId: '123',
                  fcmToken: controller.text,
                  title: 'Incoming Message',
                  body: 'Hi',
                );
              },
              child: Text('Send'))
        ],
      ),
    );
  }
}
