// 本地通知服务
// 封装 flutter_local_notifications 的初始化、权限申请、调度、取消

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // 初始化
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  // 请求 Android 13+ 通知权限
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    final result = await android.requestNotificationsPermission();
    return result ?? false;
  }

  // 安排一次性通知
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'riji_reminder',
      '提醒',
      channelDescription: '备忘录和任务的提醒通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails: details,
      // 用非精确模式，避免 Android 12+ 的 SCHEDULE_EXACT_ALARM 权限
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // 安排提醒（支持每日重复，用于重复任务）
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool repeatDaily = false,
  }) async {
    // 如果时间已过，推到明天
    var date = scheduledDate;
    final now = DateTime.now();
    if (date.isBefore(now)) {
      date = DateTime(date.year, date.month, date.day + 1,
          date.hour, date.minute);
    }

    final tzDate = tz.TZDateTime.from(date, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'riji_reminder',
      '提醒',
      channelDescription: '备忘录和任务的提醒通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // repeatDaily=true 时每天同一时刻重复
      matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
    );
  }

  // 取消指定通知
  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  // 取消所有通知
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
