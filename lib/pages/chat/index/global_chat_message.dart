import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/crypto/signalprotocol.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/p2p/chain/action/chat.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/channel_chat_message.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/smsclient.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/livekit/sfu_room_client.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:telephony/telephony.dart';

///跟踪影响全局的消息到来，对不同类型的消息进行分派
class GlobalChatMessage {
  StreamController<ChatMessage> chatMessageStreamController =
      StreamController<ChatMessage>.broadcast();
  StreamController<ChatMessage> chatReceiptStreamController =
      StreamController<ChatMessage>.broadcast();

  /// 订阅websocket onChat传来的消息
  StreamSubscription<ChainMessage>? chainMessageStreamSubscription;

  GlobalChatMessage() {
    /// websocket转发的聊天消息处理
    chainMessageStreamSubscription = chatAction.receiveStreamController.stream
        .listen((ChainMessage chainMessage) {
      onChat(chainMessage);
    });
    if (platformParams.android) {
      smsClient.smsMessageStreamController.stream
          .listen((SmsMessage smsMessage) {
        onSmsMessage(smsMessage);
      });
    }
  }

  /// 从AdvancedPeerConnection收到消息事件，先解密数据，然后转换成chatMessage
  onMessage(WebrtcEvent event) async {
    List<int> data = event.data;
    await onData(data, TransportType.webrtc);
  }

  onData(List<int> data, TransportType transportType) async {
    ChatMessage? chatMessage = await chatMessageService.decrypt(data);
    if (chatMessage != null) {
      chatMessage.transportType = transportType.name;
      logger.w('got data chatMessage from ${transportType.name}');
      _receiveChatMessage(chatMessage);
    } else {
      logger.e('Received chatMessage but decrypt failure');
    }
  }

  Future<bool> _allowedChatMessage(ChainMessage chainMessage) async {
    String? peerId = chainMessage.srcPeerId;
    if (peerId == null) {
      return false;
    }

    Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
    if (linkman != null) {
      ///呼叫者本地存在
      if (linkman.linkmanStatus == LinkmanStatus.F.name) {
        ///如果是好友，则直接接受
        return true;
      } else if (linkman.linkmanStatus == LinkmanStatus.B.name) {
        ///如果是黑名单，则直接拒绝
        return false;
      }
    }

    return true;
  }

  /// 从websocket的ChainMessage方式，chatAction接收到的ChatMessage
  Future<void> onChat(ChainMessage chainMessage) async {
    logger.w('got a chainMessage from websocket');
    bool allowed = await _allowedChatMessage(chainMessage);
    if (!allowed) {
      logger.e('chainMessage is not allowed receive');
      return;
    }

    /// 如果是密文发送，chat无需加密的情况下，对群发的时候统一加密有帮助
    ChatMessage? chatMessage;
    if (chainMessage.payloadType == PayloadType.list.name) {
      chatMessage = await chatMessageService.decrypt(chainMessage.payload);
    } else if (chainMessage.payloadType == PayloadType.chatMessage.name) {
      ///如果是明文发送，chat自己加密的情况下
      chatMessage = ChatMessage.fromJson(chainMessage.payload);
    }
    if (chatMessage != null) {
      chatMessage.transportType = TransportType.websocket.name;
      logger.w('got a chatMessage from websocket');
      _receiveChatMessage(chatMessage);
    } else {
      logger.e('onChat response chatMessage parse failure');
    }
  }

  ///接收到加密的短信
  onSmsMessage(SmsMessage smsMessage) async {
    var mobile = smsMessage.address;
    String? body = smsMessage.body;
    if (body == null) {
      return;
    }
    logger.w('got a message from mobile: $mobile sms');
    List<Linkman> linkmen = await linkmanService.findByMobile(mobile!);
    if (linkmen.isEmpty) {
      return;
    }
    Linkman? linkman = linkmen[0];
    onLinkmanSmsMessage(linkman, body);
  }

  onLinkmanSmsMessage(Linkman linkman, String text) async {
    var peerId = linkman.peerId;
    var clientId = linkman.clientId;
    Uint8List data = CryptoUtil.decodeBase64(text);
    int cryptOption = data[data.length - 1];
    SecurityContextService? securityContextService =
        ServiceLocator.securityContextServices[cryptOption];
    securityContextService =
        securityContextService ?? noneSecurityContextService;
    SecurityContext securityContext = SecurityContext();
    securityContext.srcPeerId = peerId;
    securityContext.targetClientId = clientId;
    securityContext.payload = data.sublist(0, data.length - 1);
    bool result = await securityContextService.decrypt(securityContext);
    if (result) {
      text = CryptoUtil.utf8ToString(securityContext.payload);
      ChatMessage chatMessage = await chatMessageService.buildChatMessage(
        receiverPeerId: myself.peerId,
        receiverName: myself.name,
        content: text,
        transportType: TransportType.sms,
      );
      chatMessage.senderPeerId = linkman.peerId;
      chatMessage.senderClientId = linkman.clientId;
      chatMessage.senderName = linkman.name;
      chatMessage.transportType = TransportType.sms.name;
      logger.w('got a chatMessage from sms');
      _receiveChatMessage(chatMessage);
    }
  }

