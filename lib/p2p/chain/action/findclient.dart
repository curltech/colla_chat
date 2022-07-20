import '../../../entity/dht/peerclient.dart';
import '../../../entity/p2p/message.dart';
import '../../../tool/util.dart';
import '../baseaction.dart';

///根据目标peerclient的peerid，电话和名称搜索，异步返回
class FindClientAction extends BaseAction {
  FindClientAction(MsgType msgType) : super(msgType);

  Future<List<dynamic>?> findClient(String targetPeerId, String mobileNumber,
      String email, String name) async {
    ChainMessage chainMessage = await prepareSend({
      'peerId': targetPeerId,
      'mobileNumber': mobileNumber,
      'email': email,
      'name': name
    });

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }

  @override
  Future<void> transferPayload(ChainMessage chainMessage) async {
    if (chainMessage.payloadType == PayloadType.peerClients.name) {
      List<PeerClient> peerClients = [];
      var payload = chainMessage.payload;
      var jsons = JsonUtil.toJson(payload);
      if (jsons is List) {
        for (var json in jsons) {
          var peerClient = PeerClient.fromJson(json);
          peerClients.add(peerClient);
        }
      }
      chainMessage.payload = peerClients;
    }
  }
}

final findClientAction = FindClientAction(MsgType.FINDCLIENT);
