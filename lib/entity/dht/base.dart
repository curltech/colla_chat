import 'package:colla_chat/entity/dht/peerprofile.dart';

import '../base.dart';
import 'myselfpeer.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:cryptography/cryptography.dart';

enum ActiveStatus { Up, Down }

/// 通过peerId和address表明自己的位置
abstract class PeerLocation extends StatusEntity {
  /// ed25519的公钥,表明身份,用于人，设备，如果是libp2p节点直接使用libp2p的id
  late String peerId;
  String? kind;
  String? name;
  String? securityContext;

  ///   ed25519的公私钥,表明身份，用于签名
  String? peerPublicKey;

  /// x25519的公私钥,加解密，交换信息
  String? publicKey;
  String? address;
  String? lastUpdateTime;
}

/// 附加信息代表实体的基础信息
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
