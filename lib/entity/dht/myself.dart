import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/dht/peerprofile.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';

import 'myselfpeer.dart';

/// 单例本节点对象，包含公私钥，本节点配置，密码和过往的节点信息
/// 在登录成功后被初始化
/// 可以随时获取本节点的信息
class Myself {
  String? peerId;
  String? clientId;
  // peer是ed25519,英语身份认证
  SimplePublicKey? peerPublicKey;
  SimpleKeyPair? peerPrivateKey;

  /// x25519，用于加解密
  SimplePublicKey? publicKey;
  SimpleKeyPair? privateKey;

  MyselfPeer? myselfPeer;
  PeerProfile? peerProfile;
  Widget? avatarImage;

  ///当连接p2p节点成功后设置
  PeerClient? myselfPeerClient;
  String? password;
  List<SimpleKeyPair> expiredKeys = [];

  /// signal协议
  String? signalPublicKey;
  String? signalPrivateKey;
}

///全集唯一的当前用户，存放在内存中，当前重新登录时里面的值会钱换到新的值
final myself = Myself();
