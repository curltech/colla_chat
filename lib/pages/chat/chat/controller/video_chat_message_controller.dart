import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:colla_chat/transport/webrtc/video_room_controller.dart';
import 'package:flutter/material.dart';

///视频通话的回执消息控制器
///接受方根据发起方的消息生成对应的接受或者拒绝或者终止的回执,发起方收到回执进行处理
class VideoChatMessageController with ChangeNotifier {
  //媒体回执消息，对发起方来说是是收到的(senderPeerId)，对接受方来说是自己根据_chatMessage生成的(receiverPeerId)
  ChatMessage? _chatMessage;
  ChatMessage? _chatReceipt;
  final List<ChatMessage> _acceptedChatReceipts = [];
  final List<ChatMessage> _rejectedChatReceipts = [];
  final List<ChatMessage> _terminatedChatReceipts = [];

  ChatMessage? get chatMessage {
    return _chatMessage;
  }

  set chatMessage(ChatMessage? chatMessage) {
    if (_chatMessage != chatMessage) {
      _chatMessage = chatMessage;
    }
  }

  ChatMessage? get chatReceipt {
    return _chatReceipt;
  }

  List<ChatMessage> get acceptedChatReceipts {
    return _acceptedChatReceipts;
  }

  List<ChatMessage> get rejectedChatReceipts {
    return _rejectedChatReceipts;
  }

  List<ChatMessage> get terminatedChatReceipts {
    return _terminatedChatReceipts;
  }

  ///接受到视频通话回执，一般由globalChatMessageController分发到此
  receivedChatReceipt(ChatMessage chatReceipt) async {
    //当前的视频通话邀请消息不为空
    if (_chatMessage != null) {
      logger.e('chatMessage is null');
      return;
    }
    //当前到来的回执是新的
    if (_chatReceipt != chatReceipt) {
      String messageId = _chatReceipt!.messageId!;
      //当前的视频通话邀请消息一致
      if (_chatMessage!.messageId != chatReceipt.messageId) {
        logger.e('messageId $messageId is not equal');
        return;
      }
      var chatMessage = await chatMessageService.findByMessageId(messageId,
          receiverPeerId: peerId);
      //回执的邀请消息存在
      if (chatMessage == null) {
        logger.e('messageId $messageId is not exist');
        return;
      }
      _chatReceipt = chatReceipt;
      //把回执消息分类存放
      if (chatReceipt.status == MessageStatus.accepted.name) {
        _acceptedChatReceipts.add(chatReceipt);
      }
      if (chatReceipt.status == MessageStatus.rejected.name) {
        _rejectedChatReceipts.add(chatReceipt);
      }
      if (chatReceipt.status == MessageStatus.terminated.name) {
        _terminatedChatReceipts.add(chatReceipt);
      }
      _receivedChatReceipt();
      notifyListeners();
    }
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
  ///根据消息回执是接受拒绝还是终止进行处理
  _receivedChatReceipt() async {
    if (_chatReceipt == null) {
      return;
    }
    String? status = _chatReceipt!.status;
    String? subMessageType = _chatReceipt!.subMessageType;
    logger.w('received videoChat chatReceipt status: $status');
    if (subMessageType != ChatMessageSubType.chatReceipt.name) {
      return;
    }
    String messageId = _chatReceipt!.messageId!;
    //接受通话请求的回执，加本地流，重新协商
    if (status == MessageStatus.accepted.name) {
      var peerId = _chatReceipt!.senderPeerId!;
      var clientId = _chatReceipt!.senderClientId!;
      AdvancedPeerConnection? advancedPeerConnection =
          peerConnectionPool.getOne(
        peerId,
        clientId: clientId,
      );
      //与发送者的连接存在，将本地的视频render加入连接中
      if (advancedPeerConnection != null) {
        VideoRoomRenderController? videoRoomRenderController =
            videoRoomRenderPool.getVideoRoomRenderController(messageId);
        if (videoRoomRenderController != null) {
          videoRoomRenderController
              .addAdvancedPeerConnection(advancedPeerConnection);
        }
        Map<String, PeerVideoRender> videoRenders =
            localVideoRenderController.getVideoRenders();
        for (var render in videoRenders.values) {
          await advancedPeerConnection.addLocalRender(render);
        }
        //本地视频render加入后，发起重新协商
        await advancedPeerConnection.negotiate();
      }
    } else if (status == MessageStatus.rejected.name) {
    } else if (status == MessageStatus.terminated.name) {
      var peerId = _chatReceipt!.senderPeerId!;
      var clientId = _chatReceipt!.senderClientId!;
      AdvancedPeerConnection? advancedPeerConnection =
          peerConnectionPool.getOne(
        peerId,
        clientId: clientId,
      );
      //与发送者的连接存在，将本地的视频render加入连接中
      if (advancedPeerConnection != null) {
        VideoRoomRenderController? videoRoomRenderController =
            videoRoomRenderPool.getVideoRoomRenderController(messageId);
        if (videoRoomRenderController != null) {
          videoRoomRenderController
              .removeAdvancedPeerConnection(advancedPeerConnection);
        }
        Map<String, PeerVideoRender> videoRenders =
            localVideoRenderController.getVideoRenders();
        for (var render in videoRenders.values) {
          await advancedPeerConnection.removeLocalRender(render);
        }
        //本地视频render加入后，发起重新协商
        await advancedPeerConnection.negotiate();
      }
    }
  }
}

final VideoChatMessageController videoChatMessageController =
    VideoChatMessageController();
