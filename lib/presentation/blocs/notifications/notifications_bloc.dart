import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:push_app/domain/entities/push_message.dart';

import 'package:push_app/firebase_options.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

var logger = Logger();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  logger.d("Handling a background message: ${message.messageId}");
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  int _pushMessageId = 0;

  final Future<void> Function()? requestLocalNotificationPermissions;
  final void Function({
    required int id,
    String? title,
    String? body,
    String? data,
  })? showLocalNotification;

  NotificationsBloc({
    this.requestLocalNotificationPermissions,
    this.showLocalNotification,
  }) : super(const NotificationsState()) {
    on<NotificationStatusChanged>(_notificationStatusChanged);

    on<NotificationReceived>(_onPushMessageRecived);
    // verificar estado de las notificaciones
    _initialStatusCheck();
    // Listener para notificaciones en segundo plano
    _onForegroundMessage();
  }

  static Future<void> initializeFCM() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void _notificationStatusChanged(
      NotificationStatusChanged event, Emitter<NotificationsState> emit) {
    emit(state.copyWith(status: event.status));
    _getFCMToken();
  }

  void _onPushMessageRecived(
      NotificationReceived event, Emitter<NotificationsState> emit) {
    emit(state.copyWith(notifications: [
      event.pushMessage,
      ...state.notifications,
    ]));
    _getFCMToken();
  }

  void _initialStatusCheck() async {
    final settings = await messaging.getNotificationSettings();
    add(NotificationStatusChanged(settings.authorizationStatus));
  }

  void _getFCMToken() async {
    if (state.status != AuthorizationStatus.authorized) return;
    final token = await messaging.getToken();
    logger.d('Token: $token');
  }

  void handleRemoteMessage(RemoteMessage message) {
    logger.d('Meesage data: ${message.data}');

    if (message.notification == null) return;

    final notification = PushMessage(
      messageId:
          message.messageId?.replaceAll(':', '').replaceAll('%', '') ?? '',
      title: message.notification!.title ?? '',
      body: message.notification!.body ?? '',
      sentDate: message.sentTime ?? DateTime.now(),
      data: message.data,
      imageUrl: Platform.isAndroid
          ? message.notification!.android?.imageUrl
          : message.notification!.apple?.imageUrl,
    );

    logger.d('Message also contained a notification: $notification');
    if (showLocalNotification != null) {
      showLocalNotification!(
        id: ++_pushMessageId,
        title: notification.title,
        body: notification.body,
        data: notification.messageId,
      );
    }

    //  add nuevo evento para notificaciones
    add(NotificationReceived(notification));
  }

  void _onForegroundMessage() {
    FirebaseMessaging.onMessage.listen(handleRemoteMessage);
  }

  void requestPermissions() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    // Solicitar permisos para notificaciones locales
    if (requestLocalNotificationPermissions != null) {
      await requestLocalNotificationPermissions!();
    }
    //await LocalNotifications.requestPermissionsLocalNotifications();
    // Mandar el evento de cambio de estado
    add(NotificationStatusChanged(settings.authorizationStatus));
  }

  PushMessage? getMessageById(String id) {
    final exists =
        state.notifications.any((element) => element.messageId == id);
    if (!exists) return null;
    return state.notifications.firstWhere((element) => element.messageId == id);
  }
}
