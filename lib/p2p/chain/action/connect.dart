import 'package:colla_chat/tool/util.dart';

import '../../../entity/dht/peerclient.dart';
import '../../../entity/p2p/message.dart';
import '../../../provider/app_data_provider.dart';
import '../../../service/dht/peerclient.dart';
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
}

final connectAction = ConnectAction(MsgType.CONNECT);
