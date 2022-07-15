import '../../../entity/p2p/message.dart';
import '../baseaction.dart';

///根据payloadType把数据上传到服务器
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
