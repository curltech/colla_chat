import 'base.dart';

/// 本节点实体
class MyselfPeer extends PeerEntity {
  String loginName = '';
  String peerPrivateKey = '';
  String privateKey = '';
  String signalPublicKey = '';
  String signalPrivateKey = '';
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

  String clientId;
  String? deviceToken;

  MyselfPeer(String ownerPeerId, String peerId, this.clientId)
      : super(ownerPeerId, peerId);

  MyselfPeer.fromJson(Map json)
      : loginName = json['loginName'],
        privateKey = json['privateKey'],
        peerPrivateKey = json['peerPrivateKey'],
        signalPublicKey = json['signalPublicKey'],
        signalPrivateKey = json['signalPrivateKey'],
        loginStatus = json['loginStatus'],
        password = json['password'],
        certType = json['certType'],
        certFormat = json['certFormat'],
        oldPassword = json['oldPassword'],
        oldCertPassword = json['oldCertPassword'],
        newCertPassword = json['newCertPassword'],
        certContent = json['certContent'],
        clientId = json['clientId'],
        deviceToken = json['deviceToken'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'clientId': clientId,
      'deviceToken': deviceToken,
      'loginName': loginName,
      'peerPrivateKey': peerPrivateKey,
      'privateKey': privateKey,
      'signalPublicKey': signalPublicKey,
      'signalPrivateKey': signalPrivateKey,
      'loginStatus': loginStatus,
      'password': password,
      'certType': certType,
      'certFormat': certFormat,
      'oldPassword': oldPassword,
      'oldCertPassword': oldCertPassword,
      'newCertPassword': newCertPassword,
      'certContent': certContent,
    });
    return json;
  }
}
