import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
import 'package:flutter/material.dart';

///视频通话的消息控制器
///接受方根据发起方的消息生成对应的接受或者拒绝或者终止的回执,发起方收到回执进行处理
class VideoChatMessageController with ChangeNotifier {
  //视频邀请消息对应的汇总消息
  ChatSummary? _chatSummary;

  //视频邀请消息
  ChatMessage? _chatMessage;
  final Map<String, ChatMessage> _acceptedChatReceipts = {};
  final Map<String, ChatMessage> _rejectedChatReceipts = {};
  final Map<String, ChatMessage> _terminatedChatReceipts = {};
  Conference? _conference;

  ChatSummary? get chatSummary {
    return _chatSummary;
  }

  ChatMessage? get chatMessage {
    return _chatMessage;
  }

  Conference? get conference {
    return _conference;
  }

  ///设置当前的视频邀请消息汇总和视频邀请消息
  setChatMessage(ChatMessage? chatMessage, {ChatSummary? chatSummary}) async {
    if (_chatMessage == chatMessage) {
      return;
    }
    _chatSummary = chatSummary;
    _chatMessage = chatMessage;
    _conference = null;
    _acceptedChatReceipts.clear();
    _rejectedChatReceipts.clear();
    _terminatedChatReceipts.clear();
    if (chatMessage == null) {
      notifyListeners();
      return;
    }
    //设置正确的_chatSummary
    if (_chatSummary == null) {
      if (_chatMessage!.direct == ChatDirect.send.name) {
        _chatSummary = await chatSummaryService
            .findCachedOneByPeerId(_chatMessage!.receiverPeerId!);
      }
      if (_chatMessage!.direct == ChatDirect.receive.name) {
        _chatSummary = await chatSummaryService
            .findCachedOneByPeerId(_chatMessage!.senderPeerId!);
      }
    } else {
      if (_chatMessage!.direct == ChatDirect.send.name) {
        if (_chatSummary!.peerId != _chatMessage!.receiverPeerId!) {
          return;
        }
      }
      if (_chatMessage!.direct == ChatDirect.receive.name) {
        if (_chatSummary!.peerId != _chatMessage!.senderPeerId!) {
          return;
        }
      }
    }
    var messageId = chatMessage.messageId!;
    List<ChatMessage> chatMessages =
        await chatMessageService.findByMessageId(messageId);
    if (chatMessages.isEmpty) {
      notifyListeners();
      return;
    }

    for (var chatMessage in chatMessages) {
      if (chatMessage.receiverPeerId == myself.peerId) {
        if (chatMessage.status == MessageStatus.accepted.name) {
          _acceptedChatReceipts[chatMessage.senderPeerId!] = chatMessage;
        }
        if (chatMessage.status == MessageStatus.rejected.name) {
          _rejectedChatReceipts[chatMessage.senderPeerId!] = chatMessage;
        }
        if (chatMessage.status == MessageStatus.terminated.name) {
          _terminatedChatReceipts[chatMessage.senderPeerId!] = chatMessage;
        }
      }
    }
    _parseConference();
    notifyListeners();
  }

  String _getKey(String peerId, String clientId) {
    var key = '$peerId:$clientId';
    return key;
  }

  ChatMessage? getAcceptedChatReceipts(String peerId, String clientId) {
    return _acceptedChatReceipts[_getKey(peerId, clientId)];
  }

  ChatMessage? getRejectedChatReceipts(String peerId, String clientId) {
    return _rejectedChatReceipts[_getKey(peerId, clientId)];
  }

  ChatMessage? getTerminatedChatReceipts(String peerId, String clientId) {
    return _terminatedChatReceipts[_getKey(peerId, clientId)];
  }

  void _parseConference() {
    String json = chatMessageService.recoverContent(_chatMessage!.content!);
    Map map = JsonUtil.toJson(json);
    _conference = Conference.fromJson(map);
  }

