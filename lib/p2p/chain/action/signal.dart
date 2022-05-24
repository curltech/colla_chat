import '../../message.dart';
import '../baseaction.dart';

/**
    在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
 */
class SignalAction extends BaseAction {
  SignalAction(MsgType msgType) : super(msgType) {
    //webrtcPeerPool.registSignalAction(this);
  }

  Future<dynamic> signal(
      String connectPeerId, dynamic data, String targetPeerId) async {
    ChainMessage? chainMessage = await signalAction
        .prepareSend(connectPeerId, data, targetPeerId: targetPeerId);
    // TODO: 视频通话的signal加密送过去解密完数据有问题，具体原因还没找到
    //chainMessage.NeedEncrypt = true

    ChainMessage? response = await signalAction.send(chainMessage);
    if (response != null) {
      return response.Payload;
    }

    return null;
  }

  Future<ChainMessage?> receive(ChainMessage chainMessage) async {
    ChainMessage? _chainMessage = await super.receive(chainMessage);
    if (_chainMessage != null && receivers.isNotEmpty) {
      signalAction.receivers.forEach((String key, dynamic receiver) => {
            receiver(_chainMessage.SrcPeerId, _chainMessage.SrcConnectPeerId,
                _chainMessage.SrcConnectSessionId, _chainMessage.Payload)
          });

      return null;
    }
    return null;
  }
}

final signalAction = SignalAction(MsgType.SIGNAL);
