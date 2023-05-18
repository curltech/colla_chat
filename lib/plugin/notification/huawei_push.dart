import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:huawei_push/huawei_push.dart';

class HuaweiPush {
  getToken() {
    Push.getTokenStream.listen(_onTokenEvent, onError: _onTokenError);
    Push.getToken("");
  }

  void _onTokenEvent(String event) {
    var token = event;
    print("TokenEvent: $token");
  }

  void _onTokenError(PlatformException error) {
    print("TokenErrorEvent: ${error.message}");
  }

  listen() {
    Push.onMessageReceivedStream
        .listen(_onMessageReceived, onError: _onMessageReceiveError);
  }

  void _onMessageReceived(RemoteMessage remoteMessage) {
    // Called when a data message is received
    String? data = remoteMessage.data;
  }

  void _onMessageReceiveError(Object error) {
    // Called when an error occurs while receiving the data message
  }

  void subscribe() async {
    String topic = "testTopic";
    String result = await Push.subscribe(topic);
  }

  void unsubscribe() async {
    String topic = "testTopic";
    String result = await Push.unsubscribe(topic);
  }

  ///注册后台消息处理器
  static void registerBackgroundMessageHandler() async {
    bool backgroundMessageHandler =
        await Push.registerBackgroundMessageHandler(backgroundMessageCallback);
  }

  static void backgroundMessageCallback(RemoteMessage remoteMessage) async {
    String? data = remoteMessage.data;

    Push.localNotification({
      HMSLocalNotificationAttr.TITLE: '[Headless] DataMessage Received',
      HMSLocalNotificationAttr.MESSAGE: data
    });
  }

  intentListen() async {
    Push.getIntentStream.listen(_onNewIntent, onError: _onIntentError);
    String? intent = await Push.getInitialIntent();
    _onNewIntent(intent!);
  }

  void _onNewIntent(String intentString) {
    // For navigating to the custom intent page (deep link)
    // The custom intent that sent from the push kit console is:
    // app://open.my.app/CustomIntentPage
    print('CustomIntentEvent: $intentString');
    List parsedString = intentString.split("://open.my.app/");
    if (parsedString[1] == "CustomIntentPage") {
      // Schedule the navigation after the widget is builded.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        //Navigator.of(context).push(MaterialPageRoute(builder: (context) => CustomIntentPage()));
      });
    }
  }

  void _onIntentError(PlatformException err) {
    print("Error on intent stream: $err");
  }

  void getInitialNotification() async {
    dynamic initialNotification = await Push.getInitialNotification();
    print("getInitialNotification: $initialNotification");
  }

  Future<void> initNotificationListener() async {
    Push.onNotificationOpenedApp.listen(_onNotificationOpenedApp);
  }

  void _onNotificationOpenedApp(dynamic remoteMessage) {
    print("onNotificationOpenedApp: ${remoteMessage.toMap()}");
  }

  pushLocalNotification() async {
    try {
      Map<String, dynamic> localNotification = {
        HMSLocalNotificationAttr.TITLE: 'Notification Title',
        HMSLocalNotificationAttr.MESSAGE: 'Notification Message',
        HMSLocalNotificationAttr.TICKER: "OptionalTicker",
        HMSLocalNotificationAttr.TAG: "push-tag",
        HMSLocalNotificationAttr.BIG_TEXT: 'This is a bigText',
        HMSLocalNotificationAttr.SUB_TEXT: 'This is a subText',
        HMSLocalNotificationAttr.LARGE_ICON: 'ic_launcher',
        HMSLocalNotificationAttr.SMALL_ICON: 'ic_notification',
        HMSLocalNotificationAttr.IMPORTANCE: Importance.MAX,
        HMSLocalNotificationAttr.COLOR: "white",
        HMSLocalNotificationAttr.VIBRATE: true,
        HMSLocalNotificationAttr.VIBRATE_DURATION: 1000.0,
        HMSLocalNotificationAttr.ONGOING: false,
        HMSLocalNotificationAttr.DONT_NOTIFY_IN_FOREGROUND: false,
        HMSLocalNotificationAttr.AUTO_CANCEL: false,
        HMSLocalNotificationAttr.INVOKE_APP: false,
        HMSLocalNotificationAttr.ACTIONS: ["Yes", "No"],
        HMSLocalNotificationAttr.DATA:
            Map<String, dynamic>.from({"string_val": "pushkit", "int_val": 15}),
      };
      Map<String, dynamic> response =
          await Push.localNotification(localNotification);
      print("Pushed a local notification: $response");
    } catch (e) {
      print("Error: $e");
    }
  }

  void sendRemoteMsg() async {
    RemoteMessageBuilder remoteMsg = RemoteMessageBuilder(
      // Default value of to parameter is set "push.hcm.upstream" if left empty or null
      to: '',
      data: {"key1": "test", "message": "huawei-test"},
      ttl: 120,
      messageId: Random().nextInt(10000).toString(),
      collapseKey: '-1',
    ).setSendMode(1).setReceiptMode(1);
    String result = await Push.sendRemoteMessage(remoteMsg);
    print("sendRemoteMessage: $result");
  }

  void multiSenderListen() {
    Push.getMultiSenderTokenStream
        .listen(_onMultiSenderTokenReceived, onError: _onMultiSenderTokenError);
  }

  void _onMultiSenderTokenReceived(Map<String, dynamic> multiSenderTokenEvent) {
    print('[onMultiSenderTokenReceived]$multiSenderTokenEvent');
  }

  void _onMultiSenderTokenError(dynamic error) {
    print('[onMultiSenderTokenError]$error');
  }
}
