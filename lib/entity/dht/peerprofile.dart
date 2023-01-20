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
  int seedColor = Colors.cyan.value;
  int darkSeedColor = Colors.cyan.value;
  String themeMode = ThemeMode.system.name;
  String? fontFamily;
  bool udpSwitch = false;
  bool downloadSwitch = false;
  bool localDataCryptoSwitch = false;
  bool autoLogin = false;
  bool developerOption = false;
  String? logLevel;
  String? lastSyncTime;

  /// 主发现地址，表示可信的，可以推荐你的peer地址
  String? discoveryAddress;
  String? lastFindNodeTime;

  String? mobileVerified;

  // 可见性YYYYYY (peerId, mobileNumber, groupChat, qrCode, contactCard, name）
  String? visibilitySetting;
  int creditScore = 0;
  String? preferenceScore;
  String? badCount;
  String? staleCount;
  String? blockId;
  String? balance;
  String? currency;
  String? lastTransactionTime;

  PeerProfile(this.peerId, this.clientId);

  PeerProfile.fromJson(Map json)
      : peerId = json['peerId'],
        clientId = json['clientId'],
        clientDevice = json['clientDevice'],
        clientType = json['clientType'],
        locale = json['locale'],
        userId = json['userId'],
        username = json['username'],
        seedColor = json['seedColor'] ?? Colors.cyan.value,
        darkSeedColor = json['darkSeedColor'] ?? Colors.cyan.value,
        themeMode = json['themeMode'],
        udpSwitch =
            json['udpSwitch'] == true || json['udpSwitch'] == 1 ? true : false,
        downloadSwitch =
            json['downloadSwitch'] == true || json['downloadSwitch'] == 1
                ? true
                : false,
        localDataCryptoSwitch = json['localDataCryptoSwitch'] == true ||
                json['localDataCryptoSwitch'] == 1
            ? true
            : false,
        autoLogin =
            json['autoLogin'] == true || json['autoLogin'] == 1 ? true : false,
        developerOption =
            json['developerOption'] == true || json['developerOption'] == 1
                ? true
                : false,
        logLevel = json['logLevel'],
        lastSyncTime = json['lastSyncTime'],
        discoveryAddress = json['discoveryAddress'],
        lastFindNodeTime = json['lastFindNodeTime'],
        mobileVerified = json['mobileVerified'],
        visibilitySetting = json['visibilitySetting'],
        creditScore = json['creditScore'] ?? 0,
        preferenceScore = json['preferenceScore'],
        badCount = json['badCount'],
        staleCount = json['staleCount'],
        blockId = json['blockId'],
        balance = json['balance'],
        currency = json['currency'],
        lastTransactionTime = json['lastTransactionTime'],
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
      'seedColor': seedColor,
      'darkSeedColor': darkSeedColor,
      'themeMode': themeMode,
      'udpSwitch': udpSwitch,
      'downloadSwitch': downloadSwitch,
      'localDataCryptoSwitch': localDataCryptoSwitch,
      'autoLogin': autoLogin,
      'developerOption': developerOption,
      'logLevel': logLevel,
      'lastSyncTime': lastSyncTime,
      'discoveryAddress': discoveryAddress,
      'lastFindNodeTime': lastFindNodeTime,
      'mobileVerified': mobileVerified,
      'visibilitySetting': visibilitySetting,
      'creditScore': creditScore,
      'preferenceScore': preferenceScore,
      'badCount': badCount,
      'staleCount': staleCount,
      'blockId': blockId,
      'balance': balance,
      'currency': currency,
      'lastTransactionTime': lastTransactionTime,
    });
    return json;
  }
}
