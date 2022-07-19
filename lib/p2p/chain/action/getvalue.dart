import '../../../entity/p2p/message.dart';
import '../baseaction.dart';

///根据key值搜索服务器数据
class GetValueAction extends BaseAction {
  GetValueAction(MsgType msgType) : super(msgType);

  Future<dynamic> getValue(String key) async {
    ChainMessage chainMessage = await prepareSend({'key': key});

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }

}

final getValueAction = GetValueAction(MsgType.GETVALUE);
