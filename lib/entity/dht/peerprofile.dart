import '../base.dart';

/// 节点的附属信息，包括个性化的配置
class PeerProfile extends StatusEntity {
  String? peerId;
  String? clientId;
  String? clientType;
  String? clientDevice;
  String? deviceToken;
  // 对应的用户编号
  String? userId;
  // 用户名
  String? username;

  // 个性化配置
  String? language;
  String? primaryColor;
  String? secondaryColor;
  String? lightDarkMode;
  bool? udpSwitch;
  bool? downloadSwitch;
  bool? localDataCryptoSwitch;
  bool? autoLoginSwitch;
  bool? developerOption;
  String? logLevel;
  String? lastSyncTime;
  String? avatar;
}
