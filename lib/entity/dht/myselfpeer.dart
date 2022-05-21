import 'package:colla_chat/entity/dht/peerprofile.dart';
import 'package:cryptography/cryptography.dart';

import '../../crypto/cryptography.dart';
import 'base.dart';

/// 本节点实体
class MyselfPeer extends PeerEntity {
  String? peerPrivateKey;
  String? privateKey;
  String? signalPublicKey;
  String? signalPrivateKey;
  String? loginStatus;
  String? password;

  /// 以下的字段是和证书相关，不是必须的
  String? certType;
  String? certFormat;
  // peer的保护密码，不保存到数据库，hash后成为password
  String? oldPassword;
  // peer的证书的原密码，申请新证书的时候必须提供，不保存数据库
  String? oldCertPassword;
  // peer的新证书的密码，申请新证书的时候必须提供，不保存数据库
  String? newCertPassword;
  String? certContent;

  /// 主发现地址，表示可信的，可以推荐你的peer地址
  String? discoveryAddress;
  String? lastFindNodeTime;
  // 用户头像（base64字符串）
  String? avatar;
  String? mobileVerified;
  // 可见性YYYYYY (peerId, mobileNumber, groupChat, qrCode, contactCard, name）
  String? visibilitySetting;
}
