import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/index/global_chat_message_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/p2p/local_peer_media_stream_controller.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:flutter/material.dart';

enum VideoChatStatus {
  chatting, //正在视频中，只要开始重新协商，表明进入
  calling, //正在呼叫中，发送邀请消息后，等待固定时间的振铃或者有人回答接受或者拒绝邀请后结束
  end, //结束，不在呼叫也不在视频会议
}

///视频会议的消息控制器，是一个视频会议的命令控制器
///1.发起视频会议邀请；2.接收邀请；3.发送邀请回执；4.接收邀请回执
class ConferenceChatMessageController with ChangeNotifier {
  final Key key = UniqueKey();

  ///当主视频不存在的时候是否自动创建
  bool auto = true;

  //视频邀请消息对应的汇总消息
  ChatSummary? _chatSummary;

  //视频邀请消息
  ChatMessage? _chatMessage;

  //最新的消息
  ChatMessage? _current;

  //回执
  Map<String, Map<String, ChatMessage>> _chatReceipts = {};
  String? partyType;

  //或者会议名称，或者群名称，或者联系人名称
  String? name;

  //当前的群编号，说明正在群中聊天
  String? groupId;

  //当前的联系人编号和名称，说明正在一对一聊天
  String? peerId;

  //当前的通话房间，房间是临时组建的一组联系人，互相聊天和视频通话
  //如果当前的群存在的话，房间的人在群的联系人中选择，否则在所有的联系人中选择
  Conference? _conference;

  VideoChatStatus _status = VideoChatStatus.end;

  final Map<String, List<Function(ChatMessage chatMessage)>> _receivers = {};

  ConferenceChatMessageController();

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

  VideoChatStatus get status {
    return _status;
  }

