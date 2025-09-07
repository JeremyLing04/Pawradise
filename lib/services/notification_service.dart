import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    await createNotificationChannel();
  }

  Future<bool> _checkExactAlarmPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 31) {
          // Android 12 (API 31)+
          // 检查精确警报权限
          final alarmManager = AndroidAlarmManager();
          return await alarmManager.canScheduleExactAlarms();
        }
      } catch (e) {
        debugPrint('Error checking exact alarm permission: $e');
        return false;
      }
    }
    return true; // 对于旧版本Android或其他平台，默认返回true
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      // 检查精确警报权限
      final hasExactPermission = await _checkExactAlarmPermission();

      final androidDetails = AndroidNotificationDetails(
        'pawradise_channel_id',
        'Pawradise Reminders',
        channelDescription: 'Channel for Pawradise schedule reminders',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );

      final details = NotificationDetails(android: androidDetails);

      if (hasExactPermission) {
        // 有精确权限，使用精确模式
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: null,
        );
        debugPrint('Scheduled exact notification for $scheduledTime');
      } else {
        // 没有精确权限，使用非精确模式
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: null,
        );
        debugPrint('Scheduled inexact notification for $scheduledTime');
      }
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        // 回退到非精确通知
        await _scheduleInexactNotification(
          id: id,
          title: title,
          body: body,
          scheduledTime: scheduledTime,
        );
      } else {
        debugPrint('Error scheduling notification: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Unexpected error scheduling notification: $e');
    }
  }

  Future<void> _scheduleInexactNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'pawradise_channel_id',
      'Pawradise Reminders',
      channelDescription: 'Channel for Pawradise schedule reminders',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'pawradise_channel_id',
      'Pawradise Reminders',
      channelDescription: 'Instant notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(id, title, body, details);
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'pawradise_channel_id',
      'Pawradise Reminders',
      description: 'Channel for Pawradise notifications',
      importance: Importance.high,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// 请求通知权限
  Future<bool> requestPermissions() async {
    try {
      // Android 13+ 需要请求通知权限
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          // Android 13 (API 33)+
          final status = await Permission.notification.request();
          return status.isGranted;
        }

        // 对于 Android 12+ 检查精确警报权限
        if (androidInfo.version.sdkInt >= 31) {
          final hasExactPermission = await _checkExactAlarmPermission();
          if (!hasExactPermission) {
            // 可以在这里引导用户到设置页面
            debugPrint(
              'Please guide user to enable exact alarm permission in system settings',
            );
          }
        }
      }

      // iOS/macOS
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final result =
            await _notifications
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
        return result;
      }

      return true;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  /// 打开应用设置页面
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

/// Android 警报管理器辅助类
class AndroidAlarmManager {
  static const MethodChannel _channel = MethodChannel('android_alarm_manager');

  Future<bool> canScheduleExactAlarms() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final result = await _channel.invokeMethod<bool>(
          'canScheduleExactAlarms',
        );
        return result ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking exact alarms: $e');
      return false;
    }
  }
}
