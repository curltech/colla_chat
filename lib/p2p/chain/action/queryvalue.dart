import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';

///查询服务器的数据
class QueryValueAction extends BaseAction {
  QueryValueAction(super.msgType);

  Future<bool> queryValue(dynamic data) async {
    ChainMessage chainMessage = await prepareSend(data);

    return await send(chainMessage);
  }
}

final queryValueAction = QueryValueAction(MsgType.QUERYVALUE);
