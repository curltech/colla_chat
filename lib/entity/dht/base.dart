import 'package:colla_chat/entity/dht/peerprofile.dart';

import '../base.dart';
import 'myselfpeer.dart';
import 'package:cryptography/cryptography.dart';

enum ActiveStatus { Up, Down }

/// 通过peerId和address表明自己的位置，包含有ed25519和x25519两个公钥
abstract class PeerLocation extends StatusEntity {
  /// ed25519的公钥,表明身份,用于人，设备，如果是libp2p节点直接使用libp2p的id
  String? peerId;
  String? kind;
  String? name;
  String? securityContext;

  ///   ed25519的公私钥,表明身份，用于签名
  String peerPublicKey = '';

  /// x25519的公私钥,加解密，交换信息
  String publicKey = '';
  String? address;
  String? lastUpdateTime;
  PeerLocation();
  PeerLocation.fromJson(Map json)
      : peerId = json['peerId'],
        kind = json['kind'],
        name = json['name'],
        peerPublicKey = json['peerPublicKey'],
        publicKey = json['publicKey'],
        address = json['address'],
        lastUpdateTime = json['lastUpdateTime'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'peerId': peerId,
      'kind': kind,
      'name': name,
      'peerPublicKey': peerPublicKey,
      'publicKey': publicKey,
      'address': address,
      'lastUpdateTime': lastUpdateTime,
    });
    return json;
  }
}

/// 附加信息代表实体的基础信息,包含邮件，手机号码
abstract class PeerEntity extends PeerLocation {
  String? mobile;
  String? email;
  String? startDate;
  String? endDate;
  String? lastAccessMillis;
  String? lastAccessTime;
  String? activeStatus;
  String? previousPublicKeySignature;
  String? signature;
  String? signatureData;
  String? expireDate;
  int version = 0;
  PeerEntity();
  PeerEntity.fromJson(Map json)
      : mobile = json['mobile'],
        email = json['email'],
        startDate = json['startDate'],
        endDate = json['endDate'],
        lastAccessMillis = json['lastAccessMillis'],
        lastAccessTime = json['lastAccessTime'],
        activeStatus = json['activeStatus'],
        previousPublicKeySignature = json['previousPublicKeySignature'],
        signature = json['signature'],
        signatureData = json['signatureData'],
        expireDate = json['expireDate'],
        version = json['version'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'mobile': mobile,
      'email': email,
      'startDate': startDate,
      'endDate': endDate,
      'lastAccessMillis': lastAccessMillis,
      'lastAccessTime': lastAccessTime,
      'activeStatus': activeStatus,
      'previousPublicKeySignature': previousPublicKeySignature,
      'signature': signature,
      'signatureData': signatureData,
      'expireDate': expireDate,
      'version': version,
    });
    return json;
  }
}
