import 'package:colla_chat/entity/dht/peerprofile.dart';
import 'package:flutter/material.dart';

import '../base.dart';

const String defaultExpireDate = '9999-12-31T23:59:59';

enum ActiveStatus { Up, Down }

/// PeerEntity代表具有peerId，peerPublicKey，publicKey的实体
/// 通过peerId和address表明自己的位置，包含有ed25519和x25519两个公钥
abstract class PeerEntity extends StatusEntity {
  // ed25519的公钥,表明身份,用于人，设备，如果是libp2p节点直接使用libp2p的id
  String peerId;
  String name;

  //加密的配置
  //String? securityContext;
  //   ed25519的公私钥,表明身份，用于签名
  String? peerPublicKey;

  // x25519的公私钥,加解密，交换信息
  String? publicKey;
  String? address;
  String? mobile;
  String? email;

  // 用户头像（base64字符串）
  String? avatar;
  String? startDate;
  String? endDate;
  String? lastAccessMillis;
  String? lastAccessTime;
  String? activeStatus;
  String? previousPublicKeySignature;
  String? signature;
  String? signatureData;
  String? expireDate = defaultExpireDate;
  String? trustLevel;

  //不存储数据库
  Widget? avatarImage;
  PeerProfile? peerProfile;

  PeerEntity(this.peerId, this.name);

  PeerEntity.fromJson(Map json)
      : peerId = json['peerId'],
        name = json['name'] ?? '',
        peerPublicKey = json['peerPublicKey'] ?? '',
        publicKey = json['publicKey'] ?? '',
        address = json['address'],
        mobile = json['mobile'],
        email = json['email'],
        avatar = json['avatar'],
        startDate = json['startDate'],
        endDate = json['endDate'],
        lastAccessMillis = json['lastAccessMillis'],
        lastAccessTime = json['lastAccessTime'],
        activeStatus = json['activeStatus'],
        previousPublicKeySignature = json['previousPublicKeySignature'],
        signature = json['signature'],
        signatureData = json['signatureData'],
        expireDate = json['expireDate'],
        trustLevel = json['trustLevel'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'peerId': peerId,
      'name': name,
      'peerPublicKey': peerPublicKey,
      'publicKey': publicKey,
      'address': address,
      'mobile': mobile,
      'email': email,
      'avatar': avatar,
      'startDate': startDate,
      'endDate': endDate,
      'lastAccessMillis': lastAccessMillis,
      'lastAccessTime': lastAccessTime,
      'activeStatus': activeStatus,
      'previousPublicKeySignature': previousPublicKeySignature,
      'signature': signature,
      'signatureData': signatureData,
      'expireDate': expireDate,
      'trustLevel': trustLevel,
    });
    return json;
  }
}
