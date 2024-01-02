import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
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
  String locale = 'zh_CN';
  int primaryColor = Colors.cyan.value;
  int? secondaryColor;
  String? scheme;
  String? darkScheme;
  String themeMode = ThemeMode.system.name;
  String? fontFamily;
  bool vpnSwitch = false; //是否提供vpn功能
  bool stockSwitch = false; //是否提供股票功能
  bool emalSwitch = false; //是否提供email功能
  bool autoLogin = false;
  bool developerSwitch = false;
  String? logLevel;
  String? lastSyncTime;
  bool mobileVerified = false;

  // 可见性YYYYYY (peerId, mobileNumber, groupChat, qrCode, contactCard, name）
  String? visibilitySetting;
  int creditScore = 0;
  String? currency;

  PeerProfile(this.peerId, {this.clientId = unknownClientId}) : super();

  PeerProfile.fromJson(Map json)
      : peerId = json['peerId'],
        clientId = json['clientId'],
        clientDevice = json['clientDevice'],
        clientType = json['clientType'],
        locale = json['locale'],
        userId = json['userId'],
        username = json['username'],
        primaryColor = json['primaryColor'] ?? Colors.cyan.value,
        secondaryColor = json['secondaryColor'] ?? Colors.cyan.value,
        scheme = json['scheme'],
        darkScheme = json['darkScheme'],
        themeMode = json['themeMode'],
        vpnSwitch =
            json['udpSwitch'] == true || json['udpSwitch'] == 1 ? true : false,
        stockSwitch =
            json['downloadSwitch'] == true || json['downloadSwitch'] == 1
                ? true
                : false,
        emalSwitch = json['localDataCryptoSwitch'] == true ||
                json['localDataCryptoSwitch'] == 1
            ? true
            : false,
        autoLogin =
            json['autoLogin'] == true || json['autoLogin'] == 1 ? true : false,
        developerSwitch =
            json['developerOption'] == true || json['developerOption'] == 1
                ? true
                : false,
        logLevel = json['logLevel'],
        lastSyncTime = json['lastSyncTime'],
        mobileVerified = json['mobileVerified'],
        visibilitySetting = json['visibilitySetting'],
        creditScore = json['creditScore'] ?? 0,
        currency = json['currency'],
        super.fromJson(json);

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
      'udpSwitch': vpnSwitch,
      'downloadSwitch': stockSwitch,
      'localDataCryptoSwitch': emalSwitch,
      'autoLogin': autoLogin,
      'developerOption': developerSwitch,
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
