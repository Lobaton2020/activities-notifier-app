import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lobmindergo/models/task_model.dart';
import 'package:vibration/vibration.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

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
    await _loadSettings();
    tz.initializeTimeZones();
    final bogotaLocation = tz.getLocation('America/Bogota');
    tz.setLocalLocation(bogotaLocation);
    print('Timezone set to: ${tz.local.name}');
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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    _screenFlashEnabled = prefs.getBool('screenFlashEnabled') ?? true;
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrationEnabled', _vibrationEnabled);
    await prefs.setBool('screenFlashEnabled', _screenFlashEnabled);
    await prefs.setBool('soundEnabled', _soundEnabled);
  }

  Future<void> testVibration() async {
    print('Testing vibration... vibrationEnabled: $_vibrationEnabled');
    if (_vibrationEnabled) {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      print('Has vibrator: $hasVibrator');
      if (hasVibrator) {
        Vibration.vibrate(duration: 2000);
        print('Vibration triggered for 3 seconds');
      }
    }
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
  }

  Future<void> scheduleTaskNotification(TaskModel task) async {
    if (task.state) return;
    final scheduledTime = task.scheduledDateTime;
    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) return;
    if (scheduledTime.difference(now).inMinutes > 1440) return;

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_notifications_alarm',
        'Task Alarm',
        channelDescription: 'Notificaciones de alarmas',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF2196F3),
        ledColor: const Color(0xFF00F5D4),
        ledOnMs: 1000,
        ledOffMs: 500,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        styleInformation: BigTextStyleInformation(
          task.description,
          contentTitle: '⏰ ${task.project?.name ?? "Tarea"}',
          summaryText: task.formattedTime,
        ),
      ),
    );

    print(
      'Notification config: playSound=true, vibration=true, fullScreen=true',
    );

    print('Scheduling notification for ${task.formattedTime} with sound');

    try {
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
    } catch (e) {
      // Silent fail
      await _notifications.show(
        task.id.hashCode,
        task.project?.name ?? 'Tarea Pendiente',
        '${task.formattedTime} - ${task.description}',
        notificationDetails,
        payload: task.id,
      );
    }
  }

  Future<void> showTestNotification(TaskModel task) async {
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_notifications_alarm',
        'Task Alarm',
        channelDescription: 'Notificaciones de alarmas',
        importance: Importance.max,
        priority: Priority.max,
        playSound: _soundEnabled,
        enableVibration: _vibrationEnabled,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF2196F3),
        ledColor: const Color(0xFF00F5D4),
        ledOnMs: 1000,
        ledOffMs: 500,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        styleInformation: BigTextStyleInformation(
          'Notificación de prueba',
          contentTitle: '⏰ Prueba de Alarma',
          summaryText: 'Lobmindergo',
        ),
      ),
    );

    print(
      'Testing notification - sound: $_soundEnabled, vibration: $_vibrationEnabled',
    );

    await _notifications.show(
      999999,
      '⏰ Prueba de Alarma',
      'Sonido: ${_soundEnabled ? "ON" : "OFF"} | Vibración: ${_vibrationEnabled ? "ON" : "OFF"}',
      notificationDetails,
    );

    if (_vibrationEnabled) {
      await testVibration();
    }
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
        Vibration.vibrate(duration: 2000);
      }
    }
  }

  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
    _saveSettings();
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    _saveSettings();
  }

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