  ///跟踪影响全局的消息到来，对不同类型的消息进行分派
  Future<void> _receiveChatMessage(ChatMessage chatMessage) async {
    ///保存消息
    ChatMessage? savedChatMessage =
        await chatMessageService.receiveChatMessage(chatMessage);
    if (savedChatMessage == null) {
      logger.e('new or original chatMessage save fail');
    }
    String messageId = chatMessage.messageId!;
    String peerId = chatMessage.senderPeerId!;
    String? title = chatMessage.title;
    String? content = chatMessage.content;
    ChatMessageSubType? subMessageType = StringUtil.enumFromString(
        ChatMessageSubType.values, chatMessage.subMessageType);

    //接收消息的标准处理
    logger.i('chatMessage subMessageType:${subMessageType!.name} title:$title');
    switch (subMessageType) {
      case ChatMessageSubType.videoChat:
        break;
      case ChatMessageSubType.chatReceipt:
        _receiveChatReceipt(chatMessage);
        break;
      case ChatMessageSubType.addFriend:
        linkmanService.receiveModifyLinkman(chatMessage);
        break;
      case ChatMessageSubType.findLinkman:
        linkmanService.receiveFindLinkman(chatMessage);
        break;
      case ChatMessageSubType.modifyLinkman:
        linkmanService.receiveModifyLinkman(chatMessage);
        break;
      case ChatMessageSubType.cancel:
        //接收到删除消息的消息
        String? messageId = content;
        if (messageId != null) {
          chatMessageService
              .delete(where: 'messageId=?', whereArgs: [messageId]);
        }
        break;
      case ChatMessageSubType.preKeyBundle:
        //接收到signal协议初始化消息
        _receivePreKeyBundle(chatMessage);
        break;
      case ChatMessageSubType.signal:
        //接收到webrtc的信号消息
        _receiveSignal(chatMessage);
        break;
      case ChatMessageSubType.addGroup:
        await groupService.receiveAddGroup(chatMessage);
        break;
      case ChatMessageSubType.modifyGroup:
        await groupService.receiveModifyGroup(chatMessage);
        break;
      case ChatMessageSubType.dismissGroup:
        await groupService.receiveDismissGroup(chatMessage);
        break;
      case ChatMessageSubType.addGroupMember:
        await groupService.receiveAddGroupMember(chatMessage);
        break;
      case ChatMessageSubType.removeGroupMember:
        await groupService.receiveRemoveGroupMember(chatMessage);
        break;
      case ChatMessageSubType.groupFile:
        await groupService.receiveGroupFile(chatMessage);
        break;
      case ChatMessageSubType.updateSubscript:
        await channelChatMessageService.receiveUpdateSubscript(chatMessage);
        break;
      default:
        break;
    }

    chatMessageStreamController.add(chatMessage);
    //对于接收到的非系统消息，如果消息控制器的目标与发送者相同，进行刷新
    //由于此处刷新了消息控制器，所以对非系统消息，不能同时监听chatMessageController和globalChatMessageController
    //否则会出现消息的重复
    if (chatMessage.messageType != ChatMessageType.system.name &&
        chatMessageController.chatSummary != null) {
      var peerId = chatMessageController.chatSummary!.peerId;
      if (chatMessage.senderPeerId == peerId || chatMessage.groupId == peerId) {
        chatMessageController.notifyListeners();
      }
    }
  }

