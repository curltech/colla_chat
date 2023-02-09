

import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';

///根据payloadType把数据上传到服务器
class PutValueAction extends BaseAction {
  PutValueAction(MsgType msgType) : super(msgType);

  Future<bool> putValue(String payloadType, dynamic value) async {
    ChainMessage? chainMessage = await prepareSend(value);
    chainMessage.payloadType = payloadType;

    return await send(chainMessage);
  }
}

final putValueAction = PutValueAction(MsgType.PUTVALUE);
