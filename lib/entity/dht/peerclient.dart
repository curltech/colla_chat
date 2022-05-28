import 'base.dart';

class PeerClient extends PeerLocation {
  String? clientId;
  String? clientDevice;
  String? clientType;
  String? deviceToken;
  String? language;
  // 用户头像（base64字符串）
  String? avatar;
  String? mobile;
  String? mobileVerified;
  String? visibilitySetting;
  /**
   * 客户连接到节点的位置
   */
  String? connectPeerId;
  String? connectSessionId;
  String? activeStatus;
  String? lastAccessTime;

  String? expireDate;
  String? signatureData;
  String? signature;
  String? previousPublicKeySignature;
  String? trustLevel;
  PeerClient();
  PeerClient.fromJson(Map json)
      : mobile = json['mobile'],
        clientId = json['clientId'],
        clientDevice = json['clientDevice'],
        clientType = json['clientType'],
        deviceToken = json['deviceToken'],
        language = json['language'],
        avatar = json['avatar'],
        mobileVerified = json['mobileVerified'],
        visibilitySetting = json['visibilitySetting'],
        lastAccessTime = json['lastAccessTime'],
        activeStatus = json['activeStatus'],
        connectPeerId = json['connectPeerId'],
        connectSessionId = json['connectSessionId'],
        signature = json['signature'],
        previousPublicKeySignature = json['previousPublicKeySignature'],
        signatureData = json['signatureData'],
        expireDate = json['expireDate'],
        trustLevel = json['trustLevel'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'mobile': mobile,
      'clientId': clientId,
      'clientDevice': clientDevice,
      'clientType': clientType,
      'deviceToken': deviceToken,
      'language': language,
      'avatar': avatar,
      'mobileVerified': mobileVerified,
      'visibilitySetting': visibilitySetting,
      'lastAccessTime': lastAccessTime,
      'activeStatus': activeStatus,
      'connectPeerId': connectPeerId,
      'connectSessionId': connectSessionId,
      'previousPublicKeySignature': previousPublicKeySignature,
      'signature': signature,
      'signatureData': signatureData,
      'expireDate': expireDate,
      'trustLevel': trustLevel,
    });
    return json;
  }
}
