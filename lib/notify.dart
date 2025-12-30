import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  //Init
  Future<void> initNotify() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    final TimezoneInfo currentTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTz.identifier));

    notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    const initSettingsAndroid = AndroidInitializationSettings(
      "@mipmap/ic_launcher",
    );

    const initSettingsLinux = LinuxInitializationSettings(
      defaultActionName: "Okay",
    );

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      linux: initSettingsLinux,
    );

    await notificationsPlugin.initialize(initSettings);

    _isInitialized = true;
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        "reminder_channel_id",
        "medi reminder",
        channelDescription: "Recurring reminders to take medications",
        importance: Importance.max,
        styleInformation: DefaultStyleInformation(false, false),
      ),
      linux: LinuxNotificationDetails(),
    );
  }

  //show notif

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    return notificationsPlugin.show(id, title, body, notificationDetails());
  }

  // Future<void> scheduleDailyNotification({
  //   int id = 0,
  //   String? title,
  //   String? body,
  // }) {}

  Future<void> scheduleNotification({
    int id = 1,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  void resetAll() {
    notificationsPlugin.cancelAllPendingNotifications();
  }

  Future<void> scheduleDailyNotification({
    int id = 1,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
    );

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
