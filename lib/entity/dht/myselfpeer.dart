import 'package:colla_chat/entity/dht/peerclient.dart';

/// 本节点实体，存储私钥
class MyselfPeer extends PeerClient {
  String loginName = '';
  String peerPrivateKey = '';
  String privateKey = '';
  String signalPublicKey = '';
  String signalPrivateKey = '';
  String? loginStatus;
  String? password;

  MyselfPeer(super.peerId, super.name, String clientId, this.loginName)
      : super(clientId: clientId);

  MyselfPeer.fromJson(super.json)
      : loginName = json['loginName'],
        privateKey = json['privateKey'],
        peerPrivateKey = json['peerPrivateKey'],
        signalPublicKey = json['signalPublicKey'],
        signalPrivateKey = json['signalPrivateKey'],
        loginStatus = json['loginStatus'],
        password = json['password'],
        super.fromJson();

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
    });
    return json;
  }
}
