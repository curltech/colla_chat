import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/tool/string_util.dart';

///根据目标peerclient的peerid，电话和名称搜索，异步返回
class FindClientAction extends BaseAction {
  FindClientAction(super.msgType);

  Future<bool> findClient(
      String targetPeerId, String mobile, String email, String name) async {
    if (StringUtil.isNotEmpty(mobile)) {
      mobile =
          CryptoUtil.encodeBase64(await cryptoGraphy.hash(mobile.codeUnits));
    }
    if (StringUtil.isNotEmpty(email)) {
      email = CryptoUtil.encodeBase64(await cryptoGraphy.hash(email.codeUnits));
    }
    ChainMessage chainMessage = await prepareSend({
      'peerId': targetPeerId,
      'mobile': mobile,
      'email': email,
      'name': name
    });

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
    }
  }
}

final findClientAction = FindClientAction(MsgType.FINDCLIENT);