  ///接收到视频通话邀请，做出接受或者拒绝视频通话邀请的决定
  sendChatReceipt(MessageStatus receiptType) async {
    ChatMessage? chatMessage = _chatMessage;
    if (chatMessage == null) {
      return;
    }
    var groupPeerId = chatMessage.groupPeerId;
    var groupType = chatMessage.groupType;
    var messageId = chatMessage.messageId;
    //单个联系人视频通话邀请
    if (groupType == null) {
      await _sendLinkmanChatReceipt(chatMessage, receiptType);
    } else if (groupType == PartyType.group.name) {
      await _sendGroupChatReceipt(chatMessage, receiptType);
    } else if (groupType == PartyType.conference.name) {
      await _sendConferenceChatReceipt(chatMessage, receiptType);
    }
  }

  _sendLinkmanChatReceipt(
      ChatMessage chatMessage, MessageStatus receiptType) async {
    //创建回执消息
    ChatMessage chatReceipt =
        await chatMessageService.buildChatReceipt(chatMessage, receiptType);
    await chatMessageService.updateReceiptStatus(chatMessage, receiptType);
    await chatMessageService.sendAndStore(chatReceipt);
    if (receiptType == MessageStatus.accepted) {
      var peerId = chatReceipt.receiverPeerId!;
      var clientId = chatReceipt.receiverClientId!;
      PeerVideoRender? localRender;
      //根据conference.video来判断是请求音频还是视频，并创建本地视频render
      bool video = _conference!.video;
      if (video) {
        // localRender =
        //     await localVideoRenderController.createVideoMediaRender();
        //测试目的，使用屏幕
        localRender =
            await localVideoRenderController.createDisplayMediaRender();
      } else {
        localRender = await localVideoRenderController.createAudioMediaRender();
      }

      //将本地的render加入webrtc连接
      AdvancedPeerConnection? advancedPeerConnection =
          peerConnectionPool.getOne(
        peerId,
        clientId: clientId,
      );
      if (advancedPeerConnection != null) {
        await advancedPeerConnection.addLocalRender(localRender);
        //同意视频通话则加入到视频连接池中，远程视频通过远程会议池和会议号获取
        RemoteVideoRenderController remoteVideoRenderController =
            videoConferenceRenderPool
                .createRemoteVideoRenderController(_conference!);
        remoteVideoRenderController
            .addAdvancedPeerConnection(advancedPeerConnection);
        //设置当前消息，转入视频会议界面
        chatMessageController.chatSummary = _chatSummary;
        chatMessageController.current = _chatMessage;
        indexWidgetProvider.push('chat_message');
        indexWidgetProvider.push('video_chat');
      }
    }
  }

  _sendGroupChatReceipt(
      ChatMessage chatMessage, MessageStatus receiptType) async {
    //群视频通话邀请
    //除了向发送方外，还需要向房间的各接收人发送回执，
    //首先检查接收人是否已经存在给自己的回执，不存在或者存在是accepted则发送回执
    //如果存在，如果是rejected或者terminated，则不发送回执
    //创建回执消息
    await conferenceService.store(_conference!);
    List<ChatMessage> chatReceipts = await chatMessageService
        .buildGroupChatReceipt(chatMessage, receiptType);
    if (chatReceipts.isNotEmpty) {
      for (var chatReceipt in chatReceipts) {
        //发送回执
        await chatMessageService.sendAndStore(chatReceipt);
      }
    }
    await chatMessageService.updateReceiptStatus(chatMessage, receiptType);
    if (receiptType == MessageStatus.accepted) {}
  }

  _sendConferenceChatReceipt(
      ChatMessage chatMessage, MessageStatus receiptType) async {
    //会议视频通话邀请
    //除了向发送方外，还需要向房间的各接收人发送回执，
    //首先检查接收人是否已经存在给自己的回执，不存在或者存在是accepted则发送回执
    //如果存在，如果是rejected或者terminated，则不发送回执
    await conferenceService.store(_conference!);
    List<ChatMessage> chatReceipts =
        await chatMessageService.buildGroupChatReceipt(chatMessage, receiptType,
            peerIds: _conference!.participants);
    if (chatReceipts.isNotEmpty) {
      for (var chatReceipt in chatReceipts) {
        //发送回执
        await chatMessageService.sendAndStore(chatReceipt);
      }
    }
    await chatMessageService.updateReceiptStatus(chatMessage, receiptType);
    if (receiptType == MessageStatus.accepted) {}
  }

