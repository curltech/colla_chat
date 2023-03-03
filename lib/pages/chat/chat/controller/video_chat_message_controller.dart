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
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
import 'package:flutter/material.dart';

///视频通话的消息控制器，是视频会议的命令控制器
///1.发起视频会议邀请；2.接收邀请；3.发送邀请回执；4.接收邀请回执
class VideoChatMessageController with ChangeNotifier {
  final Key key = UniqueKey();

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

  //当前的群编号，说明正在群中聊天
  String? groupPeerId;

  //当前的联系人编号和名称，说明正在一对一聊天
  String? peerId;

  //当前的通话房间，房间是临时组建的一组联系人，互相聊天和视频通话
  //如果当前的群存在的话，房间的人在群的联系人中选择，否则在所有的联系人中选择
  Conference? _conference;

  final Map<String, List<Function(ChatMessage chatMessage)>> _receivers = {};

  VideoChatMessageController();

  ///注册消息接收监听器，用于自定义的特殊处理
  registerReceiver(
      String subMessageType, Function(ChatMessage chatMessage) fn) {
    List<Function(ChatMessage chatMessage)>? fns = _receivers[subMessageType];
    if (fns == null) {
      fns = <Function(ChatMessage chatMessage)>[];
      _receivers[subMessageType] = fns;
    }
    if (!fns.contains(fn)) {
      fns.add(fn);
    }
  }

  unregisterReceiver(
      String subMessageType, Function(ChatMessage chatMessage) fn) {
    List<Function(ChatMessage chatMessage)>? fns = _receivers[subMessageType];
    if (fns != null) {
      if (fns.contains(fn)) {
        fns.remove(fn);
        if (fns.isEmpty) {
          _receivers.remove(subMessageType);
        }
      }
    }
  }

  onVideoChatMessage(ChatMessage chatMessage) async {
    //调用注册的消息接收监听器，用于自定义的特殊处理
    List<Function(ChatMessage chatMessage)>? fns =
        _receivers[chatMessage.subMessageType];
    if (fns != null && fns.isNotEmpty) {
      for (var fn in fns) {
        fn(chatMessage);
      }
    }
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

  String? get conferenceId {
    return _conference?.conferenceId;
  }

  String? get conferenceName {
    return _conference?.name;
  }

  ///设置当前的视频邀请消息汇总，可以从chatMessageController中获取当前
  ///在conference模式下，peerId就是会议编号
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
    if (chatSummary == null) {
      globalChatMessageController.unregisterReceiver(
          ChatMessageSubType.videoChat.name, receivedVideoChat);
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
      var conferenceId = _chatSummary!.peerId!;
      _conference = await conferenceService.findOneByConferenceId(conferenceId);
      if (_conference != null) {
        name = _conference!.name;
      }
    }
    globalChatMessageController.registerReceiver(
        ChatMessageSubType.videoChat.name, receivedVideoChat);
  }

