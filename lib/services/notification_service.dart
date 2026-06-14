import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:activities_notifier_app/models/task_model.dart';
import 'package:vibration/vibration.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _vibrationEnabled = true;
  bool _screenFlashEnabled = true;
  bool _soundEnabled = true;

  bool get vibrationEnabled => _vibrationEnabled;
  bool get screenFlashEnabled => _screenFlashEnabled;
  bool get soundEnabled => _soundEnabled;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleTaskNotification(TaskModel task) async {
    if (task.state) return;
    final scheduledTime = task.scheduledDateTime;
    if (scheduledTime.isBefore(DateTime.now())) return;

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_notifications',
        'Task Notifications',
        channelDescription: 'Notificaciones de tareas programadas',
        importance: Importance.max,
        priority: Priority.high,
        playSound: _soundEnabled,
        enableVibration: _vibrationEnabled,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF7B2CBF),
        ledColor: const Color(0xFF00F5D4),
        ledOnMs: 1000,
        ledOffMs: 500,
        styleInformation: BigTextStyleInformation(
          task.description,
          contentTitle: '📋 ${task.project?.name ?? "Tarea"}',
          summaryText: task.formattedTime,
        ),
      ),
    );

    await _notifications.zonedSchedule(
      task.id.hashCode,
      task.project?.name ?? 'Tarea Pendiente',
      '${task.formattedTime} - ${task.description}',
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );
  }

  Future<void> cancelTaskNotification(String taskId) async {
    await _notifications.cancel(taskId.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> triggerAlarm(TaskModel task) async {
    if (_vibrationEnabled) {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500], repeat: 0);
      }
    }
    if (_screenFlashEnabled) {
      await _triggerScreenFlash();
    }
  }

  Future<void> _triggerScreenFlash() async {
    try {
      final currentBrightness = await ScreenBrightness().current;
      for (int i = 0; i < 5; i++) {
        await ScreenBrightness().setScreenBrightness(1.0);
        await Future.delayed(const Duration(milliseconds: 200));
        await ScreenBrightness().setScreenBrightness(0.0);
        await Future.delayed(const Duration(milliseconds: 200));
      }
      await ScreenBrightness().setScreenBrightness(currentBrightness);
    } catch (e) {
      print('Error flashing screen: $e');
    }
  }

  void setVibrationEnabled(bool enabled) => _vibrationEnabled = enabled;
  void setScreenFlashEnabled(bool enabled) => _screenFlashEnabled = enabled;
  void setSoundEnabled(bool enabled) => _soundEnabled = enabled;

  Future<void> testNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Canal de prueba',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      0,
      'Test de Notificación',
      'Las notificaciones están funcionando correctamente',
      details,
    );
  }
}
