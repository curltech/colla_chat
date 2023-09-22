import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

///顶级函数用于处理后台或者终止的应用的消息通知处理
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  logger.i("background message: ${message.messageId}");
}

///firebase remote messaging推送通知控制器
class FirebaseMessagingController with ChangeNotifier {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings? settings;

  FirebaseMessagingController();

  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<AuthorizationStatus> requestPermission() async {
    settings ??= await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    return settings!.authorizationStatus;
  }

  init() async {
    ///foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.i('foreground message data: ${message.data}');

      if (message.notification != null) {
        logger.i(
            'foreground message also contained a notification: ${message.notification}');
      }
    });

    ///在main的runApp之前调用，用于初始化
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _fcmToken = await messaging.getToken();
  }

  Future<void> sendPushMessage(
      String fcmToken, String title, String messageType, dynamic data) async {
    var body = {
      'token': fcmToken,
      'data': data,
      'notification': {
        'title': title,
        'messageType': messageType,
      },
    };
    if (platformParams.android) {
      await messaging.sendMessage(
          to: fcmToken, data: data, messageId: title, messageType: messageType);
    } else {
      try {
        await http.post(
          Uri.parse('https://api.rnfirebase.io/messaging/send'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: JsonUtil.toJsonString(body),
        );
      } catch (e) {
        logger.e('post push message failure:$e');
      }
    }
  }
}

final FirebaseMessagingController firebaseMessagingController =
    FirebaseMessagingController();
