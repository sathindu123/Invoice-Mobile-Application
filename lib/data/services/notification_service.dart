import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/reminder_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  /// Request permission (Android 13+)
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'reminder_channel',
    'Reminders',
    channelDescription: 'Invoice Pro Reminders',
    importance: Importance.high,
    priority: Priority.high,
    autoCancel: false,
    actions: [
      AndroidNotificationAction('dismiss', 'Dismiss'),
    ],
  );

  static const DarwinNotificationDetails _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const NotificationDetails _notifDetails = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  /// Schedule a notification for a reminder
  static Future<int> scheduleReminderNotification(Reminder reminder) async {
    await initialize();

    final notifId = reminder.id.hashCode.abs() % 100000;

    final scheduledDate = tz.TZDateTime.from(
      reminder.reminderDate,
      tz.local,
    );

    final now = tz.TZDateTime.now(tz.local);
    final isInFuture = scheduledDate.isAfter(now);

    final bodyText = [
      if (reminder.clientName.isNotEmpty) 'Customer: ${reminder.clientName}',
      if (reminder.itemDescription.isNotEmpty) 'Item: ${reminder.itemDescription}',
      if (reminder.description.isNotEmpty) reminder.description,
    ].join(' | ');

    final title = '🔔 ${reminder.title}';
    final body = bodyText.isNotEmpty ? bodyText : 'Reminder due today';

    if (isInFuture) {
      await _plugin.zonedSchedule(
        id: notifId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } else {
      await _plugin.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: _notifDetails,
      );
    }

    return notifId;
  }

  /// Cancel a notification by ID
  static Future<void> cancelNotification(int notifId) async {
    await _plugin.cancel(id: notifId);
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
