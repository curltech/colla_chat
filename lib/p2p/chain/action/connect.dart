import '../../../app.dart';
import '../../../entity/p2p/message.dart';
import '../baseaction.dart';

///在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
class ConnectAction extends BaseAction {
  ConnectAction(MsgType msgType) : super(msgType) {
    logger.i('Action MsgType $msgType');
  }

  Future<dynamic> connect(dynamic peerClient) async {
    ChainMessage chainMessage = await prepareSend(peerClient);
    chainMessage.payloadType = PayloadType.PeerClient.name;

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }
}

final connectAction = ConnectAction(MsgType.CONNECT);
