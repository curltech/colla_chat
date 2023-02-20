import 'package:colla_chat/crypto/signalprotocol.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/p2p/chain/action/chat.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

///跟踪影响全局的消息到来，对不同类型的消息进行分派
class GlobalChatMessageController with ChangeNotifier {
  //最新的到来消息
  ChatMessage? _chatMessage;

  ChatMessage? get chatMessage {
    return _chatMessage;
  }

  GlobalChatMessageController() {
    chatAction.registerReceiver(onChat);
  }

  ///从websocket的ChainMessage方式，chatAction接收到的ChatMessage
  Future<void> onChat(ChainMessage chainMessage) async {
    if (chainMessage.srcPeerId == null) {
      logger.e('chainMessage.srcPeerId is null');
      return;
    }
    if (chainMessage.payloadType == PayloadType.chatMessage.name) {
      ChatMessage chatMessage = ChatMessage.fromJson(chainMessage.payload);
      await receiveChatMessage(chatMessage);
    }
  }

  ///跟踪影响全局的消息到来，对不同类型的消息进行分派
  Future<void> receiveChatMessage(ChatMessage chatMessage) async {
    ///保存消息
    ChatMessage? savedChatMessage =
        await chatMessageService.receiveChatMessage(chatMessage);
    if (savedChatMessage == null) {
      logger.e('new chatMessage save fail');
    }
    _chatMessage = chatMessage;
    String messageId = chatMessage.messageId!;
    String peerId = chatMessage.senderPeerId!;
    String? title = chatMessage.title;
    String? content = chatMessage.content;
    ChatMessageSubType? subMessageType = StringUtil.enumFromString(
        ChatMessageSubType.values, chatMessage.subMessageType);
    logger.i('chatMessage subMessageType:${subMessageType!.name} title:$title');
    switch (subMessageType) {
      case ChatMessageSubType.videoChat:
        break;
      case ChatMessageSubType.chatReceipt:
        //处理视频通话消息的回执
        ChatMessage? originMessage = await chatMessageService.findOriginByMessageId(
            messageId,
            receiverPeerId: chatMessage.senderPeerId!);
        if (originMessage == null) {
          logger.e('messageId:$messageId original chatMessage is not exist');
          return;
        }
        String? originMessageType = originMessage.messageType;
        String? originSubMessageType = originMessage.subMessageType;
        if (originSubMessageType == ChatMessageSubType.videoChat.name) {
          if (chatMessage.status == MessageStatus.accepted.name) {
            //收到视频通话邀请同意回执，发出本地流，关闭拨号窗口VideoDialOutWidget，显示视频通话窗口VideoChatWidget
            videoChatMessageController.receivedChatReceipt(chatMessage);
          } else if (chatMessage.status == MessageStatus.rejected.name) {
            //收到视频通话邀请拒绝回执，关闭本地流，关闭拨号窗口VideoDialOutWidget
            videoChatMessageController.receivedChatReceipt(chatMessage);
          }
        }
        break;
      case ChatMessageSubType.addFriend:
        break;
      case ChatMessageSubType.modifyFriend:
        linkmanService.receiveModifyFriend(chatMessage);
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
      default:
        break;
    }
    //对于接收到的非系统消息，对消息控制器进行刷新
    if (chatMessage.messageType != ChatMessageType.system.name) {
      chatMessageController.notifyListeners();
    }
    notifyListeners();
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

  ///收到webrtc signal消息
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

  sendModifyFriend(String peerId, {String? clientId}) async {
    linkmanService.modifyFriend(peerId, clientId: clientId);
  }

  ///发送PreKeyBundle
  sendPreKeyBundle(String peerId, {required String clientId}) async {
    return;
    PreKeyBundle preKeyBundle =
        signalSessionPool.signalKeyPair.getPreKeyBundle();
    var json = signalSessionPool.signalKeyPair.preKeyBundleToJson(preKeyBundle);
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(peerId,
        clientId: clientId,
        messageType: ChatMessageType.system,
        subMessageType: ChatMessageSubType.preKeyBundle,
        content: json);
    await chatMessageService.sendAndStore(chatMessage,
        cryptoOption: CryptoOption.cryptography);
    logger.i('peerId: $peerId clientId:$clientId sent PreKeyBundle');
  }
}

///收到的最新消息
final GlobalChatMessageController globalChatMessageController =
    GlobalChatMessageController();
