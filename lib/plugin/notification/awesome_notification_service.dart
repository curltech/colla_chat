import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here
  }
}

/// Awesome Notification推送通知控制器
class AwesomeNotificationService {
  final AwesomeNotifications awesomeNotifications = AwesomeNotifications();

  AwesomeNotificationService();

  /// 在main的runApp之前调用，用于初始化
  init() async {
    if (platformParams.mobile || platformParams.macos) {
      awesomeNotifications.initialize(
          // set the icon to null if you want to use the default app icon
          null,
          [
            NotificationChannel(
                channelGroupKey: 'colla_chat_channel_group',
                channelKey: 'colla_chat_channel',
                channelName: 'CollaChat notifications',
                channelDescription: 'Notification channel for CollaChat',
                defaultColor: myself.primary,
                ledColor: Colors.white)
          ],
          // Channel groups are only visual and are not required
          channelGroups: [
            NotificationChannelGroup(
                channelGroupKey: 'colla_chat_channel_group',
                channelGroupName: 'CollaChat group')
          ],
          debug: false);
    }
  }

  register() async {
    awesomeNotifications.setListeners(
        onActionReceivedMethod: NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod:
            NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:
            NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:
            NotificationController.onDismissActionReceivedMethod);
  }

  Future<bool> requestPermission() async {
    bool isAllowed = await awesomeNotifications.isNotificationAllowed();
    if (!isAllowed) {
      // This is just a basic example. For real apps, you must show some
      // friendly dialog box before call the request method.
      // This is very important to not harm the user experience
      return await awesomeNotifications.requestPermissionToSendNotifications();
    }
    return isAllowed;
  }

  ///app被重新打开时调用，获取初始通知消息
  Future<ReceivedAction?> getInitialNotificationAction() async {
    ReceivedAction? receivedAction = await awesomeNotifications
        .getInitialNotificationAction(removeFromActionEvents: false);
    return receivedAction;
  }

  Future<void> sendPushMessage(
      String fcmToken, String title, String messageType, String? body) async {
    awesomeNotifications.createNotification(
        content: NotificationContent(
      id: 10,
      channelKey: 'colla_chat_channel',
      actionType: ActionType.Default,
      title: title,
      body: body,
    ));
  }
}

final AwesomeNotificationService awesomeNotificationService =
    AwesomeNotificationService();
