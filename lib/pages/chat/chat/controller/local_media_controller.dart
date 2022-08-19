import 'package:fluent_ui/fluent_ui.dart';

import '../../../../entity/chat/chat.dart';
import '../../../../entity/dht/myself.dart';
import '../../../../transport/webrtc/peer_video_render.dart';

///媒体通话控制器，内部数据为视频通话的请求消息，和回执消息
class LocalMediaController with ChangeNotifier {
  //媒体请求消息，对发起方来说是自己生成的(receiverPeerId)，对接受方来说是收到的(senderPeerId)
  ChatMessage? _chatMessage;

  //媒体回执消息，对发起方来说是是收到的(senderPeerId)，对接受方来说是自己根据_chatMessage生成的(receiverPeerId)
  ChatMessage? _chatReceipt;

  bool? initiator;

  //用户媒体
  final PeerVideoRender userRender = PeerVideoRender(myself.peerId!,
      clientId: myself.clientId, name: myself.myselfPeer!.name);

  //显示媒体
  final PeerVideoRender displayRender = PeerVideoRender(myself.peerId!,
      clientId: myself.clientId, name: myself.myselfPeer!.name);

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

  String? get peerId {
    bool? initiator = this.initiator;
    ChatMessage? chatMessage = _chatMessage;
    if (initiator == null || chatMessage == null) {
      return null;
    }
    if (initiator) {
      return chatMessage.receiverPeerId;
    } else {
      return chatMessage.senderPeerId;
    }
  }

  String? get clientId {
    bool? initiator = this.initiator;
    ChatMessage? chatMessage = _chatMessage;
    if (initiator == null || chatMessage == null) {
      return null;
    }
    if (initiator) {
      return chatMessage.receiverClientId;
    } else {
      return chatMessage.senderClientId;
    }
  }

  String? get name {
    bool? initiator = this.initiator;
    ChatMessage? chatMessage = _chatMessage;
    if (initiator == null || chatMessage == null) {
      return null;
    }
    if (initiator) {
      return chatMessage.receiverName;
    } else {
      return chatMessage.senderName;
    }
  }

  hangup() {
    _chatMessage = null;
    _chatReceipt = null;
    initiator = null;
    userRender.dispose();
    displayRender.dispose();
    notifyListeners();
  }
}

final LocalMediaController localMediaController = LocalMediaController();