  _receiveChatReceipt(ChatMessage chatMessage) async {
    String? subMessageType = chatMessage.subMessageType;
    if (subMessageType != ChatMessageSubType.chatReceipt.name) {
      logger.e('chatMessage is not chatReceipt');
      return;
    }
    String? receiptType = chatMessage.receiptType;
    if (receiptType == null) {
      return;
    }
    MessageReceiptType? messageReceiptType =
        StringUtil.enumFromString(MessageReceiptType.values, receiptType);
    if (messageReceiptType == null) {
      return;
    }
    String peerId = chatMessage.senderPeerId!;
    String clientId = chatMessage.senderClientId!;
    String messageId = chatMessage.messageId!;
    if (messageReceiptType == MessageReceiptType.busy ||
        messageReceiptType == MessageReceiptType.ignored ||
        messageReceiptType == MessageReceiptType.received ||
        messageReceiptType == MessageReceiptType.rejected) {}

    ConferenceChatMessageController? conferenceChatMessageController;

    /// 以下四种消息如果没有会议，需要创建会议
    if (messageReceiptType == MessageReceiptType.accepted ||
        messageReceiptType == MessageReceiptType.join ||
        messageReceiptType == MessageReceiptType.joined ||
        messageReceiptType == MessageReceiptType.terminated ||
        messageReceiptType == MessageReceiptType.exit) {
      //将发送者的连接加入远程会议控制器中，本地的视频render加入发送者的连接中
      ChatMessage? videoChatMessage =
          await chatMessageService.findVideoChatMessage(messageId: messageId);
      if (videoChatMessage != null) {
        String? content = videoChatMessage.content;
        if (content != null) {
          content = chatMessageService.recoverContent(content);
          Map<String, dynamic> json = JsonUtil.toJson(content);
          Conference conference = Conference.fromJson(json);
          if (conference.sfu) {
            LiveKitConferenceClient? conferenceClient;
            if (messageReceiptType == MessageReceiptType.terminated ||
                messageReceiptType == MessageReceiptType.exit) {
              conferenceClient = liveKitConferenceClientPool
                  .getConferenceClient(conference.conferenceId);
            } else {
              conferenceClient = await liveKitConferenceClientPool
                  .createConferenceClient(videoChatMessage);
            }
            if (conferenceClient != null) {
              logger
                  .w('create liveKitConferenceClient:$messageId successfully');
              conferenceChatMessageController =
                  conferenceClient.conferenceChatMessageController;
            }
          } else {
            P2pConferenceClient? conferenceClient;
            if (messageReceiptType == MessageReceiptType.terminated ||
                messageReceiptType == MessageReceiptType.exit) {
              conferenceClient = p2pConferenceClientPool
                  .getConferenceClient(conference.conferenceId);
            } else {
              conferenceClient = await p2pConferenceClientPool
                  .createConferenceClient(videoChatMessage);
            }
            if (conferenceClient != null) {
              logger.w('create p2pConferenceClient:$messageId successfully');
              conferenceChatMessageController =
                  conferenceClient.conferenceChatMessageController;
            }
          }
        }
      }
    }
    await conferenceChatMessageController?.onReceivedChatReceipt(chatMessage);
    await conferenceChatMessageController?.stopAudio();
  }

  ///收到signal加密初始化消息
  _receivePreKeyBundle(ChatMessage chatMessage) async {
    String content = chatMessageService.recoverContent(chatMessage.content!);
    String peerId = chatMessage.senderPeerId!;
    String? clientId = chatMessage.senderClientId;
    if (chatMessage.subMessageType == ChatMessageSubType.preKeyBundle.name) {
      PreKeyBundle? retrievedPreKeyBundle =
          signalSessionPool.signalKeyPair.preKeyBundleFromJson(content);
      if (retrievedPreKeyBundle != null) {
        SignalSession? signalSession;
        try {
          signalSession = await signalSessionPool.create(
              peerId: peerId,
              clientId: clientId,
              deviceId: retrievedPreKeyBundle.getDeviceId(),
              retrievedPreKeyBundle: retrievedPreKeyBundle);
        } catch (e) {
          logger.e(
              'peerId: $peerId clientId:$clientId received PreKeyBundle, signalSession create failure:$e');
        }
        if (signalSession != null) {
          logger.i(
              'peerId: $peerId clientId:$clientId received PreKeyBundle, signalSession created');
        } else {
          logger.e(
              'peerId: $peerId clientId:$clientId received PreKeyBundle, signalSession create failure');
        }
      } else {
        logger.i('chatMessage content transfer to PreKeyBundle failure');
      }
    }
  }

  /// 收到webrtc signal消息
  _receiveSignal(ChatMessage chatMessage) async {
    var json = chatMessageService.recoverContent(chatMessage.content!);
    String peerId = chatMessage.senderPeerId!;
    String clientId = chatMessage.senderClientId!;
    if (chatMessage.subMessageType == ChatMessageSubType.signal.name) {
      WebrtcSignal webrtcSignal = WebrtcSignal.fromJson(JsonUtil.toJson(json));
      await peerConnectionPool.onWebrtcSignal(peerId, webrtcSignal,
          clientId: clientId);
    }
  }

  ///发送新的联系人信息
  sendModifyLinkman(String peerId, {String? clientId}) async {
    linkmanService.modifyLinkman(peerId, clientId: clientId);
  }

  ///发送PreKeyBundle
  sendPreKeyBundle(String peerId, {required String clientId}) async {
    return;
    PreKeyBundle preKeyBundle =
        signalSessionPool.signalKeyPair.getPreKeyBundle();
    var json = signalSessionPool.signalKeyPair.preKeyBundleToJson(preKeyBundle);
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(
        receiverPeerId: peerId,
        clientId: clientId,
        messageType: ChatMessageType.system,
        subMessageType: ChatMessageSubType.preKeyBundle,
        content: json);
    await chatMessageService.sendAndStore(chatMessage,
        cryptoOption: CryptoOption.linkman);
    logger.i('peerId: $peerId clientId:$clientId sent PreKeyBundle');
  }
}

///收到的最新消息
final GlobalChatMessage globalChatMessage = GlobalChatMessage();
