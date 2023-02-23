import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/tool/string_util.dart';

///把自己的peerclient信息注册到服务器，表示自己上线
class ConnectAction extends BaseAction {
  ConnectAction(MsgType msgType) : super(msgType) {
    //logger.i('Action MsgType $msgType');
  }

  Future<bool> connect(PeerClient peerClient) async {
    if (StringUtil.isNotEmpty(peerClient.mobile)) {
      peerClient.mobile = CryptoUtil.encodeBase64(
          await cryptoGraphy.hash(peerClient.mobile!.codeUnits));
    }
    if (StringUtil.isNotEmpty(peerClient.email)) {
      peerClient.email = CryptoUtil.encodeBase64(
          await cryptoGraphy.hash(peerClient.email!.codeUnits));
    }
    ChainMessage chainMessage = await prepareSend(peerClient);
    chainMessage.payloadType = PayloadType.peerClient.name;
    peerClient.connectPeerId = chainMessage.connectPeerId;
    peerClient.connectAddress = chainMessage.connectAddress;

    return await send(chainMessage);
  }

  @override
  Future<void> transferPayload(ChainMessage chainMessage) async {
    super.transferPayload(chainMessage);
    if (chainMessage.payloadType == PayloadType.peerClients.name) {
      List<PeerClient> peerClients = [];
      var jsons = chainMessage.payload;
      if (jsons is List) {
        for (var json in jsons) {
          var peerClient = PeerClient.fromJson(json);
          peerClients.add(peerClient);
        }
      }
      chainMessage.payload = peerClients;
    } else if (chainMessage.payloadType == PayloadType.peerEndpoints.name) {
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

final connectAction = ConnectAction(MsgType.CONNECT);