  ///设置当前的视频邀请消息，可以从chatMessageController中获取当前，
  ///当前chatSummary是必须存在的，不存在就查找到
  ///当前chatMessage在选择了视频邀请消息后，也是存在的
  ///如果chatMessage不存在，表明是准备新的会议
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
      globalChatMessageController.unregisterReceiver(
          ChatMessageSubType.chatReceipt.name, receivedChatReceipt);
      return;
    }
    await _initChatSummary();
    await _initChatMessage();
    globalChatMessageController.registerReceiver(
        ChatMessageSubType.chatReceipt.name, receivedChatReceipt);
    await _initChatReceipt();
  }

  ///根据_chatMessage查找对应的chatSummary
  Future<ChatSummary?> _findChatSummary() async {
    ChatSummary? chatSummary;
    if (_chatMessage!.groupType == null) {
      if (_chatMessage!.direct == ChatDirect.send.name) {
        chatSummary = await chatSummaryService
            .findCachedOneByPeerId(_chatMessage!.receiverPeerId!);
      } else if (_chatMessage!.direct == ChatDirect.receive.name) {
        chatSummary = await chatSummaryService
            .findCachedOneByPeerId(_chatMessage!.senderPeerId!);
      }
    } else {
      chatSummary = await chatSummaryService
          .findCachedOneByPeerId(_chatMessage!.messageId!);
    }
    chatSummary ??= await chatSummaryService.upsertByChatMessage(_chatMessage!);

    return chatSummary;
  }

  ///校验_chatMessage和_chatSummary，不一致则重新设置_chatSummary
  _initChatSummary() async {
    if (_chatSummary == null && _chatMessage != null) {
      ChatSummary? chatSummary = await _findChatSummary();
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
    if (_chatMessage!.subMessageType == ChatMessageSubType.videoChat.name) {
      String json = chatMessageService.recoverContent(_chatMessage!.content!);
      Map map = JsonUtil.toJson(json);
      _conference = Conference.fromJson(map);
    }
    //linkman的会议信息不保存，从消息中获取
    if (partyType != PartyType.linkman.name) {
      if (_chatMessage!.subMessageType == ChatMessageSubType.videoChat.name) {
        var conferenceId = _chatMessage!.messageId!;
        var conference =
            await conferenceService.findOneByConferenceId(conferenceId);
        if (conference != null) {
          logger.e('Conference $conferenceId name ${conference.name} is exist');
          // _conference!.id = conference.id;
          // await conferenceService.store(_conference!);
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

  ///创建新的会议功能
  ///对联系人模式，可以临时创建一个会议，会议成员从群成员中选择就是自己和对方，会议名称是对方的名称，不保存会议
  ///对群模式，可以创建一个会议，会议成员从群成员中选择，会议名称是群的名称加上当前时间，保存会议
  ///对会议模式，直接转到会议创建界面，
  Future<Conference?> _buildConference(
      {bool video = true, required List<String> participants}) async {
    var conference = _conference;
    if (conference != null) {
      logger.e('conference ${conference.name} is exist');
      return conference;
    }
    var partyType = this.partyType;
    if (partyType == PartyType.conference.name) {}
    var groupPeerId = this.groupPeerId;
    if (partyType == PartyType.group.name) {
      if (groupPeerId == null) {
        return null;
      }
    }
    if (partyType == PartyType.linkman.name) {
      var peerId = this.peerId;
      if (peerId == null) {
        return null;
      }
      participants.add(peerId);
    }
    var name = this.name;
    _conference = await conferenceService.createConference(
        '${name!}-${DateUtil.currentDate()}',
        video: video,
        participants: participants);
    if (partyType == PartyType.group.name) {
      _conference!.groupPeerId = groupPeerId;
      _conference!.groupName = name;
      _conference!.groupType = partyType;
    }
    return _conference;
  }

  ///群发送视频会议邀请消息，当前chatSummary可以不存在，因此不需要当前处于聊天场景下
  static Future<ChatMessage?> sendConferenceVideoChatMessage(
      Conference conference) async {
    List<ChatMessage> chatMessages =
        await chatMessageService.buildGroupChatMessage(
      conference.conferenceId,
      PartyType.conference,
      title: conference.video ? ContentType.video.name : ContentType.audio.name,
      content: conference,
      messageId: conference.conferenceId,
      subMessageType: ChatMessageSubType.videoChat,
      peerIds: conference.participants,
    );
    for (var chatMessage in chatMessages) {
      await chatMessageService.sendAndStore(chatMessage);
    }
    return chatMessages[0];
  }

  ///1.发送视频通邀请话消息,此时消息必须有content,包含conference信息
  ///当前chatSummary必须存在，因此只能用于当前正在聊天的时候
  ///conference的participants，而不是group的所有成员
  ///title字段存放是视频还是音频的信息
  Future<ChatMessage?> sendVideoChatMessage(
      {required ContentType contentType,
      bool video = true,
      required List<String> participants}) async {
    var conference =
        await _buildConference(video: video, participants: participants);
    if (conference != null) {
      if (partyType == PartyType.group.name) {
        await conferenceService.store(conference);
      }
    }
    //主题是会议视频属性
    ChatMessage? chatMessage = await chatMessageController.send(
        title: contentType.name,
        content: _conference,
        messageId: _conference!.conferenceId,
        subMessageType: ChatMessageSubType.videoChat,
        peerIds: _conference!.participants);
    if (chatMessage != null) {
      logger.i('send video chatMessage ${chatMessage.messageId}');
    }
    await setChatMessage(chatMessage);

    return chatMessage;
  }

  ///2.接收会议邀请消息
  receivedVideoChat(ChatMessage chatMessage) async {
    if (_chatMessage == null || _chatMessage != chatMessage) {
      if (chatMessage.subMessageType == ChatMessageSubType.videoChat.name) {
        _current = chatMessage;
        await setChatMessage(chatMessage);
        await onVideoChatMessage(chatMessage);
      }
    }
  }

  ///3.发送会议邀请回执
  ///接收到视频通话邀请，做出接受或者拒绝视频通话邀请的决定
  ///如果是接受决定，本控制器将被加入到池中
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

  ///发送视频邀请消息的回执，如果是接受，则最后转入视频页面
  ///设置当前的消息为视频邀请消息
  _sendLinkmanChatReceipt(
      ChatMessage chatMessage, MessageStatus receiptType) async {
    //创建回执消息
    ChatMessage chatReceipt =
        await chatMessageService.buildChatReceipt(chatMessage, receiptType);
    await chatMessageService.updateReceiptStatus(chatMessage, receiptType);
    await chatMessageService.sendAndStore(chatReceipt);
    //立即接听
    if (receiptType == MessageStatus.accepted) {
      var peerId = chatReceipt.receiverPeerId!;
      var clientId = chatReceipt.receiverClientId!;
      //根据conference.video来判断是请求音频还是视频，并创建本地视频render
      bool video = _conference!.video;
      if (video) {
        // localRender =
        //     await localVideoRenderController.createVideoMediaRender();
        //测试目的，使用屏幕

        await localVideoRenderController.createDisplayMediaRender();
      } else {
        await localVideoRenderController.createAudioMediaRender();
      }

      //将本地的render加入webrtc连接
      AdvancedPeerConnection? advancedPeerConnection =
          peerConnectionPool.getOne(
        peerId,
        clientId: clientId,
      );
      if (advancedPeerConnection != null) {
        //同意视频通话则加入到视频连接池中，远程视频通过远程会议池和会议号获取
        RemoteVideoRenderController remoteVideoRenderController =
            videoConferenceRenderPool.createRemoteVideoRenderController(this);
        remoteVideoRenderController
            .addAdvancedPeerConnection(advancedPeerConnection);
        //把本地视频加入连接中，然后重新协商
        List<PeerVideoRender> videoRenders =
            localVideoRenderController.getVideoRenders().values.toList();
        await remoteVideoRenderController.addLocalVideoRender(videoRenders);
        videoConferenceRenderPool.conferenceId = remoteVideoRenderController
            .videoChatMessageController!.conferenceId;
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
    //立即接听
    if (receiptType == MessageStatus.accepted) {
      RemoteVideoRenderController remoteVideoRenderController =
          videoConferenceRenderPool.createRemoteVideoRenderController(this);
      List<String>? participants = conference!.participants;
      if (participants != null && participants.isNotEmpty) {
        for (var participant in participants) {
          if (participant == myself.peerId || participant == peerId) {
            continue;
          }
          List<AdvancedPeerConnection> peerConnections =
              peerConnectionPool.get(participant);
          if (peerConnections.isNotEmpty) {
            remoteVideoRenderController
                .addAdvancedPeerConnection(peerConnections[0]);
          }
        }
      }
    }
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
    //稍后加入
    if (receiptType == MessageStatus.hold) {}
  }

  ///4.接受到视频通话回执，一般由globalChatMessageController分发到此
  ///在多个接收人的场景下，首先检查自己是否已经发过回执，存在是accepted则继续处理
  ///如果不存在，则发送自己的决定，如果存在是rejected或者terminated，则不处理
  receivedChatReceipt(ChatMessage chatReceipt) async {
    //当前的视频通话邀请消息不为空
    if (_chatMessage == null) {
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
    await onVideoChatMessage(chatReceipt);
  }

  ///收到视频通话的回执的处理，
  ///在群通话的情况下，可以收到多次，包括多个接收人的回执
  ///根据消息回执是接受拒绝还是终止进行处理
  _receivedChatReceipt(ChatMessage chatReceipt) async {
    String? content = chatReceipt.content;
    content = chatMessageService.recoverContent(content!);
    logger.w('received videoChat chatReceipt content: $content');
    String messageId = chatReceipt.messageId!;
    //对方立即接受通话请求的回执，加本地流，重新协商
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
        RemoteVideoRenderController remoteVideoRenderController =
            videoConferenceRenderPool.createRemoteVideoRenderController(this);
        remoteVideoRenderController
            .addAdvancedPeerConnection(advancedPeerConnection);
        //把本地视频加入连接中，然后重新协商
        Map<String, PeerVideoRender> videoRenders =
            localVideoRenderController.getVideoRenders();
        await remoteVideoRenderController.addLocalVideoRender(
            videoRenders.values.toList(),
            peerConnection: advancedPeerConnection);
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
          Map<String, PeerVideoRender> videoRenders =
              localVideoRenderController.getVideoRenders();
          remoteVideoRenderController.removeVideoRender(
              videoRenders.values.toList(),
              peerConnection: advancedPeerConnection);
        }
      }
    }
  }

  @override
  dispose() {
    if (_chatSummary != null) {
      globalChatMessageController.unregisterReceiver(
          ChatMessageSubType.videoChat.name, receivedVideoChat);
    }
    if (_chatMessage != null) {
      globalChatMessageController.unregisterReceiver(
          ChatMessageSubType.chatReceipt.name, receivedChatReceipt);
    }
    super.dispose();
  }
}
