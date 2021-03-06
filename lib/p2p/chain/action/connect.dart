import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/tool/util.dart';

import '../../../entity/dht/peerclient.dart';
import '../../../entity/p2p/message.dart';
import '../../../provider/app_data_provider.dart';
import '../baseaction.dart';

///把自己的peerclient信息注册到服务器，表示自己上线
class ConnectAction extends BaseAction {
  ConnectAction(MsgType msgType) : super(msgType) {
    logger.i('Action MsgType $msgType');
  }

  Future<ChainMessage?> connect(PeerClient peerClient) async {
    ChainMessage chainMessage = await prepareSend(peerClient);
    chainMessage.payloadType = PayloadType.peerClient.name;

    ChainMessage? response = await send(chainMessage);

    return response;
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
    } else if (chainMessage.payloadType == PayloadType.peerEndpoints.name) {
      List<PeerEndpoint> peerEndpoints = [];
      var payload = chainMessage.payload;
      var jsons = JsonUtil.toJson(payload);
      if (jsons is List) {
        for (var json in jsons) {
          var peerEndpoint = PeerEndpoint.fromJson(json);
          peerEndpoints.add(peerEndpoint);
        }
      }
      chainMessage.payload = peerEndpoints;
    }
  }
}

final connectAction = ConnectAction(MsgType.CONNECT);
