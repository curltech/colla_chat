import 'dart:async';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

///应用处于后台时，点击通知的响应函数
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  NotificationResponseType type = notificationResponse.notificationResponseType;
  String? input = notificationResponse.input;
  String? payload = notificationResponse.payload;
  logger.i(
      'onSelectNotification type:${type.name}, input:$input, payload:$payload');
}

///接收的本地通知消息的结构类
class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}

/// 本地通知消息
class LocalNotificationsService {
  int id = 0;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// apple下的通知的类别设置，没有按钮和输入框，仅仅显示消息
  final List<DarwinNotificationCategory> darwinNotificationCategories =
      <DarwinNotificationCategory>[
    const DarwinNotificationCategory(
      'plainCategory',
      options: <DarwinNotificationCategoryOption>{
        DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
      },
    )
  ];

  /// 初始化local notification，runApp前调用
  Future<void> init() async {
    // ios,macos的初始化设置
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: darwinNotificationCategories,
    );
    //linux的初始化设置
    final LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(
      defaultActionName: 'Open notification',
      defaultIcon: AssetsLinuxIcon('icons/app_icon.png'),
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    final WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
            appName: 'colla_chat',
            appUserModelId: 'io.curltech.colla_chat',
            guid: '5d719c82-91c0-4113-b1bf-19d32236c918');
    //初始化设置
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
            macOS: initializationSettingsDarwin,
            linux: initializationSettingsLinux,
            windows: initializationSettingsWindows);
    // 初始化，定义通知的响应函数，包括通知选择本身和通知的按钮
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      //用户选择或者点击了通知
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            onSelectNotification(notificationResponse);
            break;
          case NotificationResponseType.selectedNotificationAction:
            break;
        }
      },
      // 应用处于后台时，点击通知的响应函数
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  /// android平台是否有权限
  Future<bool> isAndroidPermissionGranted() async {
    if (platformParams.android) {
      final bool granted = await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;

      return granted;
    }

    return false;
  }

  /// 申请通知的权限
  Future<bool?> requestPermissions() async {
    bool? granted = false;
    if (platformParams.ios) {
      granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (platformParams.macos) {
      granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (platformParams.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestExactAlarmsPermission();
      granted = await androidImplementation?.requestNotificationsPermission();
    }
    return granted;
  }

  ///只用于ios10之前的版本，应用处于前台收到本地通知.
  void onDidReceiveLocalNotification(
      ReceivedNotification receivedNotification) {
    String? title = receivedNotification.title;
    String? payload = receivedNotification.payload;
  }

  /// 用户选择或者点击了通知
  void onSelectNotification(NotificationResponse notificationResponse) {
    notificationTapBackground(notificationResponse);
  }

  /// 显示本地通知
  Future<void> showNotification(
    String title,
    String body, {
    int? id,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('colla_chat', 'colla_chat',
            channelDescription: 'colla_chat',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    notificationDetails ??=
        const NotificationDetails(android: androidNotificationDetails);
    if (id == null) {
      this.id++;
      id = this.id;
    }
    await flutterLocalNotificationsPlugin
        .show(id, title, body, notificationDetails, payload: payload);
  }
}

final LocalNotificationsService localNotificationsService =
    LocalNotificationsService();
