import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:push_app/config/router/app_router.dart';
import 'package:push_app/main.dart';

class LocalNotifications {
  static Future<void> requestPermissionsLocalNotifications() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
  }

  static Future<void> initializeLocalNotifications() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const initializationSettingsAndroid = AndroidInitializationSettings(
      'app_icon',
    );
    // TODO: iOS configuration

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      //TODO: iOS configuration settings
    );

    // app_icon: viene de la carpeta android\app\src\main\res\drawable
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        //TODO:
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  static void showLocalNotification({
    required id,
    String? title,
    String? body,
    String? data,
  }) {
    const androidDetails = AndroidNotificationDetails(
      'channelId',
      'channelName',
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      // TODO: iOS configuration
    );

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: data,
    );
  }

  static void onDidReceiveNotificationResponse(NotificationResponse response) {
    logger.d('onDidReceiveNotificationResponse: $response');
    appRouter.push('/push-details/${response.payload}');
  }
}
