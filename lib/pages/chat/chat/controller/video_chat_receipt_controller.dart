import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_connections_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:flutter/material.dart';

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
            localVideoRenderController.getVideoRenders();
        for (var render in videoRenders.values) {
          await advancedPeerConnection.addLocalRender(render);
        }
        //本地视频render加入后，发起重新协商
        await advancedPeerConnection.negotiate();
        ///对方同意视频通话则加入到视频连接池中
        await peerConnectionsController.addAdvancedPeerConnection(advancedPeerConnection);
        chatMessageController.chatView = ChatView.video;
      }
    } else if (status == MessageStatus.rejected.name) {
      await localVideoRenderController.close();
      chatMessageController.chatView = ChatView.text;
    }
  }
}

final VideoChatReceiptController videoChatReceiptController =
    VideoChatReceiptController();
