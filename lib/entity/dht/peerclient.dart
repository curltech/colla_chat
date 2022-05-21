import '../base.dart';

class PeerClient extends StatusEntity {
  String? peerId;
  String? clientId;
  String? clientDevice;
  String? clientType;
  String? deviceToken;
  String? language;
  // 用户头像（base64字符串）
  String? avatar;
  String? name;
  String? mobile;
  String? mobileVerified;
  String? visibilitySetting;

  String? peerPublicKey;
  String? publicKey;
  /**
   * 客户连接到节点的位置
   */
  String? connectPeerId;
  String? connectSessionId;
  String? activeStatus;
  String? lastUpdateTime;
  String? lastAccessTime;

  String? expireDate;
  String? signatureData;
  String? signature;
  String? previousPublicKeySignature;
  String? trustLevel;
}
