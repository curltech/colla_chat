
import 'base.dart';

///联系人（Linkman）能够连接节点服务器的客户
///在表中同peerId的peerclient根据clientId的不同，有多条记录
///代表一个联系人（Linkman）通过多个机器设备登录
///这些数据的来源都是查询节点服务器
class PeerClient extends PeerEntity {
  String? deviceToken; //设备的远程推送通知的token，唯一确定设备
  String? deviceDesc; //设备的描述，比如是ios还是android
  // 客户连接到节点的位置
  String? connectPeerId;
  String? connectAddress;
  String? connectSessionId;

  PeerClient(super.peerId, super.name, {super.clientId});

  PeerClient.fromJson(super.json)
      : deviceToken = json['deviceToken'],
        deviceDesc = json['deviceDesc'],
        connectPeerId = json['connectPeerId'],
        connectAddress = json['connectAddress'],
        connectSessionId = json['connectSessionId'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'deviceToken': deviceToken,
      'deviceDesc': deviceDesc,
      'connectPeerId': connectPeerId,
      'connectAddress': connectAddress,
      'connectSessionId': connectSessionId,
    });
    return json;
  }
}
