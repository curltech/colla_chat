import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/peer_connections_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract class VideoRenderController with ChangeNotifier {
  int _crossAxisCount = 2;

  Map<String, PeerVideoRender> videoRenders({String? peerId, String? clientId});

  //横向几个video
  int get crossAxisCount {
    return _crossAxisCount;
  }

  set crossAxisCount(int crossAxisCount) {
    if (_crossAxisCount != crossAxisCount) {
      _crossAxisCount = crossAxisCount;
      notifyListeners();
    }
  }

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
    render.peerId = myself.peerId;
    render.name = myself.name;
    render.clientId = myself.clientId;
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

  ChatDirect? _direct;

  ChatMessage? get chatReceipt {
    return _chatReceipt;
  }

  ChatDirect? get direct {
    return _direct;
  }

  ///设置视频通话请求或者回执，由direct决定是请求还是回执
  setChatReceipt(ChatMessage? chatReceipt, ChatDirect direct) {
    logger.i('${direct.name} chatVideo chatReceipt');
    _direct = direct;
    _chatReceipt = chatReceipt;
    receivedReceipt();
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

  ///收到视频通话的回执，在群通话的情况下，可以收到多次
  ///每次代表群里面的一个连接
  receivedReceipt() async {
    ChatMessage? chatReceipt = videoChatReceiptController.chatReceipt;
    ChatDirect? direct = videoChatReceiptController.direct;
    if (chatReceipt == null || direct == null || direct != ChatDirect.receive) {
      return;
    }
    String? status = chatReceipt.status;
    String? subMessageType = chatReceipt.subMessageType;
    if (subMessageType == null) {
      return;
    }
    logger.w('received videoChat chatReceipt status: $status');
    if (subMessageType != ChatMessageSubType.chatReceipt.name) {
      return;
    }
    //接受通话请求
    if (status == MessageStatus.accepted.name) {
      var peerId = chatReceipt.senderPeerId!;
      var clientId = chatReceipt.senderClientId!;
      AdvancedPeerConnection? advancedPeerConnection =
          peerConnectionPool.getOne(
        peerId,
        clientId: clientId,
      );
      //与发送者的连接存在，将本地的视频render加入连接中
      if (advancedPeerConnection != null) {
        Map<String, PeerVideoRender> videoRenders =
            localMediaController.videoRenders();
        for (var render in videoRenders.values) {
          await advancedPeerConnection.addRender(render);
        }
        //本地视频render加入后，发起重新协商
        await advancedPeerConnection.negotiate();
        await peerConnectionsController.addPeerConnection(peerId,
            clientId: clientId);
        chatMessageController.chatView = ChatView.video;
      }
    } else if (status == MessageStatus.rejected.name) {
      await localMediaController.close();
      chatMessageController.chatView = ChatView.text;
    }
  }
}

final VideoChatReceiptController videoChatReceiptController =
    VideoChatReceiptController();
