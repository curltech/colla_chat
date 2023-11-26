import 'package:audioplayers/audioplayers.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/webrtc/local_peer_media_stream_controller.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

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
  final Map<String, Map<String, ChatMessage>> _chatReceipts = {};

  //当前的通话房间，房间是临时组建的一组联系人，互相聊天和视频通话
  //如果当前的群存在的话，房间的人在群的联系人中选择，否则在所有的联系人中选择
  Conference? _conference;

  VideoChatStatus _status = VideoChatStatus.end;

  final Lock _lock = Lock();

  final BlueFireAudioPlayer _audioPlayer = BlueFireAudioPlayer();

  ConferenceChatMessageController();

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

  String? get partyType {
    return chatSummary?.partyType;
  }

  ///当前的联系人编号和名称，说明正在一对一聊天
  String? get peerId {
    String? partyType = this.partyType;
    if (partyType == PartyType.linkman.name) {
      return chatSummary?.peerId;
    }
    return null;
  }

  ///或者会议名称，或者群名称，或者联系人名称
  String? get name {
    return chatSummary?.name;
  }

  ///当前的群编号，说明正在群中聊天
  String? get groupId {
    String? partyType = this.partyType;
    if (partyType == PartyType.group.name) {
      return chatSummary?.peerId;
    }
    return null;
  }

  ///设置当前的视频邀请消息，可以从chatMessageController中获取当前，
  ///当前chatSummary是必须存在的，不存在就查找到
  ///当前chatMessage在选择了视频邀请消息后，也是存在的
  ///如果chatMessage不存在，表明是准备新的会议
  setChatMessage(ChatMessage chatMessage, {ChatSummary? chatSummary}) async {
    await _lock.synchronized(() async {
      _close();
      //消息未变，直接返回
      if (_chatMessage == chatMessage) {
        return;
      }
      _chatMessage = chatMessage;
      if (chatSummary != null) {
        _chatSummary = chatSummary;
      }
      await _initChatSummary();
      await _initChatMessage();
      await _initChatReceipt();
    });
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
      _chatSummary = chatSummary;
    } else if (_chatSummary != null && _chatMessage != null) {
      if (_chatMessage!.direct == ChatDirect.send.name) {
        if (_chatSummary!.peerId != _chatMessage!.receiverPeerId) {
          var chatSummary = await _findChatSummary();
          _chatSummary = chatSummary;
        }
      }
      if (_chatMessage!.direct == ChatDirect.receive.name) {
        if (_chatSummary!.peerId != _chatMessage!.senderPeerId!) {
          _chatSummary = null;
          var chatSummary = await _findChatSummary();
          _chatSummary = chatSummary;
        }
      }
    }
    if (_chatSummary == null) {
      logger.e('init find chatSummary failure');
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
          logger.w('Conference $conferenceId name ${conference.name} is exist');
        }
      }
    }
  }

  Map<String, Map<String, ChatMessage>> chatReceipts() {
    return _chatReceipts;
  }

  void putChatReceipt(ChatMessage chatReceipt) {
    Map<String, ChatMessage>? chatReceipts =
        _chatReceipts[chatReceipt.receiptType!];
    if (chatReceipts == null) {
      chatReceipts = {};
      _chatReceipts[chatReceipt.receiptType!] = chatReceipts;
    }
    chatReceipts[chatReceipt.senderPeerId!] = chatReceipt;
  }

  _initChatReceipt() async {
    _chatReceipts.clear();
    var messageId = _chatMessage!.messageId!;
    List<ChatMessage> chatMessages =
        await chatMessageService.findByMessageId(messageId);
    for (var chatMessage in chatMessages) {
      if (chatMessage.subMessageType == ChatMessageSubType.chatReceipt.name) {
        putChatReceipt(chatMessage);
      }
    }
  }

  ChatMessage? getChatReceipt(String subMessageType, String peerId) {
    return _chatReceipts[subMessageType]?[peerId];
  }

  playAudio(String filename, bool loopMode) {
    try {
      _audioPlayer.setLoopMode(loopMode);
      _audioPlayer.play(filename);
    } catch (e) {
      logger.e('audioPlayer play failure');
    }
  }

  stopAudio({String? filename, bool loopMode = false}) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.release();
      if (filename != null) {
        _audioPlayer.setLoopMode(loopMode);
        _audioPlayer.play(filename);
        await _audioPlayer.stop();
        await _audioPlayer.release();
      }
    } catch (e) {
      logger.e('audioPlayer stop failure:$e');
    }
  }

  setAudioContext({
    AudioContextConfigRoute? route,
    bool? duckAudio,
    bool? respectSilence,
    bool? stayAwake,
  }) async {
    try {
      await _audioPlayer.setAudioContext(
          route: route,
          duckAudio: duckAudio,
          respectSilence: respectSilence,
          stayAwake: stayAwake);
    } catch (e) {
      logger.e('setAudioContext failure:$e');
    }
  }

  ///1.发送视频通邀请话消息,此时消息必须有content,包含conference信息
  ///当前chatSummary必须存在，因此只能用于当前正在聊天的时候

  ///2.接收会议邀请消息

  ///3.发送会议邀请回执，用于被邀请方
  ///接收到视频通话邀请，做出接受或者拒绝视频通话邀请的决定
  ///如果是接受决定，本控制器将被加入到池中
  sendChatReceipt(MessageReceiptType receiptType) async {
    ChatSummary? chatSummary = _chatSummary;
    if (chatSummary == null) {
      logger.e('conference chat message controller chatSummary is null');
      return;
    }
    ChatMessage? chatMessage = _chatMessage;
    if (chatMessage == null) {
      logger.e('conference chat message controller chatMessage is null');
      return;
    }
    await _sendChatReceipt(receiptType);
    var groupType = chatMessage.groupType;
    //单个联系人视频通话邀请
    if (groupType == null) {
      //立即接听
      if (receiptType == MessageReceiptType.accepted) {
        //设置当前消息，转入视频会议界面
        chatMessageController.chatSummary = _chatSummary;
        chatMessageController.current = _chatMessage;
        indexWidgetProvider.push('chat_message');
        indexWidgetProvider.push('video_chat');
        await join();
        return;
      }
    } else {
      //立即接听
      if (receiptType == MessageReceiptType.accepted) {
        //设置当前消息，转入视频会议界面
        chatMessageController.chatSummary = _chatSummary;
        chatMessageController.current = _chatMessage;
        indexWidgetProvider.push('chat_message');
        if (_conference!.sfu) {
          indexWidgetProvider.push('sfu_video_chat');
        } else {
          indexWidgetProvider.push('video_chat');
        }
        await join();
        return;
      }
    }
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
    String? receiverPeerId = chatMessage.receiverPeerId;
    String? receiverName = chatMessage.receiverName;
    String? direct = chatMessage.direct;
    if (direct == ChatDirect.receive.name) {
      receiverPeerId = chatMessage.senderPeerId;
      receiverName = chatMessage.senderName;
    }
    ChatMessage chatReceipt = await chatMessageService.buildLinkmanChatReceipt(
        chatMessage, receiptType,
        receiverPeerId: receiverPeerId, receiverName: receiverName);
    await chatMessageService.sendAndStore(chatReceipt);
    logger.w(
        'send chatReceipt peerId:${chatReceipt.receiverPeerId}, name:${chatReceipt.receiverName}, receiptType:${chatReceipt.receiptType} successfully');
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
    ConferenceChange conferenceChange =
        await conferenceService.store(_conference!);
    var unknownPeerIds = conferenceChange.unknownPeerIds;
    if (unknownPeerIds != null && unknownPeerIds.isNotEmpty) {
      await linkmanService.findLinkman(
          chatMessage.senderPeerId!, unknownPeerIds,
          clientId: chatMessage.senderClientId);
    }
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
        await localPeerMediaStreamController.createMainPeerMediaStream(
            video: _conference!.video);
      } else {
        if (auto) {
          bool sfu = _conference!.sfu;
          //如果本地主视频存在，直接返回
          await localPeerMediaStreamController.createMainPeerMediaStream(
              sfu: sfu, video: _conference!.video);
        }
      }
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
    //当前到来的回执是新的
    String messageId = chatReceipt.messageId!;
    //当前的视频通话邀请消息一致
    if (_chatMessage!.messageId != chatReceipt.messageId) {
      logger.e('messageId $messageId is not equal');
      return;
    }

    _current = chatReceipt;
    putChatReceipt(chatReceipt);
    await _onReceivedChatReceipt(chatReceipt);
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
    String senderName = chatReceipt.senderName!;
    String clientId = chatReceipt.senderClientId!;
    PlatformParticipant platformParticipant =
        PlatformParticipant(peerId, clientId: clientId, name: senderName);
    String messageId = chatReceipt.messageId!;
    logger.w(
        'received messageReceiptType:$messageReceiptType from $peerId:$senderName');
    switch (messageReceiptType) {
      case MessageReceiptType.received:
        await _onReceived(platformParticipant, messageId);
        break;
      case MessageReceiptType.accepted:
        await _onAccepted(platformParticipant, messageId);
        break;
      case MessageReceiptType.rejected:
        await _onRejected(platformParticipant, messageId);
        break;
      case MessageReceiptType.terminated:
        await _onTerminated(platformParticipant, messageId);
        break;
      case MessageReceiptType.busy:
        await _onBusy(platformParticipant, messageId);
        break;
      case MessageReceiptType.ignored:
        await _onIgnored(platformParticipant, messageId);
        break;
      case MessageReceiptType.hold:
        await _onHold(platformParticipant, messageId);
        break;
      case MessageReceiptType.join:
        await _onJoin(platformParticipant, messageId);
        break;
      case MessageReceiptType.joined:
        await _onJoined(platformParticipant, messageId);
        break;
      case MessageReceiptType.exit:
        await _onExit(platformParticipant, messageId);
        break;
      default:
        break;
    }
  }

  ///对方只是表示收到，自己什么都不用做
  Future<void> _onReceived(
      PlatformParticipant platformParticipant, String messageId) async {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.end;
    }
  }

  ///对方立即接受邀请，并且加入会议，自己也要立即加入
  Future<void> _onAccepted(
      PlatformParticipant platformParticipant, String messageId) async {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.chatting;
    }
    await join();
  }

  ///对方拒绝，自己什么都不用做
  Future<void> _onRejected(
      PlatformParticipant platformParticipant, String messageId) async {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.end;
    }
  }

  ///对方终止，把对方移除会议
  _onTerminated(
      PlatformParticipant platformParticipant, String messageId) async {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.end;
    }
    if (_conference!.sfu) {
    } else {
      P2pConferenceClient? conferenceClient =
          p2pConferenceClientPool.getConferenceClient(messageId);
      if (conferenceClient != null) {
        conferenceClient.onParticipantDisconnectedEvent(platformParticipant);
      } else {
        logger.e('participant $peerId has no peerConnections');
      }
    }
  }

  ///对方占线，自己什么都不用做
  Future<void> _onBusy(
      PlatformParticipant platformParticipant, String messageId) async {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.end;
    }
  }

  ///对方没响应，自己什么都不用做
  Future<void> _onIgnored(
      PlatformParticipant platformParticipant, String messageId) async {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.end;
    }
  }

  ///对方保持，自己可以先加入，等待对方后续加入
  Future<void> _onHold(
      PlatformParticipant platformParticipant, String messageId) async {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.chatting;
    }
    await join();
  }

  /// 收到对方加入消息，自己加入，返回joined消息
  Future<void> _onJoin(
      PlatformParticipant platformParticipant, String messageId) async {
    if (_conference!.sfu) {
    } else {
      P2pConferenceClient? p2pConferenceClient =
          p2pConferenceClientPool.getConferenceClient(messageId);
      if (p2pConferenceClient != null && p2pConferenceClient.joined) {
        _sendChatReceipt(MessageReceiptType.joined);
      }
    }
    await _onJoined(platformParticipant, messageId);
  }

  /// 对方收到自己的joined消息，返回已经加入消息，自己也要配合把对方的连接加入本地流，属于被动加入
  Future<void> _onJoined(
      PlatformParticipant platformParticipant, String messageId) async {
    if (_conference!.sfu) {
    } else {
      //将邀请消息发送者的连接加入远程会议控制器中，本地的视频render加入发送者的连接中
      P2pConferenceClient? p2pConferenceClient =
          p2pConferenceClientPool.getConferenceClient(messageId);
      if (p2pConferenceClient != null) {
        if (_status == VideoChatStatus.calling) {
          status = VideoChatStatus.chatting;
        }
        p2pConferenceClient.onParticipantConnectedEvent(platformParticipant);
      } else {
        logger.e('p2pConferenceClient:$messageId is not exist');
      }
    }
  }

  /// 收到对方退出消息
  Future<void> _onExit(
      PlatformParticipant platformParticipant, String messageId) async {
    if (_status == VideoChatStatus.calling) {
      status = VideoChatStatus.end;
    }
    if (_conference!.sfu) {
    } else {
      //将发送者的连接加入远程会议控制器中，本地的视频render加入发送者的连接中
      P2pConferenceClient? p2pConferenceClient = p2pConferenceClientPool
          .getConferenceClient(_conference!.conferenceId);
      if (p2pConferenceClient != null) {
        p2pConferenceClient.onParticipantDisconnectedEvent(platformParticipant);
      } else {
        logger.e('p2pConferenceClient:$messageId is not exist');
      }
    }
  }

  ///通知所有人自己加入会议，发送join回执，并且加入
  join() async {
    await joinConference();
    await _sendChatReceipt(MessageReceiptType.join);
  }

  ///自己主动加入
  joinConference() async {
    await openLocalMainPeerMediaStream();
    if (_conference!.sfu) {
    } else {
      //创建新的视频会议控制器
      P2pConferenceClient? p2pConferenceClient = p2pConferenceClientPool
          .getConferenceClient(_conference!.conferenceId);
      if (p2pConferenceClient != null) {
        await p2pConferenceClient.join();
        status = VideoChatStatus.chatting;
      } else {
        logger
            .e('p2pConferenceClient:${_conference!.conferenceId} is not exist');
      }
    }
  }

  ///自己主动退出会议，发送exit回执
  exit() async {
    await _sendChatReceipt(MessageReceiptType.exit);
    status = VideoChatStatus.end;
  }

  ///自己主动终止，发送terminate回执，关闭会议
  ///如果会议发起人发出终止信号，收到的参与者都将退出，而且会议将不可再加入
  terminate() async {
    await _sendChatReceipt(MessageReceiptType.terminated);
    close();
  }

  close() async {
    await _lock.synchronized(() {
      _close();
    });
    notifyListeners();
  }

  void _close() {
    _chatMessage = null;
    _chatSummary = null;
    _chatReceipts.clear();
    _conference = null;
    _current = null;
    _status = VideoChatStatus.end;
  }
}
