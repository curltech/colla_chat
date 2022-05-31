import '../../../entity/p2p/message.dart';
import '../baseaction.dart';

/**
    在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
    Ping只是一个演示，适合点对点的通信，这种方式灵活度高，但是需要自己实现全网遍历的功能
    chat就可以采用这种方式
 */
class PutValueAction extends BaseAction {
  PutValueAction(MsgType msgType) : super(msgType);

  Future<dynamic> putValue(String payloadType, dynamic value) async {
    ChainMessage? chainMessage = await prepareSend(value);
    chainMessage.payloadType = payloadType;

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      if (response.payload == MsgType.ERROR) {
        return response.tip;
      } else {
        return response.payload;
      }
    }

    return null;
  }
}

final putValueAction = PutValueAction(MsgType.PUTVALUE);
