import '../../../entity/dht/peerclient.dart';
import '../../../entity/p2p/message.dart';
import '../../../service/dht/peerclient.dart';
import '../../../tool/util.dart';
import '../baseaction.dart';

///根据目标peerclient的peerid，电话和名称搜索，异步返回
class FindClientAction extends BaseAction {
  FindClientAction(MsgType msgType) : super(msgType);

  Future<List<dynamic>?> findClient(
      String targetPeerId, String mobileNumber, String name) async {
    ChainMessage chainMessage = await prepareSend(
        {'peerId': targetPeerId, 'mobileNumber': mobileNumber, 'name': name});

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }

  ///覆盖父亲的返回处理方法，对返回的负载转换成peerclients，再进一步处理
  @override
  Future<void> response(ChainMessage chainMessage) async {
    if (chainMessage.payloadType == PayloadType.peerClients.name) {
      var payload = chainMessage.payload;
      var jsons = JsonUtil.toJson(payload);
      if (jsons is List) {
        for (var json in jsons) {
          var peerClient = PeerClient.fromJson(json);
          await peerClientService.store(peerClient);
        }
      }
    }
  }
}

final findClientAction = FindClientAction(MsgType.FINDCLIENT);
