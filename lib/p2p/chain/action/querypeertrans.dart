import '../../../entity/p2p/message.dart';
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

  @override
  Future<ChainMessage?> receive(ChainMessage chainMessage) async {
    ChainMessage? chainMessage_ = await super.receive(chainMessage);
    if (chainMessage_ != null && receivers.isNotEmpty) {
      receivers.forEach((String key, dynamic receiver) async =>
          {await receiver(chainMessage_.payload)});

      return null;
    }

    return null;
  }
}

final queryPeerTransAction = QueryPeerTransAction(MsgType.QUERYPEERTRANS);
