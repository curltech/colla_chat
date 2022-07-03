import '../../../entity/dht/peerclient.dart';
import '../../../entity/p2p/message.dart';
import '../../../provider/app_data_provider.dart';
import '../baseaction.dart';

///在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
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
