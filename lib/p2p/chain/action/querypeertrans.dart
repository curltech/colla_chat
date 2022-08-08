import '../../../entity/p2p/chain_message.dart';
import '../baseaction.dart';

///查询服务器的交易信息
class QueryPeerTransAction extends BaseAction {
  QueryPeerTransAction(MsgType msgType) : super(msgType);

  Future<List<dynamic>?> queryPeerTrans(dynamic data) async {
    ChainMessage chainMessage = await prepareSend(data);

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }

}

final queryPeerTransAction = QueryPeerTransAction(MsgType.QUERYPEERTRANS);
