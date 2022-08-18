

import 'package:fluent_ui/fluent_ui.dart';

import '../../../../entity/chat/chat.dart';
import '../../../../transport/webrtc/peer_video_render.dart';

///视频通话控制器，内部数据为视频通话的请求消息，当有回执时触发修改
class LocalMediaController with ChangeNotifier {
  //媒体请求消息
  ChatMessage? _chatMessage;

  //媒体回执消息
  ChatMessage? _chatReceipt;

  //用户媒体
  final PeerVideoRender userRender = PeerVideoRender();

  //显示媒体
  final PeerVideoRender displayRender = PeerVideoRender();

  ChatMessage? get chatMessage {
    return _chatMessage;
  }

  set chatMessage(ChatMessage? chatMessage) {
    _chatMessage = chatMessage;
    notifyListeners();
  }

  ChatMessage? get chatReceipt {
    return _chatReceipt;
  }

  set chatReceipt(ChatMessage? chatReceipt) {
    _chatReceipt = chatReceipt;
    notifyListeners();
  }
}

final LocalMediaController localMediaController = LocalMediaController();