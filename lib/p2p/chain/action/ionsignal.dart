import '../../../app.dart';
import '../../../tool/util.dart';
import '../../../entity/p2p/message.dart';
import '../baseaction.dart';

/**
    在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
 */
class IonSignalAction extends BaseAction {
  IonSignalAction(MsgType msgType) : super(msgType) {
    //ionSfuClientPool.registSignalAction(this);
  }

  Future<dynamic> signal(
      String connectPeerId, dynamic data, String targetPeerId) async {
    ChainMessage? chainMessage =
        await prepareSend(connectPeerId, data, targetPeerId: targetPeerId);
    chainMessage.needEncrypt = true;

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      logger.i('IonSignal response:${JsonUtil.toJsonString(response)}');
      return response.payload;
    }

    return null;
  }

  Future<ChainMessage?> receive(ChainMessage chainMessage) async {
    ChainMessage? _chainMessage = await super.receive(chainMessage);
    if (_chainMessage != null && receivers.isNotEmpty) {
      ionSignalAction.receivers.forEach((String key, dynamic receiver) => {
            receiver(_chainMessage.srcPeerId, _chainMessage.srcConnectPeerId,
                _chainMessage.srcConnectSessionId, _chainMessage.payload)
          });

      return null;
    }

    return null;
  }
}

final ionSignalAction = IonSignalAction(MsgType.IONSIGNAL);
