import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mobpush_plugin/mobpush_custom_message.dart';
import 'package:mobpush_plugin/mobpush_local_notification.dart';
import 'package:mobpush_plugin/mobpush_notify_message.dart';
import 'package:mobpush_plugin/mobpush_plugin.dart';

class MobilePusher {
  String _sdkVersion = 'Unknown';
  String _registrationId = 'Unknown';

  void updatePermission() {
    MobpushPlugin.updatePrivacyPermissionStatus(true);
  }

  setCustomNotification() {
    if (Platform.isIOS) {
      MobpushPlugin.setCustomNotification();
    }
  }

  setAPNsForProduction() {
    if (Platform.isIOS) {
      // 开发环境 false, 线上环境 true
      MobpushPlugin.setAPNsForProduction(false);
    }
  }

  addPushReceiver() {
    MobpushPlugin.addPushReceiver(_onEvent, _onError);
  }

  stopPush() {
    MobpushPlugin.stopPush();
  }

  restartPush() {
    MobpushPlugin.restartPush();
  }

  isPushStopped() {
    MobpushPlugin.isPushStopped();
  }

  setAlias() {
    MobpushPlugin.setAlias("别名").then((Map<String, dynamic> aliasMap) {
      String res = aliasMap['res'];
      String error = aliasMap['error'];
      String errorCode = aliasMap['errorCode'];
      print(">>>>>>>>>>>>>>>>>>>>>>>>>>> setAlias -> res: $res error: $error");
    });
  }

  getAlias() {
    MobpushPlugin.getAlias().then((Map<String, dynamic> aliasMap) {
      String res = aliasMap['res'];
      String error = aliasMap['error'];
      print(">>>>>>>>>>>>>>>>>>>>>>>>>>> getAlias -> res: $res error: $error");
    });
  }

  deleteAlias() {
    MobpushPlugin.deleteAlias().then((Map<String, dynamic> aliasMap) {
      String res = aliasMap['res'];
      String error = aliasMap['error'];
      print(
          ">>>>>>>>>>>>>>>>>>>>>>>>>>> deleteAlias -> res: $res error: $error");
    });
  }

  addTags() {
    List<String> tags = [];
    tags.add("tag1");
    tags.add("tag2");
    MobpushPlugin.addTags(tags).then((Map<String, dynamic> tagsMap) {
      String res = tagsMap['res'];
      String error = tagsMap['error'];
      print(">>>>>>>>>>>>>>>>>>>>>>>>>>> addTags -> res: $res error: $error");
    });
  }

  getTags() {
    MobpushPlugin.getTags().then((Map<String, dynamic> tagsMap) {
      List<String> resList = List<String>.from(tagsMap['res']);
      String error = tagsMap['error'];
      print(
          ">>>>>>>>>>>>>>>>>>>>>>>>>>> getTags -> res: $resList error: $error");
    });
    ;
  }

  deleteTags() {
    List<String> tags = [];
    tags.add("tag1");
    tags.add("tag2");
    MobpushPlugin.deleteTags(tags).then((Map<String, dynamic> tagsMap) {
      String res = tagsMap['res'];
      String error = tagsMap['error'];
      print(
          ">>>>>>>>>>>>>>>>>>>>>>>>>>> deleteTags -> res: $res error: $error");
    });
  }

  cleanTags() {
    MobpushPlugin.cleanTags().then((Map<String, dynamic> tagsMap) {
      String res = tagsMap['res'];
      String error = tagsMap['error'];
      print(">>>>>>>>>>>>>>>>>>>>>>>>>>> cleanTags -> res: $res error: $error");
    });
  }

  addLocalNotification(MobPushLocalNotification localNotification) {
    MobpushPlugin.addLocalNotification(localNotification);
  }

  bindPhoneNum() {
    MobpushPlugin.bindPhoneNum("110");
  }

