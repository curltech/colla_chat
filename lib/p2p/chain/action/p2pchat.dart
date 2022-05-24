import '../../message.dart';
import '../baseaction.dart';

/// 在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
class P2pChatAction extends BaseAction {
  P2pChatAction(MsgType msgType) : super(msgType);

  Future<dynamic> chat(
      String connectPeerId, dynamic data, String targetPeerId) async {
    ChainMessage? chainMessage =
        await prepareSend(connectPeerId, data, targetPeerId: targetPeerId);
    // 已经使用signal protocol加密，不用再加密
    //chainMessage.NeedEncrypt = true
    //chainMessage.NeedSlice = true
    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response;
    }

    return null;
  }

  Future<ChainMessage?> receive(ChainMessage chainMessage) async {
    ChainMessage? _chainMessage = await super.receive(chainMessage);
    String srcPeerId = chainMessage.SrcPeerId;
    String payload;
    if (_chainMessage != null &&
        _chainMessage.PayloadType == PayloadType.DataBlock.name) {
      dynamic _dataBlock = _chainMessage.Payload;
      //await dataBlockService.decrypt(_dataBlock);
      payload = _dataBlock.payload;
    } else {
      payload = chainMessage.Payload;
    }
    if (_chainMessage != null && receivers.isNotEmpty) {
      p2pChatAction.receivers.forEach((String key, dynamic receiver) async =>
          {await receiver(srcPeerId, payload)});
      return null;
    }

    return null;
  }
}

final p2pChatAction = P2pChatAction(MsgType.P2PCHAT);
