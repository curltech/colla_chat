import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

///local awesome通知控制器
class AwesomeLocalNotificationController with ChangeNotifier{
  static ReceivedAction? initialCallAction;

  ///初始化控制器
  static Future<void> initializeLocalNotifications() async {
    ///初始化通知
    await AwesomeNotifications().initialize(
        null, // 'resource://drawable/res_app_icon',
        [
          NotificationChannel(
              channelGroupKey: 'basic_tests',
              channelKey: 'basic_channel',
              channelName: 'Basic notifications',
              channelDescription: 'Notification channel for basic tests',
              defaultColor: myself.primary,
              ledColor: Colors.white,
              importance: NotificationImportance.High),
        ],
        channelGroups: [
          NotificationChannelGroup(
              channelGroupKey: 'basic_tests', channelGroupName: 'Basic tests'),
        ],
        debug: true);
  }

  static Future<void> initializeNotificationsEventListeners() async {
    /// 设置通知监听器
    AwesomeNotifications().setListeners(
        onActionReceivedMethod:
            AwesomeLocalNotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod:
            AwesomeLocalNotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:
            AwesomeLocalNotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:
            AwesomeLocalNotificationController.onDismissActionReceivedMethod);
  }

  ///In case you need to capture the user notification action before calling the method setListeners
  getInitialNotificationAction() async {
    ReceivedAction? receivedAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);
    if (receivedAction?.channelKey == 'call_channel') {
    } else {}
  }

  /// 检查和申请权限
  static checkPermission() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // This is just a basic example. For real apps, you must show some
        // friendly dialog box before call the request method.
        // This is very important to not harm the user experience
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  static Future<List<NotificationPermission>> requestUserPermissions(
      BuildContext context,
      {
      // if you only intends to request the permissions until app level, set the channelKey value to null
      required String? channelKey,
      required List<NotificationPermission> permissionList}) async {
    // Check if the basic permission was conceived by the user
    // if (!await requestBasicPermissionToSendNotifications(context)) return [];

    // Check which of the permissions you need are allowed at this time
    List<NotificationPermission> permissionsAllowed =
        await AwesomeNotifications().checkPermissionList(
            channelKey: channelKey, permissions: permissionList);

    // If all permissions are allowed, there is nothing to do
    if (permissionsAllowed.length == permissionList.length) {
      return permissionsAllowed;
    }

    // Refresh the permission list with only the disallowed permissions
    List<NotificationPermission> permissionsNeeded =
        permissionList.toSet().difference(permissionsAllowed.toSet()).toList();

    // Check if some of the permissions needed request user's intervention to be enabled
    List<NotificationPermission> lockedPermissions =
        await AwesomeNotifications().shouldShowRationaleToRequest(
            channelKey: channelKey, permissions: permissionsNeeded);

    // If there is no permissions depending on user's intervention, so request it directly
    if (lockedPermissions.isEmpty) {
      // Request the permission through native resources.
      await AwesomeNotifications().requestPermissionToSendNotifications(
          channelKey: channelKey, permissions: permissionsNeeded);

      // After the user come back, check if the permissions has successfully enabled
      permissionsAllowed = await AwesomeNotifications().checkPermissionList(
          channelKey: channelKey, permissions: permissionsNeeded);
    } else {}

    // Return the updated list of allowed permissions
    return permissionsAllowed;
  }

  createNotification({
    required int id,
  }) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
      id: id,
      channelKey: 'basic_channel',
      title:
          'Emojis are awesome too! ${Emojis.smile_face_with_tongue}${Emojis.smile_rolling_on_the_floor_laughing}${Emojis.emotion_red_heart}',
      body:
          'Simple body with a bunch of Emojis! ${Emojis.transport_police_car} ${Emojis.animals_dog} ${Emojis.flag_UnitedStates} ${Emojis.person_baby}',
      bigPicture: 'https://tecnoblog.net/wp-content/uploads/2019/09/emoji.jpg',
      notificationLayout: NotificationLayout.BigPicture,
    ));
  }

  static String _toSimpleEnum(NotificationLifeCycle lifeCycle) =>
      lifeCycle.toString().split('.').last;

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    Fluttertoast.showToast(
        msg:
            'Notification created on ${_toSimpleEnum(receivedNotification.createdLifeCycle!)}',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.green,
        gravity: ToastGravity.BOTTOM);
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    Fluttertoast.showToast(
        msg:
            'Notification displayed on ${_toSimpleEnum(receivedNotification.displayedLifeCycle!)}',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.blue,
        gravity: ToastGravity.BOTTOM);
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    Fluttertoast.showToast(
        msg:
            'Notification dismissed on ${_toSimpleEnum(receivedAction.dismissedLifeCycle!)}',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.orange,
        gravity: ToastGravity.BOTTOM);
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Always ensure that all plugins was initialized
    WidgetsFlutterBinding.ensureInitialized();

    bool isSilentAction =
        receivedAction.actionType == ActionType.SilentAction ||
            receivedAction.actionType == ActionType.SilentBackgroundAction;

    // SilentBackgroundAction runs on background thread and cannot show
    // UI/visual elements
    if (receivedAction.actionType != ActionType.SilentBackgroundAction) {
      Fluttertoast.showToast(
          msg:
              '${isSilentAction ? 'Silent action' : 'Action'} received on ${_toSimpleEnum(receivedAction.actionLifeCycle!)}',
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: isSilentAction ? Colors.blueAccent : myself.primary,
          gravity: ToastGravity.BOTTOM);
    }

    switch (receivedAction.channelKey) {
      case 'call_channel':
        if (receivedAction.actionLifeCycle != NotificationLifeCycle.AppKilled) {
          await receiveCallNotificationAction(receivedAction);
        }
        break;

      case 'alarm_channel':
        await receiveAlarmNotificationAction(receivedAction);
        break;

      case 'media_player':
        await receiveMediaNotificationAction(receivedAction);
        break;

      case 'chats':
        await receiveChatNotificationAction(receivedAction);
        break;

      default:
        if (isSilentAction) {
          debugPrint(receivedAction.toString());
          debugPrint("start");
          await Future.delayed(const Duration(seconds: 4));
          final url = Uri.parse("http://google.com");
          break;
        }
        if (!AwesomeStringUtils.isNullOrEmpty(receivedAction.buttonKeyInput)) {
          receiveButtonInputText(receivedAction);
        } else {
          receiveStandardNotificationAction(receivedAction);
        }
        break;
    }
  }

  static Future<void> receiveButtonInputText(
      ReceivedAction receivedAction) async {
    debugPrint('Input Button Message: "${receivedAction.buttonKeyInput}"');
    Fluttertoast.showToast(
        msg: 'Msg: ${receivedAction.buttonKeyInput}',
        backgroundColor: myself.primary,
        textColor: Colors.white);
  }

  static Future<void> receiveStandardNotificationAction(
      ReceivedAction receivedAction) async {}

  static Future<void> receiveMediaNotificationAction(
      ReceivedAction receivedAction) async {
    switch (receivedAction.buttonKeyPressed) {
      case 'MEDIA_CLOSE':
        break;

      case 'MEDIA_PLAY':
      case 'MEDIA_PAUSE':
        break;

      case 'MEDIA_PREV':
        break;

      case 'MEDIA_NEXT':
        break;

      default:
        break;
    }
  }

  int createUniqueID(int maxValue) {
    Random random = Random();
    return random.nextInt(maxValue);
  }

  static Future<void> receiveChatNotificationAction(
      ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == 'REPLY') {
      await AwesomeNotifications().createNotification(
          content: NotificationContent(
        id: 1,
        channelKey: 'basic_channel',
        title:
            'Emojis are awesome too! ${Emojis.smile_face_with_tongue}${Emojis.smile_rolling_on_the_floor_laughing}${Emojis.emotion_red_heart}',
        body:
            'Simple body with a bunch of Emojis! ${Emojis.transport_police_car} ${Emojis.animals_dog} ${Emojis.flag_UnitedStates} ${Emojis.person_baby}',
        bigPicture:
            'https://tecnoblog.net/wp-content/uploads/2019/09/emoji.jpg',
        notificationLayout: NotificationLayout.BigPicture,
      ));
    } else {}
  }

  static Future<void> receiveAlarmNotificationAction(
      ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == 'SNOOZE') {}
  }

  static Future<void> receiveCallNotificationAction(
      ReceivedAction receivedAction) async {
    switch (receivedAction.buttonKeyPressed) {
      case 'REJECT':
        // Is not necessary to do anything, because the reject button is
        // already auto dismissible
        break;

      case 'ACCEPT':
        break;

      default:
        break;
    }
  }

  static Future<void> interceptInitialCallActionRequest() async {
    ReceivedAction? receivedAction =
        await AwesomeNotifications().getInitialNotificationAction();

    if (receivedAction?.channelKey == 'call_channel') {
      initialCallAction = receivedAction;
    }
  }
}
