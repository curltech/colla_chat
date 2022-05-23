import 'base.dart';

/// 本节点实体
class MyselfPeer extends PeerEntity {
  late String loginName;
  late String peerPrivateKey = '';
  late String privateKey = '';
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

  /// 主发现地址，表示可信的，可以推荐你的peer地址
  String? discoveryAddress;
  String? lastFindNodeTime;

  // 用户头像（base64字符串）
  String? avatar;
  String? mobileVerified;

  // 可见性YYYYYY (peerId, mobileNumber, groupChat, qrCode, contactCard, name）
  String? visibilitySetting;

  MyselfPeer();

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
        discoveryAddress = json['discoveryAddress'],
        lastFindNodeTime = json['lastFindNodeTime'],
        avatar = json['avatar'],
        mobileVerified = json['mobileVerified'],
        visibilitySetting = json['visibilitySetting'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
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
      'discoveryAddress': discoveryAddress,
      'lastFindNodeTime': lastFindNodeTime,
      'avatar': avatar,
      'mobileVerified': mobileVerified,
      'visibilitySetting': visibilitySetting,
    });
    return json;
  }
}
