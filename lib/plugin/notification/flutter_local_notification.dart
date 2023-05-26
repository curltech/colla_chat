import 'dart:typed_data';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// flutter_local_notifications实现的本地通知服务
class FlutterLocalNotification {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  FlutterLocalNotification() {
    init();
  }

  ///初始化本地通知组件
  init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
            macOS: initializationSettingsDarwin,
            linux: initializationSettingsLinux);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  ///老版本的ios需要处理
  onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {}

  ///用户点击通知后触发
  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      logger.i('notification payload: $payload');
    }
  }

  ///apple平台获取权限
  requestPermissions() async {
    bool? result = true;
    if (platformParams.ios) {
      result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    if (platformParams.macos) {
      result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    return result;
  }

  ///发送本地通知
  show(String? title, String? body, String? payload,
      {bool vibration = false}) async {
    var vibrationPattern = Int64List(4);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 1000;
    vibrationPattern[2] = 5000;
    vibrationPattern[3] = 2000;
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
            'CollaChat notification', 'CollaChat notification',
            channelDescription: 'CollaChat notification description',
            importance: Importance.max,
            priority: Priority.high,
            vibrationPattern: vibration ? vibrationPattern : null,
            enableVibration: vibration,
            ticker: 'ticker');
    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    try {
      await flutterLocalNotificationsPlugin
          .show(0, title, body, notificationDetails, payload: payload);
    } catch (ex) {
      logger.e('flutterLocalNotifications show message failure:$ex');
    }
  }

  ///用户点击通知后获取细节
  Future<NotificationAppLaunchDetails?>
      getNotificationAppLaunchDetails() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    return notificationAppLaunchDetails;
  }

  ///删除通知
  cancel({int? id, String? tag}) async {
    if (id != null) {
      await flutterLocalNotificationsPlugin.cancel(id, tag: tag);
    } else {
      await flutterLocalNotificationsPlugin.cancelAll();
    }
  }
}

final flutterLocalNotification = FlutterLocalNotification();
