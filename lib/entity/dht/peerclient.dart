import 'base.dart';

const int defaultExpireDate = 3600 * 24 * 365;

class PeerClient extends PeerLocation {
  String? clientId;
  String? deviceToken;
  String? mobile;

  /// 客户连接到节点的位置
  String? connectPeerId;
  String? connectSessionId;
  String? activeStatus;
  String? lastAccessTime;
  int? expireDate = defaultExpireDate;
  String? signatureData;
  String? signature;
  String? previousPublicKeySignature;
  String? trustLevel;

  PeerClient();

  PeerClient.fromJson(Map json)
      : mobile = json['mobile'],
        clientId = json['clientId'],
        deviceToken = json['deviceToken'],
        lastAccessTime = json['lastAccessTime'],
        activeStatus = json['activeStatus'],
        connectPeerId = json['connectPeerId'],
        connectSessionId = json['connectSessionId'],
        signature = json['signature'],
        previousPublicKeySignature = json['previousPublicKeySignature'],
        signatureData = json['signatureData'],
        expireDate =
            json['expireDate'] != null ? json['expireDate'] : defaultExpireDate,
        trustLevel = json['trustLevel'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'mobile': mobile,
      'clientId': clientId,
      'deviceToken': deviceToken,
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
