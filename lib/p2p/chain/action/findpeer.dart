import '../../../entity/dht/peerendpoint.dart';
import '../../../entity/p2p/chain_message.dart';
import '../../../tool/util.dart';
import '../baseaction.dart';

/// 根据目标peerpoint的peerid搜索
class FindPeerAction extends BaseAction {
  FindPeerAction(MsgType msgType) : super(msgType);

  Future<dynamic> findPeer(String targetPeerId) async {
    ChainMessage? chainMessage = await prepareSend({'peerId': targetPeerId});

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }

  @override
  Future<void> transferPayload(ChainMessage chainMessage) async {
    if (chainMessage.payloadType == PayloadType.peerEndpoints.name) {
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

final findPeerAction = FindPeerAction(MsgType.FINDPEER);
