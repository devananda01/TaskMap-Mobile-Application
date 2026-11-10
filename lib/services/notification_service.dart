import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/task_model.dart';

/// Schedules and cancels the four fixed local-notification reminders
/// (2 days / 1 day / 6 hours / 1 hour before a task's deadline).
///
/// Every public method is a safe no-op on Flutter Web — the
/// flutter_local_notifications plugin has no web implementation, so we
/// guard early rather than let the app crash.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _channelId = 'taskmap_deadline_reminders';
  static const _channelName = 'Deadline Reminders';
  static const _channelDescription =
      'Reminders for upcoming TaskMap task deadlines';

  //for testing purpose i changes the days to minutes and hours to secs
  static const List<_ReminderOffset> _offsets = [
    _ReminderOffset(Duration(minutes: 2), 'due in 2 days', 1),
    _ReminderOffset(Duration(minutes: 1), 'due tomorrow', 2),
    _ReminderOffset(Duration(seconds: 30), 'due in 6 hours', 3),
    _ReminderOffset(Duration(seconds: 10), 'due in 1 hour', 4),
  ];

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    tz_data.initializeTimeZones();
    _setLocalTimeZoneFromOffset();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  Future<void> requestPermission() async {
    if (kIsWeb) return;

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Cancels any existing reminders for this task, then schedules whichever
  /// of the four fixed reminders still fall in the future. Safe to call
  /// even if reminders are disabled or the task is already done — it will
  /// just clear old ones and schedule nothing.
  Future<void> scheduleTaskReminders(TaskModel task) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();

    await cancelTaskReminders(task.id);

    if (!task.reminderEnabled || task.isDone) return;

    final now = DateTime.now();

    for (final offset in _offsets) {
      final triggerTime = task.deadline.subtract(offset.duration);
      if (!triggerTime.isAfter(now)) continue;

      try {
        await _plugin.zonedSchedule(
          id: _notificationId(task.id, offset.code),
          title: 'TaskMap',
          body: '${task.title} is ${offset.phrase}.',
          scheduledDate: tz.TZDateTime.from(triggerTime, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e, st) {
        developer.log(
          'Failed to schedule reminder for task ${task.id}',
          error: e,
          stackTrace: st,
          name: 'NotificationService',
        );
      }
    }
  }

  Future<void> cancelTaskReminders(String taskId) async {
    if (kIsWeb) return;

    for (final offset in _offsets) {
      await _plugin.cancel(id: _notificationId(taskId, offset.code));
    }
  }

  Future<void> cancelAllTaskReminders() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  int _notificationId(String taskId, int offsetCode) {
    final base = taskId.hashCode & 0xFFFFFF;
    return base * 10 + offsetCode;
  }

  void _setLocalTimeZoneFromOffset() {
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    final locationName = offsetHours == 0
        ? 'UTC'
        : 'Etc/GMT${offsetHours <= 0 ? '+' : '-'}${offsetHours.abs()}';
    try {
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }
}

class _ReminderOffset {
  final Duration duration;
  final String phrase;
  final int code;

  const _ReminderOffset(this.duration, this.phrase, this.code);
}
