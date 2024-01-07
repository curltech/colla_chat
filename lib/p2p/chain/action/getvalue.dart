import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';

///根据key值搜索服务器数据
class GetValueAction extends BaseAction {
  GetValueAction(super.msgType);

  Future<bool> getValue(String key) async {
    ChainMessage chainMessage = await prepareSend({'key': key});

    return await send(chainMessage);
  }
}

final getValueAction = GetValueAction(MsgType.GETVALUE);
