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
class LocalMediaController extends VideoRenderController {
  PeerVideoRender? _videoRender;

  final Map<String, PeerVideoRender> _videoRenders = {};

  Future<PeerVideoRender> createVideoRender(
      {MediaStream? stream,
      bool videoMedia = false,
      bool audioMedia = false,
      bool displayMedia = false}) async {
    if (_videoRender != null) {
      if (videoMedia || audioMedia) {
        return _videoRender!;
      }
    }
    if (stream != null) {
      var streamId = stream.id;
      var videoRender = _videoRenders[streamId];
      if (videoRender != null) {
        return videoRender;
      }
    }
    PeerVideoRender render = await PeerVideoRender.from(myself.peerId!,
        clientId: myself.clientId,
        name: myself.myselfPeer!.name,
        stream: stream,
        videoMedia: videoMedia,
        audioMedia: audioMedia,
        displayMedia: displayMedia);
    if (audioMedia || videoMedia) {
      _videoRender = render;
    }
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
    if (id == null) {
      for (var videoRender in _videoRenders.values) {
        videoRender.dispose();
      }
      _videoRenders.clear();
      _videoRender = null;
    } else {
      var videoRender = _videoRenders[id];
      if (videoRender != null) {
        videoRender.dispose();
        _videoRenders.remove(id);
        if (_videoRender != null && _videoRender!.id == id) {
          _videoRender = null;
        }
      }
    }
    notifyListeners();
  }
}

final LocalMediaController localMediaController = LocalMediaController();

///视频通话的请求消息，和回执消息控制器
class VideoChatReceiptController with ChangeNotifier {
  //媒体回执消息，对发起方来说是是收到的(senderPeerId)，对接受方来说是自己根据_chatMessage生成的(receiverPeerId)
  ChatMessage? _chatReceipt;

  ChatMessage? get chatReceipt {
    return _chatReceipt;
  }

  set chatReceipt(ChatMessage? chatReceipt) {
    logger.i('received chatVideo chatReceipt');
    _chatReceipt = chatReceipt;
    notifyListeners();
  }

  String? get peerId {
    ChatMessage? chatMessage = _chatReceipt;
    if (chatMessage == null) {
      return null;
    }
    String? direct = chatMessage.direct;
    if (direct == ChatDirect.send.name) {
      return chatMessage.receiverPeerId;
    } else {
      return chatMessage.senderPeerId;
    }
  }

  String? get clientId {
    ChatMessage? chatMessage = _chatReceipt;
    if (chatMessage == null) {
      return null;
    }
    String? direct = chatMessage.direct;
    if (direct == ChatDirect.send.name) {
      return chatMessage.receiverClientId;
    } else {
      return chatMessage.senderClientId;
    }
  }

  String? get name {
    ChatMessage? chatMessage = _chatReceipt;
    if (chatMessage == null) {
      return null;
    }
    String? direct = chatMessage.direct;
    if (direct == ChatDirect.send.name) {
      return chatMessage.receiverName;
    } else {
      return chatMessage.senderName;
    }
  }
}

final VideoChatReceiptController videoChatReceiptController =
    VideoChatReceiptController();
