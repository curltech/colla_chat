import 'package:colla_chat/crypto/signalprotocol.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_receipt_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

///跟踪影响全局的消息到来，对不同类型的消息进行分派
class GlobalChatMessageController with ChangeNotifier {
  ChatMessage? _chatMessage;

  ChatMessage? get chatMessage {
    return _chatMessage;
  }

  ///跟踪影响全局的消息到来，对不同类型的消息进行分派
  receiveChatMessage(ChatMessage? chatMessage) async {
    _chatMessage = chatMessage;
    if (chatMessage != null) {
      String messageId = chatMessage.messageId!;
      String peerId = chatMessage.senderPeerId!;
      String? clientId = chatMessage.senderClientId;
      String? title = chatMessage.title;
      String? content = chatMessage.content;
      // String? contentType = chatMessage.contentType;
      // if (content != null) {
      //   if (contentType == null || contentType == ContentType.text.name) {
      //     content = CryptoUtil.utf8ToString(CryptoUtil.decodeBase64(content));
      //   }
      // }
      ChatMessageSubType? subMessageType = StringUtil.enumFromString(
          ChatMessageSubType.values, chatMessage.subMessageType);
      logger
          .i('chatMessage subMessageType:${subMessageType!.name} title:$title');
      switch (subMessageType) {
        case ChatMessageSubType.videoChat:
          break;
        case ChatMessageSubType.chatReceipt:
          ChatMessage? originMessage =
              await chatMessageService.findByMessageId(messageId);
          if (originMessage == null) {
            logger.e('messageId:$messageId original chatMessage is not exist');
            return;
          }
          String? originMessageType = originMessage.messageType;
          String? originSubMessageType = originMessage.subMessageType;
          if (originSubMessageType == ChatMessageSubType.videoChat.name) {
            if (chatMessage.status == MessageStatus.accepted.name) {
              //收到视频通话邀请同意回执，发出本地流，关闭拨号窗口VideoDialOutWidget，显示视频通话窗口VideoChatWidget
              videoChatReceiptController.setChatReceipt(
                  chatMessage, ChatDirect.receive);
            } else if (chatMessage.status == MessageStatus.rejected.name) {
              //收到视频通话邀请拒绝回执，关闭本地流，关闭拨号窗口VideoDialOutWidget
              videoChatReceiptController.setChatReceipt(
                  chatMessage, ChatDirect.receive);
            }
          }
          break;
        case ChatMessageSubType.modifyFriend:
          content = CryptoUtil.utf8ToString(CryptoUtil.decodeBase64(content!));
          linkmanService.receiveModifyFriend(chatMessage, content);
          break;
        case ChatMessageSubType.cancel:
          String? messageId = content;
          if (messageId != null) {
            chatMessageService
                .delete(where: 'messageId=?', whereArgs: [messageId]);
          }
          break;
        case ChatMessageSubType.preKeyBundle:
          content = CryptoUtil.utf8ToString(CryptoUtil.decodeBase64(content!));
          _receivePreKeyBundle(chatMessage, content);
          break;
        case ChatMessageSubType.signal:
          content = CryptoUtil.utf8ToString(CryptoUtil.decodeBase64(content!));
          _receiveSignal(chatMessage, content);
          break;
        default:
          break;
      }
      if (chatMessage.messageType != ChatMessageType.system.name) {
        String? groupPeerId = chatMessage.groupPeerId;
        if (groupPeerId == null) {
          chatMessageController.modify(peerId, clientId: clientId);
        } else {
          chatMessageController.modify(groupPeerId);
        }
      }
    }
    notifyListeners();
  }

  ///收到signal加密初始化消息
  _receivePreKeyBundle(ChatMessage chatMessage, String content) async {
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
  _receiveSignal(ChatMessage chatMessage, String content) async {
    String peerId = chatMessage.senderPeerId!;
    String clientId = chatMessage.senderClientId!;
    if (chatMessage.subMessageType == ChatMessageSubType.signal.name) {
      WebrtcSignal webrtcSignal =
          WebrtcSignal.fromJson(JsonUtil.toJson(content));
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
        data: CryptoUtil.stringToUtf8(json));
    await chatMessageService.sendAndStore(chatMessage,
        cryptoOption: CryptoOption.cryptography);
    logger.i('peerId: $peerId clientId:$clientId sent PreKeyBundle');
  }
}

///收到的最新消息
final GlobalChatMessageController globalChatMessageController =
    GlobalChatMessageController();
