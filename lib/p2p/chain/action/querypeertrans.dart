import '../../message.dart';
import '../baseaction.dart';

/**
 在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
 Ping只是一个演示，适合点对点的通信，这种方式灵活度高，但是需要自己实现全网遍历的功能
 chat就可以采用这种方式
 */
class QueryPeerTransAction extends BaseAction {
  QueryPeerTransAction(MsgType msgType) : super(msgType);

  Future<List<dynamic>?> queryPeerTrans(
      String connectPeerId, dynamic data) async {
    ChainMessage chainMessage = await prepareSend(connectPeerId, data);

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.Payload;
    }

    return null;
  }
}

final queryPeerTransAction = QueryPeerTransAction(MsgType.QUERYPEERTRANS);
