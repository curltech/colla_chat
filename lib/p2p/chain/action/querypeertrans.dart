import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';

///查询服务器的交易信息
class QueryPeerTransAction extends BaseAction {
  QueryPeerTransAction(super.msgType);

  Future<bool> queryPeerTrans(dynamic data) async {
    ChainMessage chainMessage = await prepareSend(data);

    return await send(chainMessage);
  }
}

final queryPeerTransAction = QueryPeerTransAction(MsgType.QUERYPEERTRANS);
