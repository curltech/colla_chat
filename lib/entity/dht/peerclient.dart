import 'package:colla_chat/entity/dht/peerprofile.dart';

import 'base.dart';

///联系人，能够连接节点服务器的客户
class PeerClient extends PeerEntity {
  String clientId;
  String? deviceToken;
  bool linkman = false;

  // 客户连接到节点的位置
  String? connectPeerId;
  String? connectAddress;
  String? connectSessionId;
  PeerProfile? peerProfile;

  PeerClient(String ownerPeerId, String peerId, this.clientId, String name)
      : super(ownerPeerId, peerId, name);

  PeerClient.fromJson(Map json)
      : clientId = json['clientId'] ?? '',
        deviceToken = json['deviceToken'],
        linkman =
            json['linkman'] == true || json['linkman'] == 1 ? true : false,
        connectPeerId = json['connectPeerId'],
        connectAddress = json['connectAddress'],
        connectSessionId = json['connectSessionId'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'clientId': clientId,
      'deviceToken': deviceToken,
      'linkman': linkman,
      'connectPeerId': connectPeerId,
      'connectAddress': connectAddress,
      'connectSessionId': connectSessionId,
    });
    return json;
  }
}
