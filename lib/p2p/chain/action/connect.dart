import '../../../provider/app_data.dart';
import '../../../entity/dht/peerclient.dart';
import '../../../entity/p2p/message.dart';
import '../baseaction.dart';

///在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
class ConnectAction extends BaseAction {
  ConnectAction(MsgType msgType) : super(msgType) {
    logger.i('Action MsgType $msgType');
  }

  ///走https协议，同步获取返回信息
  Future<bool> connect(PeerClient peerClient) async {
    var appParams = AppDataProvider.instance;
    ChainMessage chainMessage = await prepareSend(peerClient,
        connectAddress: appParams.defaultNodeAddress.httpConnectAddress);
    chainMessage.payloadType = PayloadType.peerClient.name;

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      if (response.statusCode == 200) {
        return true;
      }
    }

    return false;
  }
}

final connectAction = ConnectAction(MsgType.CONNECT);
