import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';

/// 根据目标peerpoint的peerid搜索
class FindPeerAction extends BaseAction {
  FindPeerAction(MsgType msgType) : super(msgType);

  Future<bool> findPeer(String targetPeerId) async {
    ChainMessage? chainMessage = await prepareSend({'peerId': targetPeerId});

    return await send(chainMessage);
  }

  @override
  Future<void> transferPayload(ChainMessage chainMessage) async {
    super.transferPayload(chainMessage);
    if (chainMessage.payloadType == PayloadType.peerEndpoints.name) {
      List<PeerEndpoint> peerEndpoints = [];
      var jsons = chainMessage.payload;
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