  ///接受到视频通话回执，一般由globalChatMessageController分发到此
  ///在多个接收人的场景下，首先检查自己是否已经发过回执，存在是accepted则继续处理
  ///如果不存在，则发送自己的决定，如果存在是rejected或者terminated，则不处理
  receivedChatReceipt(ChatMessage chatReceipt) async {
    //当前的视频通话邀请消息不为空
    if (_chatMessage != null) {
      logger.e('Video chatMessage is null');
      return;
    }
    //当前到来的回执是新的
    String messageId = chatReceipt.messageId!;
    //当前的视频通话邀请消息一致
    if (_chatMessage!.messageId != chatReceipt.messageId) {
      logger.e('messageId $messageId is not equal');
      return;
    }

    //把回执消息分类存放
    var key = _getKey(chatReceipt.senderPeerId!, chatReceipt.senderClientId!);
    if (chatReceipt.status == MessageStatus.accepted.name) {
      _acceptedChatReceipts[key] = chatReceipt;
    }
    if (chatReceipt.status == MessageStatus.rejected.name) {
      _rejectedChatReceipts[key] = chatReceipt;
    }
    if (chatReceipt.status == MessageStatus.terminated.name) {
      _terminatedChatReceipts[key] = chatReceipt;
    }
    _receivedChatReceipt(chatReceipt);
    notifyListeners();
  }

  ///收到视频通话的回执的处理，
  ///在群通话的情况下，可以收到多次，包括多个接收人的回执
  ///根据消息回执是接受拒绝还是终止进行处理
  _receivedChatReceipt(ChatMessage chatReceipt) async {
    String? content = chatReceipt.content;
    String? subMessageType = chatReceipt.subMessageType;
    logger.w('received videoChat chatReceipt content: $content');
    if (subMessageType != ChatMessageSubType.chatReceipt.name) {
      return;
    }
    String messageId = chatReceipt.messageId!;
    //接受通话请求的回执，加本地流，重新协商
    if (content == MessageStatus.accepted.name) {
      var peerId = chatReceipt.senderPeerId!;
      var clientId = chatReceipt.senderClientId!;
      AdvancedPeerConnection? advancedPeerConnection =
          peerConnectionPool.getOne(
        peerId,
        clientId: clientId,
      );
      //与发送者的连接存在，将本地的视频render加入连接中
      if (advancedPeerConnection != null) {
        RemoteVideoRenderController? remoteVideoRenderController =
            videoConferenceRenderPool.getRemoteVideoRenderController(messageId);
        if (remoteVideoRenderController != null) {
          remoteVideoRenderController
              .addAdvancedPeerConnection(advancedPeerConnection);
        }
        //把本地视频加入连接中，然后重新协商
        Map<String, PeerVideoRender> videoRenders =
            localVideoRenderController.getVideoRenders();
        for (var render in videoRenders.values) {
          await advancedPeerConnection.addLocalRender(render);
        }
        //本地视频render加入后，发起重新协商
        await advancedPeerConnection.negotiate();
      }
    } else if (content == MessageStatus.rejected.name) {
    } else if (content == MessageStatus.terminated.name) {
      var peerId = chatReceipt.senderPeerId!;
      var clientId = chatReceipt.senderClientId!;
      AdvancedPeerConnection? advancedPeerConnection =
          peerConnectionPool.getOne(
        peerId,
        clientId: clientId,
      );
      //与发送者的连接存在，将本地的视频render加入连接中
      if (advancedPeerConnection != null) {
        RemoteVideoRenderController? remoteVideoRenderController =
            videoConferenceRenderPool.getRemoteVideoRenderController(messageId);
        if (remoteVideoRenderController != null) {
          remoteVideoRenderController
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
