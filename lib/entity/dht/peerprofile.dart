import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import '../base.dart';

/// 节点的附属信息，包括个性化的配置
class PeerProfile extends StatusEntity {
  String peerId;
  String clientId;
  String? clientDevice;
  String? clientType;

  // 对应的用户编号
  String? userId;
  String? username;

  // 个性化配置
  String locale = 'en_US';
  int primaryColor = Colors.cyan.darken().value;
  int secondaryColor = Colors.cyan.darken().value;
  String? scheme;
  String? darkScheme;
  String themeMode = ThemeMode.system.name;
  String? fontFamily;
  bool vpnSwitch = false; //是否提供vpn功能
  bool stockSwitch = false; //是否提供股票功能
  bool emailSwitch = false; //是否提供email功能
  bool autoLogin = false;
  bool developerSwitch = false;
  String? logLevel;
  String? lastSyncTime;
  bool mobileVerified = false;

  // 可见性YYYYYY (peerId, mobileNumber, groupChat, qrCode, contactCard, name）
  String? visibilitySetting;
  int creditScore = 0;
  String? currency;

  PeerProfile(this.peerId, {this.clientId = unknownClientId});

  PeerProfile.fromJson(super.json)
      : peerId = json['peerId'],
        clientId = json['clientId'],
        clientDevice = json['clientDevice'],
        clientType = json['clientType'],
        locale = json['locale'] ?? 'zh_CN',
        userId = json['userId'],
        username = json['username'],
        primaryColor = json['primaryColor'] ?? Colors.cyan.value,
        secondaryColor = json['secondaryColor'] ?? Colors.cyan.value,
        scheme = json['scheme'],
        darkScheme = json['darkScheme'],
        themeMode = json['themeMode'] ?? ThemeMode.system.name,
        vpnSwitch =
            json['vpnSwitch'] == true || json['vpnSwitch'] == 1 ? true : false,
        stockSwitch = json['stockSwitch'] == true || json['stockSwitch'] == 1
            ? true
            : false,
        emailSwitch = json['emailSwitch'] == true || json['emailSwitch'] == 1
            ? true
            : false,
        autoLogin =
            json['autoLogin'] == true || json['autoLogin'] == 1 ? true : false,
        developerSwitch =
            json['developerSwitch'] == true || json['developerSwitch'] == 1
                ? true
                : false,
        logLevel = json['logLevel'],
        lastSyncTime = json['lastSyncTime'],
        mobileVerified =
            json['mobileVerified'] == true || json['developerOption'] == 1
                ? true
                : false,
        visibilitySetting = json['visibilitySetting'],
        creditScore = json['creditScore'] ?? 0,
        currency = json['currency'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'peerId': peerId,
      'clientId': clientId,
      'clientDevice': clientDevice,
      'clientType': clientType,
      'locale': locale,
      'userId': userId,
      'username': username,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'scheme': scheme,
      'darkScheme': darkScheme,
      'themeMode': themeMode,
      'vpnSwitch': vpnSwitch,
      'stockSwitch': stockSwitch,
      'emailSwitch': emailSwitch,
      'autoLogin': autoLogin,
      'developerSwitch': developerSwitch,
      'logLevel': logLevel,
      'lastSyncTime': lastSyncTime,
      'mobileVerified': mobileVerified,
      'visibilitySetting': visibilitySetting,
      'creditScore': creditScore,
      'currency': currency,
    });
    return json;
  }
}
