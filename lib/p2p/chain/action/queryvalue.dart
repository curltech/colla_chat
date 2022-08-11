import '../../../entity/p2p/chain_message.dart';
import '../baseaction.dart';

///查询服务器的数据
class QueryValueAction extends BaseAction {
  QueryValueAction(MsgType msgType) : super(msgType);

  Future<List<dynamic>?> queryValue(dynamic data) async {
    ChainMessage chainMessage = await prepareSend(data);

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }
}

final queryValueAction = QueryValueAction(MsgType.QUERYVALUE);
