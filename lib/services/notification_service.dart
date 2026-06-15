import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lobmindergo/models/task_model.dart';
import 'package:lobmindergo/services/api_service.dart';
import 'package:vibration/vibration.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

@pragma('vm:entry-point')
Future<void> _alarmCallback(int id, [Map<String, dynamic>? params]) async {
  print('[Alarm] Callback started for id: $id');
  try {
    final prefs = await SharedPreferences.getInstance();
    final taskText = prefs.getString('task_$id') ?? 'Es hora de trabajar';

    // Leer settings directamente o usar params
    final vibrationEnabled =
        params?['vibrationEnabled'] ??
        prefs.getBool('vibrationEnabled') ??
        true;
    final ttsEnabled =
        params?['ttsEnabled'] ?? prefs.getBool('ttsEnabled') ?? true;

    print(
      '[Alarm] Task: $taskText, vibration: $vibrationEnabled, tts: $ttsEnabled',
    );

    // Vibrate
    if (vibrationEnabled) {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(duration: 500);
        await Future.delayed(const Duration(milliseconds: 500));
        Vibration.vibrate(duration: 500);
        print('[Alarm] Vibrated');
      }
    }

    // TTS
    if (ttsEnabled) {
      final tts = FlutterTts();
      await tts.setLanguage('es-CO');
      await tts.setSpeechRate(0.5);
      await tts.setVolume(1.0);
      await tts.setPitch(1.0);
      await tts.speak(taskText);
      print('[Alarm] TTS spoken');
    }
  } catch (e) {
    print('[Alarm] Error: $e');
  }
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FlutterTts _tts = FlutterTts();

  bool _vibrationEnabled = true;
  bool _screenFlashEnabled = true;
  bool _soundEnabled = true;
  bool _ttsEnabled = true;

  bool get vibrationEnabled => _vibrationEnabled;
  bool get screenFlashEnabled => _screenFlashEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get ttsEnabled => _ttsEnabled;

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
    await _initTts();
    await AndroidAlarmManager.initialize();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('es-CO');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    print('TTS initialized: es-CO');
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    _screenFlashEnabled = prefs.getBool('screenFlashEnabled') ?? true;
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _ttsEnabled = prefs.getBool('ttsEnabled') ?? true;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrationEnabled', _vibrationEnabled);
    await prefs.setBool('screenFlashEnabled', _screenFlashEnabled);
    await prefs.setBool('soundEnabled', _soundEnabled);
    await prefs.setBool('ttsEnabled', _ttsEnabled);
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

  void _onNotificationTapped(NotificationResponse response) async {
    // Solo abre la app al tocar notificación - no hace nada extra
  }

  Future<void> _flashScreen() async {
    if (!_screenFlashEnabled) return;
    try {
      await ScreenBrightness().setScreenBrightness(1.0);
      await Future.delayed(const Duration(seconds: 1));
      await ScreenBrightness().resetScreenBrightness();
    } catch (e) {
      print('[Flash] Error: $e');
    }
  }

  Future<void> _triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(duration: 500);
        await Future.delayed(const Duration(milliseconds: 500));
        Vibration.vibrate(duration: 500);
      }
    } catch (e) {
      print('[Vibration] Error: $e');
    }
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

    // Programar alarma para TTS y vibración al mismo tiempo que la notificación
    await _scheduleAlarm(task);
  }

  Future<void> _scheduleAlarm(TaskModel task) async {
    if (!ttsEnabled && !vibrationEnabled) return;
    final scheduledTime = task.scheduledDateTime;
    if (scheduledTime.isBefore(DateTime.now())) return;

    final taskId = task.id.hashCode;
    final taskText = '${task.project?.name ?? "Tarea"}: ${task.description}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('task_$taskId', taskText);
    await prefs.setBool('vibrationEnabled', _vibrationEnabled);
    await prefs.setBool('ttsEnabled', _ttsEnabled);
    print('[Alarm] Scheduled for ${task.formattedTime}: $taskText');
    print(
      '[Alarm] Settings - vibration: $_vibrationEnabled, tts: $_ttsEnabled',
    );

    await AndroidAlarmManager.oneShotAt(
      scheduledTime,
      taskId,
      _alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true,
    );
  }

  Future<void> showTestNotification(TaskModel task) async {
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_notifications_alarm',
        'Task Alarm',
        channelDescription: 'Notificaciones de alarmas',
        importance: Importance.max,
        priority: Priority.max,
        playSound: soundEnabled,
        enableVibration: vibrationEnabled,
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

  void setTtsEnabled(bool enabled) {
    _ttsEnabled = enabled;
    _saveSettings();
  }

  Future<void> speakTask(TaskModel task) async {
    if (!_ttsEnabled) return;
    final text = '${task.project?.name ?? "Tarea"}: ${task.description}';
    print('[TTS] Speaking: $text');
    try {
      await _tts.speak(text);
      print('[TTS] speak() called successfully');
    } catch (e) {
      print('[TTS] Error: $e');
    }
  }

  Future<void> testTts() async {
    print('[TTS] Testing TTS...');
    try {
      await _tts.setLanguage('es-CO');
      final result = await _tts.speak(
        'Prueba de voz. Tarea: Completar informe.',
      );
      print('[TTS] Test result: $result');
    } catch (e) {
      print('[TTS] Test error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
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
