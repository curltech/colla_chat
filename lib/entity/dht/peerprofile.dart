import 'package:flutter/material.dart';

import '../base.dart';

/// 节点的附属信息，包括个性化的配置
class PeerProfile extends StatusEntity {
  String? peerId;
  String? clientDevice;
  String? clientType;

  // 对应的用户编号
  String? userId;
  String? username;

  // 个性化配置
  String? locale;
  String? primaryColor;
  String? secondaryColor;
  String? brightness;
  bool udpSwitch = false;
  bool downloadSwitch = false;
  bool localDataCryptoSwitch = false;
  bool autoLoginSwitch = false;
  bool developerOption = false;
  String? logLevel;
  String? lastSyncTime;

  /// 主发现地址，表示可信的，可以推荐你的peer地址
  String? discoveryAddress;
  String? lastFindNodeTime;

  // 用户头像（base64字符串）
  String? avatar;
  Widget? avatarImage;
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

  PeerProfile();

  PeerProfile.fromJson(Map json)
      : peerId = json['peerId'],
        clientDevice = json['clientDevice'],
        clientType = json['clientType'],
        locale = json['locale'],
        avatar = json['avatar'],
        userId = json['userId'],
        username = json['username'],
        primaryColor = json['primaryColor'],
        secondaryColor = json['secondaryColor'],
        brightness = json['brightness'],
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
        autoLoginSwitch =
            json['autoLoginSwitch'] == true || json['autoLoginSwitch'] == 1
                ? true
                : false,
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
        creditScore = json['creditScore'] != null ? json['creditScore'] : 0,
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
      'clientDevice': clientDevice,
      'clientType': clientType,
      'locale': locale,
      'avatar': avatar,
      'userId': userId,
      'username': username,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'brightness': brightness,
      'udpSwitch': udpSwitch,
      'downloadSwitch': downloadSwitch,
      'localDataCryptoSwitch': localDataCryptoSwitch,
      'autoLoginSwitch': autoLoginSwitch,
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
