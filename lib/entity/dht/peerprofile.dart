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
  bool udpSwitch = false;
  bool downloadSwitch = false;
  bool localDataCryptoSwitch = false;
  bool autoLoginSwitch = false;
  bool developerOption = false;
  String? logLevel;
  String? lastSyncTime;
  String? avatar;

  PeerProfile();

  PeerProfile.fromJson(Map json)
      : peerId = json['peerId'],
        clientId = json['clientId'],
        clientDevice = json['clientDevice'],
        clientType = json['clientType'],
        deviceToken = json['deviceToken'],
        language = json['language'],
        avatar = json['avatar'],
        userId = json['userId'],
        username = json['username'],
        primaryColor = json['primaryColor'],
        secondaryColor = json['secondaryColor'],
        lightDarkMode = json['lightDarkMode'],
        udpSwitch =
            json['udpSwitch'] == true || json['udpSwitch'] == 1 ? true : false,
        downloadSwitch =
            json['downloadSwitch'] == true || json['downloadSwitch'] == 1
                ? true
                : false,
        localDataCryptoSwitch = json['localDataCryptoSwitch'] == true ||
                json['localDataCryptoSwitch'] == 1
            ? true
            : false,
        autoLoginSwitch =
            json['autoLoginSwitch'] == true || json['autoLoginSwitch'] == 1
                ? true
                : false,
        developerOption =
            json['developerOption'] == true || json['developerOption'] == 1
                ? true
                : false,
        logLevel = json['logLevel'],
        lastSyncTime = json['lastSyncTime'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'peerId': peerId,
      'clientId': clientId,
      'clientDevice': clientDevice,
      'clientType': clientType,
      'deviceToken': deviceToken,
      'language': language,
      'avatar': avatar,
      'userId': userId,
      'username': username,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'lightDarkMode': lightDarkMode,
      'udpSwitch': udpSwitch,
      'downloadSwitch': downloadSwitch,
      'localDataCryptoSwitch': localDataCryptoSwitch,
      'autoLoginSwitch': autoLoginSwitch,
      'developerOption': developerOption,
      'logLevel': logLevel,
      'lastSyncTime': lastSyncTime,
    });
    return json;
  }
}
