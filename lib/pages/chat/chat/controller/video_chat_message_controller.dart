import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/index/global_chat_message_controller.dart';
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

  //最新的消息
  ChatMessage? _current;

  final Map<String, ChatMessage> _acceptedChatReceipts = {};
  final Map<String, ChatMessage> _rejectedChatReceipts = {};
  final Map<String, ChatMessage> _terminatedChatReceipts = {};
  String? partyType;

  //或者会议名称，或者群名称，或者联系人名称
  String? name;

  //当前的会议编号，说明正在群中聊天
  String? conferenceId;
  String? conferenceName;

  //当前的群编号，说明正在群中聊天
  String? groupPeerId;

  //当前的联系人编号和名称，说明正在一对一聊天
  String? peerId;

  //当前的通话房间，房间是临时组建的一组联系人，互相聊天和视频通话
  //如果当前的群存在的话，房间的人在群的联系人中选择，否则在所有的联系人中选择
  Conference? _conference;

  VideoChatMessageController() {
    globalChatMessageController.registerReceiver(
        ChatMessageSubType.videoChat.name, receivedVideoChat);
    globalChatMessageController.registerReceiver(
        ChatMessageSubType.chatReceipt.name, receivedChatReceipt);
  }

  ChatSummary? get chatSummary {
    return _chatSummary;
  }

  ChatMessage? get chatMessage {
    return _chatMessage;
  }

  ChatMessage? get current {
    return _current;
  }

  Conference? get conference {
    return _conference;
  }

  set conference(Conference? conference) {
    if (_conference != conference) {
      _conference = conference;
      notifyListeners();
    }
  }

  ///设置当前的视频邀请消息汇总和视频邀请消息，可以从chatMessageController中获取当前
  setChatSummary(ChatSummary? chatSummary) async {
    //消息汇总未变，直接返回
    if (_chatSummary == chatSummary) {
      return;
    }
    _chatSummary = chatSummary;
    //先清空数据
    _acceptedChatReceipts.clear();
    _rejectedChatReceipts.clear();
    _terminatedChatReceipts.clear();
    partyType = null;
    peerId = null;
    groupPeerId = null;
    _conference = null;
    conferenceId = null;
    conferenceName = null;
    if (chatSummary == null) {
      notifyListeners();
      return;
    }
    partyType = chatSummary.partyType;
    if (partyType == PartyType.linkman.name) {
      peerId = chatSummary.peerId!;
      name = chatSummary.name!;
    } else if (partyType == PartyType.group.name) {
      groupPeerId = chatSummary.peerId!;
      name = chatSummary.name!;
    } else if (partyType == PartyType.conference.name) {
      //conference的会议信息保存，_chatSummary中获取peerId，就是conferenceId
      conferenceId = _chatSummary!.peerId!;
      _conference =
          await conferenceService.findOneByConferenceId(conferenceId!);
      if (_conference != null) {
        name = _conference!.name;
        conferenceName = _conference!.name;
      }
    }
    notifyListeners();
  }

  ///设置当前的视频邀请消息，可以从chatMessageController中获取当前
  ///本界面是在聊天界面转过来，所以当前chatSummary是必然存在的，
  ///当前chatMessage在选择了视频邀请消息后，也是存在的
  ///如果chatMessage不存在，表明是想开始发起新的linkman或者group会议
  ///初始化是根据当前的视频邀请消息chatMessage来决定的，无论是发起还是接收邀请
  ///也可以根据当前会议来决定的，适用于群和会议模式
  ///如果没有设置，表明是新的会议
  setChatMessage(ChatMessage? chatMessage) async {
    //消息未变，直接返回
    if (_chatMessage == chatMessage) {
      return;
    }
    _chatMessage = chatMessage;
    //先清空数据
    _conference = null;
    _acceptedChatReceipts.clear();
    _rejectedChatReceipts.clear();
    _terminatedChatReceipts.clear();
    //如果是清空数据，直接返回
    if (_chatMessage == null) {
      notifyListeners();
      return;
    }
    await _initChatSummary();
    await _initChatMessage();
    await _initChatReceipt();
    notifyListeners();
  }

  ///根据_chatMessage查找对应的chatSummary
  Future<ChatSummary?> _findChatSummary() async {
    if (_chatMessage!.direct == ChatDirect.send.name) {
      return await chatSummaryService
          .findCachedOneByPeerId(_chatMessage!.receiverPeerId!);
    }
    if (_chatMessage!.direct == ChatDirect.receive.name) {
      return await chatSummaryService
          .findCachedOneByPeerId(_chatMessage!.senderPeerId!);
    }
    return null;
  }

  ///校验_chatMessage和_chatSummary，不一致则重新设置_chatSummary
  _initChatSummary() async {
    if (_chatSummary == null && _chatMessage != null) {
      var chatSummary = await _findChatSummary();
      await setChatSummary(chatSummary);
    } else if (_chatSummary != null && _chatMessage != null) {
      if (_chatMessage!.direct == ChatDirect.send.name) {
        if (_chatSummary!.peerId != _chatMessage!.receiverPeerId!) {
          var chatSummary = await _findChatSummary();
          await setChatSummary(chatSummary);
        }
      }
      if (_chatMessage!.direct == ChatDirect.receive.name) {
        if (_chatSummary!.peerId != _chatMessage!.senderPeerId!) {
          _chatSummary = null;
          var chatSummary = await _findChatSummary();
          await setChatSummary(chatSummary);
        }
      }
    }
  }

  ///根据_chatMessage设置会议属性
  _initChatMessage() async {
    //linkman的会议信息不保存，从消息中获取
    if (partyType == PartyType.linkman.name) {
      String json = chatMessageService.recoverContent(_chatMessage!.content!);
      Map map = JsonUtil.toJson(json);
      _conference = Conference.fromJson(map);
      if (_chatMessage!.subMessageType == ChatMessageSubType.videoChat.name) {
        conferenceName = _conference!.name;
      }
    } else if (partyType == PartyType.group.name) {
      //group的会议信息保存，_chatMessage中获取messageId，就是conferenceId
      if (_chatMessage!.subMessageType == ChatMessageSubType.videoChat.name) {
        conferenceId = _chatMessage!.messageId!;
        _conference =
            await conferenceService.findOneByConferenceId(conferenceId!);
        if (conference != null) {
          conferenceName = _conference!.name;
        }
      }
    }
  }

  _initChatReceipt() async {
    //如果_chatMessage不为空，查询所有的相同的消息
    var messageId = _chatMessage!.messageId!;
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

  receivedVideoChat(ChatMessage chatMessage) async {
    if (_chatMessage == null || _chatMessage != chatMessage) {
      if (chatMessage.subMessageType == ChatMessageSubType.videoChat.name) {
        _current = chatMessage;
        await setChatMessage(chatMessage);
      }
    }
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
    String? subMessageType = chatReceipt.subMessageType;
    if (subMessageType != ChatMessageSubType.chatReceipt.name) {
      logger.e('chatReceipt is not chatReceipt');
      return;
    }
    //当前到来的回执是新的
    String messageId = chatReceipt.messageId!;
    //当前的视频通话邀请消息一致
    if (_chatMessage!.messageId != chatReceipt.messageId) {
      logger.e('messageId $messageId is not equal');
      return;
    }

    _current = chatReceipt;
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
    await _receivedChatReceipt(chatReceipt);
    notifyListeners();
  }

  ///收到视频通话的回执的处理，
  ///在群通话的情况下，可以收到多次，包括多个接收人的回执
  ///根据消息回执是接受拒绝还是终止进行处理
  _receivedChatReceipt(ChatMessage chatReceipt) async {
    String? content = chatReceipt.content;
    logger.w('received videoChat chatReceipt content: $content');
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

  @override
  dispose() {
    globalChatMessageController.unregisterReceiver(
        ChatMessageSubType.videoChat.name, receivedVideoChat);
    globalChatMessageController.unregisterReceiver(
        ChatMessageSubType.chatReceipt.name, receivedChatReceipt);
    super.dispose();
  }
}