  set status(VideoChatStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
    }
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
    _chatReceipts = {};
    partyType = null;
    peerId = null;
    groupId = null;
    _conference = null;
    if (chatSummary == null) {
      globalChatMessageController.unregisterReceiver(
          ChatMessageSubType.videoChat.name, onReceivedInvitation);
      return;
    }
    partyType = chatSummary.partyType;
    if (partyType == PartyType.linkman.name) {
      peerId = chatSummary.peerId!;
      name = chatSummary.name!;
    } else if (partyType == PartyType.group.name) {
      groupId = chatSummary.peerId!;
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
        ChatMessageSubType.videoChat.name, onReceivedInvitation);
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
    _chatReceipts = {};
    //如果是清空数据，直接返回
    if (_chatMessage == null) {
      globalChatMessageController.unregisterReceiver(
          ChatMessageSubType.chatReceipt.name, onReceivedChatReceipt);
      return;
    }
    await _initChatSummary();
    await _initChatMessage();
    globalChatMessageController.registerReceiver(
        ChatMessageSubType.chatReceipt.name, onReceivedChatReceipt);
    await _initChatReceipt();
  }

  ///根据_chatMessage查找对应的chatSummary
  Future<ChatSummary?> _findChatSummary() async {
    ChatSummary? chatSummary;

    ///个人的消息receiverPeerId不为空
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
        if (_chatSummary!.peerId != _chatMessage!.receiverPeerId) {
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

  static Future<Map<String, Map<String, ChatMessage>>> findChatReceipts(
      String messageId) async {
    List<ChatMessage> chatMessages =
        await chatMessageService.findByMessageId(messageId);
    Map<String, Map<String, ChatMessage>> chatReceipts = {};
    if (chatMessages.isEmpty) {
      return chatReceipts;
    }

    for (var chatMessage in chatMessages) {
      if (chatMessage.subMessageType == ChatMessageSubType.chatReceipt.name) {
        putChatReceipt(chatReceipts, chatMessage);
      }
    }
    return chatReceipts;
  }

  static void putChatReceipt(
      Map<String, Map<String, ChatMessage>> chatReceiptMap,
      ChatMessage chatReceipt) {
    Map<String, ChatMessage>? chatReceipts =
        chatReceiptMap[chatReceipt.receiptType!];
    if (chatReceipts == null) {
      chatReceipts = {};
      chatReceiptMap[chatReceipt.receiptType!] = chatReceipts;
    }
    chatReceipts[chatReceipt.senderPeerId!] = chatReceipt;
  }

  _initChatReceipt() async {
    //如果_chatMessage不为空，查询所有的相同的消息
    var messageId = _chatMessage!.messageId!;
    _chatReceipts = await findChatReceipts(messageId);
  }

  ChatMessage? getChatReceipt(String subMessageType, String peerId) {
    return _chatReceipts[subMessageType]?[peerId];
  }

  ///创建新的会议功能
  ///对联系人模式，可以临时创建一个会议，会议成员从群成员中选择就是自己和对方，会议名称是对方的名称，不保存会议
  ///对群模式，可以创建一个会议，会议成员从群成员中选择，会议名称是群的名称加上当前时间，保存会议
  ///对会议模式，直接转到会议创建界面，
  Future<void> buildConference(
      {required bool video, required List<String> participants}) async {
    var conference = _conference;
    if (conference != null) {
      logger.e('conference ${conference.name} is exist');
      return;
    }
    var partyType = this.partyType;
    if (partyType == PartyType.conference.name) {}
    var groupId = this.groupId;
    if (partyType == PartyType.group.name) {
      if (groupId == null) {
        return;
      }
    }
    if (partyType == PartyType.linkman.name) {
      var peerId = this.peerId;
      if (peerId == null) {
        return;
      }
      if (!participants.contains(peerId)) {
        participants.add(peerId);
      }
    }
    var name = this.name;
    var current = DateTime.now();
    var dateName = current.toLocal().toIso8601String();
    _conference = await conferenceService.createConference(
        'video-chat-$dateName', video,
        startDate: current.toUtc().toIso8601String(),
        endDate:
            current.add(const Duration(hours: 2)).toUtc().toIso8601String(),
        participants: participants);
    if (partyType == PartyType.group.name) {
      _conference!.groupId = groupId;
      _conference!.groupName = name;
      _conference!.groupType = partyType;
    }
  }

  ///1.发送视频通邀请话消息,此时消息必须有content,包含conference信息
  ///当前chatSummary可以不存在，因此不需要当前处于聊天场景下，因此是一个静态方法，创建永久conference的时候使用
  ///对linkman模式下，conference是临时的，不保存数据库
  ///对group和conference模式下，conference是永久的，保存数据库，可以以后重新加入
  static Future<ChatMessage?> invite(Conference conference) async {
    ChatMessage chatMessage = await chatMessageService.buildGroupChatMessage(
      conference.conferenceId,
      PartyType.conference,
      title: conference.video
          ? ChatMessageContentType.video.name
          : ChatMessageContentType.audio.name,
      content: conference,
      messageId: conference.conferenceId,
      subMessageType: ChatMessageSubType.videoChat,
    );
    await chatMessageService.sendAndStore(chatMessage,
        cryptoOption: CryptoOption.group, peerIds: conference.participants);

    return chatMessage;
  }

  ///1.发送视频通邀请话消息,此时消息必须有content,包含conference信息
  ///当前chatSummary必须存在，因此只能用于当前正在聊天的时候
  Future<ChatMessage?> inviteWithChatSummary() async {
    ///有chatSummary和conference的时候发送邀请消息
    ChatMessage? chatMessage = await chatMessageController.send(
        title: _conference!.video
            ? ChatMessageContentType.video.name
            : ChatMessageContentType.audio.name,
        content: _conference,
        messageId: _conference!.conferenceId,
        subMessageType: ChatMessageSubType.videoChat,
        peerIds: _conference!.participants);
    if (chatMessage != null) {
      logger.i('send video chatMessage ${chatMessage.messageId}');
    }
    await setChatMessage(chatMessage!);
    p2pConferenceClientPool.createP2pConferenceClient(this);
    status = VideoChatStatus.calling;

    return chatMessage;
  }

  ///2.接收会议邀请消息
  onReceivedInvitation(ChatMessage chatMessage) async {
    if (_chatMessage == null || _chatMessage != chatMessage) {
      if (chatMessage.subMessageType == ChatMessageSubType.videoChat.name) {
        _current = chatMessage;
        await setChatMessage(chatMessage);
        await onVideoChatMessage(chatMessage);
      }
    }
  }

  ///3.发送会议邀请回执，用于被邀请方
  ///接收到视频通话邀请，做出接受或者拒绝视频通话邀请的决定
  ///如果是接受决定，本控制器将被加入到池中
  sendChatReceipt(MessageReceiptType receiptType) async {
    ChatMessage? chatMessage = _chatMessage;
    if (chatMessage == null) {
      return;
    }
    await _sendChatReceipt(receiptType);
    var groupType = chatMessage.groupType;
    //单个联系人视频通话邀请
    if (groupType == null) {
      //立即接听
      if (receiptType == MessageReceiptType.accepted) {
        await joinConference();
        //设置当前消息，转入视频会议界面
        chatMessageController.chatSummary = _chatSummary;
        chatMessageController.current = _chatMessage;
        indexWidgetProvider.push('chat_message');
        indexWidgetProvider.push('video_chat');
        return;
      }
    } else if (groupType == PartyType.group.name) {
      //立即接听
      if (receiptType == MessageReceiptType.accepted) {
        await joinConference();
        //设置当前消息，转入视频会议界面
        chatMessageController.chatSummary = _chatSummary;
        chatMessageController.current = _chatMessage;
        indexWidgetProvider.push('chat_message');
        indexWidgetProvider.push('video_chat');
        return;
      }
    }
    await setChatSummary(null);
    await setChatMessage(null);
  }

  ///仅仅发送回执消息
  _sendChatReceipt(MessageReceiptType receiptType) async {
    ChatMessage? chatMessage = _chatMessage;
    if (chatMessage == null) {
      return;
    }
    var groupType = chatMessage.groupType;
    //单个联系人视频通话邀请
    if (groupType == null) {
      await _sendLinkmanChatReceipt(receiptType);
    } else if (groupType == PartyType.group.name) {
      await _sendGroupChatReceipt(receiptType);
    } else if (groupType == PartyType.conference.name) {
      await _sendConferenceChatReceipt(receiptType);
    }
  }

  ///发送linkman视频邀请消息的回执
  _sendLinkmanChatReceipt(MessageReceiptType receiptType) async {
    ChatMessage? chatMessage = _chatMessage;
    if (chatMessage == null) {
      return;
    }
    //创建回执消息
    ChatMessage chatReceipt = await chatMessageService.buildLinkmanChatReceipt(
        chatMessage, receiptType);
    await chatMessageService.sendAndStore(chatReceipt);
    await chatMessageService.updateReceiptType(chatMessage, receiptType);
  }

  ///发送group视频邀请消息的回执
  _sendGroupChatReceipt(MessageReceiptType receiptType) async {
    ChatMessage? chatMessage = _chatMessage;
    if (chatMessage == null) {
      return;
    }
    //群视频通话邀请
    //除了向发送方外，还需要向房间的各接收人发送回执，
    //首先检查接收人是否已经存在给自己的回执，不存在或者存在是accepted则发送回执
    //如果存在，如果是rejected或者terminated，则不发送回执
    //创建回执消息
    //await conferenceService.store(_conference!);
    ChatMessage chatReceipt = await chatMessageService.buildGroupChatReceipt(
        chatMessage, receiptType);
    await chatMessageService.sendAndStore(chatReceipt,
        cryptoOption: CryptoOption.group, peerIds: _conference!.participants);
    await chatMessageService.updateReceiptType(chatMessage, receiptType);
  }

  ///发送conference视频邀请消息的回执
  _sendConferenceChatReceipt(MessageReceiptType receiptType) async {
    ChatMessage? chatMessage = _chatMessage;
    if (chatMessage == null) {
      return;
    }
    //会议视频通话邀请
    //除了向发送方外，还需要向房间的各接收人发送回执，
    //首先检查接收人是否已经存在给自己的回执，不存在或者存在是accepted则发送回执
    //如果存在，如果是rejected或者terminated，则不发送回执
    await conferenceService.store(_conference!);
    ChatMessage chatReceipt = await chatMessageService.buildGroupChatReceipt(
        chatMessage, receiptType);
    await chatMessageService.sendAndStore(chatReceipt,
        cryptoOption: CryptoOption.group, peerIds: _conference!.participants);
    await chatMessageService.updateReceiptType(chatMessage, receiptType);
  }

  ///在会议创建后，打开本地视频，如果存在则直接返回，
  ///否则在linkman模式下自动创建，会议和群模式根据auto参数决定是否自动创建
  openLocalMainPeerMediaStream() async {
    PeerMediaStream? mainPeerMediaStream =
        localPeerMediaStreamController.mainPeerMediaStream;
    if (mainPeerMediaStream != null) {
      return;
    } else {
      if (chatSummary == null) {
        logger.e('chatSummary is null');
        return;
      }
      var partyType = chatSummary!.partyType!;
      if (partyType == PartyType.linkman.name) {
        await localPeerMediaStreamController
            .openLocalMainPeerMediaStream(_conference!.video);
      } else {
        if (auto) {
          //如果本地主视频存在，直接返回
          await localPeerMediaStreamController
              .openLocalMainPeerMediaStream(_conference!.video);
        }
      }
    }
  }

  ///在视频会议中增加本地视频到所有连接
  addLocalPeerMediaStream(PeerMediaStream peerMediaStream) async {
    if (_conference != null && _status == VideoChatStatus.chatting) {
      await p2pConferenceClientPool.addLocalPeerMediaStream(
          _conference!.conferenceId, [peerMediaStream]);
    }
  }

  ///在视频会议中增加多个本地视频到所有连接
  addLocalPeerMediaStreams() async {
    if (_conference != null && _status == VideoChatStatus.chatting) {
      var peerMediaStreams =
          localPeerMediaStreamController.getPeerMediaStreams().values.toList();
      await p2pConferenceClientPool.addLocalPeerMediaStream(
          _conference!.conferenceId, peerMediaStreams);
    }
  }

  ///在视频会议中删除本地视频到所有连接
  removePeerMediaStream(PeerMediaStream peerMediaStream) async {
    if (_conference != null) {
      await p2pConferenceClientPool
          .removePeerMediaStream(_conference!.conferenceId, [peerMediaStream]);
    }
  }

  ///4.接受到视频通话回执，一般由globalChatMessageController分发到此
  ///在多个接收人的场景下，首先检查自己是否已经发过回执，存在是accepted则继续处理
  ///如果不存在，则发送自己的决定，如果存在是rejected或者terminated，则不处理
  onReceivedChatReceipt(ChatMessage chatReceipt) async {
    //当前的视频通话邀请消息不为空
    if (_chatMessage == null) {
      logger.e('Video chatMessage is null');
      return;
    }
    String? subMessageType = chatReceipt.subMessageType;
    if (subMessageType != ChatMessageSubType.chatReceipt.name) {
      logger.e('chatMessage is not chatReceipt');
      return;
    }
    //当前到来的回执是新的
    String messageId = chatReceipt.messageId!;
    //当前的视频通话邀请消息一致
    if (_chatMessage!.messageId != chatReceipt.messageId) {
      logger.e('messageId $messageId is not equal');
    }

    _current = chatReceipt;
    putChatReceipt(_chatReceipts, chatReceipt);
    await _onReceivedChatReceipt(chatReceipt);
    await onVideoChatMessage(chatReceipt);
  }

  ///收到视频通话的回执的处理，
  ///在群通话的情况下，可以收到多次，包括多个接收人的回执
  ///根据消息回执是接受拒绝还是终止进行处理
  _onReceivedChatReceipt(ChatMessage chatReceipt) async {
    String? receiptType = chatReceipt.receiptType;
    if (receiptType == null) {
      return;
    }
    MessageReceiptType? messageReceiptType =
        StringUtil.enumFromString(MessageReceiptType.values, receiptType);
    if (messageReceiptType == null) {
      return;
    }
    logger.w('received videoChat chatReceipt content: $receiptType');
    String peerId = chatReceipt.senderPeerId!;
    String clientId = chatReceipt.senderClientId!;
    String messageId = chatReceipt.messageId!;
    switch (messageReceiptType) {
      case MessageReceiptType.received:
        await _onReceived(peerId, clientId, messageId);
        break;
      case MessageReceiptType.accepted:
        await _onAccepted(peerId, clientId, messageId);
        break;
      case MessageReceiptType.rejected:
        await _onRejected(peerId, clientId, messageId);
        break;
      case MessageReceiptType.terminated:
        await _onTerminated(peerId, clientId, messageId);
        break;
      case MessageReceiptType.busy:
        await _onBusy(peerId, clientId, messageId);
        break;
      case MessageReceiptType.ignored:
        await _onIgnored(peerId, clientId, messageId);
        break;
      case MessageReceiptType.hold:
        await _onHold(peerId, clientId, messageId);
        break;
      case MessageReceiptType.join:
        await _onJoin(peerId, clientId, messageId);
        break;
      case MessageReceiptType.exit:
        await _onExit(peerId, clientId, messageId);
        break;
      default:
        break;
    }
  }

  ///对方只是表示收到，自己什么都不用做
  Future<void> _onReceived(
      String peerId, String clientId, String messageId) async {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.end;
    }
  }

  ///对方立即接受邀请，并且加入会议，自己也要立即加入
  Future<void> _onAccepted(
      String peerId, String clientId, String messageId) async {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.chatting;
    }
    await joinConference();
  }

  ///对方拒绝，自己什么都不用做
  Future<void> _onRejected(
      String peerId, String clientId, String messageId) async {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.end;
    }
  }

  ///对方终止，把对方移除会议
  _onTerminated(String peerId, String clientId, String messageId) {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.end;
    }
    AdvancedPeerConnection? advancedPeerConnection = peerConnectionPool.getOne(
      peerId,
      clientId: clientId,
    );
    //与发送者的连接存在，将本地的视频render加入连接中
    if (advancedPeerConnection != null) {
      P2pConferenceClient? p2pConferenceClient =
          p2pConferenceClientPool.getP2pConferenceClient(messageId);
      if (p2pConferenceClient != null) {
        p2pConferenceClient
            .removeAdvancedPeerConnection(advancedPeerConnection);
      }
    } else {
      logger.e('participant $peerId has no peerConnections');
    }
  }

  ///对方占线，自己什么都不用做
  Future<void> _onBusy(String peerId, String clientId, String messageId) async {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.end;
    }
  }

  ///对方没响应，自己什么都不用做
  Future<void> _onIgnored(
      String peerId, String clientId, String messageId) async {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.end;
    }
  }

  ///对方保持，自己可以先加入，等待对方后续加入
  Future<void> _onHold(String peerId, String clientId, String messageId) async {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.end;
    }
    await join();
  }

  ///对方加入，自己也要配合把对方的连接加入本地流，属于被动加入
  Future<void> _onJoin(String peerId, String clientId, String messageId) async {
    AdvancedPeerConnection? advancedPeerConnection = peerConnectionPool.getOne(
      peerId,
      clientId: clientId,
    );
    //将发送者的连接加入远程会议控制器中，本地的视频render加入发送者的连接中
    if (advancedPeerConnection != null) {
      P2pConferenceClient p2pConferenceClient =
          p2pConferenceClientPool.createP2pConferenceClient(this);
      p2pConferenceClient.addAdvancedPeerConnection(advancedPeerConnection);
    } else {
      logger.e('participant $peerId has no peerConnections');
    }
  }

  ///对方退出，自己也要配合把对方的连接退出
  Future<void> _onExit(String peerId, String clientId, String messageId) async {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.end;
    }
    AdvancedPeerConnection? advancedPeerConnection = peerConnectionPool.getOne(
      peerId,
      clientId: clientId,
    );
    //将发送者的连接加入远程会议控制器中，本地的视频render加入发送者的连接中
    if (advancedPeerConnection != null) {
      P2pConferenceClient? p2pConferenceClient = p2pConferenceClientPool
          .getP2pConferenceClient(_conference!.conferenceId);
      if (p2pConferenceClient != null) {
        p2pConferenceClient
            .removeAdvancedPeerConnection(advancedPeerConnection);
      }
    } else {
      logger.e('participant $peerId has no peerConnections');
    }
  }

  ///通知所有人自己加入会议，发送join回执，并且加入
  join() async {
    await _sendChatReceipt(MessageReceiptType.join);
    await joinConference();
  }

  ///自己主动加入，包含加本地视频和将会议的每个参与者加入会议中两步，对会议的参与者的所以连接操作
  ///每一个新加入的会议是池中的当前会议
  joinConference() async {
    await openLocalMainPeerMediaStream();
    //创建新的视频会议控制器
    P2pConferenceClient p2pConferenceClient =
        p2pConferenceClientPool.createP2pConferenceClient(this);
    List<String>? participants = conference!.participants;
    if (participants != null && participants.isNotEmpty) {
      //将所有的参与者的连接加入会议控制器，自己除外
      for (var participant in participants) {
        if (participant == myself.peerId) {
          continue;
        }
        List<AdvancedPeerConnection> peerConnections =
            peerConnectionPool.get(participant);
        if (peerConnections.isNotEmpty) {
          AdvancedPeerConnection peerConnection = peerConnections[0];
          await p2pConferenceClient.addAdvancedPeerConnection(peerConnection);
        } else {
          logger.e('participant $participant has no peerConnections');
        }
      }
    }
    status = VideoChatStatus.chatting;
  }

  ///自己主动退出会议，发送exit回执，关闭会议
  exit() async {
    await _sendChatReceipt(MessageReceiptType.exit);
    await p2pConferenceClientPool.exitConference(_conference!.conferenceId);
    status = VideoChatStatus.end;
  }

  ///自己主动终止，发送terminate回执，关闭会议
  ///如果会议发起人发出终止信号，收到的参与者都将退出，而且会议将不可再加入
  terminate() async {
    await _sendChatReceipt(MessageReceiptType.terminated);
    await p2pConferenceClientPool.exitConference(_conference!.conferenceId);
    status = VideoChatStatus.end;
  }
}
