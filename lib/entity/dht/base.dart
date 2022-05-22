import 'package:colla_chat/entity/dht/peerprofile.dart';

import '../base.dart';
import 'myselfpeer.dart';
import 'package:cryptography/cryptography.dart';

enum ActiveStatus { Up, Down }

/// 通过peerId和address表明自己的位置，包含有ed25519和x25519两个公钥
abstract class PeerLocation extends StatusEntity {
  /// ed25519的公钥,表明身份,用于人，设备，如果是libp2p节点直接使用libp2p的id
  late String peerId;
  String? kind;
  String? name;
  String? securityContext;

  ///   ed25519的公私钥,表明身份，用于签名
  late String peerPublicKey;

  /// x25519的公私钥,加解密，交换信息
  late String publicKey;
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
  int? creditScore;
  String? preferenceScore;
  String? badCount;
  String? staleCount;
  String? lastAccessMillis;
  String? lastAccessTime;
  String? activeStatus;
  String? blockId;
  String? balance;
  String? currency;
  String? lastTransactionTime;
  String? previousPublicKeySignature;
  String? signature;
  String? signatureData;
  String? expireDate;
  int? version;
  PeerEntity();
  PeerEntity.fromJson(Map json)
      : mobile = json['mobile'],
        email = json['email'],
        startDate = json['startDate'],
        endDate = json['endDate'],
        creditScore = json['creditScore'],
        preferenceScore = json['preferenceScore'],
        badCount = json['badCount'],
        staleCount = json['staleCount'],
        lastAccessMillis = json['lastAccessMillis'],
        lastAccessTime = json['lastAccessTime'],
        activeStatus = json['activeStatus'],
        blockId = json['blockId'],
        balance = json['balance'],
        currency = json['currency'],
        lastTransactionTime = json['lastTransactionTime'],
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
      'creditScore': creditScore,
      'preferenceScore': preferenceScore,
      'badCount': badCount,
      'staleCount': staleCount,
      'lastAccessMillis': lastAccessMillis,
      'lastAccessTime': lastAccessTime,
      'activeStatus': activeStatus,
      'blockId': blockId,
      'balance': balance,
      'currency': currency,
      'lastTransactionTime': lastTransactionTime,
      'previousPublicKeySignature': previousPublicKeySignature,
      'signature': signature,
      'signatureData': signatureData,
      'expireDate': expireDate,
      'version': version,
    });
    return json;
  }
}

/// 单例本节点对象，包含公私钥，本节点配置，密码和过往的节点信息
/// 可以随时获取本节点的信息
class Myself {
  // peer是ed25519,英语身份认证
  Object? peerPublicKey;
  Object? peerPrivateKey;

  /// x25519，用于加解密
  SimplePublicKey? publicKey;
  SimpleKeyPair? privateKey;

  /// signal协议
  String? signalPublicKey;
  String? signalPrivateKey;
  late MyselfPeer myselfPeer;
  PeerProfile? peerProfile;
  String? myselfPeerClient; // combine myselfPeer & peerProfile
  String? password;
  List<SimpleKeyPair> expiredKeys = [];
}

final myself = Myself();