  send(int type, String content, int space, String extras) {
    /**
     * 测试模拟推送，用于测试
     * type：模拟消息类型，1、通知测试；2、内推测试；3、定时
     * content：模拟发送内容，500字节以内，UTF-8
     * space：仅对定时消息有效，单位分钟，默认1分钟
     * extras: 附加数据，json字符串
     */
    MobpushPlugin.send(type, content, space, extras)
        .then((Map<String, dynamic> sendMap) {
      String res = sendMap['res'];
      String error = sendMap['error'];
      print(">>>>>>>>>>>>>>>>>>>>>>>>>>> send -> res: $res error: $error");
    });
  }

  setClickNotificationToLaunchMainActivity(bool enable) {
    MobpushPlugin.setClickNotificationToLaunchMainActivity(enable);
  }

  removeLocalNotification(int notificationId) {
    MobpushPlugin.removeLocalNotification(notificationId);
  }

  clearLocalNotifications() {
    MobpushPlugin.clearLocalNotifications();
  }

  setNotifyIcon(String resId) {
    MobpushPlugin.setNotifyIcon(resId);
  }

  setAppForegroundHiddenNotification(bool hidden) {
    MobpushPlugin.setAppForegroundHiddenNotification(hidden);
  }

  setSilenceTime(int startHour, int startMinute, int endHour, int endMinute) {
    /**
     * 设置通知静音时段（推送选项）(仅andorid)
     * @param startHour   开始时间[0~23] (小时)
     * @param startMinute 开始时间[0~59]（分钟）
     * @param endHour     结束时间[0~23]（小时）
     * @param endMinute   结束时间[0~59]（分钟）
     */
    MobpushPlugin.setSilenceTime(startHour, startMinute, endHour, endMinute);
  }

  setBadge(int badge) {
    MobpushPlugin.setBadge(badge);
  }

  clearBadge() {
    MobpushPlugin.clearBadge();
  }

  getRegistrationId() {
    MobpushPlugin.getRegistrationId().then((Map<String, dynamic> ridMap) {
      print(ridMap);
      String regId = ridMap['res'].toString();
      print('------>#### registrationId: ' + regId);
    });
  }

  void init() {
    //上传隐私协议许可
    MobpushPlugin.updatePrivacyPermissionStatus(true).then((value) {
      print(">>>>>>>>>>>>>>>>>>>updatePrivacyPermissionStatus:" +
          value.toString());
    });
    if (Platform.isIOS) {
      //设置地区：regionId 默认0（国内），1:海外
      MobpushPlugin.setRegionId(1);
      MobpushPlugin.registerApp(
          "3276d3e413040", "4280a3a6df667cfce37528dec03fd9c3");
    }

    initPlatformState();

    if (Platform.isIOS) {
      MobpushPlugin.setCustomNotification();
      MobpushPlugin.setAPNsForProduction(true);
    }
    MobpushPlugin.addPushReceiver(_onEvent, _onError);
  }

  Future<void> initPlatformState() async {
    String sdkVersion;
    try {
      sdkVersion = await MobpushPlugin.getSDKVersion();
    } on PlatformException {
      sdkVersion = 'Failed to get platform version.';
    }
    try {
      Future.delayed(Duration(milliseconds: 500), () {
        MobpushPlugin.getRegistrationId().then((Map<String, dynamic> ridMap) {
          print(ridMap);
          _registrationId = ridMap['res'].toString();
          print('------>#### registrationId: ' + _registrationId);
        });
      });
    } on PlatformException {
      _registrationId = 'Failed to get registrationId.';
    }
    _sdkVersion = sdkVersion;
  }

  void _onEvent(dynamic event) {
    print('>>>>>>>>>>>>>>>>>>>>>>>>>>>onEvent:' + event.toString());
    Map<String, dynamic> eventMap = json.decode(event as String);
    Map<String, dynamic> result = eventMap['result'];
    int action = eventMap['action'];

    switch (action) {
      case 0:
        MobPushCustomMessage message =
            new MobPushCustomMessage.fromJson(result);
        message.content;
        break;
      case 1:
        MobPushNotifyMessage message =
            new MobPushNotifyMessage.fromJson(result);
        break;
      case 2:
        MobPushNotifyMessage message =
            new MobPushNotifyMessage.fromJson(result);
        break;
    }
  }

  void _onError(dynamic event) {
    print('>>>>>>>>>>>>>>>>>>>>>>>>>>>onError:' + event.toString());
  }
}
