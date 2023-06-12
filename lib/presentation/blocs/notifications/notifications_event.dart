part of 'notifications_bloc.dart';

abstract class NotificationsEvent {
  const NotificationsEvent();
}

class NotificationStatusChanged extends NotificationsEvent {
  final AuthorizationStatus status;

  const NotificationStatusChanged(this.status);
}

// Notificacion recibida
class NotificationReceived extends NotificationsEvent {
  final PushMessage pushMessage;
  const NotificationReceived(this.pushMessage);
}
