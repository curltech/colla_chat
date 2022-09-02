import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../entity/chat/chat.dart';
import '../../../../entity/dht/myself.dart';
import '../../../../plugin/logger.dart';
import '../../../../transport/webrtc/peer_video_render.dart';

abstract class VideoRenderController with ChangeNotifier {
  Map<String, PeerVideoRender> videoRenders({String? peerId, String? clientId});

  close({String? id});
}

///本地媒体通话控制器，内部数据为视频通话的请求消息，和回执消息
///如果本地的render存在，在创建peerconnection的时候将加入
class LocalMediaController extends VideoRenderController {
  //媒体请求消息，对发起方来说是自己生成的(receiverPeerId)，对接受方来说是收到的(senderPeerId)
  ChatMessage? _chatMessage;

  //媒体回执消息，对发起方来说是是收到的(senderPeerId)，对接受方来说是自己根据_chatMessage生成的(receiverPeerId)
  ChatMessage? _chatReceipt;

  bool? initiator;

  Map<String, PeerVideoRender> _videoRenders = {};

  ChatMessage? get chatMessage {
    return _chatMessage;
  }

  set chatMessage(ChatMessage? chatMessage) {
    _chatMessage = chatMessage;
    logger.i('request chatVideo chatMessage');
    notifyListeners();
  }

  ChatMessage? get chatReceipt {
    return _chatReceipt;
  }

  set chatReceipt(ChatMessage? chatReceipt) {
    logger.i('received chatVideo chatReceipt');
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

  Future<PeerVideoRender> createVideoRender(
      {MediaStream? stream,
      bool videoMedia = false,
      bool audioMedia = false,
      bool displayMedia = false}) async {
    PeerVideoRender render = await PeerVideoRender.from(myself.peerId!,
        clientId: myself.clientId,
        name: myself.myselfPeer!.name,
        stream: stream,
        videoMedia: videoMedia,
        audioMedia: audioMedia,
        displayMedia: displayMedia);
    await render.bindRTCVideoRender();
    _videoRenders[render.id!] = render;
    notifyListeners();

    return render;
  }

  @override
  Map<String, PeerVideoRender> videoRenders(
      {String? peerId, String? clientId}) {
    return _videoRenders;
  }

  @override
  close({String? id}) {
    _chatMessage = null;
    _chatReceipt = null;
    initiator = null;
    if (id == null) {
      for (var videoRender in _videoRenders.values) {
        videoRender.dispose();
      }
      _videoRenders.clear();
    } else {
      var videoRender = _videoRenders[id];
      if (videoRender != null) {
        videoRender.dispose();
        _videoRenders.remove(id);
      }
    }
    notifyListeners();
  }
}

final LocalMediaController localMediaController = LocalMediaController();
